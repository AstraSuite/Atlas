#pragma once

#include <QObject>
#include <QString>
#include <QDateTime>
#include <qqmlintegration.h>

namespace prism::core {

class FileMetadata : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString name READ name NOTIFY metadataChanged)
    Q_PROPERTY(qint64 size READ size NOTIFY metadataChanged)
    Q_PROPERTY(QString formattedSize READ formattedSize NOTIFY metadataChanged)
    Q_PROPERTY(bool isDir READ isDir NOTIFY metadataChanged)
    Q_PROPERTY(bool isSymLink READ isSymLink NOTIFY metadataChanged)
    Q_PROPERTY(QString symLinkTarget READ symLinkTarget NOTIFY metadataChanged)
    Q_PROPERTY(bool isImage READ isImage NOTIFY metadataChanged)
    Q_PROPERTY(bool isVideo READ isVideo NOTIFY metadataChanged)
    Q_PROPERTY(bool isAudio READ isAudio NOTIFY metadataChanged)
    Q_PROPERTY(QString thumbnailPath READ thumbnailPath NOTIFY metadataChanged)
    Q_PROPERTY(QString mimeType READ mimeType NOTIFY metadataChanged)
    Q_PROPERTY(QString mimeDescription READ mimeDescription NOTIFY metadataChanged)
    Q_PROPERTY(QString permissions READ permissions NOTIFY metadataChanged)
    Q_PROPERTY(QString owner READ owner NOTIFY metadataChanged)
    Q_PROPERTY(QString group READ group NOTIFY metadataChanged)
    Q_PROPERTY(QString formattedCreated READ formattedCreated NOTIFY metadataChanged)
    Q_PROPERTY(QString formattedModified READ formattedModified NOTIFY metadataChanged)
    Q_PROPERTY(QString formattedAccessed READ formattedAccessed NOTIFY metadataChanged)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY metadataChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY metadataChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY metadataChanged)
    Q_PROPERTY(QString imageDimensions READ imageDimensions NOTIFY metadataChanged)
    Q_PROPERTY(QString md5 READ md5 NOTIFY checksumsChanged)
    Q_PROPERTY(QString sha1 READ sha1 NOTIFY checksumsChanged)
    Q_PROPERTY(QString sha256 READ sha256 NOTIFY checksumsChanged)
    Q_PROPERTY(bool checksumsLoading READ checksumsLoading NOTIFY checksumsChanged)
    Q_PROPERTY(int octalPermissions READ octalPermissions NOTIFY metadataChanged)
    Q_PROPERTY(QString audioTitle READ audioTitle NOTIFY metadataChanged)
    Q_PROPERTY(QString audioArtist READ audioArtist NOTIFY metadataChanged)
    Q_PROPERTY(QString audioAlbum READ audioAlbum NOTIFY metadataChanged)
    Q_PROPERTY(QString durationFormatted READ durationFormatted NOTIFY metadataChanged)

public:
    explicit FileMetadata(QObject* parent = nullptr);

    QString path() const { return m_path; }
    void setPath(const QString& p);

    QString name() const { return m_name; }
    qint64 size() const { return m_size; }
    QString formattedSize() const { return m_formattedSize; }
    bool isDir() const { return m_isDir; }
    bool isSymLink() const { return m_isSymLink; }
    QString symLinkTarget() const { return m_symLinkTarget; }
    bool isImage() const { return m_isImage; }
    bool isVideo() const { return m_isVideo; }
    bool isAudio() const { return m_isAudio; }
    QString thumbnailPath() const { return m_thumbnailPath; }
    QString mimeType() const { return m_mimeType; }
    QString mimeDescription() const { return m_mimeDescription; }
    QString permissions() const { return m_permissions; }
    QString owner() const { return m_owner; }
    QString group() const { return m_group; }
    QString formattedCreated() const { return m_formattedCreated; }
    QString formattedModified() const { return m_formattedModified; }
    QString formattedAccessed() const { return m_formattedAccessed; }
    int itemCount() const { return m_itemCount; }
    int imageWidth() const { return m_imageWidth; }
    int imageHeight() const { return m_imageHeight; }
    QString imageDimensions() const { return m_imageDimensions; }

    QString md5() const { return m_md5; }
    QString sha1() const { return m_sha1; }
    QString sha256() const { return m_sha256; }
    bool checksumsLoading() const { return m_checksumsLoading; }
    int octalPermissions() const { return m_octalPermissions; }
    QString audioTitle() const { return m_audioTitle; }
    QString audioArtist() const { return m_audioArtist; }
    QString audioAlbum() const { return m_audioAlbum; }
    QString durationFormatted() const { return m_durationFormatted; }

    Q_INVOKABLE void reload();
    Q_INVOKABLE void calculateChecksums();
    Q_INVOKABLE bool applyPermissions(int userRead, int userWrite, int userExec,
                                     int groupRead, int groupWrite, int groupExec,
                                     int otherRead, int otherWrite, int otherExec,
                                     bool recursive = false);

signals:
    void pathChanged();
    void metadataChanged();
    void checksumsChanged();

private:
    QString findThumbnail(const QString& filePath);

    QString m_path;
    QString m_name;
    qint64 m_size = 0;
    QString m_formattedSize;
    bool m_isDir = false;
    bool m_isSymLink = false;
    QString m_symLinkTarget;
    bool m_isImage = false;
    bool m_isVideo = false;
    bool m_isAudio = false;
    QString m_thumbnailPath;
    QString m_mimeType;
    QString m_mimeDescription;
    QString m_permissions;
    QString m_owner;
    QString m_group;
    QString m_formattedCreated;
    QString m_formattedModified;
    QString m_formattedAccessed;
    int m_itemCount = 0;
    int m_imageWidth = 0;
    int m_imageHeight = 0;
    QString m_imageDimensions;
    QString m_md5;
    QString m_sha1;
    QString m_sha256;
    bool m_checksumsLoading = false;
    int m_octalPermissions = 0755;
    QString m_audioTitle;
    QString m_audioArtist;
    QString m_audioAlbum;
    QString m_durationFormatted;
};

} // namespace prism::core
