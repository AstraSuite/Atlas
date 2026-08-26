#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace atlas::core {

class AppIntegration : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:

    static AppIntegration* instance();
    static AppIntegration* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    Q_INVOKABLE QVariantList getAppsForFile(const QString& filePath);
    Q_INVOKABLE QVariantList getAvailableSharingServices();
    Q_INVOKABLE void shareFiles(const QString& serviceId, const QStringList& paths);
    Q_INVOKABLE void openWithDefault(const QString& filePath);
    Q_INVOKABLE void openWithApp(const QString& execLine, const QString& filePath);
    Q_INVOKABLE void openInTerminal(const QString& directoryPath);
    Q_INVOKABLE bool isRunnable(const QString& filePath) const;
    Q_INVOKABLE void runExecutable(const QString& filePath, bool inTerminal);
    Q_INVOKABLE void openNewWindow(const QString& path = QString());

    Q_INVOKABLE QVariantList getCustomActions(const QString& currentDir, const QStringList& selectedPaths, bool isDir, const QString& mimeType);
    Q_INVOKABLE void executeCustomAction(const QString& actionId, const QString& currentDir, const QStringList& selectedPaths);
    Q_INVOKABLE void openScriptsFolder();
    Q_INVOKABLE QString scriptsFolderPath() const;
    Q_INVOKABLE int handleCustomProtocol(const QString& uri);
    Q_INVOKABLE QString getSystemGeometry(int index);

    // Papirus folder color and icon theme management
    Q_INVOKABLE bool isPapirusAvailable();
    Q_INVOKABLE QString currentPapirusColor();
    Q_INVOKABLE QStringList availablePapirusColors();
    Q_INVOKABLE bool setPapirusColor(const QString& color);
    Q_INVOKABLE void reloadIconTheme();


private:
    explicit AppIntegration(QObject* parent = nullptr);
    void scanDesktopFiles();
    void scanCustomActions();

    struct DesktopApp {
        QString name;
        QString icon;
        QString exec;
        QString desktopFile;
        QStringList mimeTypes;
    };

    struct CustomActionItem {
        QString id;
        QString name;
        QString icon;
        QString exec;
        QString target; // "all", "dir", "file", "archive"
        QStringList mimeTypes;
        bool isScript = false;
        QString scriptPath;
        bool themeIcon = false;
    };

    QList<DesktopApp> m_apps;
    QList<CustomActionItem> m_customActions;
};

} // namespace atlas::core
