#include "iconprovider.hpp"
#include <QPainter>
#include <QIcon>

namespace prism::core {

IconImageProvider::IconImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {}

QImage IconImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 64;

    if (size) {
        *size = QSize(w, h);
    }

    QIcon icon = QIcon::fromTheme(id);
    if (!icon.isNull()) {
        return icon.pixmap(w, h).toImage();
    }

    QIcon fallbackIcon = QIcon::fromTheme("text-plain");
    if (!fallbackIcon.isNull()) {
        return fallbackIcon.pixmap(w, h).toImage();
    }

    QImage img(w, h, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    return img;
}

} // namespace prism::core
