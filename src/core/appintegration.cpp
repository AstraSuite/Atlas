#include "appintegration.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QDesktopServices>
#include <QUrl>
#include <QMimeDatabase>
#include <QSettings>
#include <QStandardPaths>
#include <QSet>
#include <QCoreApplication>

namespace prism::core {

AppIntegration::AppIntegration(QObject* parent)
    : QObject(parent) {
    scanDesktopFiles();
}

AppIntegration* AppIntegration::instance() {
    static auto* s_instance = new AppIntegration();
    return s_instance;
}

void AppIntegration::scanDesktopFiles() {
    m_apps.clear();
    QStringList appDirs = {
        QDir::homePath() + "/.local/share/applications",
        "/usr/local/share/applications",
        "/usr/share/applications"
    };

    QSet<QString> seenFiles;

    for (const QString& dirPath : appDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) continue;

        const auto entries = dir.entryInfoList(QStringList{ "*.desktop" }, QDir::Files);
        for (const auto& fi : entries) {
            if (seenFiles.contains(fi.fileName())) continue;
            seenFiles.insert(fi.fileName());

            QSettings desktop(fi.absoluteFilePath(), QSettings::IniFormat);
            desktop.beginGroup("Desktop Entry");

            bool noDisplay = desktop.value("NoDisplay", false).toBool();
            bool hidden = desktop.value("Hidden", false).toBool();
            QString type = desktop.value("Type").toString();

            if (noDisplay || hidden || (type != "Application" && !type.isEmpty())) {
                desktop.endGroup();
                continue;
            }

            QString name = desktop.value("Name").toString();
            QString icon = desktop.value("Icon").toString();
            QString exec = desktop.value("Exec").toString();
            QString mimes = desktop.value("MimeType").toString();

            desktop.endGroup();

            if (name.isEmpty() || exec.isEmpty()) continue;

            QStringList mimeList = mimes.split(';', Qt::SkipEmptyParts);
            for (QString& m : mimeList) m = m.trimmed();

            m_apps.append({ name, icon, exec, fi.absoluteFilePath(), mimeList });
        }
    }
}

QVariantList AppIntegration::getAppsForFile(const QString& filePath) {
    QVariantList result;
    if (filePath.isEmpty()) return result;

    QMimeDatabase mimeDb;
    QString mime = mimeDb.mimeTypeForFile(filePath).name();

    for (const auto& app : m_apps) {
        if (app.mimeTypes.contains(mime) || app.mimeTypes.contains("*/*")) {
            QVariantMap map;
            map["name"] = app.name;
            map["icon"] = app.icon;
            map["exec"] = app.exec;
            map["desktopFile"] = app.desktopFile;
            result.append(map);
        }
    }
    return result;
}

QVariantList AppIntegration::getAvailableSharingServices() {
    QVariantList services;

    // 1. LocalSend
    bool hasLocalSend = !QStandardPaths::findExecutable("localsend").isEmpty() ||
                         !QStandardPaths::findExecutable("localsend_app").isEmpty() ||
                         QFile::exists(QDir::homePath() + "/.local/share/flatpak/app/org.localsend.localsend_app") ||
                         QFile::exists("/var/lib/flatpak/app/org.localsend.localsend_app");
    if (!hasLocalSend) {
        for (const auto& app : m_apps) {
            if (app.name.contains("LocalSend", Qt::CaseInsensitive) || app.exec.contains("localsend", Qt::CaseInsensitive)) {
                hasLocalSend = true;
                break;
            }
        }
    }
    if (hasLocalSend) {
        QVariantMap s;
        s["id"] = "localsend";
        s["name"] = "LocalSend";
        s["icon"] = "wifi_tethering";
        services.append(s);
    }

    // 2. KDE Connect
    bool hasKdeConnect = !QStandardPaths::findExecutable("kdeconnect-handler").isEmpty() ||
                          !QStandardPaths::findExecutable("kdeconnect-cli").isEmpty() ||
                          !QStandardPaths::findExecutable("kdeconnect-app").isEmpty();
    if (!hasKdeConnect) {
        for (const auto& app : m_apps) {
            if (app.name.contains("KDE Connect", Qt::CaseInsensitive) || app.exec.contains("kdeconnect", Qt::CaseInsensitive)) {
                hasKdeConnect = true;
                break;
            }
        }
    }
    if (hasKdeConnect) {
        QVariantMap s;
        s["id"] = "kdeconnect";
        s["name"] = "KDE Connect";
        s["icon"] = "phone_android";
        services.append(s);
    }

    // 3. Quick Share / Nearby / Warpinator
    bool hasQuickShare = !QStandardPaths::findExecutable("rquickshare").isEmpty() ||
                          !QStandardPaths::findExecutable("nearbyshare").isEmpty() ||
                          !QStandardPaths::findExecutable("warpinator").isEmpty();
    if (!hasQuickShare) {
        for (const auto& app : m_apps) {
            if (app.name.contains("Quick Share", Qt::CaseInsensitive) ||
                app.name.contains("Nearby Share", Qt::CaseInsensitive) ||
                app.name.contains("Warpinator", Qt::CaseInsensitive)) {
                hasQuickShare = true;
                break;
            }
        }
    }
    if (hasQuickShare) {
        QVariantMap s;
        s["id"] = "quickshare";
        s["name"] = "Quick Share";
        s["icon"] = "share";
        services.append(s);
    }

    // 4. Bluetooth Send To
    bool hasBluetooth = !QStandardPaths::findExecutable("gnome-bluetooth-sendto").isEmpty() ||
                         !QStandardPaths::findExecutable("bluetooth-sendto").isEmpty() ||
                         !QStandardPaths::findExecutable("blueman-sendto").isEmpty();
    if (hasBluetooth) {
        QVariantMap s;
        s["id"] = "bluetooth";
        s["name"] = "Bluetooth";
        s["icon"] = "bluetooth";
        services.append(s);
    }

    // 5. Email Attachment
    bool hasEmail = !QStandardPaths::findExecutable("xdg-email").isEmpty() ||
                    !QStandardPaths::findExecutable("thunderbird").isEmpty();
    if (hasEmail) {
        QVariantMap s;
        s["id"] = "email";
        s["name"] = "Email";
        s["icon"] = "mail";
        services.append(s);
    }

    // If no specific tools were detected, provide standard options so the user always has functional Send To targets
    if (services.isEmpty()) {
        QVariantMap sEmail;
        sEmail["id"] = "email";
        sEmail["name"] = "Email";
        sEmail["icon"] = "mail";
        services.append(sEmail);

        QVariantMap sLocalSend;
        sLocalSend["id"] = "localsend";
        sLocalSend["name"] = "LocalSend";
        sLocalSend["icon"] = "wifi_tethering";
        services.append(sLocalSend);

        QVariantMap sKde;
        sKde["id"] = "kdeconnect";
        sKde["name"] = "KDE Connect";
        sKde["icon"] = "phone_android";
        services.append(sKde);
    }

    return services;
}

