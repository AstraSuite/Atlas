#include "iconprovider.hpp"
#include <QIcon>
#include <QPixmap>

namespace prism::core {

IconImageProvider::IconImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap IconImageProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) {
    int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 64;

    if (size) {
        *size = QSize(w, h);
    }

    QIcon icon = QIcon::fromTheme(id);
    if (icon.isNull()) {
        icon = QIcon::fromTheme("text-plain");
    }

    if (!icon.isNull()) {
        return icon.pixmap(w, h);
    }

    QPixmap px(w, h);
    px.fill(Qt::transparent);
    return px;
}

} // namespace prism::core
