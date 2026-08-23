#pragma once

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QMap>
#include <QMimeDatabase>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantMap>

namespace prism::portal {

class PortalRequest : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.impl.portal.Request")

public:
    explicit PortalRequest(const QString& path, QObject* parent = nullptr);
    ~PortalRequest() override;

public slots:
    Q_SCRIPTABLE void Close();

signals:
    void closeRequested();

private:
    QString m_path;
};

class FileChooserPortal : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.impl.portal.FileChooser")

public:
    explicit FileChooserPortal(QObject* parent = nullptr);
    ~FileChooserPortal() override = default;

public slots:
    Q_SCRIPTABLE void OpenFile(const QDBusObjectPath& handle,
                               const QString& app_id,
                               const QString& parent_window,
                               const QString& title,
                               const QVariantMap& options,
                               const QDBusMessage& message);

    Q_SCRIPTABLE void SaveFile(const QDBusObjectPath& handle,
                               const QString& app_id,
                               const QString& parent_window,
                               const QString& title,
                               const QVariantMap& options,
                               const QDBusMessage& message);

    Q_SCRIPTABLE void SaveFiles(const QDBusObjectPath& handle,
                                const QString& app_id,
                                const QString& parent_window,
                                const QString& title,
                                const QVariantMap& options,
                                const QDBusMessage& message);

private:
    struct PendingRequest {
        QDBusMessage message;
        QProcess* process = nullptr;
        PortalRequest* requestObject = nullptr;
        bool isSaveFiles = false;
        QStringList fileListToSave;
    };

    void launchPrismPicker(const QString& title,
                           const QString& initialDir,
                           bool directoryOnly,
                           const QStringList& filters,
                           const QString& filterLabel,
                           const QDBusObjectPath& handle,
                           const QDBusMessage& message,
                           bool isSaveFiles = false,
                           const QStringList& fileList = {},
                           bool saveMode = false,
                           const QString& suggestedName = {});

    static QString findPrismBinary();
    static QString parseInitialDirectory(const QVariantMap& options);
    static void parseFilters(const QVariantMap& options, QStringList& outFilters, QString& outLabel);

    QMap<QString, PendingRequest> m_requests;
};

} // namespace prism::portal
