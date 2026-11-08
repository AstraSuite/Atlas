//! RunnerGame: the offline runner easter egg. Physics run here at ~60 FPS;
//! RunnerGameModal.qml draws the sprites.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    #[qenum(RunnerGame)]
    enum GameState {
        Waiting,
        Running,
        Crashed,
    }

    #[qenum(RunnerGame)]
    enum ObstacleType {
        CactusSmall,
        CactusLarge,
        Pterodactyl,
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(i32, state, READ, NOTIFY = state_changed)]
        #[qproperty(i32, score, READ, NOTIFY = score_changed)]
        #[qproperty(i32, high_score, cxx_name = "highScore", READ, NOTIFY = high_score_changed)]
        #[qproperty(f64, player_x, cxx_name = "playerX", READ, NOTIFY = player_moved)]
        #[qproperty(f64, player_y, cxx_name = "playerY", READ, NOTIFY = player_moved)]
        #[qproperty(bool, is_ducking, cxx_name = "isDucking", READ, NOTIFY = player_moved)]
        #[qproperty(bool, is_jumping, cxx_name = "isJumping", READ, NOTIFY = player_moved)]
        #[qproperty(i32, player_frame, cxx_name = "playerFrame", READ, NOTIFY = player_moved)]
        #[qproperty(f64, intro_progress, cxx_name = "introProgress", READ, NOTIFY = intro_progress_changed)]
        #[qproperty(QList_QVariant, ground_segments, cxx_name = "groundSegments", READ = ground_segments, NOTIFY = ground_moved)]
        #[qproperty(QList_QVariant, obstacles, READ = obstacles, NOTIFY = obstacles_changed)]
        #[qproperty(QList_QVariant, clouds, READ = clouds, NOTIFY = clouds_changed)]
        #[qproperty(QList_QVariant, stars, READ = stars, NOTIFY = stars_changed)]
        #[qproperty(bool, is_night_mode, cxx_name = "isNightMode", READ, NOTIFY = night_mode_changed)]
        #[qproperty(f64, current_speed, cxx_name = "currentSpeed", READ = current_speed, NOTIFY = speed_changed)]
        type RunnerGame = super::RunnerGameRust;

        #[qsignal]
        #[cxx_name = "stateChanged"]
        fn state_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "scoreChanged"]
        fn score_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "highScoreChanged"]
        fn high_score_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "playerMoved"]
        fn player_moved(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "groundMoved"]
        fn ground_moved(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "introProgressChanged"]
        fn intro_progress_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "obstaclesChanged"]
        fn obstacles_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "cloudsChanged"]
        fn clouds_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "starsChanged"]
        fn stars_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "nightModeChanged"]
        fn night_mode_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "speedChanged"]
        fn speed_changed(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "jumpSoundTriggered"]
        fn jump_sound_triggered(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "scoreSoundTriggered"]
        fn score_sound_triggered(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "hitSoundTriggered"]
        fn hit_sound_triggered(self: Pin<&mut RunnerGame>);
        #[qsignal]
        #[cxx_name = "frameUpdated"]
        fn frame_updated(self: Pin<&mut RunnerGame>);

        #[cxx_name = "groundSegments"]
        fn ground_segments(self: &RunnerGame) -> QList_QVariant;
        fn obstacles(self: &RunnerGame) -> QList_QVariant;
        fn clouds(self: &RunnerGame) -> QList_QVariant;
        fn stars(self: &RunnerGame) -> QList_QVariant;
        #[cxx_name = "currentSpeed"]
        fn current_speed(self: &RunnerGame) -> f64;

        #[qinvokable]
        fn start(self: Pin<&mut RunnerGame>);
        #[qinvokable]
        fn jump(self: Pin<&mut RunnerGame>);
        #[qinvokable]
        #[cxx_name = "endJump"]
        fn end_jump(self: Pin<&mut RunnerGame>);
        #[qinvokable]
        #[cxx_name = "setDucking"]
        fn set_ducking(self: Pin<&mut RunnerGame>, ducking: bool);
        #[qinvokable]
        fn restart(self: Pin<&mut RunnerGame>);
        #[qinvokable]
        fn reset(self: Pin<&mut RunnerGame>);
        #[qinvokable]
        fn pause(self: Pin<&mut RunnerGame>);
    }

    impl cxx_qt::Threading for RunnerGame {}
}

