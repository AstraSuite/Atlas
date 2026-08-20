#include "iconprovider.hpp"
#include <QCache>
#include <QIcon>
#include <QMutex>

namespace prism::core {

static QCache<QString, QImage> s_iconCache(500);
static QMutex s_iconMutex;

IconImageProvider::IconImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {}

QImage IconImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 64;

    if (size) {
        *size = QSize(w, h);
    }

    QString key = id + "@" + QString::number(w) + "x" + QString::number(h);
    {
        QMutexLocker locker(&s_iconMutex);
        if (auto* cached = s_iconCache.object(key)) {
            return *cached;
        }
    }

    QIcon icon = QIcon::fromTheme(id);
    if (icon.isNull()) {
        icon = QIcon::fromTheme("text-plain");
    }

    QImage img;
    if (!icon.isNull()) {
        img = icon.pixmap(w, h).toImage();
    } else {
        img = QImage(w, h, QImage::Format_ARGB32_Premultiplied);
        img.fill(Qt::transparent);
    }

    {
        QMutexLocker locker(&s_iconMutex);
        s_iconCache.insert(key, new QImage(img));
    }

    return img;
}

} // namespace prism::core
