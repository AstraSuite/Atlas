#include "tokens.hpp"
#include <QPointF>

namespace prism::config {

QEasingCurve AnimCurves::makeBezier(qreal p1x, qreal p1y, qreal p2x, qreal p2y) {
    QEasingCurve curve(QEasingCurve::BezierSpline);
    curve.addCubicBezierSegment(QPointF(p1x, p1y), QPointF(p2x, p2y), QPointF(1.0, 1.0));
    return curve;
}

AnimCurves::AnimCurves(QObject* parent)
    : QObject(parent)
    , m_durations(new AnimDurationTokens(this)) {}

QEasingCurve AnimCurves::emphasized() const {
    return makeBezier(0.2, 0.0, 0.0, 1.0);
}

QEasingCurve AnimCurves::emphasizedAccel() const {
    return makeBezier(0.3, 0.0, 0.8, 0.15);
}

QEasingCurve AnimCurves::emphasizedDecel() const {
    return makeBezier(0.05, 0.7, 0.1, 1.0);
}

QEasingCurve AnimCurves::standard() const {
    return makeBezier(0.2, 0.0, 0.0, 1.0);
}

QEasingCurve AnimCurves::standardAccel() const {
    return makeBezier(0.3, 0.0, 1.0, 1.0);
}

QEasingCurve AnimCurves::standardDecel() const {
    return makeBezier(0.0, 0.0, 0.0, 1.0);
}

QEasingCurve AnimCurves::expressiveFastSpatial() const {
    return makeBezier(0.42, 1.67, 0.21, 0.9);
}

QEasingCurve AnimCurves::expressiveDefaultSpatial() const {
    return makeBezier(0.38, 1.21, 0.22, 1.0);
}

QEasingCurve AnimCurves::expressiveSlowSpatial() const {
    return makeBezier(0.39, 1.29, 0.35, 0.98);
}

QEasingCurve AnimCurves::expressiveFastEffects() const {
    return makeBezier(0.31, 0.94, 0.34, 1.0);
}

QEasingCurve AnimCurves::expressiveDefaultEffects() const {
    return makeBezier(0.34, 0.8, 0.34, 1.0);
}

QEasingCurve AnimCurves::expressiveSlowEffects() const {
    return makeBezier(0.34, 0.88, 0.34, 1.0);
}

// TokensSingleton
TokensSingleton::TokensSingleton(QObject* parent)
    : QObject(parent)
    , m_rounding(new RoundingTokens(this))
    , m_spacing(new SpacingTokens(this))
    , m_padding(new PaddingTokens(this))
    , m_anim(new AnimCurves(this))
    , m_font(new FontTokens(this)) {}

TokensSingleton* TokensSingleton::instance() {
    static auto* s_instance = new TokensSingleton();
    return s_instance;
}

} // namespace prism::config
