#pragma once

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
    QVector<QRectF> collisionBoxes;
};

struct GameCloud {
    qreal x;
    qreal y;
    qreal speed;
};

class RunnerGame : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int state READ state NOTIFY stateChanged)
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(int highScore READ highScore NOTIFY highScoreChanged)
    Q_PROPERTY(qreal playerY READ playerY NOTIFY playerMoved)
    Q_PROPERTY(bool isDucking READ isDucking NOTIFY playerMoved)
    Q_PROPERTY(bool isJumping READ isJumping NOTIFY playerMoved)
    Q_PROPERTY(int playerFrame READ playerFrame NOTIFY playerMoved)
    Q_PROPERTY(qreal groundX READ groundX NOTIFY groundMoved)
    Q_PROPERTY(QVariantList obstacles READ obstacles NOTIFY obstaclesChanged)
    Q_PROPERTY(QVariantList clouds READ clouds NOTIFY cloudsChanged)
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

    explicit RunnerGame(QObject* parent = nullptr);
    ~RunnerGame() override = default;

    static RunnerGame* instance();

    [[nodiscard]] int state() const { return m_state; }
    [[nodiscard]] int score() const { return m_score; }
    [[nodiscard]] int highScore() const { return m_highScore; }
    [[nodiscard]] qreal playerY() const { return m_playerY; }
    [[nodiscard]] bool isDucking() const { return m_isDucking; }
    [[nodiscard]] bool isJumping() const { return m_isJumping; }
    [[nodiscard]] int playerFrame() const { return m_playerFrame; }
    [[nodiscard]] qreal groundX() const { return m_groundX; }
    [[nodiscard]] QVariantList obstacles() const;
    [[nodiscard]] QVariantList clouds() const;
    [[nodiscard]] bool isNightMode() const { return m_isNightMode; }
    [[nodiscard]] qreal currentSpeed() const { return m_currentSpeed; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void jump();
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
    void obstaclesChanged();
    void cloudsChanged();
    void nightModeChanged();
    void speedChanged();
    void jumpSoundTriggered();
    void scoreSoundTriggered();
    void hitSoundTriggered();
    void frameUpdated();

private slots:
    void gameLoop();

private:
    void updatePhysics(qreal dt);
    void updateObstacles(qreal dt);
    void updateClouds(qreal dt);
    void spawnObstacle();
    void spawnCloud();
    bool checkCollision(const GameObstacle& obs) const;
    void crash();

    int m_state = Waiting;
    int m_score = 0;
    int m_highScore = 0;
    qreal m_distanceRan = 0;
    int m_lastScoreSound = 0;

    // Player physics
    qreal m_playerY = 0; // 0 is ground
    qreal m_playerVy = 0;
    bool m_isJumping = false;
    bool m_isDucking = false;
    int m_playerFrame = 0;
    qreal m_legTimer = 0;
    qreal m_blinkTimer = 0;
    bool m_blinkState = false;

    // World physics
    qreal m_groundX = 0;
    qreal m_currentSpeed = 360.0; // pixels per second in virtual 600x150 space
    qreal m_obstacleSpawnTimer = 0;
    qreal m_minObstacleGap = 180.0;
    bool m_isNightMode = false;
    qreal m_nightModeTimer = 0;

    QVector<GameObstacle> m_obstacleList;
    QVector<GameCloud> m_cloudList;

    QTimer m_timer;
    QElapsedTimer m_elapsed;
};

} // namespace prism::core
