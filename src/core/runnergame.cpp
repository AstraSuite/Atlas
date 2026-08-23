#include "runnergame.hpp"
#include <QRandomGenerator>
#include <QSettings>
#include <algorithm>
#include <cmath>

namespace prism::core {

namespace {
constexpr qreal GROUND_Y = 93.0; // Stand position for T-Rex
constexpr qreal GRAVITY = 0.6;
constexpr qreal INITIAL_JUMP_VELOCITY = -10.0;
constexpr qreal DROP_VELOCITY = -5.0;
constexpr qreal SPEED_DROP_COEFFICIENT = 3.0;
constexpr qreal INITIAL_SPEED = 6.0;
constexpr qreal MAX_SPEED = 13.0;
constexpr qreal ACCELERATION = 0.001;
constexpr qreal VIRTUAL_WIDTH = 600.0;
constexpr qreal CLEAR_TIME = 2.0; // seconds before obstacles spawn
} // namespace

RunnerGame::RunnerGame(QObject* parent)
    : QObject(parent) {
    QSettings settings("prism", "prism");
    m_highScore = settings.value("runner/highScore", 0).toInt();

    m_groundSegments[0] = { 0.0, 2 };
    m_groundSegments[1] = { 600.0, 1202 };

    connect(&m_timer, &QTimer::timeout, this, &RunnerGame::gameLoop);
    m_timer.setInterval(16); // ~60 FPS

    m_cloudList.append({ 120, 35, 0.4 });
    m_cloudList.append({ 320, 50, 0.35 });
    m_cloudList.append({ 500, 30, 0.5 });

    m_starList.append({ 80, 25 });
    m_starList.append({ 210, 45 });
    m_starList.append({ 360, 20 });
    m_starList.append({ 460, 55 });
    m_starList.append({ 540, 35 });
}

RunnerGame* RunnerGame::instance() {
    static auto* s_instance = new RunnerGame();
    return s_instance;
}

QVariantList RunnerGame::groundSegments() const {
    QVariantList list;
    for (int i = 0; i < 2; ++i) {
        QVariantMap map;
        map["x"] = m_groundSegments[i].x;
        map["sourceX"] = m_groundSegments[i].sourceX;
        list.append(map);
    }
    return list;
}

QVariantList RunnerGame::obstacles() const {
    QVariantList list;
    list.reserve(m_obstacleList.size());
    for (const auto& obs : m_obstacleList) {
        QVariantMap map;
        map["type"] = obs.type;
        map["x"] = obs.x;
        map["y"] = obs.y;
        map["width"] = obs.width;
        map["height"] = obs.height;
        map["size"] = obs.size;
        map["frame"] = obs.frame;
        list.append(map);
    }
    return list;
}

QVariantList RunnerGame::clouds() const {
    QVariantList list;
    list.reserve(m_cloudList.size());
    for (const auto& c : m_cloudList) {
        QVariantMap map;
        map["x"] = c.x;
        map["y"] = c.y;
        list.append(map);
    }
    return list;
}

QVariantList RunnerGame::stars() const {
    QVariantList list;
    list.reserve(m_starList.size());
    for (const auto& s : m_starList) {
        QVariantMap map;
        map["x"] = s.x;
        map["y"] = s.y;
        list.append(map);
    }
    return list;
}

void RunnerGame::start() {
    if (m_state == Running) return;
    if (m_state == Crashed) {
        reset();
    }
    m_state = Running;
    m_playingIntro = true;
    m_introProgress = 0.0;
    m_elapsed.start();
    m_timer.start();
    emit stateChanged();
    emit introProgressChanged();
}

void RunnerGame::restart() {
    reset();
    m_state = Running;
    m_playingIntro = false;
    m_introProgress = 1.0;
    m_elapsed.start();
    m_timer.start();
    emit stateChanged();
    emit introProgressChanged();
}

void RunnerGame::reset() {
    m_state = Waiting;
    m_score = 0;
    m_distanceRan = 0;
    m_runningTime = 0;
    m_lastScoreSound = 0;
    m_playerX = 50.0;
    m_playerY = GROUND_Y;
    m_jumpVelocity = 0;
    m_isJumping = false;
    m_isDucking = false;
    m_speedDrop = false;
    m_reachedMinHeight = false;
    m_jumpPendingEnd = false;
    m_playerFrame = 0;
    m_legTimer = 0;
    m_blinkTimer = 0;
    m_speed = INITIAL_SPEED;
    m_obstacleSpawnTimer = 0;
    m_isNightMode = false;
    m_playingIntro = false;
    m_introProgress = 0.0;
    m_obstacleList.clear();

    m_groundSegments[0] = { 0.0, 2 };
    m_groundSegments[1] = { 600.0, 1202 };

    m_timer.stop();
    emit stateChanged();
    emit scoreChanged();
    emit playerMoved();
    emit obstaclesChanged();
    emit groundMoved();
    emit introProgressChanged();
    emit nightModeChanged();
    emit frameUpdated();
}

void RunnerGame::pause() {
    if (m_state == Running) {
        m_timer.stop();
        m_state = Waiting;
        emit stateChanged();
    }
}

void RunnerGame::jump() {
    if (m_state == Waiting) {
        start();
        m_jumpVelocity = INITIAL_JUMP_VELOCITY - (m_speed / 10.0);
        m_isJumping = true;
        m_reachedMinHeight = false;
        m_jumpPendingEnd = false;
        m_speedDrop = false;
        emit jumpSoundTriggered();
        emit playerMoved();
        return;
    }

    if (m_state == Crashed) {
        restart();
        m_jumpVelocity = INITIAL_JUMP_VELOCITY - (m_speed / 10.0);
        m_isJumping = true;
        m_reachedMinHeight = false;
        m_jumpPendingEnd = false;
        m_speedDrop = false;
        emit jumpSoundTriggered();
        emit playerMoved();
        return;
    }

    if (m_state == Running && !m_isJumping) {
        m_jumpVelocity = INITIAL_JUMP_VELOCITY - (m_speed / 10.0);
        m_isJumping = true;
        m_reachedMinHeight = false;
        m_jumpPendingEnd = false;
        m_speedDrop = false;
        emit jumpSoundTriggered();
        emit playerMoved();
    }
}

void RunnerGame::endJump() {
    m_jumpPendingEnd = true;
    if (m_reachedMinHeight && m_jumpVelocity < DROP_VELOCITY) {
        m_jumpVelocity = DROP_VELOCITY;
    }
}

void RunnerGame::setDucking(bool ducking) {
    if (m_isDucking != ducking) {
        m_isDucking = ducking;
        if (m_isJumping && ducking) {
            m_speedDrop = true;
        }
        emit playerMoved();
    }
}

void RunnerGame::gameLoop() {
    qint64 elapsedMs = m_elapsed.restart();
    if (elapsedMs > 100) elapsedMs = 16;
    qreal dt = elapsedMs / 1000.0;
    if (dt <= 0) return;

    qreal framesElapsed = dt * 60.0;

    if (m_state == Running) {
        m_runningTime += dt;

        // Intro zoom animation
        if (m_playingIntro) {
            m_introProgress = std::min(1.0, m_introProgress + dt / 0.4);
            emit introProgressChanged();
            if (m_introProgress >= 1.0) {
                m_playingIntro = false;
            }
        }

        // Speed acceleration
        if (m_speed < MAX_SPEED) {
            m_speed += ACCELERATION * framesElapsed;
        }

        // Distance & score
        m_distanceRan += m_speed * framesElapsed * 0.025;
        int newScore = static_cast<int>(m_distanceRan);
        if (newScore != m_score) {
            m_score = newScore;
            emit scoreChanged();

            if (m_score > 0 && m_score % 100 == 0 && m_score != m_lastScoreSound) {
                m_lastScoreSound = m_score;
                emit scoreSoundTriggered();
            }

            // Invert every 700 points
            bool night = ((m_score / 700) % 2) == 1;
            if (night != m_isNightMode) {
                m_isNightMode = night;
                emit nightModeChanged();
            }
        }

        // Update ground scrolling
        if (!m_playingIntro || m_introProgress > 0.4) {
            updateGround(framesElapsed);
        }

        updatePhysics(framesElapsed, dt);
        updateObstacles(framesElapsed, dt);
        updateClouds(framesElapsed, dt);
    } else if (m_state == Waiting) {
        // Idle blinking
        m_blinkTimer += dt;
        if (m_blinkTimer >= m_blinkDelay) {
            m_playerFrame = 1;
            if (m_blinkTimer >= m_blinkDelay + 0.18) {
                m_playerFrame = 0;
                m_blinkTimer = 0;
                m_blinkDelay = QRandomGenerator::global()->bounded(2000, 6000) / 1000.0;
            }
            emit playerMoved();
        }
    }

    emit frameUpdated();
}

void RunnerGame::updateGround(qreal framesElapsed) {
    qreal moveDist = m_speed * framesElapsed;
    for (int i = 0; i < 2; ++i) {
        m_groundSegments[i].x -= moveDist;
    }

    for (int i = 0; i < 2; ++i) {
        if (m_groundSegments[i].x <= -600.0) {
            int other = 1 - i;
            m_groundSegments[i].x = m_groundSegments[other].x + 600.0;
            m_groundSegments[i].sourceX = (QRandomGenerator::global()->bounded(2) == 0) ? 2 : 1202;
        }
    }

    emit groundMoved();
}

void RunnerGame::updatePhysics(qreal framesElapsed, qreal dt) {
    if (m_isJumping) {
        if (m_speedDrop) {
            m_playerY += m_jumpVelocity * SPEED_DROP_COEFFICIENT * framesElapsed;
        } else {
            m_playerY += m_jumpVelocity * framesElapsed;
        }

        m_jumpVelocity += GRAVITY * framesElapsed;

        if (m_playerY <= GROUND_Y - 30.0 || m_speedDrop) {
            m_reachedMinHeight = true;
            if (m_jumpPendingEnd && m_jumpVelocity < DROP_VELOCITY) {
                m_jumpVelocity = DROP_VELOCITY;
            }
        }

        if (m_playerY >= GROUND_Y) {
            m_playerY = GROUND_Y;
            m_jumpVelocity = 0;
            m_isJumping = false;
            m_speedDrop = false;
            m_reachedMinHeight = false;
            m_jumpPendingEnd = false;
        }
        m_playerFrame = 0;
    } else if (m_isDucking) {
        m_legTimer += dt;
        qreal duckInterval = 1.0 / 8.0;
        if (m_legTimer >= duckInterval) {
            m_legTimer = 0;
            m_playerFrame = (m_playerFrame == 3) ? 4 : 3;
        }
    } else {
        m_legTimer += dt;
        qreal runInterval = 1.0 / 12.0;
        if (m_legTimer >= runInterval) {
            m_legTimer = 0;
            m_playerFrame = (m_playerFrame == 0) ? 1 : 0;
        }
    }

    emit playerMoved();
}

void RunnerGame::updateObstacles(qreal framesElapsed, qreal dt) {
    if (m_runningTime < CLEAR_TIME) {
        return;
    }

    // Move existing obstacles
    for (int i = m_obstacleList.size() - 1; i >= 0; --i) {
        auto& obs = m_obstacleList[i];
        obs.x -= (m_speed + obs.speedOffset) * framesElapsed;

        if (obs.type == Pterodactyl) {
            obs.frameTimer += dt;
            if (obs.frameTimer >= (1.0 / 6.0)) {
                obs.frameTimer = 0;
                obs.frame = (obs.frame == 0) ? 1 : 0;
            }
        }

        if (checkCollision(obs)) {
            crash();
            return;
        }

        if (obs.x + obs.width < -40) {
            m_obstacleList.removeAt(i);
        }
    }

    // Distance accumulated
    m_obstacleSpawnTimer += m_speed * framesElapsed;
    if (m_obstacleSpawnTimer >= m_minObstacleGap) {
        if (m_obstacleList.isEmpty() || (VIRTUAL_WIDTH - m_obstacleList.last().x >= m_minObstacleGap)) {
            spawnObstacle();
            m_obstacleSpawnTimer = 0;
            m_minObstacleGap = QRandomGenerator::global()->bounded(110, 200) + (m_speed * 12.0);
        }
    }

    emit obstaclesChanged();
}

void RunnerGame::spawnObstacle() {
    int r = QRandomGenerator::global()->bounded(100);
    GameObstacle obs;
    obs.frame = 0;
    obs.frameTimer = 0;
    obs.speedOffset = 0;

    if (m_score > 350 && r < 30) {
        // Pterodactyl
        obs.type = Pterodactyl;
        obs.width = 46;
        obs.height = 40;
        obs.size = 1;
        obs.speedOffset = 0.8;

        int hType = QRandomGenerator::global()->bounded(3);
        if (hType == 0) obs.y = 100;
        else if (hType == 1) obs.y = 75;
        else obs.y = 50;
    } else if (r < 65) {
        // Small Cactus
        obs.type = CactusSmall;
        int count = QRandomGenerator::global()->bounded(1, (m_speed > 9.0) ? 4 : 3);
        obs.size = count;
        obs.width = 17 * count;
        obs.height = 35;
        obs.y = 105;
    } else {
        // Large Cactus
        obs.type = CactusLarge;
        int count = QRandomGenerator::global()->bounded(1, (m_speed > 10.0) ? 4 : 3);
        obs.size = count;
        obs.width = 25 * count;
        obs.height = 50;
        obs.y = 90;
    }

    obs.x = VIRTUAL_WIDTH + 20;
    m_obstacleList.append(obs);
}

void RunnerGame::updateClouds(qreal framesElapsed, qreal) {
    for (auto& c : m_cloudList) {
        c.x -= c.speed * framesElapsed;
        if (c.x < -60) {
            c.x = VIRTUAL_WIDTH + QRandomGenerator::global()->bounded(30, 150);
            c.y = QRandomGenerator::global()->bounded(15, 60);
        }
    }
    emit cloudsChanged();
}

bool RunnerGame::checkCollision(const GameObstacle& obs) const {
    qreal tX = m_playerX;
    qreal tY = m_playerY;
    bool duck = m_isDucking && (m_state != Crashed);

    if (duck) {
        QRectF duckBox(tX + 1, tY + 18, 55, 25);
        QRectF obsBox(obs.x + 4, obs.y + 4, obs.width - 8, obs.height - 8);
        return duckBox.intersects(obsBox);
    } else {
        QRectF headBox(tX + 22, tY, 17, 16);
        QRectF bodyBox(tX + 1, tY + 18, 30, 15);
        QRectF feetBox(tX + 10, tY + 35, 14, 12);
        QRectF obsBox(obs.x + 4, obs.y + 4, obs.width - 8, obs.height - 8);

        return headBox.intersects(obsBox) || bodyBox.intersects(obsBox) || feetBox.intersects(obsBox);
    }
}

void RunnerGame::crash() {
    m_state = Crashed;
    m_timer.stop();
    m_playerFrame = 5;

    if (m_score > m_highScore) {
        m_highScore = m_score;
        QSettings settings("prism", "prism");
        settings.setValue("runner/highScore", m_highScore);
        emit highScoreChanged();
    }

    emit hitSoundTriggered();
    emit stateChanged();
    emit playerMoved();
}

} // namespace prism::core
