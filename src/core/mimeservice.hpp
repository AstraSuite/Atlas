#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace prism::core {

class MimeService : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit MimeService(QObject* parent = nullptr);
    static MimeService* instance();

    Q_INVOKABLE QVariantList getApplicationsForFile(const QString& filePath);
    Q_INVOKABLE QVariantList getAllApplications();
    Q_INVOKABLE QVariantMap getDefaultApp(const QString& mimeType);
    Q_INVOKABLE QVariantMap getDefaultAppForFile(const QString& filePath);
    Q_INVOKABLE void openWith(const QString& filePath, const QString& desktopFilePath);
    Q_INVOKABLE void setDefaultApp(const QString& mimeType, const QString& desktopFileName);
};

} // namespace prism::core
