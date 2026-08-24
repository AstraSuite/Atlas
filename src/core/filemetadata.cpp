#include "filemetadata.hpp"
#include "exifreader.hpp"
#include "fileutils.hpp"

#include <QCryptographicHash>
#include <QtConcurrent>
#include <QDir>
#include <QFileInfo>
#include <QImageReader>
#include <QMediaMetaData>
#include <QMediaPlayer>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QUrl>

namespace atlas::core {
namespace {

void appendDetailRow(QVariantList& rows, const QString& label, const QString& value) {
    if (!value.simplified().isEmpty()) {
        rows.append(QVariantMap{{"label", label}, {"value", value}});
    }
}

QString formatDuration(qint64 milliseconds) {
    if (milliseconds <= 0) return QString();
    const qint64 totalSeconds = milliseconds / 1000;
    const qint64 hours = totalSeconds / 3600;
    const qint64 minutes = (totalSeconds % 3600) / 60;
    const qint64 seconds = totalSeconds % 60;
    if (hours > 0)
        return QStringLiteral("%1:%2:%3").arg(hours).arg(minutes, 2, 10, QLatin1Char('0')).arg(seconds, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1:%2").arg(minutes).arg(seconds, 2, 10, QLatin1Char('0'));
}

QString formatBitRate(qint64 bitsPerSecond) {
    if (bitsPerSecond <= 0) return QString();
    if (bitsPerSecond >= 1000000)
        return QStringLiteral("%1 Mbps").arg(QString::number(bitsPerSecond / 1000000.0, 'f', 1));
    if (bitsPerSecond >= 1000)
        return QStringLiteral("%1 kbps").arg(QString::number(bitsPerSecond / 1000.0, 'f', 0));
    return QStringLiteral("%1 bps").arg(bitsPerSecond);
}

QString formatFrameRate(qreal framesPerSecond) {
    if (framesPerSecond <= 0.0) return QString();
    if (framesPerSecond == static_cast<double>(static_cast<int>(framesPerSecond)))
        return QStringLiteral("%1 fps").arg(static_cast<int>(framesPerSecond));
    return QStringLiteral("%1 fps").arg(QString::number(framesPerSecond, 'f', 2));
}

} // namespace

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

    // FreeDesktop Thumbnail spec: MD5 of URI
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
        m_lastModified = QDateTime();
        resetMediaDetails();
        emit metadataChanged();
        emit mediaDetailsChanged();
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

    m_formattedCreated = FileUtils::formatDateTime(fi.birthTime());
    m_formattedModified = FileUtils::formatDateTime(fi.lastModified());
    m_formattedAccessed = FileUtils::formatDateTime(fi.lastRead());
    m_lastModified = fi.lastModified();

    // Drop details from the previously selected file before re-populating
    resetMediaDetails();

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

        const QVariantList exifRows = ExifReader::read(m_path);
        if (!exifRows.isEmpty()) {
            m_mediaDetails = exifRows;
            m_hasMediaDetails = true;
        }
    } else {
        m_imageWidth = 0;
        m_imageHeight = 0;
        m_imageDimensions.clear();
    }

    probeMediaMetadata();

    emit metadataChanged();
    emit mediaDetailsChanged();
}

void FileMetadata::resetMediaDetails() {
    m_hasMediaDetails = false;
    m_videoDimensions.clear();
    m_videoCodecName.clear();
    m_audioCodecName.clear();
    m_frameRate.clear();
    m_bitRate.clear();
    m_copyright.clear();
    m_durationFormatted.clear();
    m_audioTitle.clear();
    m_audioArtist.clear();
    m_audioAlbum.clear();
    m_mediaDetails.clear();

    if (m_mediaProbe && m_mediaProbe->source().isValid())
        m_mediaProbe->setSource(QUrl());
}

