#include "mimeservice.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QMimeDatabase>
#include <QMimeType>
#include <QProcess>
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

// Read the semicolon-separated value(s) of `key` inside `group` of a plain
// XDG mimeapps.list file. The file format is NOT QSettings-compatible, so it
// is parsed line-by-line here.
static QStringList mimeappsGroupValues(const QString& path, const QString& groupName, const QString& key) {
    QFile inFile(path);
    if (!inFile.open(QIODevice::ReadOnly | QIODevice::Text)) return {};

    QString currentGroup;
    QStringList result;
    while (!inFile.atEnd()) {
        QString line = QString::fromUtf8(inFile.readLine()).trimmed();
        if (line.startsWith('[')) {
            currentGroup = line.mid(1, line.size() - 2).trimmed();
            continue;
        }
        if (currentGroup.compare(groupName, Qt::CaseInsensitive) != 0) continue;

        int eq = line.indexOf(QLatin1Char('='));
        if (eq < 0) continue;
        if (line.left(eq).trimmed() != key) continue;

        QString value = line.mid(eq + 1).trimmed();
        if (value.startsWith('"') && value.endsWith('"'))
            value = value.mid(1, value.size() - 2);
        result = value.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    }

    return result;
}

// Update [Default Applications] and [Added Associations] in a plain XDG
// mimeapps.list file. QSettings::IniFormat would escape spaces in the group
// names ("Default%20Applications") and slashes in MIME keys ("image\/png"),
// producing a file that xdg-open silently ignores, so the file is edited by
// hand instead.
static void writeDefaultEntries(const QString& path, const QStringList& mimes, const QString& appId) {
    QMap<QString, QString> defaults;
    QMap<QString, QString> added;
    QStringList otherLines;

    QFile inFile(path);
    if (inFile.exists() && inFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString currentGroup;
        while (!inFile.atEnd()) {
            QString line = QString::fromUtf8(inFile.readLine()).trimmed();
            if (line.isEmpty() || line.startsWith('#')) {
                otherLines << line;
                continue;
            }
            if (line.startsWith('[')) {
                currentGroup = line.mid(1, line.size() - 2).trimmed();
                bool managed = currentGroup.compare("Default Applications", Qt::CaseInsensitive) == 0
                            || currentGroup.compare("Added Associations", Qt::CaseInsensitive) == 0;
                if (!managed)
                    otherLines << line;
                continue;
            }
            int eq = line.indexOf(QLatin1Char('='));
            if (eq < 0) {
                otherLines << line;
                continue;
            }
            QString key = line.left(eq).trimmed();
            QString value = line.mid(eq + 1).trimmed();
            if (value.startsWith('"') && value.endsWith('"'))
                value = value.mid(1, value.size() - 2);
            if (currentGroup.compare("Default Applications", Qt::CaseInsensitive) == 0) {
                defaults[key] = value;
            } else if (currentGroup.compare("Added Associations", Qt::CaseInsensitive) == 0) {
                added[key] = value;
            } else {
                otherLines << line;
            }
        }
        inFile.close();
    }

    for (const QString& mime : mimes) {
        defaults[mime] = appId;
        QStringList entries = added.value(mime).split(QLatin1Char(';'), Qt::SkipEmptyParts);
        entries.removeAll(appId);
        entries.prepend(appId);
        added[mime] = entries.join(QLatin1Char(';')) + QLatin1Char(';');
    }

    QFile outFile(path);
    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) return;
    QTextStream out(&outFile);
    for (const QString& line : otherLines)
        out << line << '\n';
    if (!otherLines.isEmpty() && !otherLines.last().isEmpty())
        out << '\n';
    out << "[Default Applications]\n";
    for (auto it = defaults.constBegin(); it != defaults.constEnd(); ++it)
        out << it.key() << '=' << it.value() << '\n';
    out << "\n[Added Associations]\n";
    for (auto it = added.constBegin(); it != added.constEnd(); ++it)
        out << it.key() << '=' << it.value() << '\n';
    outFile.close();
}

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

    // Query user mimeapps.list
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configDir.isEmpty()) {
        QString mimeAppsPath = configDir + "/mimeapps.list";
        auto defs = mimeappsGroupValues(mimeAppsPath, "Default Applications", mimeType);
        if (!defs.isEmpty()) desktopId = defs.first();
        if (desktopId.isEmpty()) {
            auto added = mimeappsGroupValues(mimeAppsPath, "Added Associations", mimeType);
            if (!added.isEmpty()) desktopId = added.first();
        }
    }

    // Query system mimeapps.list
    if (desktopId.isEmpty()) {
        QStringList systemConfigDirs = { "/etc/xdg", "/usr/share/applications", "/usr/local/share/applications" };
        for (const auto& dir : systemConfigDirs) {
            QString path = dir + "/mimeapps.list";
            auto defs = mimeappsGroupValues(path, "Default Applications", mimeType);
            if (!defs.isEmpty()) { desktopId = defs.first(); break; }
            auto added = mimeappsGroupValues(path, "Added Associations", mimeType);
            if (!added.isEmpty()) { desktopId = added.first(); break; }
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

void MimeService::setDefaultApp(const QString& mimeType, const QString& desktopFileName) {
    if (mimeType.isEmpty() || desktopFileName.isEmpty()) return;

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

    // Write mimeapps.list by hand: QSettings::IniFormat escapes spaces in the
    // group names and slashes in MIME keys, producing a file that xdg-open
    // silently ignores (the PNG default stopped working once a JPEG default
    // was set in the same file). xdg-open / GLib read this file directly, so
    // no extra xdg-mime invocation is needed.
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configDir.isEmpty()) {
        QDir().mkpath(configDir);
        writeDefaultEntries(configDir + "/mimeapps.list", mimes, cleanId);
    }
}

} // namespace atlas::core
