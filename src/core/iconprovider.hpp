#pragma once

#include <QQuickImageProvider>
#include <QImage>
#include <QIcon>

namespace atlas::core {

class IconImageProvider : public QQuickImageProvider {
public:
    IconImageProvider();

    static void clearCache();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;
};

} // namespace atlas::core
