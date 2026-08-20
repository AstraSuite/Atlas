#include "filemetadata.hpp"
#include "fileutils.hpp"

#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QUrl>

namespace prism::core {

FileMetadata::FileMetadata(QObject* parent)
    : QObject(parent) {}

void FileMetadata::setPath(const QString& p) {
    if (m_path != p) {
        m_path = p;
        emit pathChanged();
        reload();
    }
}

QString FileMetadata::findThumbnail(const QString& filePath) {
    if (filePath.isEmpty()) return QString();

    // FreeDesktop Thumbnail spec: MD5 of URI (file:///path/to/file)
    QString uri = QUrl::fromLocalFile(filePath).toString();
    QByteArray hash = QCryptographicHash::hash(uri.toUtf8(), QCryptographicHash::Md5).toHex();
    QString filename = QString::fromUtf8(hash) + ".png";

    QString home = QDir::homePath();
    QStringList paths = {
        home + "/.cache/thumbnails/x-large/" + filename,
        home + "/.cache/thumbnails/large/" + filename,
        home + "/.cache/thumbnails/normal/" + filename
    };

    for (const auto& p : paths) {
        if (QFile::exists(p)) {
            return p;
        }
    }
    return QString();
}

void FileMetadata::reload() {
    if (m_path.isEmpty() || !QFile::exists(m_path)) {
        m_name.clear();
        m_size = 0;
        m_formattedSize.clear();
        m_isDir = false;
        m_isSymLink = false;
        m_symLinkTarget.clear();
        m_isImage = false;
        m_isVideo = false;
        m_isAudio = false;
        m_thumbnailPath.clear();
        m_mimeType.clear();
        m_mimeDescription.clear();
        m_permissions.clear();
        m_owner.clear();
        m_group.clear();
        m_formattedCreated.clear();
        m_formattedModified.clear();
        m_formattedAccessed.clear();
        m_itemCount = 0;
        m_imageWidth = 0;
        m_imageHeight = 0;
        m_imageDimensions.clear();
        emit metadataChanged();
        return;
    }

    QFileInfo fi(m_path);
    m_name = fi.fileName();
    if (m_name.isEmpty()) m_name = m_path;

    m_isDir = fi.isDir();
    m_isSymLink = fi.isSymLink();
    m_symLinkTarget = fi.isSymLink() ? fi.symLinkTarget() : QString();

    if (m_isDir) {
        QDir d(m_path);
        m_itemCount = static_cast<int>(d.entryList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden).size());
        m_size = 0;
        m_formattedSize.clear();
    } else {
        m_itemCount = 0;
        m_size = fi.size();
        m_formattedSize = FileUtils::formatSize(m_size);
    }

    QMimeDatabase mimeDb;
    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    m_mimeType = mime.name();
    m_mimeDescription = mime.comment();

    m_isImage = m_mimeType.startsWith("image/");
    m_isVideo = m_mimeType.startsWith("video/");
    m_isAudio = m_mimeType.startsWith("audio/");

    // Check thumbnail cache
    QString cachedThumb = findThumbnail(m_path);
    if (!cachedThumb.isEmpty()) {
        m_thumbnailPath = cachedThumb;
    } else if (m_isImage) {
        m_thumbnailPath = m_path;
    } else {
        m_thumbnailPath.clear();
    }

    // UNIX Permissions
    auto perms = fi.permissions();
    QString pStr;
    pStr += (perms & QFile::ReadUser) ? 'r' : '-';
    pStr += (perms & QFile::WriteUser) ? 'w' : '-';
    pStr += (perms & QFile::ExeUser) ? 'x' : '-';
    pStr += (perms & QFile::ReadGroup) ? 'r' : '-';
    pStr += (perms & QFile::WriteGroup) ? 'w' : '-';
    pStr += (perms & QFile::ExeGroup) ? 'x' : '-';
    pStr += (perms & QFile::ReadOther) ? 'r' : '-';
    pStr += (perms & QFile::WriteOther) ? 'w' : '-';
    pStr += (perms & QFile::ExeOther) ? 'x' : '-';
    m_permissions = pStr;

    m_owner = fi.owner();
    m_group = fi.group();

    m_formattedCreated = fi.birthTime().toString("yyyy-MM-dd hh:mm");
    m_formattedModified = fi.lastModified().toString("yyyy-MM-dd hh:mm");
    m_formattedAccessed = fi.lastRead().toString("yyyy-MM-dd hh:mm");

    if (m_isImage) {
        QImageReader reader(m_path);
        QSize sz = reader.size();
        if (sz.isValid()) {
            m_imageWidth = sz.width();
            m_imageHeight = sz.height();
            m_imageDimensions = QString("%1 × %2").arg(m_imageWidth).arg(m_imageHeight);
        } else {
            m_imageWidth = 0;
            m_imageHeight = 0;
            m_imageDimensions.clear();
        }
    } else {
        m_imageWidth = 0;
        m_imageHeight = 0;
        m_imageDimensions.clear();
    }

    emit metadataChanged();
}

} // namespace prism::core
