#pragma once

#include <QQuickAsyncImageProvider>
#include <QQuickTextureFactory>
#include <QThreadPool>
#include <QRunnable>
#include <QImage>
#include <QString>

namespace prism::core {

class ThumbnailResponse : public QQuickImageResponse, public QRunnable {
    Q_OBJECT
public:
    ThumbnailResponse(const QString& id, const QSize& requestedSize);

    void run() override;
    QQuickTextureFactory* textureFactory() const override;

private:
    QString m_id;
    QSize m_requestedSize;
    QImage m_image;
};

class ThumbnailImageProvider : public QQuickAsyncImageProvider {
public:
    ThumbnailImageProvider();
    ~ThumbnailImageProvider() override;

    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override;
    static QThreadPool* threadPool();
};

} // namespace prism::core