void AppIntegration::shareFiles(const QString& serviceId, const QStringList& paths) {
    if (paths.isEmpty()) return;

    if (serviceId == "localsend") {
        if (!QStandardPaths::findExecutable("localsend").isEmpty()) {
            QProcess::startDetached("localsend", paths);
        } else if (!QStandardPaths::findExecutable("localsend_app").isEmpty()) {
            QProcess::startDetached("localsend_app", paths);
        } else {
            QProcess::startDetached("flatpak", QStringList{ "run", "org.localsend.localsend_app" } + paths);
        }
    } else if (serviceId == "kdeconnect") {
        if (!QStandardPaths::findExecutable("kdeconnect-handler").isEmpty()) {
            QProcess::startDetached("kdeconnect-handler", paths);
        } else if (!QStandardPaths::findExecutable("kdeconnect-cli").isEmpty()) {
            QProcess::startDetached("kdeconnect-cli", QStringList{ "--share" } + paths);
        } else {
            QProcess::startDetached("kdeconnect-app", paths);
        }
    } else if (serviceId == "quickshare") {
        if (!QStandardPaths::findExecutable("rquickshare").isEmpty()) {
            QProcess::startDetached("rquickshare", paths);
        } else if (!QStandardPaths::findExecutable("warpinator").isEmpty()) {
            QProcess::startDetached("warpinator", paths);
        } else {
            QProcess::startDetached("nearbyshare", paths);
        }
    } else if (serviceId == "bluetooth") {
        if (!QStandardPaths::findExecutable("gnome-bluetooth-sendto").isEmpty()) {
            QProcess::startDetached("gnome-bluetooth-sendto", paths);
        } else if (!QStandardPaths::findExecutable("bluetooth-sendto").isEmpty()) {
            QProcess::startDetached("bluetooth-sendto", paths);
        } else {
            QProcess::startDetached("blueman-sendto", paths);
        }
    } else if (serviceId == "email") {
        QStringList args;
        for (const auto& p : paths) {
            args << "--attach" << p;
        }
        QProcess::startDetached("xdg-email", args);
    }
}

void AppIntegration::openWithDefault(const QString& filePath) {
    QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
}

void AppIntegration::openWithApp(const QString& execLine, const QString& filePath) {
    QString cmd = execLine;
    // Replace %f, %F, %u, %U with file path
    cmd.replace("%f", QString("\"%1\"").arg(filePath));
    cmd.replace("%F", QString("\"%1\"").arg(filePath));
    cmd.replace("%u", QString("\"%1\"").arg(QUrl::fromLocalFile(filePath).toString()));
    cmd.replace("%U", QString("\"%1\"").arg(QUrl::fromLocalFile(filePath).toString()));
    cmd.remove("%i");
    cmd.remove("%c");
    cmd.remove("%k");
    cmd.remove("%m");

    QProcess::startDetached("/bin/sh", QStringList{ "-c", cmd });
}

void AppIntegration::openInTerminal(const QString& directoryPath) {
    QString term = qEnvironmentVariable("TERMINAL");
    if (term.isEmpty()) {
        static const QStringList candidates = { "foot", "kitty", "alacritty", "ghostty", "wezterm", "konsole", "gnome-terminal", "xterm" };
        for (const auto& c : candidates) {
            if (!QStandardPaths::findExecutable(c).isEmpty()) {
                term = c;
                break;
            }
        }
    }
    if (term.isEmpty()) term = "xterm";

    QProcess::startDetached(term, QStringList(), directoryPath);
}

void AppIntegration::openNewWindow(const QString& path) {
    QString appPath = QCoreApplication::applicationFilePath();
    QStringList args;
    if (!path.isEmpty()) {
        args << path;
    }
    QProcess::startDetached(appPath, args);
}

} // namespace prism::core
