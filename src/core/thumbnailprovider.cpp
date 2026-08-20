#include "thumbnailprovider.hpp"
#include <QCache>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QMutex>
#include <QProcess>
#include <QStandardPaths>

namespace prism::core {

static QCache<QString, QImage> s_memoryCache(200); // In-memory LRU cache
static QMutex s_cacheMutex;

static QString getDiskCachePath(const QString& filePath, const QFileInfo& fi) {
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    QDir().mkpath(cacheDir);

    QString keySource = filePath + ":" + QString::number(fi.size()) + ":" + QString::number(fi.lastModified().toMSecsSinceEpoch());
    QString hash = QString::fromUtf8(QCryptographicHash::hash(keySource.toUtf8(), QCryptographicHash::Sha256).toHex());

    return cacheDir + "/" + hash + ".png";
}

static QImage generateThumbnail(const QString& filePath, int targetSize) {
    QFileInfo fi(filePath);
    if (!fi.exists()) return QImage();

    int sz = targetSize > 0 ? targetSize : 256;
    QString diskCachePath = getDiskCachePath(filePath, fi);

    // 1. Check in-memory cache
    {
        QMutexLocker locker(&s_cacheMutex);
        if (auto* cached = s_memoryCache.object(diskCachePath)) {
            return *cached;
        }
    }

    // 2. Check persistent disk cache
    if (QFile::exists(diskCachePath)) {
        QImage diskImg(diskCachePath);
        if (!diskImg.isNull()) {
            QMutexLocker locker(&s_cacheMutex);
            s_memoryCache.insert(diskCachePath, new QImage(diskImg));
            return diskImg;
        }
    }

    // 3. Generate thumbnail
    QImage result;
    QString suffix = fi.suffix().toLower();
    static const QStringList videoExtensions = { "mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v", "ts" };

    if (videoExtensions.contains(suffix)) {
        // Generate video thumbnail via ffmpegthumbnailer or ffmpeg
        QProcess proc;
        proc.start("ffmpegthumbnailer", QStringList{ "-i", filePath, "-o", diskCachePath, "-s", QString::number(sz), "-q", "8" });
        if (proc.waitForFinished(2000) && proc.exitCode() == 0 && QFile::exists(diskCachePath)) {
            result.load(diskCachePath);
        } else {
            // Fallback to ffmpeg
            proc.start("ffmpeg", QStringList{ "-y", "-ss", "00:00:01", "-i", filePath, "-vframes", "1", "-vf", QString("scale=%1:-1").arg(sz), diskCachePath });
            if (proc.waitForFinished(3000) && proc.exitCode() == 0 && QFile::exists(diskCachePath)) {
                result.load(diskCachePath);
            }
        }
    } else {
        // Image generation using QImageReader
        QImageReader reader(filePath);
        reader.setAutoTransform(true);
        QSize orig = reader.size();
        if (orig.isValid() && orig.width() > 0 && orig.height() > 0) {
            QSize scaled = orig.scaled(sz, sz, Qt::KeepAspectRatio);
            reader.setScaledSize(scaled);
        }
        result = reader.read();
        if (!result.isNull()) {
            if (result.width() > sz || result.height() > sz) {
                result = result.scaled(sz, sz, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            }
            // Save to persistent disk cache
            result.save(diskCachePath, "PNG");
        }
    }

    if (!result.isNull()) {
        QMutexLocker locker(&s_cacheMutex);
        s_memoryCache.insert(diskCachePath, new QImage(result));
    }

    return result;
}

ThumbnailResponse::ThumbnailResponse(const QString& id, const QSize& requestedSize)
    : m_id(id), m_requestedSize(requestedSize) {
    setAutoDelete(false);
}

void ThumbnailResponse::run() {
    int targetSize = qMax(m_requestedSize.width(), m_requestedSize.height());
    if (targetSize <= 0) targetSize = 256;

    m_image = generateThumbnail(m_id, targetSize);
    emit finished();
}

QQuickTextureFactory* ThumbnailResponse::textureFactory() const {
    if (m_image.isNull()) return nullptr;
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

static QThreadPool* s_threadPool = nullptr;

ThumbnailImageProvider::ThumbnailImageProvider()
    : QQuickAsyncImageProvider() {
    if (!s_threadPool) {
        s_threadPool = new QThreadPool();
        s_threadPool->setMaxThreadCount(qBound(2, QThread::idealThreadCount(), 8));
    }
}

ThumbnailImageProvider::~ThumbnailImageProvider() = default;

QThreadPool* ThumbnailImageProvider::threadPool() {
    return s_threadPool;
}

QQuickImageResponse* ThumbnailImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize) {
    auto* resp = new ThumbnailResponse(id, requestedSize);
    s_threadPool->start(resp);
    return resp;
}

} // namespace prism::core
