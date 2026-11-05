#include "qthelpers.h"

#include "providers/iconprovider.hpp"
#include "providers/thumbnailprovider.hpp"
#include "theme/tokens.hpp"

#include <QQmlApplicationEngine>
#include <qqml.h>

namespace atlas::native {

// The theme tokens and image providers stay native (QEasingCurve and QFont
// gadgets, QQuickImageProvider); everything else in the "atlas" module comes
// from the Rust side's cxx-qt registrations.
void installEngine(QQmlApplicationEngine& engine) {
    engine.addImageProvider("icon", new atlas::core::IconImageProvider());
    engine.addImageProvider("thumb", new atlas::core::ThumbnailImageProvider());

    auto* tokens = atlas::config::TokensSingleton::instance();
    QQmlEngine::setObjectOwnership(tokens, QQmlEngine::CppOwnership);
    qmlRegisterSingletonInstance("atlas", 1, 0, "Tokens", tokens);
}

} // namespace atlas::native
