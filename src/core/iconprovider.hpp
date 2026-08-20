#pragma once

#include <QQuickImageProvider>
#include <QImage>
#include <QIcon>

namespace prism::core {

class IconImageProvider : public QQuickImageProvider {
public:
    IconImageProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;
};

} // namespace prism::core
