#include "iconprovider.hpp"
#include <QCache>
#include <QCoreApplication>
#include <QIcon>
#include <QMutex>
#include <QThread>

namespace atlas::core {

static QCache<QString, QImage> s_iconCache(500);
static QMutex s_iconMutex;

IconImageProvider::IconImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {}

void IconImageProvider::clearCache() {
    {
        QMutexLocker locker(&s_iconMutex);
        s_iconCache.clear();
    }

    auto resetQtTheme = []() {
        QString currentTheme = QIcon::themeName();
        // Trigger Qt internal theme cache reset
        QIcon::setThemeSearchPaths(QIcon::themeSearchPaths());
        if (!currentTheme.isEmpty()) {
            QIcon::setThemeName(currentTheme);
        }
    };

    if (QThread::currentThread() == qApp->thread()) {
        resetQtTheme();
    } else {
        QMetaObject::invokeMethod(qApp, resetQtTheme, Qt::BlockingQueuedConnection);
    }
}

QImage IconImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize) {
    int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 64;

    if (size) {
        *size = QSize(w, h);
    }

    QString cleanId = id.section('?', 0, 0);
    QString key = id + "@" + QString::number(w) + "x" + QString::number(h);
    {
        QMutexLocker locker(&s_iconMutex);
        if (auto* cached = s_iconCache.object(key)) {
            return *cached;
        }
    }

    QImage img;
    // Safely query QIcon::fromTheme on the main GUI thread
    if (QThread::currentThread() == qApp->thread()) {
        QIcon icon = QIcon::fromTheme(cleanId);
        if (icon.isNull()) icon = QIcon::fromTheme("text-plain");
        if (!icon.isNull()) {
            img = icon.pixmap(w, h).toImage();
        }
    } else {
        QMetaObject::invokeMethod(qApp, [&img, cleanId, w, h]() {
            QIcon icon = QIcon::fromTheme(cleanId);
            if (icon.isNull()) icon = QIcon::fromTheme("text-plain");
            if (!icon.isNull()) {
                img = icon.pixmap(w, h).toImage();
            }
        }, Qt::BlockingQueuedConnection);
    }

    if (img.isNull()) {
        img = QImage(w, h, QImage::Format_ARGB32_Premultiplied);
        img.fill(Qt::transparent);
    }

    {
        QMutexLocker locker(&s_iconMutex);
        s_iconCache.insert(key, new QImage(img));
    }

    return img;
}

} // namespace atlas::core
