#pragma once

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

    Q_INVOKABLE static QString formatSize(qint64 bytes);
    Q_INVOKABLE static QString shortenHome(const QString& path);
    Q_INVOKABLE static QString toLocalFile(const QUrl& url);
    Q_INVOKABLE static QString baseName(const QString& path);
    Q_INVOKABLE static QString iconForName(const QString& name, const QString& fallback = QString());
    Q_INVOKABLE static QString iconForFile(const QString& name, bool isDir, const QString& mimeType);
};

} // namespace prism::core