use crate::bridge::native::{settings, to_qvariant_list};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QList, QVariant};
use qobject::RunnerGame;
use rand::Rng;
use serde_json::json;
use std::pin::Pin;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Instant;

const GROUND_Y: f64 = 93.0;
const GRAVITY: f64 = 0.6;
const INITIAL_JUMP_VELOCITY: f64 = -10.0;
const DROP_VELOCITY: f64 = -5.0;
const SPEED_DROP_COEFFICIENT: f64 = 3.0;
const INITIAL_SPEED: f64 = 6.0;
const MAX_SPEED: f64 = 13.0;
const ACCELERATION: f64 = 0.001;
const VIRTUAL_WIDTH: f64 = 600.0;
/// Seconds before obstacles spawn.
const CLEAR_TIME: f64 = 2.0;

const WAITING: i32 = 0;
const RUNNING: i32 = 1;
const CRASHED: i32 = 2;
const PTERODACTYL: i32 = 2;

#[derive(Clone)]
struct Obstacle {
    kind: i32,
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    size: i32,
    frame: i32,
    frame_timer: f64,
    speed_offset: f64,
}

struct Rect(f64, f64, f64, f64);

impl Rect {
    /// QRectF::intersects: overlapping with a non-empty area.
    fn intersects(&self, o: &Rect) -> bool {
        self.0 < o.0 + o.2 && o.0 < self.0 + self.2 && self.1 < o.1 + o.3 && o.1 < self.1 + self.3
    }
}

pub struct RunnerGameRust {
    state: i32,
    score: i32,
    high_score: i32,
    distance_ran: f64,
    last_score_sound: i32,
    playing_intro: bool,
    intro_progress: f64,
    running_time: f64,
    player_x: f64,
    player_y: f64,
    jump_velocity: f64,
    is_jumping: bool,
    is_ducking: bool,
    speed_drop: bool,
    reached_min_height: bool,
    jump_pending_end: bool,
    player_frame: i32,
    leg_timer: f64,
    blink_timer: f64,
    blink_delay: f64,
    speed: f64,
    obstacle_spawn_timer: f64,
    min_obstacle_gap: f64,
    is_night_mode: bool,
    ground: [(f64, i32); 2],
    obstacles: Vec<Obstacle>,
    clouds: Vec<(f64, f64, f64)>,
    stars: Vec<(f64, f64)>,
    last_tick: Option<Instant>,
    /// Bumped to stop the frame timer thread.
    timer_generation: Arc<AtomicU64>,
}

impl Default for RunnerGameRust {
    fn default() -> Self {
        Self {
            state: WAITING,
            score: 0,
            high_score: settings::int("runner/highScore", 0),
            distance_ran: 0.0,
            last_score_sound: 0,
            playing_intro: false,
            intro_progress: 0.0,
            running_time: 0.0,
            player_x: 50.0,
            player_y: GROUND_Y,
            jump_velocity: 0.0,
            is_jumping: false,
            is_ducking: false,
            speed_drop: false,
            reached_min_height: false,
            jump_pending_end: false,
            player_frame: 0,
            leg_timer: 0.0,
            blink_timer: 0.0,
            blink_delay: 3.0,
            speed: INITIAL_SPEED,
            obstacle_spawn_timer: 0.0,
            min_obstacle_gap: 120.0,
            is_night_mode: false,
            ground: [(0.0, 2), (600.0, 1202)],
            obstacles: Vec::new(),
            clouds: vec![(120.0, 35.0, 0.4), (320.0, 50.0, 0.35), (500.0, 30.0, 0.5)],
            stars: vec![(80.0, 25.0), (210.0, 45.0), (360.0, 20.0), (460.0, 55.0), (540.0, 35.0)],
            last_tick: None,
            timer_generation: Arc::new(AtomicU64::new(0)),
        }
    }
}

