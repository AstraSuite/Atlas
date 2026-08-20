#include "filemetadata.hpp"
#include "fileutils.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QImageReader>

namespace prism::core {

FileMetadata::FileMetadata(QObject* parent) : QObject(parent) {}

void FileMetadata::setPath(const QString& p) {
    if (m_path != p) {
        m_path = p;
        emit pathChanged();
        reload();
    }
}

void FileMetadata::reload() {
    if (m_path.isEmpty()) {
        m_name.clear();
        m_size = 0;
        m_formattedSize.clear();
        m_isDir = false;
        m_isSymLink = false;
        m_symLinkTarget.clear();
        m_mimeType.clear();
        m_mimeDescription.clear();
        m_permissions.clear();
        m_owner.clear();
        m_group.clear();
        m_createdFormatted.clear();
        m_modifiedFormatted.clear();
        m_accessedFormatted.clear();
        m_itemCount = 0;
        m_imageWidth = 0;
        m_imageHeight = 0;
        m_imageDimensions.clear();
        emit metadataChanged();
        return;
    }

    QFileInfo fi(m_path);
    m_name = fi.fileName();
    m_isDir = fi.isDir();
    m_isSymLink = fi.isSymLink();
    m_symLinkTarget = fi.symLinkTarget();

    QMimeDatabase mimeDb;
    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    m_mimeType = mime.name();
    m_mimeDescription = mime.comment();

    m_owner = fi.owner();
    m_group = fi.group();

    // Permissions string (e.g. rwxr-xr-x)
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

    m_createdFormatted = fi.birthTime().isValid() ? fi.birthTime().toString("yyyy-MM-dd hh:mm") : fi.metadataChangeTime().toString("yyyy-MM-dd hh:mm");
    m_modifiedFormatted = fi.lastModified().toString("yyyy-MM-dd hh:mm");
    m_accessedFormatted = fi.lastRead().toString("yyyy-MM-dd hh:mm");

    if (m_isDir) {
        QDir dir(m_path);
        const auto entries = dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
        m_itemCount = entries.size();
        m_size = 0;
        m_formattedSize = QString("%1 items").arg(m_itemCount);
        m_imageWidth = 0;
        m_imageHeight = 0;
        m_imageDimensions.clear();
    } else {
        m_size = fi.size();
        m_formattedSize = FileUtils::formatSize(m_size);
        m_itemCount = 0;

        if (m_mimeType.startsWith("image/")) {
            QImageReader reader(m_path);
            QSize imgSize = reader.size();
            if (imgSize.isValid()) {
                m_imageWidth = imgSize.width();
                m_imageHeight = imgSize.height();
                m_imageDimensions = QString("%1 × %2 px").arg(m_imageWidth).arg(m_imageHeight);
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
    }

    emit metadataChanged();
}

} // namespace prism::core
