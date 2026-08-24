#include "filechooserportal.hpp"
#include <QCoreApplication>
#include <QDBusArgument>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QUrl>

namespace atlas::portal {

PortalRequest::PortalRequest(const QString& path, QObject* parent)
    : QObject(parent), m_path(path) {
    QDBusConnection::sessionBus().registerObject(m_path, this, QDBusConnection::ExportAllSlots);
}

PortalRequest::~PortalRequest() {
    QDBusConnection::sessionBus().unregisterObject(m_path);
}

void PortalRequest::Close() {
    emit closeRequested();
}

FileChooserPortal::FileChooserPortal(QObject* parent)
    : QObject(parent) {
}

QString FileChooserPortal::findAtlasBinary() {
    // Check same directory as portal binary
    QString appDir = QCoreApplication::applicationDirPath();
    if (QFile::exists(appDir + "/atlas")) {
        return appDir + "/atlas";
    }
    // Check /usr/bin/atlas
    if (QFile::exists("/usr/bin/atlas")) {
        return "/usr/bin/atlas";
    }
    // Check /usr/local/bin/atlas
    if (QFile::exists("/usr/local/bin/atlas")) {
        return "/usr/local/bin/atlas";
    }
    // Default to searching in PATH
    return "atlas";
}

QString FileChooserPortal::parseInitialDirectory(const QVariantMap& options) {
    QString raw;
    if (options.contains("current_folder")) {
        QVariant var = options.value("current_folder");
        if (var.userType() == QMetaType::QByteArray) {
            QByteArray bytes = var.toByteArray();
            if (bytes.endsWith('\0')) {
                bytes.chop(1);
            }
            raw = QString::fromUtf8(bytes);
        } else {
            raw = var.toString();
        }
    }
    if (raw.isEmpty() && options.contains("current_file")) {
        QVariant var = options.value("current_file");
        if (var.userType() == QMetaType::QByteArray) {
            QByteArray bytes = var.toByteArray();
            if (bytes.endsWith('\0')) {
                bytes.chop(1);
            }
            raw = QString::fromUtf8(bytes);
        } else {
            raw = var.toString();
        }
    }

    if (raw.isEmpty()) {
        return {};
    }

    if (raw.startsWith(QLatin1String("file://"))) {
        raw = QUrl(raw).toLocalFile();
    }

    QFileInfo fi(raw);
    if (fi.exists()) {
        if (fi.isDir()) {
            return fi.absoluteFilePath();
        } else {
            return fi.absolutePath();
        }
    }

    if (!fi.absolutePath().isEmpty() && QDir(fi.absolutePath()).exists()) {
        return fi.absolutePath();
    }

    return raw;
}

void FileChooserPortal::parseFilters(const QVariantMap& options, QStringList& outFilters, QString& outLabel) {
    outFilters.clear();
    outLabel.clear();

    if (!options.contains("filters")) {
        return;
    }

    QMimeDatabase mimeDb;
    QVariant filtersVar = options.value("filters");
    if (filtersVar.canConvert<QDBusArgument>()) {
        const auto arg = filtersVar.value<QDBusArgument>();
        if (arg.currentType() == QDBusArgument::ArrayType) {
            arg.beginArray();
            while (!arg.atEnd()) {
                arg.beginStructure();
                QString label;
                arg >> label;
                if (outLabel.isEmpty() && !label.isEmpty()) {
                    outLabel = label;
                }
                arg.beginArray();
                while (!arg.atEnd()) {
                    arg.beginStructure();
                    uint type = 0;
                    QString pattern;
                    arg >> type >> pattern;
                    if (!pattern.isEmpty()) {
                        if (type == 0) {
                            // Glob pattern
                            if (pattern.startsWith("*.")) {
                                pattern = pattern.mid(2);
                            } else if (pattern.startsWith('.')) {
                                pattern = pattern.mid(1);
                            }
                            if (!pattern.isEmpty() && !outFilters.contains(pattern)) {
                                outFilters.append(pattern);
                            }
                        } else if (type == 1) {
                            // MIME type pattern
                            QMimeType mt = mimeDb.mimeTypeForName(pattern);
                            if (mt.isValid()) {
                                for (QString glob : mt.globPatterns()) {
                                    if (glob.startsWith("*.")) {
                                        glob = glob.mid(2);
                                    } else if (glob.startsWith('.')) {
                                        glob = glob.mid(1);
                                    }
                                    if (!glob.isEmpty() && !outFilters.contains(glob)) {
                                        outFilters.append(glob);
                                    }
                                }
                            }
                        }
                    }
                    arg.endStructure();
                }
                arg.endArray();
                arg.endStructure();
            }
            arg.endArray();
        }
    }
}

void FileChooserPortal::OpenFile(const QDBusObjectPath& handle,
                                 const QString& app_id,
                                 const QString& parent_window,
                                 const QString& title,
                                 const QVariantMap& options,
                                 const QDBusMessage& message) {
    Q_UNUSED(app_id);
    Q_UNUSED(parent_window);

    message.setDelayedReply(true);

    QString dialogTitle = title.isEmpty() ? QStringLiteral("Open File") : title;
    QString initialDir = parseInitialDirectory(options);
    bool directoryOnly = options.value("directory", false).toBool();

    QStringList filters;
    QString filterLabel;
    parseFilters(options, filters, filterLabel);

    if (options.contains("accept_label") && !options.value("accept_label").toString().isEmpty()) {
        filterLabel = options.value("accept_label").toString();
    }

    launchAtlasPicker(dialogTitle, initialDir, directoryOnly, filters, filterLabel, handle, message);
}

void FileChooserPortal::SaveFile(const QDBusObjectPath& handle,
                                 const QString& app_id,
                                 const QString& parent_window,
                                 const QString& title,
                                 const QVariantMap& options,
                                 const QDBusMessage& message) {
    Q_UNUSED(app_id);
    Q_UNUSED(parent_window);

    message.setDelayedReply(true);

    QString dialogTitle = title.isEmpty() ? QStringLiteral("Save File") : title;
    QString initialDir = parseInitialDirectory(options);

    QStringList filters;
    QString filterLabel;
    parseFilters(options, filters, filterLabel);

    if (options.contains("accept_label") && !options.value("accept_label").toString().isEmpty()) {
        filterLabel = options.value("accept_label").toString();
    }

    QString suggestedName;
    if (options.contains(QStringLiteral("current_name")))
        suggestedName = options.value(QStringLiteral("current_name")).toString();

    if (options.contains(QStringLiteral("current_file"))) {
        const QString current = QFile::decodeName(options.value(QStringLiteral("current_file")).toByteArray());
        const QFileInfo info(current.trimmed());
        if (!info.filePath().isEmpty()) {
            if (suggestedName.isEmpty())
                suggestedName = info.fileName();
            if (initialDir.isEmpty())
                initialDir = info.absolutePath();
        }
    }

    launchAtlasPicker(dialogTitle, initialDir, false, filters, filterLabel, handle, message, false, {}, true, suggestedName);
}

void FileChooserPortal::SaveFiles(const QDBusObjectPath& handle,
                                  const QString& app_id,
                                  const QString& parent_window,
                                  const QString& title,
                                  const QVariantMap& options,
                                  const QDBusMessage& message) {
    Q_UNUSED(app_id);
    Q_UNUSED(parent_window);

    message.setDelayedReply(true);

    QString dialogTitle = title.isEmpty() ? QStringLiteral("Save Files") : title;
    QString initialDir = parseInitialDirectory(options);

    QStringList fileList;
    if (options.contains("files")) {
        QVariant filesVar = options.value("files");
        if (filesVar.canConvert<QDBusArgument>()) {
            const auto arg = filesVar.value<QDBusArgument>();
            if (arg.currentType() == QDBusArgument::ArrayType) {
                arg.beginArray();
                while (!arg.atEnd()) {
                    QByteArray rawName;
                    arg >> rawName;
                    if (rawName.endsWith('\0')) rawName.chop(1);
                    fileList.append(QString::fromUtf8(rawName));
                }
                arg.endArray();
            }
        }
    }

    launchAtlasPicker(dialogTitle, initialDir, true, {}, {}, handle, message, true, fileList);
}

void FileChooserPortal::launchAtlasPicker(const QString& title,
                                         const QString& initialDir,
                                         bool directoryOnly,
                                         const QStringList& filters,
                                         const QString& filterLabel,
                                         const QDBusObjectPath& handle,
                                         const QDBusMessage& message,
                                         bool isSaveFiles,
                                         const QStringList& fileList,
                                         bool saveMode,
                                         const QString& suggestedName) {
    QString handleStr = handle.path();
    auto* process = new QProcess(this);
    auto* reqObj = new PortalRequest(handleStr, this);

    PendingRequest req;
    req.message = message;
    req.process = process;
    req.requestObject = reqObj;
    req.isSaveFiles = isSaveFiles;
    req.fileListToSave = fileList;
    m_requests.insert(handleStr, req);

    connect(reqObj, &PortalRequest::closeRequested, this, [process]() {
        if (process && process->state() != QProcess::NotRunning) {
            process->terminate();
            process->kill();
        }
    });

    QStringList args = { QStringLiteral("-p"), QStringLiteral("-t"), title };
    if (!initialDir.isEmpty()) {
        args << QStringLiteral("-d") << initialDir;
    }
    if (directoryOnly) {
        args << QStringLiteral("--directory-only");
    }
    if (!filters.isEmpty()) {
        args << QStringLiteral("-f") << filters.join(QLatin1Char(','));
    }
    if (!filterLabel.isEmpty()) {
        args << QStringLiteral("-l") << filterLabel;
    }
    if (saveMode) {
        args << QStringLiteral("--save");
        if (!suggestedName.isEmpty())
            args << QStringLiteral("--name") << suggestedName;
    }

    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, handleStr](int exitCode, QProcess::ExitStatus exitStatus) {
                if (!m_requests.contains(handleStr)) {
                    return;
                }
                PendingRequest req = m_requests.take(handleStr);
                QProcess* proc = req.process;
                PortalRequest* reqObj = req.requestObject;

                QDBusMessage reply = req.message.createReply();
                QVariantMap results;

                if (exitStatus == QProcess::NormalExit && exitCode == 0) {
                    QString stdoutText = QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
                    QString selectedPath = stdoutText.split(QLatin1Char('\n')).first().trimmed();

                    if (!selectedPath.isEmpty()) {
                        QStringList uris;
                        if (req.isSaveFiles && !req.fileListToSave.isEmpty()) {
                            for (const QString& fn : req.fileListToSave) {
                                QString full = selectedPath + QLatin1Char('/') + fn;
                                uris.append(QUrl::fromLocalFile(full).toString());
                            }
                        } else {
                            uris.append(QUrl::fromLocalFile(selectedPath).toString());
                        }
                        results.insert(QStringLiteral("uris"), uris);
                        results.insert(QStringLiteral("writable"), true);
                        reply << static_cast<uint>(0) << results;
                    } else {
                        reply << static_cast<uint>(1) << results;
                    }
                } else {
                    // Cancelled by user or closed
                    reply << static_cast<uint>(1) << results;
                }

                QDBusConnection::sessionBus().send(reply);
                if (reqObj) {
                    reqObj->deleteLater();
                }
                proc->deleteLater();
            });

    process->start(findAtlasBinary(), args);
}

} // namespace atlas::portal
