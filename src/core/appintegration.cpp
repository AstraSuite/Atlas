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
