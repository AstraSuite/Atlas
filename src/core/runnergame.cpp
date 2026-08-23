#include "runnergame.hpp"
#include <QRandomGenerator>
#include <QSettings>
#include <algorithm>
#include <cmath>

namespace prism::core {

namespace {
constexpr qreal GRAVITY = 1850.0;
constexpr qreal JUMP_VELOCITY = 590.0;
constexpr qreal DUCK_DROP_VELOCITY = 750.0;
constexpr qreal INITIAL_SPEED = 360.0;
constexpr qreal MAX_SPEED = 820.0;
constexpr qreal SPEED_ACCEL = 4.5; // per second
constexpr qreal VIRTUAL_WIDTH = 600.0;
constexpr qreal VIRTUAL_HEIGHT = 150.0;
constexpr qreal TREX_X = 40.0;
constexpr qreal TREX_NORMAL_WIDTH = 44.0;
constexpr qreal TREX_NORMAL_HEIGHT = 47.0;
constexpr qreal TREX_DUCK_WIDTH = 59.0;
constexpr qreal TREX_DUCK_HEIGHT = 25.0;
} // namespace

RunnerGame::RunnerGame(QObject* parent)
    : QObject(parent) {
    QSettings settings("prism", "prism");
    m_highScore = settings.value("runner/highScore", 0).toInt();

    connect(&m_timer, &QTimer::timeout, this, &RunnerGame::gameLoop);
    m_timer.setInterval(16); // ~60 FPS

    // Seed initial background clouds
    m_cloudList.append({ 150, 35, 30.0 });
    m_cloudList.append({ 380, 50, 35.0 });
    m_cloudList.append({ 550, 30, 28.0 });
}

RunnerGame* RunnerGame::instance() {
    static auto* s_instance = new RunnerGame();
    return s_instance;
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

void RunnerGame::start() {
    if (m_state == Running) return;
    if (m_state == Crashed) {
        reset();
    }
    m_state = Running;
    m_elapsed.start();
    m_timer.start();
    emit stateChanged();
}

void RunnerGame::restart() {
    reset();
    start();
}

void RunnerGame::reset() {
    m_state = Waiting;
    m_score = 0;
    m_distanceRan = 0;
    m_lastScoreSound = 0;
    m_playerY = 0;
    m_playerVy = 0;
    m_isJumping = false;
    m_isDucking = false;
    m_playerFrame = 0;
    m_legTimer = 0;
    m_currentSpeed = INITIAL_SPEED;
    m_obstacleSpawnTimer = 0;
    m_isNightMode = false;
    m_nightModeTimer = 0;
    m_obstacleList.clear();

    m_timer.stop();
    emit stateChanged();
    emit scoreChanged();
    emit playerMoved();
    emit obstaclesChanged();
    emit groundMoved();
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
    if (m_state == Waiting || m_state == Crashed) {
        restart();
        m_playerVy = JUMP_VELOCITY;
        m_isJumping = true;
        m_isDucking = false;
        emit jumpSoundTriggered();
        return;
    }

    if (m_state == Running && !m_isJumping) {
        m_playerVy = JUMP_VELOCITY;
        m_isJumping = true;
        m_isDucking = false;
        emit jumpSoundTriggered();
        emit playerMoved();
    }
}

void RunnerGame::setDucking(bool ducking) {
    if (m_isDucking != ducking) {
        m_isDucking = ducking;
        if (m_isJumping && ducking) {
            m_playerVy -= DUCK_DROP_VELOCITY * 0.5;
        }
        emit playerMoved();
    }
}

void RunnerGame::gameLoop() {
    qint64 elapsedMs = m_elapsed.restart();
    if (elapsedMs > 100) elapsedMs = 16;
    qreal dt = elapsedMs / 1000.0;
    if (dt <= 0) return;

    if (m_state == Running) {
        // Accelerate
        if (m_currentSpeed < MAX_SPEED) {
            m_currentSpeed += SPEED_ACCEL * dt;
        }

        // Distance & score
        m_distanceRan += m_currentSpeed * dt * 0.025;
        int newScore = static_cast<int>(m_distanceRan);
        if (newScore != m_score) {
            m_score = newScore;
            emit scoreChanged();

            if (m_score > 0 && m_score % 100 == 0 && m_score != m_lastScoreSound) {
                m_lastScoreSound = m_score;
                emit scoreSoundTriggered();
            }

            // Day / Night cycle every 700 points
            bool night = ((m_score / 700) % 2) == 1;
            if (night != m_isNightMode) {
                m_isNightMode = night;
                emit nightModeChanged();
            }
        }

        // Ground scroll
        m_groundX += m_currentSpeed * dt;
        if (m_groundX >= VIRTUAL_WIDTH) {
            m_groundX = std::fmod(m_groundX, VIRTUAL_WIDTH);
        }
        emit groundMoved();

        updatePhysics(dt);
        updateObstacles(dt);
        updateClouds(dt);
    } else if (m_state == Waiting) {
        // Idle blinking
        m_blinkTimer += dt;
        if (m_blinkTimer > 3.0) {
            m_blinkState = !m_blinkState;
            m_playerFrame = m_blinkState ? 1 : 0;
            if (m_blinkTimer > 3.3) {
                m_blinkTimer = 0;
                m_blinkState = false;
                m_playerFrame = 0;
            }
            emit playerMoved();
        }
    }

    emit frameUpdated();
}

void RunnerGame::updatePhysics(qreal dt) {
    if (m_isJumping) {
        m_playerVy -= GRAVITY * dt;
        m_playerY += m_playerVy * dt;

        if (m_playerY <= 0) {
            m_playerY = 0;
            m_playerVy = 0;
            m_isJumping = false;
        }
        m_playerFrame = 2; // Jump frame
    } else if (m_isDucking) {
        m_legTimer += dt;
        qreal legInterval = std::max(0.04, 0.12 - (m_currentSpeed / MAX_SPEED) * 0.06);
        if (m_legTimer >= legInterval) {
            m_legTimer = 0;
            m_playerFrame = (m_playerFrame == 3) ? 4 : 3; // Ducking run frames
        }
    } else {
        m_legTimer += dt;
        qreal legInterval = std::max(0.04, 0.12 - (m_currentSpeed / MAX_SPEED) * 0.06);
        if (m_legTimer >= legInterval) {
            m_legTimer = 0;
            m_playerFrame = (m_playerFrame == 0) ? 1 : 0; // Standing run frames
        }
    }

    emit playerMoved();
}

void RunnerGame::updateObstacles(qreal dt) {
    // Move existing obstacles
    for (int i = m_obstacleList.size() - 1; i >= 0; --i) {
        auto& obs = m_obstacleList[i];
        obs.x -= (m_currentSpeed + obs.speedOffset) * dt;

        // Animate pterodactyl wings
        if (obs.type == Pterodactyl) {
            obs.frameTimer += dt;
            if (obs.frameTimer >= 0.15) {
                obs.frameTimer = 0;
                obs.frame = (obs.frame == 0) ? 1 : 0;
            }
        }

        // Check collision
        if (checkCollision(obs)) {
            crash();
            return;
        }

        // Remove offscreen
        if (obs.x + obs.width < -20) {
            m_obstacleList.removeAt(i);
        }
    }

    // Spawn new obstacles
    m_obstacleSpawnTimer += dt;
    qreal spawnInterval = m_minObstacleGap / m_currentSpeed;
    if (m_obstacleSpawnTimer >= spawnInterval) {
        if (m_obstacleList.isEmpty() || (VIRTUAL_WIDTH - m_obstacleList.last().x >= m_minObstacleGap)) {
            spawnObstacle();
            m_obstacleSpawnTimer = 0;
            m_minObstacleGap = QRandomGenerator::global()->bounded(160, 320);
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

    if (m_score > 350 && r < 28) {
        // Pterodactyl
        obs.type = Pterodactyl;
        obs.width = 46;
        obs.height = 40;
        obs.size = 1;
        obs.speedOffset = 25.0;

        // 3 heights: low (jump over), mid (duck under), high (run under)
        int hType = QRandomGenerator::global()->bounded(3);
        if (hType == 0) obs.y = 15;      // Low (y=15 above ground)
        else if (hType == 1) obs.y = 45; // Mid (y=45 above ground)
        else obs.y = 75;                 // High (y=75 above ground)
    } else if (r < 65) {
        // Small Cactus
        obs.type = CactusSmall;
        int count = QRandomGenerator::global()->bounded(1, (m_currentSpeed > 550) ? 4 : 3);
        obs.size = count;
        obs.width = 17 * count;
        obs.height = 35;
        obs.y = 0;
    } else {
        // Large Cactus
        obs.type = CactusLarge;
        int count = QRandomGenerator::global()->bounded(1, (m_currentSpeed > 600) ? 4 : 3);
        obs.size = count;
        obs.width = 25 * count;
        obs.height = 50;
        obs.y = 0;
    }

    obs.x = VIRTUAL_WIDTH + 10;
    m_obstacleList.append(obs);
}

void RunnerGame::updateClouds(qreal dt) {
    for (auto& c : m_cloudList) {
        c.x -= c.speed * dt;
        if (c.x < -60) {
            c.x = VIRTUAL_WIDTH + QRandomGenerator::global()->bounded(20, 100);
            c.y = QRandomGenerator::global()->bounded(20, 65);
        }
    }
    emit cloudsChanged();
}

bool RunnerGame::checkCollision(const GameObstacle& obs) const {
    qreal playerW = m_isDucking ? TREX_DUCK_WIDTH : TREX_NORMAL_WIDTH;
    qreal playerH = m_isDucking ? TREX_DUCK_HEIGHT : TREX_NORMAL_HEIGHT;
    qreal playerX = TREX_X;
    qreal playerY = m_playerY; // 0 is ground

    // Generous padding to match original gameplay feel
    qreal padX = 6.0;
    qreal padY = 5.0;

    QRectF playerRect(playerX + padX, playerY + padY, playerW - padX * 2, playerH - padY * 2);
    QRectF obsRect(obs.x + padX, obs.y + padY, obs.width - padX * 2, obs.height - padY * 2);

    return playerRect.intersects(obsRect);
}

void RunnerGame::crash() {
    m_state = Crashed;
    m_timer.stop();
    m_playerFrame = 5; // Crashed shocked eye frame

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