void FileMetadata::probeMediaMetadata() {
    if (!m_isVideo && !m_isAudio) return;

    if (!m_mediaProbe) {
        m_mediaProbe = new QMediaPlayer(this);
        connect(m_mediaProbe, &QMediaPlayer::metaDataChanged, this, &FileMetadata::applyMediaMetaData);
        connect(m_mediaProbe, &QMediaPlayer::errorOccurred, this,
                [this](QMediaPlayer::Error, const QString&) {
                    // Demux failed; leave details empty rather than retrying
                });
    }
    m_mediaProbe->setSource(QUrl::fromLocalFile(m_path));
}

void FileMetadata::applyMediaMetaData() {
    if (!m_mediaProbe) return;

    const QUrl source = m_mediaProbe->source();
    if (source.isValid() && source.toLocalFile() != m_path) return; // stale signal

    const QMediaMetaData md = m_mediaProbe->metaData();
    if (md.isEmpty()) return;

    const QSize resolution = md.value(QMediaMetaData::Resolution).toSize();
    m_videoDimensions = resolution.isValid()
                           ? QStringLiteral("%1 × %2").arg(resolution.width()).arg(resolution.height())
                           : QString();

    m_durationFormatted = formatDuration(md.value(QMediaMetaData::Duration).toLongLong());
    m_videoCodecName = md.stringValue(QMediaMetaData::VideoCodec);
    m_audioCodecName = md.stringValue(QMediaMetaData::AudioCodec);
    m_frameRate = formatFrameRate(md.value(QMediaMetaData::VideoFrameRate).toReal());

    const qint64 videoRate = md.value(QMediaMetaData::VideoBitRate).toLongLong();
    const qint64 audioRate = md.value(QMediaMetaData::AudioBitRate).toLongLong();
    m_bitRate = formatBitRate(videoRate > 0 ? videoRate : audioRate);

    m_copyright = md.stringValue(QMediaMetaData::Copyright);
    m_audioTitle = md.stringValue(QMediaMetaData::Title);
    m_audioAlbum = md.stringValue(QMediaMetaData::AlbumTitle);
    for (const auto key : {QMediaMetaData::AlbumArtist, QMediaMetaData::ContributingArtist, QMediaMetaData::LeadPerformer}) {
        const QString artist = md.stringValue(key);
        if (!artist.isEmpty()) {
            m_audioArtist = artist;
            break;
        }
    }

    QVariantList rows;
    appendDetailRow(rows, "Title", m_audioTitle);
    appendDetailRow(rows, "Artist", m_audioArtist);
    appendDetailRow(rows, "Album", m_audioAlbum);
    appendDetailRow(rows, "Track", md.value(QMediaMetaData::TrackNumber).toString());
    appendDetailRow(rows, "Genre", md.stringValue(QMediaMetaData::Genre));
    appendDetailRow(rows, "Resolution", m_videoDimensions);
    appendDetailRow(rows, "Duration", m_durationFormatted);
    appendDetailRow(rows, "Container", md.stringValue(QMediaMetaData::FileFormat));
    appendDetailRow(rows, "Video Codec", m_videoCodecName);
    appendDetailRow(rows, "Frame Rate", m_frameRate);
    if (videoRate > 0) appendDetailRow(rows, "Video Bit Rate", formatBitRate(videoRate));
    appendDetailRow(rows, "Audio Codec", m_audioCodecName);
    if (audioRate > 0) appendDetailRow(rows, "Audio Bit Rate", formatBitRate(audioRate));

    const QDateTime recorded = md.value(QMediaMetaData::Date).toDateTime();
    if (recorded.isValid()) appendDetailRow(rows, "Recorded", FileUtils::formatDateTime(recorded));

    QString comment = md.stringValue(QMediaMetaData::Comment);
    if (comment.isEmpty()) comment = md.stringValue(QMediaMetaData::Description);
    appendDetailRow(rows, "Comment", comment);
    appendDetailRow(rows, "Copyright", m_copyright);

    m_hasMediaDetails = !rows.isEmpty();
    m_mediaDetails = rows;
    emit metadataChanged();
    emit mediaDetailsChanged();
}

