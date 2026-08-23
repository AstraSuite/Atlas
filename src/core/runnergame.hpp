#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QElapsedTimer>
#include <QVector>
#include <QRectF>
#include <qqmlintegration.h>

namespace prism::core {

struct GameObstacle {
    int type; // 0: CACTUS_SMALL, 1: CACTUS_LARGE, 2: PTERODACTYL
    qreal x;
    qreal y;
    qreal width;
    qreal height;
    int size; // 1, 2, or 3 for cacti
    int frame; // For pterodactyl flapping
    qreal frameTimer;
    qreal speedOffset;
};

struct GameCloud {
    qreal x;
    qreal y;
    qreal speed;
};

struct GameStar {
    qreal x;
    qreal y;
};

struct GroundSegment {
    qreal x;
    int sourceX; // 2 or 1202 in 2x HDPI sprite
};

class RunnerGame : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int state READ state NOTIFY stateChanged)
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(int highScore READ highScore NOTIFY highScoreChanged)
    Q_PROPERTY(qreal playerX READ playerX NOTIFY playerMoved)
    Q_PROPERTY(qreal playerY READ playerY NOTIFY playerMoved)
    Q_PROPERTY(bool isDucking READ isDucking NOTIFY playerMoved)
    Q_PROPERTY(bool isJumping READ isJumping NOTIFY playerMoved)
    Q_PROPERTY(int playerFrame READ playerFrame NOTIFY playerMoved)
    Q_PROPERTY(qreal introProgress READ introProgress NOTIFY introProgressChanged)
    Q_PROPERTY(QVariantList groundSegments READ groundSegments NOTIFY groundMoved)
    Q_PROPERTY(QVariantList obstacles READ obstacles NOTIFY obstaclesChanged)
    Q_PROPERTY(QVariantList clouds READ clouds NOTIFY cloudsChanged)
    Q_PROPERTY(QVariantList stars READ stars NOTIFY starsChanged)
    Q_PROPERTY(bool isNightMode READ isNightMode NOTIFY nightModeChanged)
    Q_PROPERTY(qreal currentSpeed READ currentSpeed NOTIFY speedChanged)

public:
    enum GameState {
        Waiting = 0,
        Running = 1,
        Crashed = 2
    };
    Q_ENUM(GameState)

    enum ObstacleType {
        CactusSmall = 0,
        CactusLarge = 1,
        Pterodactyl = 2
    };
    Q_ENUM(ObstacleType)

    ~RunnerGame() override = default;

    static RunnerGame* instance();
    static RunnerGame* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    [[nodiscard]] int state() const { return m_state; }
    [[nodiscard]] int score() const { return m_score; }
    [[nodiscard]] int highScore() const { return m_highScore; }
    [[nodiscard]] qreal playerX() const { return m_playerX; }
    [[nodiscard]] qreal playerY() const { return m_playerY; }
    [[nodiscard]] bool isDucking() const { return m_isDucking; }
    [[nodiscard]] bool isJumping() const { return m_isJumping; }
    [[nodiscard]] int playerFrame() const { return m_playerFrame; }
    [[nodiscard]] qreal introProgress() const { return m_introProgress; }
    [[nodiscard]] QVariantList groundSegments() const;
    [[nodiscard]] QVariantList obstacles() const;
    [[nodiscard]] QVariantList clouds() const;
    [[nodiscard]] QVariantList stars() const;
    [[nodiscard]] bool isNightMode() const { return m_isNightMode; }
    [[nodiscard]] qreal currentSpeed() const { return m_speed; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void jump();
    Q_INVOKABLE void endJump();
    Q_INVOKABLE void setDucking(bool ducking);
    Q_INVOKABLE void restart();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void pause();

signals:
    void stateChanged();
    void scoreChanged();
    void highScoreChanged();
    void playerMoved();
    void groundMoved();
    void introProgressChanged();
    void obstaclesChanged();
    void cloudsChanged();
    void starsChanged();
    void nightModeChanged();
    void speedChanged();
    void jumpSoundTriggered();
    void scoreSoundTriggered();
    void hitSoundTriggered();
    void frameUpdated();

private slots:
    void gameLoop();

private:
    explicit RunnerGame(QObject* parent = nullptr);
    void updatePhysics(qreal framesElapsed, qreal dt);
    void updateObstacles(qreal framesElapsed, qreal dt);
    void updateClouds(qreal framesElapsed, qreal dt);
    void updateGround(qreal framesElapsed);
    void spawnObstacle();
    void spawnCloud();
    bool checkCollision(const GameObstacle& obs) const;
    void crash();

    int m_state = Waiting;
    int m_score = 0;
    int m_highScore = 0;
    qreal m_distanceRan = 0;
    int m_lastScoreSound = 0;

    // Intro animation
    bool m_playingIntro = false;
    qreal m_introProgress = 0.0;
    qreal m_runningTime = 0.0;

    // Player physics
    qreal m_playerX = 50.0;
    qreal m_playerY = 93.0;
    qreal m_jumpVelocity = 0.0;
    bool m_isJumping = false;
    bool m_isDucking = false;
    bool m_speedDrop = false;
    bool m_reachedMinHeight = false;
    bool m_jumpPendingEnd = false;
    int m_playerFrame = 0;
    qreal m_legTimer = 0;
    qreal m_blinkTimer = 0;
    qreal m_blinkDelay = 3.0;

    // World physics
    qreal m_speed = 6.0;
    qreal m_obstacleSpawnTimer = 0;
    qreal m_minObstacleGap = 120.0;
    bool m_isNightMode = false;

    GroundSegment m_groundSegments[2];
    QVector<GameObstacle> m_obstacleList;
    QVector<GameCloud> m_cloudList;
    QVector<GameStar> m_starList;

    QTimer m_timer;
    QElapsedTimer m_elapsed;
};

} // namespace prism::core
