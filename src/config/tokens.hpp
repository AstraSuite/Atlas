#pragma once

#include "font.hpp"
#include <QObject>
#include <QEasingCurve>
#include <QFileSystemWatcher>
#include <QList>
#include <QJsonObject>
#include <qqmlintegration.h>

namespace prism::config {

class RoundingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY valuesChanged)

#define TOKEN_PROP(name, defaultVal) \
    Q_PROPERTY(int name READ name NOTIFY valuesChanged) \
public: \
    int name() const { return static_cast<int>(m_##name * m_scale); } \
    void set_##name(int val) { m_##name = val; } \
private: \
    int m_##name = defaultVal;

    TOKEN_PROP(extraSmall, 4)
    TOKEN_PROP(small, 8)
    TOKEN_PROP(medium, 12)
    TOKEN_PROP(large, 16)
    TOKEN_PROP(largeIncreased, 20)
    TOKEN_PROP(extraLarge, 28)
    TOKEN_PROP(extraLargeIncreased, 32)
    TOKEN_PROP(extraExtraLarge, 48)
    TOKEN_PROP(full, 9999)

#undef TOKEN_PROP

public:
    explicit RoundingTokens(QObject* parent = nullptr) : QObject(parent) {}

    [[nodiscard]] qreal scale() const { return m_scale; }
    void setScale(qreal scale) {
        if (qFuzzyCompare(m_scale, scale))
            return;
        m_scale = scale;
        emit valuesChanged();
    }
    void loadJson(const QJsonObject& json);

signals:
    void valuesChanged();

private:
    qreal m_scale = 1.0;
};

class SpacingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY valuesChanged)

#define TOKEN_PROP(name, defaultVal) \
    Q_PROPERTY(int name READ name NOTIFY valuesChanged) \
public: \
    int name() const { return static_cast<int>(m_##name * m_scale); } \
    void set_##name(int val) { m_##name = val; } \
private: \
    int m_##name = defaultVal;

    TOKEN_PROP(extraSmall, 4)
    TOKEN_PROP(small, 8)
    TOKEN_PROP(medium, 12)
    TOKEN_PROP(large, 16)
    TOKEN_PROP(largeIncreased, 20)
    TOKEN_PROP(extraLarge, 28)
    TOKEN_PROP(extraLargeIncreased, 32)
    TOKEN_PROP(extraExtraLarge, 48)

#undef TOKEN_PROP

public:
    explicit SpacingTokens(QObject* parent = nullptr) : QObject(parent) {}

    [[nodiscard]] qreal scale() const { return m_scale; }
    void setScale(qreal scale) {
        if (qFuzzyCompare(m_scale, scale))
            return;
        m_scale = scale;
        emit valuesChanged();
    }
    void loadJson(const QJsonObject& json);

signals:
    void valuesChanged();

private:
    qreal m_scale = 1.0;
};

class PaddingTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY valuesChanged)

#define TOKEN_PROP(name, defaultVal) \
    Q_PROPERTY(int name READ name NOTIFY valuesChanged) \
public: \
    int name() const { return static_cast<int>(m_##name * m_scale); } \
    void set_##name(int val) { m_##name = val; } \
private: \
    int m_##name = defaultVal;

    TOKEN_PROP(extraSmall, 4)
    TOKEN_PROP(small, 8)
    TOKEN_PROP(medium, 12)
    TOKEN_PROP(large, 16)
    TOKEN_PROP(largeIncreased, 20)
    TOKEN_PROP(extraLarge, 28)
    TOKEN_PROP(extraLargeIncreased, 32)
    TOKEN_PROP(extraExtraLarge, 48)

#undef TOKEN_PROP

public:
    explicit PaddingTokens(QObject* parent = nullptr) : QObject(parent) {}

    [[nodiscard]] qreal scale() const { return m_scale; }
    void setScale(qreal scale) {
        if (qFuzzyCompare(m_scale, scale))
            return;
        m_scale = scale;
        emit valuesChanged();
    }
    void loadJson(const QJsonObject& json);

signals:
    void valuesChanged();

private:
    qreal m_scale = 1.0;
};

class AnimDurationTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY valuesChanged)

#define TOKEN_PROP(name, defaultVal) \
    Q_PROPERTY(int name READ name NOTIFY valuesChanged) \
