#include "mimeservice.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDebug>
#include <QMap>
#include <QMimeDatabase>
#include <QMimeType>
#include <QProcess>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>

namespace atlas::core {

MimeService::MimeService(QObject* parent) : QObject(parent) {}

MimeService* MimeService::instance() {
    static auto* s_instance = new MimeService();
    return s_instance;
}

// Read a single key from a .desktop file's [Desktop Entry] group.
// QSettings::IniFormat mangles the semicolon-separated lists used by the
// desktop entry spec: "MimeType=image/png;image/jpeg;" is collapsed to
// "image/png", silently dropping every MIME type after the first. Desktop
// entries are therefore parsed here instead.
static QString desktopEntryValue(const QString& desktopPath, const QString& key) {
    QFile file(desktopPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    bool inEntryGroup = false;
    QString value;

    while (!file.atEnd()) {
        QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith('#') || line.startsWith(';'))
            continue;

        if (line.startsWith('[')) {
            inEntryGroup = line.compare(QStringLiteral("[Desktop Entry]"), Qt::CaseInsensitive) == 0;
            continue;
        }
        if (!inEntryGroup)
            continue;

        int eq = line.indexOf(QLatin1Char('='));
        if (eq <= 0)
            continue;
        if (line.left(eq).trimmed().compare(key, Qt::CaseInsensitive) != 0)
            continue;

        // Later occurrences override earlier ones (desktop entry spec).
        value = line.mid(eq + 1).trimmed();
    }

    return value;
}

static QVariantMap parseDesktopFile(const QString& desktopPath, bool includeNoDisplay = false) {
    bool noDisplay = desktopEntryValue(desktopPath, QStringLiteral("NoDisplay"))
                         .compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0;
    if (noDisplay && !includeNoDisplay) {
        return {};
    }

    bool hidden = desktopEntryValue(desktopPath, QStringLiteral("Hidden"))
                      .compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0;
    if (hidden) {
        return {};
    }

    // Terminal apps (e.g. micro) must be launched inside a terminal emulator.
    bool terminal = desktopEntryValue(desktopPath, QStringLiteral("Terminal"))
                        .compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0;

    // Type defaults to "Application" when absent.
    QString type = desktopEntryValue(desktopPath, QStringLiteral("Type"));
    if (!type.isEmpty() && type.compare(QStringLiteral("Application"), Qt::CaseInsensitive) != 0) {
        return {};
    }

    QString name = desktopEntryValue(desktopPath, QStringLiteral("Name"));
    QString exec = desktopEntryValue(desktopPath, QStringLiteral("Exec"));
    QString icon = desktopEntryValue(desktopPath, QStringLiteral("Icon"));
    QString comment = desktopEntryValue(desktopPath, QStringLiteral("Comment"));
    QStringList mimeTypes = desktopEntryValue(desktopPath, QStringLiteral("MimeType"))
                                .split(QLatin1Char(';'), Qt::SkipEmptyParts);

    if (name.isEmpty() || exec.isEmpty()) return {};

    QVariantMap map;
    map["id"] = QFileInfo(desktopPath).fileName();
    map["path"] = desktopPath;
    map["name"] = name;
    map["exec"] = exec;
    map["icon"] = icon.isEmpty() ? "application-x-executable" : icon;
    map["comment"] = comment;
    map["mimeTypes"] = mimeTypes;
    map["noDisplay"] = noDisplay;
    map["terminal"] = terminal;
    return map;
}

// Pick the user's terminal emulator, mirroring AppIntegration::resolveTerminal.
static QString resolveTerminal() {
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
    if (term.isEmpty()) term = QStringLiteral("xterm");
    return term;
}

static QVariantList scanApplications(bool includeNoDisplay) {
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

            auto map = parseDesktopFile(fi.absoluteFilePath(), includeNoDisplay);
            if (!map.isEmpty()) {
                seenIds.insert(id);
                apps.append(map);
            }
        }
    }

    return apps;
}

static QString findDesktopFile(const QString& desktopId) {
    if (QFile::exists(desktopId)) return desktopId;
    const QStringList appDirs = {
        QDir::homePath() + "/.local/share/applications",
        "/usr/local/share/applications",
        "/usr/share/applications"
    };
    for (const auto& dir : appDirs) {
        QString fullPath = dir + "/" + desktopId;
        if (QFile::exists(fullPath)) return fullPath;
    }
    return {};
}

// Plain-XDG mimeapps.list model. The file format is NOT QSettings-compatible,
// so it is parsed and written by hand: QSettings::IniFormat escapes spaces in
// the group names ("Default%20Applications") and slashes in MIME keys
// ("image\/png"), producing a file that xdg-open silently ignores.
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
    // Read the canonical sections first, then migrate the group/key names that
    // an older QSettings-based writer mangled, so previously-corrupted files
    // are healed in place.
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

QVariantList MimeService::getAllApplications() {
    return scanApplications(false);
}

