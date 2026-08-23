#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>
#include <QUrl>
#include <qqmlintegration.h>

namespace prism::core {

class FileUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString home READ home CONSTANT)
    Q_PROPERTY(QString pictures READ pictures CONSTANT)
    Q_PROPERTY(QString videos READ videos CONSTANT)
    Q_PROPERTY(QString documents READ documents CONSTANT)
    Q_PROPERTY(QString downloads READ downloads CONSTANT)
    Q_PROPERTY(QString music READ music CONSTANT)
    Q_PROPERTY(QString desktop READ desktop CONSTANT)

public:
    explicit FileUtils(QObject* parent = nullptr);

    [[nodiscard]] QString home() const;
    [[nodiscard]] QString pictures() const;
    [[nodiscard]] QString videos() const;
    [[nodiscard]] QString documents() const;
    [[nodiscard]] QString downloads() const;
    [[nodiscard]] QString music() const;
    [[nodiscard]] QString desktop() const;

    enum DateFormat {
        SystemLocale = 0,
        Iso = 1,
        LongLocale = 2,
        Custom = 3
    };
    Q_ENUM(DateFormat)

    Q_INVOKABLE static QString formatSize(qint64 bytes);
    Q_INVOKABLE static QString formatDateTime(const QDateTime& dt, int format = -1);
    static void setDateFormat(int format);
    static int dateFormat();
    Q_INVOKABLE static bool shouldThumbnail(bool isImage, bool isVideo, qint64 size);
    static void setThumbnailsEnabled(bool enabled);
    static void setCustomDateFormat(const QString& pattern);
    static void setThumbnailMaxBytes(qint64 bytes);
    Q_INVOKABLE static QString shortenHome(const QString& path);
    Q_INVOKABLE static QString toLocalFile(const QUrl& url);
    Q_INVOKABLE static QString baseName(const QString& path);
    Q_INVOKABLE static QVariantList describePaths(const QStringList& paths);
    Q_INVOKABLE static QString freeSpaceFor(const QString& path);
    Q_INVOKABLE static QVariantList templates();
    Q_INVOKABLE static bool isImage(const QString& path);
    Q_INVOKABLE static bool isVideo(const QString& path);
    Q_INVOKABLE static bool isAudio(const QString& path);
    Q_INVOKABLE static QString iconForName(const QString& name, const QString& fallback = QString());
    Q_INVOKABLE static QString iconForFile(const QString& name, bool isDir, const QString& mimeType);
    Q_INVOKABLE static QString mimeTypeForFile(const QString& path);
    Q_INVOKABLE static QString expandPath(const QString& input, const QString& currentDir = QString());
    Q_INVOKABLE static QVariantList getPathSuggestions(const QString& input, const QString& currentDir = QString());
    Q_INVOKABLE static QString getCompletedPath(const QString& input, const QString& currentDir = QString());
};

} // namespace prism::core

