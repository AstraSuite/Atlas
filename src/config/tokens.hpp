#pragma once

#include "font.hpp"
#include <QObject>
#include <QEasingCurve>
#include <QList>
#include <qqmlintegration.h>

namespace prism::config {

class RoundingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int extraSmall READ extraSmall CONSTANT)
    Q_PROPERTY(int small READ small CONSTANT)
    Q_PROPERTY(int medium READ medium CONSTANT)
    Q_PROPERTY(int large READ large CONSTANT)
    Q_PROPERTY(int largeIncreased READ largeIncreased CONSTANT)
    Q_PROPERTY(int extraLarge READ extraLarge CONSTANT)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased CONSTANT)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge CONSTANT)
    Q_PROPERTY(int full READ full CONSTANT)

public:
    explicit RoundingTokens(QObject* parent = nullptr) : QObject(parent) {}

    int extraSmall() const { return 4; }
    int small() const { return 8; }
    int medium() const { return 12; }
    int large() const { return 16; }
    int largeIncreased() const { return 20; }
    int extraLarge() const { return 28; }
    int extraLargeIncreased() const { return 32; }
    int extraExtraLarge() const { return 48; }
    int full() const { return 9999; }
};

class SpacingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int extraSmall READ extraSmall CONSTANT)
    Q_PROPERTY(int small READ small CONSTANT)
    Q_PROPERTY(int medium READ medium CONSTANT)
    Q_PROPERTY(int large READ large CONSTANT)
    Q_PROPERTY(int largeIncreased READ largeIncreased CONSTANT)
    Q_PROPERTY(int extraLarge READ extraLarge CONSTANT)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased CONSTANT)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge CONSTANT)

public:
    explicit SpacingTokens(QObject* parent = nullptr) : QObject(parent) {}

    int extraSmall() const { return 4; }
    int small() const { return 8; }
    int medium() const { return 12; }
    int large() const { return 16; }
    int largeIncreased() const { return 20; }
    int extraLarge() const { return 28; }
    int extraLargeIncreased() const { return 32; }
    int extraExtraLarge() const { return 48; }
};

class PaddingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int extraSmall READ extraSmall CONSTANT)
    Q_PROPERTY(int small READ small CONSTANT)
    Q_PROPERTY(int medium READ medium CONSTANT)
    Q_PROPERTY(int large READ large CONSTANT)
    Q_PROPERTY(int largeIncreased READ largeIncreased CONSTANT)
    Q_PROPERTY(int extraLarge READ extraLarge CONSTANT)
    Q_PROPERTY(int extraLargeIncreased READ extraLargeIncreased CONSTANT)
    Q_PROPERTY(int extraExtraLarge READ extraExtraLarge CONSTANT)

public:
    explicit PaddingTokens(QObject* parent = nullptr) : QObject(parent) {}

    int extraSmall() const { return 4; }
    int small() const { return 8; }
    int medium() const { return 12; }
    int large() const { return 16; }
    int largeIncreased() const { return 20; }
    int extraLarge() const { return 28; }
    int extraLargeIncreased() const { return 32; }
    int extraExtraLarge() const { return 48; }
};

class AnimDurationTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int small READ small CONSTANT)
    Q_PROPERTY(int normal READ normal CONSTANT)
    Q_PROPERTY(int large READ large CONSTANT)
    Q_PROPERTY(int extraLarge READ extraLarge CONSTANT)
    Q_PROPERTY(int expressiveFastSpatial READ expressiveFastSpatial CONSTANT)
    Q_PROPERTY(int expressiveDefaultSpatial READ expressiveDefaultSpatial CONSTANT)
    Q_PROPERTY(int expressiveSlowSpatial READ expressiveSlowSpatial CONSTANT)
    Q_PROPERTY(int expressiveFastEffects READ expressiveFastEffects CONSTANT)
    Q_PROPERTY(int expressiveDefaultEffects READ expressiveDefaultEffects CONSTANT)
    Q_PROPERTY(int expressiveSlowEffects READ expressiveSlowEffects CONSTANT)

