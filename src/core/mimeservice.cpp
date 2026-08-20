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

void MimeService::openWith(const QString& filePath, const QString& desktopFilePath) {
    auto map = parseDesktopFile(desktopFilePath);
    if (map.isEmpty()) return;

    QString exec = map["exec"].toString();
    // Strip standard desktop entry field codes (%f, %F, %u, %U, etc.)
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
    QProcess::startDetached("xdg-mime", QStringList{ "default", desktopFileName, mimeType });
}

} // namespace prism::core