QVariantList MimeService::getApplicationsForFile(const QString& filePath) {
    QFileInfo fi(filePath);
    QMimeDatabase mimeDb;
    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    QString mimeName = mime.name();

    QVariantList recommended;
    QVariantList others;
    QSet<QString> seenIds;

    auto supportsMime = [&](const QVariantMap& map) {
        QStringList mimes = map["mimeTypes"].toStringList();
        if (mimes.contains(mimeName)) return true;
        if (!mime.aliases().isEmpty() && mimes.contains(mime.aliases().first())) return true;
        return false;
    };

    auto addApp = [&](QVariantMap map) {
        if (seenIds.contains(map["id"].toString())) return;
        seenIds.insert(map["id"].toString());
        bool matches = supportsMime(map);
        map["isRecommended"] = matches;
        if (matches)
            recommended.append(map);
        else
            others.append(map);
    };

    // All launcher-visible applications.
    for (const auto& var : scanApplications(false))
        addApp(var.toMap());

    // NoDisplay entries are hidden from launchers, but one that explicitly
    // declares this file's mime type is still a valid "Open With" choice
    // (e.g. swappy ships NoDisplay=true with MimeType=image/png;image/jpeg;).
    for (const auto& var : scanApplications(true)) {
        auto map = var.toMap();
        if (map["noDisplay"].toBool() && supportsMime(map))
            addApp(map);
    }

    QVariantList result = recommended;
    result.append(others);
    return result;
}

QVariantMap MimeService::getDefaultApp(const QString& mimeType) {
    if (mimeType.isEmpty()) return {};

    QString desktopId;
    QStringList removed;

    // Query user mimeapps.list
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

    // Query system mimeapps.list
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
                // A NoDisplay handler (e.g. swappy) is a valid default too.
                auto parsed = parseDesktopFile(fullPath, true);
                if (!parsed.isEmpty()) return parsed;
            }
        }
    }

    // Fallback to first recommended app; explicit MIME handlers with
    // NoDisplay=true are valid defaults too.
    for (const auto& var : scanApplications(true)) {
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
    // Include NoDisplay entries here too: they can be picked from the
    // Open With dialog (e.g. swappy) and must still launch.
    auto map = parseDesktopFile(desktopFilePath, true);
    if (map.isEmpty()) return;

    QString exec = map["exec"].toString();
    // Strip standard desktop entry field codes
    exec.remove("%f").remove("%F").remove("%u").remove("%U").remove("%d").remove("%D").remove("%n").remove("%N").remove("%i").remove("%c").remove("%k").remove("%v").remove("%m");
    exec = exec.trimmed();

    QStringList args = QProcess::splitCommand(exec);
    if (args.isEmpty()) return;

    QString program = args.takeFirst();
    args.append(filePath);

    if (map["terminal"].toBool()) {
        // Terminal apps (e.g. micro) can't run without a terminal attached, so
        // launch them inside the user's terminal emulator.
        QStringList launchArgs = QStringList{ QStringLiteral("-e"), program };
        launchArgs.append(args);
        QProcess::startDetached(resolveTerminal(), launchArgs);
        return;
    }

    QProcess::startDetached(program, args);
}

bool MimeService::setDefaultApp(const QString& mimeType, const QString& desktopFileName) {
    if (mimeType.isEmpty() || desktopFileName.isEmpty()) return false;

    QString cleanId = desktopFileName;
    if (cleanId.contains('/')) {
        cleanId = QFileInfo(cleanId).fileName();
    }

    // Register the default for the whole group of MIME types the chosen app
    // declares (e.g. all image/* types for an image app), so a single
    // "Always use this application for this file type" click covers every
    // extension the app supports instead of just the exact file type. This
    // also prevents a later choice for one image type from clobbering an
    // earlier choice for another one.
    QStringList mimes;
    QString appPath = findDesktopFile(desktopFileName);
    if (!appPath.isEmpty()) {
        auto app = parseDesktopFile(appPath, true);
        QString groupPrefix = mimeType.left(mimeType.indexOf(QLatin1Char('/')));
        for (const auto& m : app["mimeTypes"].toStringList()) {
            if (m == "*/*" || m == "application/octet-stream") continue;
            if (m == mimeType || (!groupPrefix.isEmpty() && m.startsWith(groupPrefix + "/")))
                mimes << m;
        }
    }
    if (!mimes.contains(mimeType))
        mimes.prepend(mimeType);
    mimes.removeDuplicates();

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

    for (const QString& mime : mimes) {
        QStringList defList = data.value("Default Applications", mime).split(';', Qt::SkipEmptyParts);
        defList.removeAll(cleanId);
        defList.prepend(cleanId);
        data.set("Default Applications", mime, defList.join(';'));

        QStringList addedList = data.value("Added Associations", mime).split(';', Qt::SkipEmptyParts);
        addedList.removeAll(cleanId);
        addedList.prepend(cleanId);
        data.set("Added Associations", mime, addedList.join(';') + ";");

        QStringList removedList = data.value("Removed Associations", mime).split(';', Qt::SkipEmptyParts);
        if (removedList.removeAll(cleanId) > 0) {
            if (removedList.isEmpty()) data.unset("Removed Associations", mime);
            else data.set("Removed Associations", mime, removedList.join(';') + ";");
        }
    }

    return writeMimeapps(mimeAppsPath, data);
}

} // namespace atlas::core