public: \
    int name() const { return static_cast<int>(m_##name * m_scale); } \
    void set_##name(int val) { m_##name = val; } \
private: \
    int m_##name = defaultVal;

    TOKEN_PROP(small, 200)
    TOKEN_PROP(normal, 400)
    TOKEN_PROP(large, 600)
    TOKEN_PROP(extraLarge, 1000)
    TOKEN_PROP(expressiveFastSpatial, 350)
    TOKEN_PROP(expressiveDefaultSpatial, 500)
    TOKEN_PROP(expressiveSlowSpatial, 650)
    TOKEN_PROP(expressiveFastEffects, 150)
    TOKEN_PROP(expressiveDefaultEffects, 200)
    TOKEN_PROP(expressiveSlowEffects, 300)

#undef TOKEN_PROP

public:
    explicit AnimDurationTokens(QObject* parent = nullptr) : QObject(parent) {}

    [[nodiscard]] qreal scale() const { return m_scale; }
    void setScale(qreal scale) {
        if (qFuzzyCompare(m_scale, scale))
            return;
        m_scale = scale;
        emit valuesChanged();
    }
    void loadJson(const QJsonObject& json);

signals:
    void valuesChanged();

private:
    qreal m_scale = 1.0;
};

class AnimCurves : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QEasingCurve emphasized READ emphasized NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedAccel READ emphasizedAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve emphasizedDecel READ emphasizedDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standard READ standard NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardAccel READ standardAccel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve standardDecel READ standardDecel NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveFastSpatial READ expressiveFastSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveDefaultSpatial READ expressiveDefaultSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveSlowSpatial READ expressiveSlowSpatial NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveFastEffects READ expressiveFastEffects NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveDefaultEffects READ expressiveDefaultEffects NOTIFY curvesChanged)
    Q_PROPERTY(QEasingCurve expressiveSlowEffects READ expressiveSlowEffects NOTIFY curvesChanged)
    Q_PROPERTY(prism::config::AnimDurationTokens* durations READ durations CONSTANT)

public:
    explicit AnimCurves(QObject* parent = nullptr);

    QEasingCurve emphasized() const { return m_emphasized; }
    QEasingCurve emphasizedAccel() const { return m_emphasizedAccel; }
    QEasingCurve emphasizedDecel() const { return m_emphasizedDecel; }
    QEasingCurve standard() const { return m_standard; }
    QEasingCurve standardAccel() const { return m_standardAccel; }
    QEasingCurve standardDecel() const { return m_standardDecel; }
    QEasingCurve expressiveFastSpatial() const { return m_expressiveFastSpatial; }
    QEasingCurve expressiveDefaultSpatial() const { return m_expressiveDefaultSpatial; }
    QEasingCurve expressiveSlowSpatial() const { return m_expressiveSlowSpatial; }
    QEasingCurve expressiveFastEffects() const { return m_expressiveFastEffects; }
    QEasingCurve expressiveDefaultEffects() const { return m_expressiveDefaultEffects; }
    QEasingCurve expressiveSlowEffects() const { return m_expressiveSlowEffects; }

    AnimDurationTokens* durations() const { return m_durations; }
    void loadJson(const QJsonObject& json);

signals:
    void curvesChanged();

private:
    AnimDurationTokens* m_durations = nullptr;
    QEasingCurve m_emphasized;
    QEasingCurve m_emphasizedAccel;
    QEasingCurve m_emphasizedDecel;
    QEasingCurve m_standard;
    QEasingCurve m_standardAccel;
    QEasingCurve m_standardDecel;
    QEasingCurve m_expressiveFastSpatial;
    QEasingCurve m_expressiveDefaultSpatial;
    QEasingCurve m_expressiveSlowSpatial;
    QEasingCurve m_expressiveFastEffects;
    QEasingCurve m_expressiveDefaultEffects;
    QEasingCurve m_expressiveSlowEffects;

    static QEasingCurve makeBezier(qreal p1x, qreal p1y, qreal p2x, qreal p2y);
    static QEasingCurve parseBezierList(const QJsonArray& arr, const QEasingCurve& fallback);
};

class SidebarSizeTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(int width READ width NOTIFY valuesChanged)

public:
    explicit SidebarSizeTokens(QObject* parent = nullptr) : QObject(parent) {}
    int width() const { return m_width; }
    void set_width(int w) { if (m_width != w) { m_width = w; emit valuesChanged(); } }

signals:
    void valuesChanged();

private:
    int m_width = 230;
};

class SizeTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(prism::config::SidebarSizeTokens* sidebar READ sidebar CONSTANT)

public:
    explicit SizeTokens(QObject* parent = nullptr)
        : QObject(parent)
        , m_sidebar(new SidebarSizeTokens(this)) {}

    SidebarSizeTokens* sidebar() const { return m_sidebar; }
    void loadJson(const QJsonObject& json);

private:
    SidebarSizeTokens* m_sidebar = nullptr;
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
    Q_PROPERTY(prism::config::SizeTokens* sizes READ sizes CONSTANT)

public:
    explicit TokensSingleton(QObject* parent = nullptr);

    RoundingTokens* rounding() const { return m_rounding; }
    SpacingTokens* spacing() const { return m_spacing; }
    PaddingTokens* padding() const { return m_padding; }
    AnimCurves* anim() const { return m_anim; }
    FontTokens* font() const { return m_font; }
    SizeTokens* sizes() const { return m_sizes; }

    void loadTokensFile(const QString& filePath);
    void loadShellConfigFile(const QString& filePath);
    void reload();

    static TokensSingleton* instance();

private:
    RoundingTokens* m_rounding = nullptr;
    SpacingTokens* m_spacing = nullptr;
    PaddingTokens* m_padding = nullptr;
    AnimCurves* m_anim = nullptr;
    FontTokens* m_font = nullptr;
    SizeTokens* m_sizes = nullptr;
    QFileSystemWatcher m_watcher;
};

} // namespace prism::config