public:
    explicit AnimDurationTokens(QObject* parent = nullptr) : QObject(parent) {}

    int small() const { return 200; }
    int normal() const { return 400; }
    int large() const { return 600; }
    int extraLarge() const { return 1000; }
    int expressiveFastSpatial() const { return 350; }
    int expressiveDefaultSpatial() const { return 500; }
    int expressiveSlowSpatial() const { return 650; }
    int expressiveFastEffects() const { return 150; }
    int expressiveDefaultEffects() const { return 200; }
    int expressiveSlowEffects() const { return 300; }
};

class AnimCurves : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QEasingCurve emphasized READ emphasized CONSTANT)
    Q_PROPERTY(QEasingCurve emphasizedAccel READ emphasizedAccel CONSTANT)
    Q_PROPERTY(QEasingCurve emphasizedDecel READ emphasizedDecel CONSTANT)
    Q_PROPERTY(QEasingCurve standard READ standard CONSTANT)
    Q_PROPERTY(QEasingCurve standardAccel READ standardAccel CONSTANT)
    Q_PROPERTY(QEasingCurve standardDecel READ standardDecel CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveFastSpatial READ expressiveFastSpatial CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveDefaultSpatial READ expressiveDefaultSpatial CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveSlowSpatial READ expressiveSlowSpatial CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveFastEffects READ expressiveFastEffects CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveDefaultEffects READ expressiveDefaultEffects CONSTANT)
    Q_PROPERTY(QEasingCurve expressiveSlowEffects READ expressiveSlowEffects CONSTANT)
    Q_PROPERTY(prism::config::AnimDurationTokens* durations READ durations CONSTANT)

public:
    explicit AnimCurves(QObject* parent = nullptr);

    QEasingCurve emphasized() const;
    QEasingCurve emphasizedAccel() const;
    QEasingCurve emphasizedDecel() const;
    QEasingCurve standard() const;
    QEasingCurve standardAccel() const;
    QEasingCurve standardDecel() const;
    QEasingCurve expressiveFastSpatial() const;
    QEasingCurve expressiveDefaultSpatial() const;
    QEasingCurve expressiveSlowSpatial() const;
    QEasingCurve expressiveFastEffects() const;
    QEasingCurve expressiveDefaultEffects() const;
    QEasingCurve expressiveSlowEffects() const;

    AnimDurationTokens* durations() const { return m_durations; }

private:
    AnimDurationTokens* m_durations = nullptr;
    static QEasingCurve makeBezier(qreal p1x, qreal p1y, qreal p2x, qreal p2y);
};

class TokensSingleton : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(prism::config::RoundingTokens* rounding READ rounding CONSTANT)
    Q_PROPERTY(prism::config::SpacingTokens* spacing READ spacing CONSTANT)
    Q_PROPERTY(prism::config::PaddingTokens* padding READ padding CONSTANT)
    Q_PROPERTY(prism::config::AnimCurves* anim READ anim CONSTANT)
    Q_PROPERTY(prism::config::FontTokens* font READ font CONSTANT)

public:
    explicit TokensSingleton(QObject* parent = nullptr);

    RoundingTokens* rounding() const { return m_rounding; }
    SpacingTokens* spacing() const { return m_spacing; }
    PaddingTokens* padding() const { return m_padding; }
    AnimCurves* anim() const { return m_anim; }
    FontTokens* font() const { return m_font; }

    static TokensSingleton* instance();

private:
    RoundingTokens* m_rounding = nullptr;
    SpacingTokens* m_spacing = nullptr;
    PaddingTokens* m_padding = nullptr;
    AnimCurves* m_anim = nullptr;
    FontTokens* m_font = nullptr;
};

} // namespace prism::config
