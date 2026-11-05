#pragma once

// Lets Rust create and dispose of cxx-qt QObjects it owns (tabs, model rows,
// palettes). cxx binds each declaration to a typed function pointer, which
// is what picks T and P here.

#include <QObject>
#include <QQmlEngine>

template <typename T, typename P>
T* atlasNewChild(P* parent) {
    auto* object = new T(parent);
    // Parented objects are never collected by QML, but say so explicitly.
    QQmlEngine::setObjectOwnership(object, QQmlEngine::CppOwnership);
    return object;
}

template <typename T>
void atlasDeleteLater(T* object) {
    if (object)
        object->deleteLater();
}
