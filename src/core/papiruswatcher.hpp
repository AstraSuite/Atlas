#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QFileSystemWatcher>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <qqmlintegration.h>

namespace prism::core {

class PapirusWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString currentColor READ currentColor NOTIFY colorChanged)
    Q_PROPERTY(QStringList availableColors READ availableColors CONSTANT)
    Q_PROPERTY(bool isAvailable READ isAvailable CONSTANT)

public:
    ~PapirusWatcher() override = default;

    static PapirusWatcher* instance();
    static PapirusWatcher* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    [[nodiscard]] QString currentColor() const;
    [[nodiscard]] QStringList availableColors() const;
    [[nodiscard]] bool isAvailable() const;

    Q_INVOKABLE void reload();

signals:
    void colorChanged(const QString& color);
    void themeReloaded();

private slots:
    void onFileSystemChanged(const QString& path);
    void onDebounceTimeout();

private:
    explicit PapirusWatcher(QObject* parent = nullptr);
    void scanAndWatch();
    void addPathIfValid(const QString& path, bool isDir);
    QString readColorFromKeepFile(const QString& filePath) const;
    QString detectColorFromSymlink() const;

    QFileSystemWatcher m_watcher;
    QTimer m_debounceTimer;
    QString m_lastColor;
    QString m_lastSymlinkTarget;
    QStringList m_watchedDirectories;
    QStringList m_watchedFiles;
};

} // namespace prism::core