void FileMetadata::calculateChecksums() {
    if (m_path.isEmpty() || m_isDir || !QFile::exists(m_path)) return;

    m_checksumsLoading = true;
    emit checksumsChanged();

    QString p = m_path;
    (void)QtConcurrent::run([this, p]() {
        QFile file(p);
        if (!file.open(QIODevice::ReadOnly)) {
            QMetaObject::invokeMethod(this, [this]() {
                m_checksumsLoading = false;
                emit checksumsChanged();
            });
            return;
        }

        QCryptographicHash md5Hash(QCryptographicHash::Md5);
        QCryptographicHash sha1Hash(QCryptographicHash::Sha1);
        QCryptographicHash sha256Hash(QCryptographicHash::Sha256);

        char buffer[65536];
        while (!file.atEnd()) {
            qint64 bytesRead = file.read(buffer, sizeof(buffer));
            if (bytesRead > 0) {
                QByteArrayView view(buffer, bytesRead);
                md5Hash.addData(view);
                sha1Hash.addData(view);
                sha256Hash.addData(view);
            }
        }
        file.close();

        QString md5Str = QString::fromUtf8(md5Hash.result().toHex());
        QString sha1Str = QString::fromUtf8(sha1Hash.result().toHex());
        QString sha256Str = QString::fromUtf8(sha256Hash.result().toHex());

        QMetaObject::invokeMethod(this, [this, md5Str, sha1Str, sha256Str]() {
            m_md5 = md5Str;
            m_sha1 = sha1Str;
            m_sha256 = sha256Str;
            m_checksumsLoading = false;
            emit checksumsChanged();
        });
    });
}

static QFile::Permissions traversablePermissions(QFile::Permissions perms) {
    if (perms & QFile::ReadUser)
        perms |= QFile::ExeUser;
    if (perms & QFile::ReadGroup)
        perms |= QFile::ExeGroup;
    if (perms & QFile::ReadOther)
        perms |= QFile::ExeOther;
    return perms;
}

bool FileMetadata::applyPermissions(int userRead, int userWrite, int userExec,
                                    int groupRead, int groupWrite, int groupExec,
                                    int otherRead, int otherWrite, int otherExec,
                                    bool recursive) {
    if (m_path.isEmpty() || !QFile::exists(m_path)) return false;

    QFile::Permissions perms;
    if (userRead) perms |= QFile::ReadUser;
    if (userWrite) perms |= QFile::WriteUser;
    if (userExec) perms |= QFile::ExeUser;
    if (groupRead) perms |= QFile::ReadGroup;
    if (groupWrite) perms |= QFile::WriteGroup;
    if (groupExec) perms |= QFile::ExeGroup;
    if (otherRead) perms |= QFile::ReadOther;
    if (otherWrite) perms |= QFile::WriteOther;
    if (otherExec) perms |= QFile::ExeOther;

    if (!recursive) {
        const bool success = QFile::setPermissions(m_path, perms);
        reload();
        return success;
    }

    const QString root = m_path;
    (void)QtConcurrent::run([this, root, perms]() {
        QFile::setPermissions(root, traversablePermissions(perms));

        QDirIterator it(root, QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString entry = it.next();
            const QFileInfo info = it.fileInfo();
            if (info.isSymLink())
                continue;
            QFile::setPermissions(entry, info.isDir() ? traversablePermissions(perms) : perms);
        }

        QMetaObject::invokeMethod(this, [this]() {
            reload();
        });
    });

    return true;
}

bool FileMetadata::setComment(const QString& comment) {
    if (m_path.isEmpty() || !m_isImage) return false;
    const bool ok = ExifReader::writeComment(m_path, comment);
    if (ok) {
        reload();
    }
    return ok;
}

} // namespace atlas::core