impl RunnerGame {
    fn ground_segments(&self) -> QList<QVariant> {
        let list: Vec<_> = self.ground.iter().map(|(x, sx)| json!({ "x": x, "sourceX": sx })).collect();
        to_qvariant_list(&list)
    }

    fn obstacles(&self) -> QList<QVariant> {
        let list: Vec<_> = self
            .obstacles
            .iter()
            .map(|o| {
                json!({ "type": o.kind, "x": o.x, "y": o.y, "width": o.width, "height": o.height, "size": o.size, "frame": o.frame })
            })
            .collect();
        to_qvariant_list(&list)
    }

    fn clouds(&self) -> QList<QVariant> {
        let list: Vec<_> = self.clouds.iter().map(|(x, y, _)| json!({ "x": x, "y": y })).collect();
        to_qvariant_list(&list)
    }

    fn stars(&self) -> QList<QVariant> {
        let list: Vec<_> = self.stars.iter().map(|(x, y)| json!({ "x": x, "y": y })).collect();
        to_qvariant_list(&list)
    }

    fn current_speed(&self) -> f64 {
        self.speed
    }

    /// Starts the ~60 FPS frame timer.
    fn start_timer(mut self: Pin<&mut Self>) {
        let generation = self.timer_generation.fetch_add(1, Ordering::AcqRel) + 1;
        self.as_mut().rust_mut().last_tick = Some(Instant::now());
        let token = self.timer_generation.clone();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            while token.load(Ordering::Acquire) == generation {
                std::thread::sleep(std::time::Duration::from_millis(16));
                if token.load(Ordering::Acquire) != generation {
                    break;
                }
                if thread.queue(move |game| {
                    if game.timer_generation.load(Ordering::Acquire) == generation {
                        game.game_loop();
                    }
                }).is_err()
                {
                    break;
                }
            }
        });
    }

    fn stop_timer(&self) {
        self.timer_generation.fetch_add(1, Ordering::AcqRel);
    }

    fn begin_running(mut self: Pin<&mut Self>, intro: bool) {
        {
            let mut r = self.as_mut().rust_mut();
            r.state = RUNNING;
            r.playing_intro = intro;
            r.intro_progress = if intro { 0.0 } else { 1.0 };
        }
        self.as_mut().start_timer();
        self.as_mut().state_changed();
        self.intro_progress_changed();
    }

    fn start(mut self: Pin<&mut Self>) {
        if self.state == RUNNING {
            return;
        }
        if self.state == CRASHED {
            self.as_mut().reset();
        }
        self.begin_running(true);
    }

    fn restart(mut self: Pin<&mut Self>) {
        self.as_mut().reset();
        self.begin_running(false);
    }

    fn reset(mut self: Pin<&mut Self>) {
        self.stop_timer();
        {
            let mut r = self.as_mut().rust_mut();
            r.state = WAITING;
            r.score = 0;
            r.distance_ran = 0.0;
            r.running_time = 0.0;
            r.last_score_sound = 0;
            r.player_x = 50.0;
            r.player_y = GROUND_Y;
            r.jump_velocity = 0.0;
            r.is_jumping = false;
            r.is_ducking = false;
            r.speed_drop = false;
            r.reached_min_height = false;
            r.jump_pending_end = false;
            r.player_frame = 0;
            r.leg_timer = 0.0;
            r.blink_timer = 0.0;
            r.speed = INITIAL_SPEED;
            r.obstacle_spawn_timer = 0.0;
            r.is_night_mode = false;
            r.playing_intro = false;
            r.intro_progress = 0.0;
            r.obstacles.clear();
            r.ground = [(0.0, 2), (600.0, 1202)];
        }
        self.as_mut().state_changed();
        self.as_mut().score_changed();
        self.as_mut().player_moved();
        self.as_mut().obstacles_changed();
        self.as_mut().ground_moved();
        self.as_mut().intro_progress_changed();
        self.as_mut().night_mode_changed();
        self.frame_updated();
    }

    fn pause(mut self: Pin<&mut Self>) {
        if self.state == RUNNING {
            self.stop_timer();
            self.as_mut().rust_mut().state = WAITING;
            self.state_changed();
        }
    }

    fn launch_jump(mut self: Pin<&mut Self>) {
        {
            let mut r = self.as_mut().rust_mut();
            r.jump_velocity = INITIAL_JUMP_VELOCITY - r.speed / 10.0;
            r.is_jumping = true;
            r.reached_min_height = false;
            r.jump_pending_end = false;
            r.speed_drop = false;
        }
        self.as_mut().jump_sound_triggered();
        self.player_moved();
    }

    fn jump(mut self: Pin<&mut Self>) {
        match self.state {
            WAITING => {
                self.as_mut().start();
                self.launch_jump();
            }
            CRASHED => {
                self.as_mut().restart();
                self.launch_jump();
            }
            RUNNING if !self.is_jumping => self.launch_jump(),
            _ => {}
        }
    }

    fn end_jump(mut self: Pin<&mut Self>) {
        let mut r = self.as_mut().rust_mut();
        r.jump_pending_end = true;
        if r.reached_min_height && r.jump_velocity < DROP_VELOCITY {
            r.jump_velocity = DROP_VELOCITY;
        }
    }

    fn set_ducking(mut self: Pin<&mut Self>, ducking: bool) {
        if self.is_ducking != ducking {
            let mut r = self.as_mut().rust_mut();
            r.is_ducking = ducking;
            if r.is_jumping && ducking {
                r.speed_drop = true;
            }
            self.player_moved();
        }
    }

    fn game_loop(mut self: Pin<&mut Self>) {
        let now = Instant::now();
        let mut elapsed_ms = self.last_tick.map(|t| now.duration_since(t).as_millis() as i64).unwrap_or(16);
        self.as_mut().rust_mut().last_tick = Some(now);
        if elapsed_ms > 100 {
            elapsed_ms = 16;
        }
        let dt = elapsed_ms as f64 / 1000.0;
        if dt <= 0.0 {
            return;
        }
        let frames = dt * 60.0;

        if self.state == RUNNING {
            self.as_mut().rust_mut().running_time += dt;
            if self.playing_intro {
                let progress = (self.intro_progress + dt / 0.4).min(1.0);
                let mut r = self.as_mut().rust_mut();
                r.intro_progress = progress;
                if progress >= 1.0 {
                    r.playing_intro = false;
                }
                self.as_mut().intro_progress_changed();
            }
            if self.speed < MAX_SPEED {
                self.as_mut().rust_mut().speed += ACCELERATION * frames;
            }
            let distance = self.distance_ran + self.speed * frames * 0.025;
            self.as_mut().rust_mut().distance_ran = distance;
            let new_score = distance as i32;
            if new_score != self.score {
                self.as_mut().rust_mut().score = new_score;
                self.as_mut().score_changed();
                if new_score > 0 && new_score % 100 == 0 && new_score != self.last_score_sound {
                    self.as_mut().rust_mut().last_score_sound = new_score;
                    self.as_mut().score_sound_triggered();
                }
                // Invert every 700 points.
                let night = (new_score / 700) % 2 == 1;
                if night != self.is_night_mode {
                    self.as_mut().rust_mut().is_night_mode = night;
                    self.as_mut().night_mode_changed();
                }
            }
            if !self.playing_intro || self.intro_progress > 0.4 {
                self.as_mut().update_ground(frames);
            }
            self.as_mut().update_physics(frames, dt);
            if !self.as_mut().update_obstacles(frames, dt) {
                return;
            }
            self.as_mut().update_clouds(frames);
        } else if self.state == WAITING {
            // Idle blinking.
            self.as_mut().rust_mut().blink_timer += dt;
            if self.blink_timer >= self.blink_delay {
                let mut r = self.as_mut().rust_mut();
                r.player_frame = 1;
                if r.blink_timer >= r.blink_delay + 0.18 {
                    r.player_frame = 0;
                    r.blink_timer = 0.0;
                    r.blink_delay = rand::thread_rng().gen_range(2000..6000) as f64 / 1000.0;
                }
                self.as_mut().player_moved();
            }
        }
        self.frame_updated();
    }

    fn update_ground(mut self: Pin<&mut Self>, frames: f64) {
        {
            let mut r = self.as_mut().rust_mut();
            let distance = r.speed * frames;
            for seg in r.ground.iter_mut() {
                seg.0 -= distance;
            }
            for i in 0..2 {
                if r.ground[i].0 <= -600.0 {
                    r.ground[i].0 = r.ground[1 - i].0 + 600.0;
                    r.ground[i].1 = if rand::thread_rng().gen_bool(0.5) { 2 } else { 1202 };
                }
            }
        }
        self.ground_moved();
    }

    fn update_physics(mut self: Pin<&mut Self>, frames: f64, dt: f64) {
        {
            let mut r = self.as_mut().rust_mut();
            if r.is_jumping {
                let coefficient = if r.speed_drop { SPEED_DROP_COEFFICIENT } else { 1.0 };
                r.player_y += r.jump_velocity * coefficient * frames;
                r.jump_velocity += GRAVITY * frames;
                if r.player_y <= GROUND_Y - 30.0 || r.speed_drop {
                    r.reached_min_height = true;
                    if r.jump_pending_end && r.jump_velocity < DROP_VELOCITY {
                        r.jump_velocity = DROP_VELOCITY;
                    }
                }
                if r.player_y >= GROUND_Y {
                    r.player_y = GROUND_Y;
                    r.jump_velocity = 0.0;
                    r.is_jumping = false;
                    r.speed_drop = false;
                    r.reached_min_height = false;
                    r.jump_pending_end = false;
                }
                r.player_frame = 0;
            } else if r.is_ducking {
                r.leg_timer += dt;
                if r.leg_timer >= 1.0 / 8.0 {
                    r.leg_timer = 0.0;
                    r.player_frame = if r.player_frame == 3 { 4 } else { 3 };
                }
            } else {
                r.leg_timer += dt;
                if r.leg_timer >= 1.0 / 12.0 {
                    r.leg_timer = 0.0;
                    r.player_frame = if r.player_frame == 0 { 1 } else { 0 };
                }
            }
        }
        self.player_moved();
    }

    fn collides(&self, o: &Obstacle) -> bool {
        let (x, y) = (self.player_x, self.player_y);
        let obstacle = Rect(o.x + 4.0, o.y + 4.0, o.width - 8.0, o.height - 8.0);
        if self.is_ducking && self.state != CRASHED {
            return Rect(x + 1.0, y + 18.0, 55.0, 25.0).intersects(&obstacle);
        }
        [Rect(x + 22.0, y, 17.0, 16.0), Rect(x + 1.0, y + 18.0, 30.0, 15.0), Rect(x + 10.0, y + 35.0, 14.0, 12.0)]
            .iter()
            .any(|r| r.intersects(&obstacle))
    }

    /// Returns false when the player crashed.
    fn update_obstacles(mut self: Pin<&mut Self>, frames: f64, dt: f64) -> bool {
        if self.running_time < CLEAR_TIME {
            return true;
        }
        let speed = self.speed;
        for i in (0..self.obstacles.len()).rev() {
            {
                let mut r = self.as_mut().rust_mut();
                let o = &mut r.obstacles[i];
                o.x -= (speed + o.speed_offset) * frames;
                if o.kind == PTERODACTYL {
                    o.frame_timer += dt;
                    if o.frame_timer >= 1.0 / 6.0 {
                        o.frame_timer = 0.0;
                        o.frame = if o.frame == 0 { 1 } else { 0 };
                    }
                }
            }
            let o = self.obstacles[i].clone();
            if self.collides(&o) {
                self.crash();
                return false;
            }
            if o.x + o.width < -40.0 {
                self.as_mut().rust_mut().obstacles.remove(i);
            }
        }
        self.as_mut().rust_mut().obstacle_spawn_timer += speed * frames;
        if self.obstacle_spawn_timer >= self.min_obstacle_gap {
            let room = self.obstacles.last().map(|o| VIRTUAL_WIDTH - o.x >= self.min_obstacle_gap).unwrap_or(true);
            if room {
                self.as_mut().spawn_obstacle();
                let mut r = self.as_mut().rust_mut();
                r.obstacle_spawn_timer = 0.0;
                r.min_obstacle_gap = rand::thread_rng().gen_range(110..200) as f64 + r.speed * 12.0;
            }
        }
        self.obstacles_changed();
        true
    }

    fn spawn_obstacle(mut self: Pin<&mut Self>) {
        let mut rng = rand::thread_rng();
        let roll = rng.gen_range(0..100);
        let (score, speed) = (self.score, self.speed);
        let obstacle = if score > 350 && roll < 30 {
            let y = match rng.gen_range(0..3) {
                0 => 100.0,
                1 => 75.0,
                _ => 50.0,
            };
            Obstacle { kind: PTERODACTYL, x: 0.0, y, width: 46.0, height: 40.0, size: 1, frame: 0, frame_timer: 0.0, speed_offset: 0.8 }
        } else if roll < 65 {
            let count = rng.gen_range(1..if speed > 9.0 { 4 } else { 3 });
            Obstacle { kind: 0, x: 0.0, y: 105.0, width: 17.0 * count as f64, height: 35.0, size: count, frame: 0, frame_timer: 0.0, speed_offset: 0.0 }
        } else {
            let count = rng.gen_range(1..if speed > 10.0 { 4 } else { 3 });
            Obstacle { kind: 1, x: 0.0, y: 90.0, width: 25.0 * count as f64, height: 50.0, size: count, frame: 0, frame_timer: 0.0, speed_offset: 0.0 }
        };
        self.as_mut().rust_mut().obstacles.push(Obstacle { x: VIRTUAL_WIDTH + 20.0, ..obstacle });
    }

    fn update_clouds(mut self: Pin<&mut Self>, frames: f64) {
        {
            let mut rng = rand::thread_rng();
            let mut r = self.as_mut().rust_mut();
            for cloud in r.clouds.iter_mut() {
                cloud.0 -= cloud.2 * frames;
                if cloud.0 < -60.0 {
                    cloud.0 = VIRTUAL_WIDTH + rng.gen_range(30..150) as f64;
                    cloud.1 = rng.gen_range(15..60) as f64;
                }
            }
        }
        self.clouds_changed();
    }

    fn crash(mut self: Pin<&mut Self>) {
        self.stop_timer();
        {
            let mut r = self.as_mut().rust_mut();
            r.state = CRASHED;
            r.player_frame = 5;
        }
        if self.score > self.high_score {
            let score = self.score;
            self.as_mut().rust_mut().high_score = score;
            settings::set_int("runner/highScore", score);
            self.as_mut().high_score_changed();
        }
        self.as_mut().hit_sound_triggered();
        self.as_mut().state_changed();
        self.player_moved();
    }
}
