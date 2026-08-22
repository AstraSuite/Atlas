#include "mimeservice.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <algorithm>

namespace prism::core {

MimeService::MimeService(QObject* parent) : QObject(parent) {}

MimeService* MimeService::instance() {
    static auto* s_instance = new MimeService();
    return s_instance;
}

static QVariantMap parseDesktopFile(const QString& desktopPath) {
    QSettings ini(desktopPath, QSettings::IniFormat);
    ini.beginGroup("Desktop Entry");

    if (ini.value("NoDisplay", false).toBool() || ini.value("Hidden", false).toBool()) {
        return {};
    }

    if (ini.value("Type", "Application").toString() != "Application") {
        return {};
    }

    QString name = ini.value("Name").toString();
    QString exec = ini.value("Exec").toString();
    QString icon = ini.value("Icon").toString();
    QString comment = ini.value("Comment").toString();
    QString mimeStr = ini.value("MimeType").toString();
    QStringList mimeTypes = mimeStr.split(';', Qt::SkipEmptyParts);

    if (name.isEmpty() || exec.isEmpty()) return {};

    QVariantMap map;
    map["id"] = QFileInfo(desktopPath).fileName();
    map["path"] = desktopPath;
    map["name"] = name;
    map["exec"] = exec;
    map["icon"] = icon.isEmpty() ? "application-x-executable" : icon;
    map["comment"] = comment;
    map["mimeTypes"] = mimeTypes;
    return map;
}

QVariantList MimeService::getAllApplications() {
    QVariantList apps;
    QStringList appDirs = {
        QDir::homePath() + "/.local/share/applications",
        "/usr/local/share/applications",
        "/usr/share/applications"
    };

    QSet<QString> seenIds;

    for (const auto& dirPath : appDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) continue;

        const auto entries = dir.entryInfoList({ "*.desktop" }, QDir::Files);
        for (const auto& fi : entries) {
            QString id = fi.fileName();
            if (seenIds.contains(id)) continue;

            auto map = parseDesktopFile(fi.absoluteFilePath());
            if (!map.isEmpty()) {
                seenIds.insert(id);
                apps.append(map);
            }
        }
    }

    return apps;
}

QVariantList MimeService::getApplicationsForFile(const QString& filePath) {
    QFileInfo fi(filePath);
    QMimeDatabase mimeDb;
    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    QString mimeName = mime.name();

    auto allApps = getAllApplications();
    QVariantList recommended;
    QVariantList others;

    for (const auto& var : allApps) {
        auto map = var.toMap();
        QStringList mimes = map["mimeTypes"].toStringList();
        if (mimes.contains(mimeName) || (!mime.aliases().isEmpty() && mimes.contains(mime.aliases().first()))) {
            map["isRecommended"] = true;
            recommended.append(map);
        } else {
            map["isRecommended"] = false;
            others.append(map);
        }
    }

    QVariantList result = recommended;
    result.append(others);
    return result;
}

QVariantMap MimeService::getDefaultApp(const QString& mimeType) {
    if (mimeType.isEmpty()) return {};

    QString desktopId;

    // Query user mimeapps.list
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configDir.isEmpty()) {
        QSettings settings(configDir + "/mimeapps.list", QSettings::IniFormat);
        desktopId = settings.value(QString("Default Applications/%1").arg(mimeType)).toString();
        if (desktopId.isEmpty()) {
            desktopId = settings.value(QString("Added Associations/%1").arg(mimeType)).toString().split(';', Qt::SkipEmptyParts).value(0);
        }
    }

    // Query system mimeapps.list
    if (desktopId.isEmpty()) {
        QStringList systemConfigDirs = { "/etc/xdg", "/usr/share/applications", "/usr/local/share/applications" };
        for (const auto& dir : systemConfigDirs) {
            QString path = dir + "/mimeapps.list";
            if (QFile::exists(path)) {
                QSettings settings(path, QSettings::IniFormat);
                desktopId = settings.value(QString("Default Applications/%1").arg(mimeType)).toString();
                if (!desktopId.isEmpty()) break;
            }
        }
    }

    // Fallback to xdg-mime query default
    if (desktopId.isEmpty()) {
        QProcess proc;
        proc.start("xdg-mime", QStringList{ "query", "default", mimeType });
        if (proc.waitForFinished(1000)) {
            desktopId = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        }
    }

    // If desktopId contains semicolons, pick the first
    if (desktopId.contains(';')) {
        desktopId = desktopId.split(';', Qt::SkipEmptyParts).value(0).trimmed();
    }

    if (!desktopId.isEmpty()) {
        QStringList appDirs = {
            QDir::homePath() + "/.local/share/applications",
            "/usr/local/share/applications",
            "/usr/share/applications"
        };

        for (const auto& dirPath : appDirs) {
            QString fullPath = dirPath + "/" + desktopId;
            if (QFile::exists(fullPath)) {
                auto parsed = parseDesktopFile(fullPath);
                if (!parsed.isEmpty()) return parsed;
            }
        }
    }

    // Fallback to first recommended app
    auto allApps = getAllApplications();
    for (const auto& var : allApps) {
        auto map = var.toMap();
        if (map["mimeTypes"].toStringList().contains(mimeType)) {
            return map;
        }
    }

    return {};
}

QVariantMap MimeService::getDefaultAppForFile(const QString& filePath) {
    if (filePath.isEmpty()) return {};
    QMimeDatabase db;
    QString mime = db.mimeTypeForFile(filePath).name();
    return getDefaultApp(mime);
}

void MimeService::openWith(const QString& filePath, const QString& desktopFilePath) {
    auto map = parseDesktopFile(desktopFilePath);
    if (map.isEmpty()) return;

    QString exec = map["exec"].toString();
    // Strip standard desktop entry field codes
    exec.remove("%f").remove("%F").remove("%u").remove("%U").remove("%d").remove("%D").remove("%n").remove("%N").remove("%i").remove("%c").remove("%k").remove("%v").remove("%m");
    exec = exec.trimmed();

    QStringList args = QProcess::splitCommand(exec);
    if (args.isEmpty()) return;

    QString program = args.takeFirst();
    args.append(filePath);

    QProcess::startDetached(program, args);
}

void MimeService::setDefaultApp(const QString& mimeType, const QString& desktopFileName) {
    if (mimeType.isEmpty() || desktopFileName.isEmpty()) return;

    QString cleanId = desktopFileName;
    if (cleanId.contains('/')) {
        cleanId = QFileInfo(cleanId).fileName();
    }

    // Update mimeapps.list directly according to XDG Desktop Entry Specification
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configDir.isEmpty()) {
        QDir().mkpath(configDir);
        QString mimeAppsPath = configDir + "/mimeapps.list";

        QSettings settings(mimeAppsPath, QSettings::IniFormat);
        settings.beginGroup("Default Applications");
        settings.setValue(mimeType, cleanId);
        settings.endGroup();

        settings.beginGroup("Added Associations");
        QString currentAdded = settings.value(mimeType).toString();
        QStringList addedList = currentAdded.split(';', Qt::SkipEmptyParts);
        addedList.removeAll(cleanId);
        addedList.prepend(cleanId);
        settings.setValue(mimeType, addedList.join(';') + ";");
        settings.endGroup();
        settings.sync();
    }

    // Also invoke xdg-mime default
    QProcess::startDetached("xdg-mime", QStringList{ "default", cleanId, mimeType });
}

} // namespace prism::core
