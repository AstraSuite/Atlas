#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace prism::core {

class AppIntegration : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit AppIntegration(QObject* parent = nullptr);

    static AppIntegration* instance();

    Q_INVOKABLE QVariantList getAppsForFile(const QString& filePath);
    Q_INVOKABLE QVariantList getAvailableSharingServices();
    Q_INVOKABLE void shareFiles(const QString& serviceId, const QStringList& paths);
    Q_INVOKABLE void openWithDefault(const QString& filePath);
    Q_INVOKABLE void openWithApp(const QString& execLine, const QString& filePath);
    Q_INVOKABLE void openInTerminal(const QString& directoryPath);
    Q_INVOKABLE void openNewWindow(const QString& path = QString());

private:
    void scanDesktopFiles();

    struct DesktopApp {
        QString name;
        QString icon;
        QString exec;
        QString desktopFile;
        QStringList mimeTypes;
    };
    QList<DesktopApp> m_apps;
};

} // namespace prism::core
