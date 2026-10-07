#include "mimeservice.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QMap>
#include <QSaveFile>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>

namespace atlas::core {

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

namespace {
struct MimeappsData {
    QStringList sections;
    QMap<QString, QStringList> keyOrder;
    QMap<QString, QMap<QString, QString>> values;

    QString value(const QString& section, const QString& key) const {
        return values.value(section).value(key);
    }
    void set(const QString& section, const QString& key, const QString& val) {
        if (!values.contains(section)) {
            sections.append(section);
            keyOrder[section] = {};
            values[section] = {};
        }
        if (!values[section].contains(key)) keyOrder[section].append(key);
        values[section][key] = val;
    }
    void unset(const QString& section, const QString& key) {
        if (!values.contains(section) || !values[section].contains(key)) return;
        values[section].remove(key);
        keyOrder[section].removeAll(key);
    }
};

bool parseMimeapps(const QString& filePath, MimeappsData& data) {
    data = MimeappsData();
    QFile f(filePath);
    if (!f.exists()) return true;
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return false;
    QStringList lines;
    QTextStream in(&f);
    while (!in.atEnd()) lines.append(in.readLine());
    for (int pass = 0; pass < 2; ++pass) {
        QString section;
        bool inMangled = false;
        for (const QString& raw : std::as_const(lines)) {
            const QString t = raw.trimmed();
            if (t.startsWith('[') && t.endsWith(']')) {
                const QString name = t.mid(1, t.size() - 2).trimmed();
                inMangled = (name == QStringLiteral("Added%20Associations")
                    || name == QStringLiteral("Default%20Applications"));
                if (inMangled != (pass == 1)) {
                    section.clear();
                    continue;
                }
                section = name;
                if (inMangled) section.replace("%20", " ");
                if (!data.values.contains(section)) {
                    data.sections.append(section);
                    data.keyOrder[section] = {};
                    data.values[section] = {};
                }
                continue;
            }
            if (section.isEmpty() || t.isEmpty() || t.startsWith('#') || t.startsWith(';')) continue;
            const int eq = t.indexOf('=');
            if (eq <= 0) continue;
            QString key = t.left(eq).trimmed();
            QString val = t.mid(eq + 1).trimmed();
            if (inMangled) {
                key.replace('\\', '/');
                if (val.size() >= 2 && val.startsWith('"') && val.endsWith('"')) {
                    val = val.mid(1, val.size() - 2);
                }
                if (data.values[section].contains(key)) continue;
            }
            if (!data.values[section].contains(key)) data.keyOrder[section].append(key);
            data.values[section][key] = val;
        }
    }
    return true;
}

bool writeMimeapps(const QString& filePath, const MimeappsData& data) {
    QString target = filePath;
    const QString canonical = QFileInfo(filePath).canonicalFilePath();
    if (!canonical.isEmpty()) target = canonical;
    const QFile::Permissions perms = QFile::permissions(target);
    QSaveFile f(target);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Atlas: cannot write" << target;
        return false;
    }
    QTextStream out(&f);
    bool first = true;
    for (const QString& section : data.sections) {
        if (!first) out << '\n';
        first = false;
        out << '[' << section << "]\n";
        for (const QString& key : data.keyOrder.value(section)) {
            out << key << '=' << data.values.value(section).value(key) << '\n';
        }
    }
    if (perms != QFile::Permissions()) f.setPermissions(perms);
    if (!f.commit()) {
        qWarning() << "Atlas: failed to commit" << target;
        return false;
    }
    return true;
}
} // namespace
QVariantMap MimeService::getDefaultApp(const QString& mimeType) {
    if (mimeType.isEmpty()) return {};

    QString desktopId;
    QStringList removed;

    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configDir.isEmpty()) {
        MimeappsData userData;
        if (parseMimeapps(configDir + "/mimeapps.list", userData)) {
            desktopId = userData.value("Default Applications", mimeType);
            if (desktopId.isEmpty()) {
                desktopId = userData.value("Added Associations", mimeType).split(';', Qt::SkipEmptyParts).value(0);
            }
            removed = userData.value("Removed Associations", mimeType).split(';', Qt::SkipEmptyParts);
        }
    }

    if (desktopId.isEmpty()) {
        QStringList systemConfigDirs = { "/etc/xdg", "/usr/share/applications", "/usr/local/share/applications" };
        for (const auto& dir : systemConfigDirs) {
            QString path = dir + "/mimeapps.list";
            if (!QFile::exists(path)) continue;
            MimeappsData sysData;
            if (!parseMimeapps(path, sysData)) continue;
            desktopId = sysData.value("Default Applications", mimeType);
            if (!desktopId.isEmpty()) break;
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
    if (!desktopId.isEmpty() && removed.contains(desktopId)) desktopId.clear();

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


bool MimeService::setDefaultApp(const QString& mimeType, const QString& desktopFileName) {
    if (mimeType.isEmpty() || desktopFileName.isEmpty()) return false;

    QString cleanId = desktopFileName;
    if (cleanId.contains('/')) {
        cleanId = QFileInfo(cleanId).fileName();
    }

    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (configDir.isEmpty()) return false;
    QDir().mkpath(configDir);

    const QStringList desktops = QString::fromUtf8(qgetenv("XDG_CURRENT_DESKTOP")).toLower().split(':', Qt::SkipEmptyParts);
    for (const QString& desktop : desktops) {
        const QString shadow = configDir + "/" + desktop + "-mimeapps.list";
        if (QFile::exists(shadow) && QFileInfo(shadow).size() > 0) {
            qWarning() << "Atlas: per-desktop associations file shadows mimeapps.list:" << shadow;
            break;
        }
    }

    const QString mimeAppsPath = configDir + "/mimeapps.list";
    MimeappsData data;
    if (!parseMimeapps(mimeAppsPath, data)) {
        qWarning() << "Atlas: cannot read" << mimeAppsPath;
        return false;
    }

    QStringList defList = data.value("Default Applications", mimeType).split(';', Qt::SkipEmptyParts);
    defList.removeAll(cleanId);
    defList.prepend(cleanId);
    data.set("Default Applications", mimeType, defList.join(';'));

    QStringList addedList = data.value("Added Associations", mimeType).split(';', Qt::SkipEmptyParts);
    addedList.removeAll(cleanId);
    addedList.prepend(cleanId);
    data.set("Added Associations", mimeType, addedList.join(';') + ";");

    QStringList removedList = data.value("Removed Associations", mimeType).split(';', Qt::SkipEmptyParts);
    if (removedList.removeAll(cleanId) > 0) {
        if (removedList.isEmpty()) data.unset("Removed Associations", mimeType);
        else data.set("Removed Associations", mimeType, removedList.join(';') + ";");
    }

    return writeMimeapps(mimeAppsPath, data);
}

} // namespace atlas::core
