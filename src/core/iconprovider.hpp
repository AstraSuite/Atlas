#pragma once

#include <QQuickImageProvider>
#include <QPixmap>
#include <QIcon>

namespace prism::core {

class IconImageProvider : public QQuickImageProvider {
public:
    IconImageProvider();

    QPixmap requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) override;
};

} // namespace prism::core
