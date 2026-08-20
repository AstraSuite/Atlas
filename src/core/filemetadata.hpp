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
    Q_PROPERTY(QString mimeType READ mimeType NOTIFY metadataChanged)
    Q_PROPERTY(QString mimeDescription READ mimeDescription NOTIFY metadataChanged)
    Q_PROPERTY(QString permissions READ permissions NOTIFY metadataChanged)
    Q_PROPERTY(QString owner READ owner NOTIFY metadataChanged)
    Q_PROPERTY(QString group READ group NOTIFY metadataChanged)
    Q_PROPERTY(QString createdFormatted READ createdFormatted NOTIFY metadataChanged)
    Q_PROPERTY(QString modifiedFormatted READ modifiedFormatted NOTIFY metadataChanged)
    Q_PROPERTY(QString accessedFormatted READ accessedFormatted NOTIFY metadataChanged)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY metadataChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY metadataChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY metadataChanged)
    Q_PROPERTY(QString imageDimensions READ imageDimensions NOTIFY metadataChanged)

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
    QString mimeType() const { return m_mimeType; }
    QString mimeDescription() const { return m_mimeDescription; }
    QString permissions() const { return m_permissions; }
    QString owner() const { return m_owner; }
    QString group() const { return m_group; }
    QString createdFormatted() const { return m_createdFormatted; }
    QString modifiedFormatted() const { return m_modifiedFormatted; }
    QString accessedFormatted() const { return m_accessedFormatted; }
    int itemCount() const { return m_itemCount; }
    int imageWidth() const { return m_imageWidth; }
    int imageHeight() const { return m_imageHeight; }
    QString imageDimensions() const { return m_imageDimensions; }

    Q_INVOKABLE void reload();

signals:
    void pathChanged();
    void metadataChanged();

private:
    QString m_path;
    QString m_name;
    qint64 m_size = 0;
    QString m_formattedSize;
    bool m_isDir = false;
    bool m_isSymLink = false;
    QString m_symLinkTarget;
    QString m_mimeType;
    QString m_mimeDescription;
    QString m_permissions;
    QString m_owner;
    QString m_group;
    QString m_createdFormatted;
    QString m_modifiedFormatted;
    QString m_accessedFormatted;
    int m_itemCount = 0;
    int m_imageWidth = 0;
    int m_imageHeight = 0;
    QString m_imageDimensions;
};

} // namespace prism::core
