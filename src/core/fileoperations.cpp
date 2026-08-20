#include "fileoperations.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QtConcurrent>
#include <QGuiApplication>
#include <QClipboard>
#include <QStandardPaths>
#include <QProcess>
#include <QLoggingCategory>
#include <QDrag>
#include <QMimeData>
#include <QUrl>
#include <QPixmap>
#include <QPainter>

namespace prism::core {

Q_LOGGING_CATEGORY(lcFileOps, "prism.fileops", QtInfoMsg)

FileOperations::FileOperations(QObject* parent)
    : QObject(parent)
    , m_progress(new FileOperationProgress(this)) {}

FileOperations* FileOperations::instance() {
    static auto* s_instance = new FileOperations();
    return s_instance;
}

void FileOperations::setTransferEngine(int engine) {
    if (m_transferEngine != engine) {
        m_transferEngine = engine;
        emit transferEngineChanged();
    }
}

void FileOperations::setCustomCommand(const QString& cmd) {
    if (m_customCommand != cmd) {
        m_customCommand = cmd;
        emit customCommandChanged();
    }
}

void FileOperations::copyToClipboard(const QStringList& paths) {
    m_clipboardFiles = paths;
    m_isCut = false;
    emit clipboardChanged();
}

void FileOperations::cutToClipboard(const QStringList& paths) {
    m_clipboardFiles = paths;
    m_isCut = true;
    emit clipboardChanged();
}

void FileOperations::copyTextToClipboard(const QString& text) {
    QGuiApplication::clipboard()->setText(text);
}

void FileOperations::clearClipboard() {
    m_clipboardFiles.clear();
    m_isCut = false;
    emit clipboardChanged();
}

void FileOperations::paste(const QString& destinationDir) {
    if (m_clipboardFiles.isEmpty() || destinationDir.isEmpty())
        return;

    QStringList sources = m_clipboardFiles;
    if (m_isCut) {
        moveFiles(sources, destinationDir);
        clearClipboard();
    } else {
        copyFiles(sources, destinationDir);
    }
}

qint64 FileOperations::calculateTotalSize(const QStringList& paths) {
    qint64 total = 0;
    for (const QString& p : paths) {
        QFileInfo fi(p);
        if (fi.isDir()) {
            QDir dir(p);
            const auto entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
            QStringList subPaths;
            for (const auto& e : entries) subPaths << e.absoluteFilePath();
            total += calculateTotalSize(subPaths);
        } else {
            total += fi.size();
        }
    }
    return total;
}

bool FileOperations::copyRecursively(const QString& src, const QString& dest, std::atomic<bool>& cancelFlag, qint64& processedBytes, qint64 totalBytes) {
    if (cancelFlag.load())
        return false;

    QFileInfo srcInfo(src);
    if (srcInfo.isDir()) {
        QDir().mkpath(dest);
        QDir dir(src);
        const auto list = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden);
        for (const auto& item : list) {
            if (cancelFlag.load()) return false;
            QString destItem = dest + "/" + item.fileName();
            if (!copyRecursively(item.absoluteFilePath(), destItem, cancelFlag, processedBytes, totalBytes))
                return false;
        }
        return true;
    } else {
        QFile in(src);
        if (!in.open(QIODevice::ReadOnly))
            return false;

        QFile out(dest);
        if (!out.open(QIODevice::WriteOnly))
            return false;

        QByteArray buf(64 * 1024, 0);
        while (!in.atEnd()) {
            if (cancelFlag.load()) {
                out.close();
                QFile::remove(dest);
                return false;
            }
            qint64 bytesRead = in.read(buf.data(), buf.size());
            if (bytesRead > 0) {
                out.write(buf.constData(), bytesRead);
                processedBytes += bytesRead;
                if (totalBytes > 0) {
                    qreal p = static_cast<qreal>(processedBytes) / totalBytes;
                    QMetaObject::invokeMethod(m_progress, [this, p, src]() {
                        m_progress->setProgress(p);
                        m_progress->setCurrentItem(src);
                    });
                }
            }
        }
        return true;
    }
}

bool FileOperations::removeRecursively(const QString& path) {
    QFileInfo fi(path);
    if (fi.isDir()) {
        QDir dir(path);
        return dir.removeRecursively();
    } else {
        return QFile::remove(path);
    }
}

void FileOperations::copyFiles(const QStringList& sources, const QString& destinationDir) {
    m_cancelRequested = false;
    m_progress->setRunning(true);
    m_progress->setProgress(0.0);
    m_progress->setStatusText(tr("Copying files..."));

    (void)QtConcurrent::run([this, sources, destinationDir]() {
        bool allSuccess = true;

        if (m_transferEngine == RsyncEngine) {
            // Rsync transfer with checksum verification and progress
            QStringList args;
            args << "-avh" << "--progress" << "--checksum";
            args.append(sources);
            args << destinationDir + "/";

            QProcess proc;
            proc.start("rsync", args);
            proc.waitForFinished(-1);
            allSuccess = (proc.exitCode() == 0);
        } else {
            qint64 total = calculateTotalSize(sources);
            qint64 processed = 0;

            for (const QString& src : sources) {
                if (m_cancelRequested.load()) {
                    allSuccess = false;
                    break;
                }
                QFileInfo fi(src);
                QString dest = destinationDir + "/" + fi.fileName();
                if (QFile::exists(dest)) {
                    // Auto-rename with (copy)
                    QString base = fi.completeBaseName();
                    QString ext = fi.suffix().isEmpty() ? "" : "." + fi.suffix();
                    int counter = 1;
                    while (QFile::exists(dest)) {
                        dest = QString("%1/%2 (copy %3)%4").arg(destinationDir, base, QString::number(counter++), ext);
                    }
                }

                if (!copyRecursively(src, dest, m_cancelRequested, processed, total)) {
                    allSuccess = false;
                    break;
                }
            }
        }

        QMetaObject::invokeMethod(this, [this, allSuccess]() {
            m_progress->setRunning(false);
            m_progress->setProgress(1.0);
            emit operationFinished(allSuccess, allSuccess ? tr("Copy completed") : tr("Copy failed or cancelled"));
        });
    });
}

void FileOperations::moveFiles(const QStringList& sources, const QString& destinationDir) {
    m_cancelRequested = false;
    m_progress->setRunning(true);
    m_progress->setProgress(0.0);
    m_progress->setStatusText(tr("Moving files..."));

    (void)QtConcurrent::run([this, sources, destinationDir]() {
        bool allSuccess = true;

        if (m_transferEngine == RsyncEngine) {
            QStringList args;
            args << "-avh" << "--remove-source-files" << "--progress" << "--checksum";
            args.append(sources);
            args << destinationDir + "/";

            QProcess proc;
            proc.start("rsync", args);
            proc.waitForFinished(-1);
            allSuccess = (proc.exitCode() == 0);
        } else {
            qint64 total = calculateTotalSize(sources);
            qint64 processed = 0;

            for (const QString& src : sources) {
                if (m_cancelRequested.load()) {
                    allSuccess = false;
                    break;
                }
                QFileInfo fi(src);
                QString dest = destinationDir + "/" + fi.fileName();

                // Try fast filesystem rename
                if (!QFile::rename(src, dest)) {
                    // Fallback to copy and remove
                    if (copyRecursively(src, dest, m_cancelRequested, processed, total)) {
                        removeRecursively(src);
                    } else {
                        allSuccess = false;
                    }
                }
            }
        }

        QMetaObject::invokeMethod(this, [this, allSuccess]() {
            m_progress->setRunning(false);
            m_progress->setProgress(1.0);
            emit operationFinished(allSuccess, allSuccess ? tr("Move completed") : tr("Move failed or cancelled"));
        });
    });
}

void FileOperations::extractArchive(const QString& archivePath, const QString& destinationDir) {
    m_progress->setRunning(true);
    m_progress->setStatusText(tr("Extracting archive..."));

    (void)QtConcurrent::run([this, archivePath, destinationDir]() {
        QFileInfo fi(archivePath);
        QString dest = destinationDir.isEmpty() ? fi.absolutePath() : destinationDir;
        QDir().mkpath(dest);

        bool success = false;
        QString name = fi.fileName().toLower();
        QProcess proc;

        if (name.endsWith(".zip")) {
            proc.start("unzip", QStringList{ "-o", archivePath, "-d", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".tar.gz") || name.endsWith(".tgz")) {
            proc.start("tar", QStringList{ "-xzf", archivePath, "-C", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".tar.xz") || name.endsWith(".txz")) {
            proc.start("tar", QStringList{ "-xJf", archivePath, "-C", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".tar.zst")) {
            proc.start("tar", QStringList{ "--zstd", "-xf", archivePath, "-C", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".tar.bz2") || name.endsWith(".tbz2")) {
            proc.start("tar", QStringList{ "-xjf", archivePath, "-C", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".tar")) {
            proc.start("tar", QStringList{ "-xf", archivePath, "-C", dest });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (name.endsWith(".7z") || name.endsWith(".rar")) {
            proc.start("7z", QStringList{ "x", "-y", QString("-o%1").arg(dest), archivePath });
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, fi]() {
            m_progress->setRunning(false);
            emit operationFinished(success, success ? tr("Extracted %1").arg(fi.fileName()) : tr("Extraction failed"));
        });
    });
}

void FileOperations::createArchive(const QStringList& sourcePaths, const QString& destinationFile, const QString& format) {
    m_progress->setRunning(true);
    m_progress->setStatusText(tr("Creating archive..."));

    (void)QtConcurrent::run([this, sourcePaths, destinationFile, format]() {
        bool success = false;
        QProcess proc;
        QString fmt = format.toLower();

        if (fmt == "zip" || destinationFile.endsWith(".zip", Qt::CaseInsensitive)) {
            QStringList args;
            args << "-r" << destinationFile;
            for (const auto& s : sourcePaths) args << QFileInfo(s).fileName();
            if (!sourcePaths.isEmpty()) proc.setWorkingDirectory(QFileInfo(sourcePaths.first()).absolutePath());
            proc.start("zip", args);
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (fmt == "tar.gz" || fmt == "tgz" || destinationFile.endsWith(".tar.gz", Qt::CaseInsensitive)) {
            QStringList args;
            args << "-czf" << destinationFile;
            for (const auto& s : sourcePaths) args << QFileInfo(s).fileName();
            if (!sourcePaths.isEmpty()) proc.setWorkingDirectory(QFileInfo(sourcePaths.first()).absolutePath());
            proc.start("tar", args);
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (fmt == "tar.zst" || destinationFile.endsWith(".tar.zst", Qt::CaseInsensitive)) {
            QStringList args;
            args << "--zstd" << "-cf" << destinationFile;
            for (const auto& s : sourcePaths) args << QFileInfo(s).fileName();
            if (!sourcePaths.isEmpty()) proc.setWorkingDirectory(QFileInfo(sourcePaths.first()).absolutePath());
            proc.start("tar", args);
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        } else if (fmt == "7z" || destinationFile.endsWith(".7z", Qt::CaseInsensitive)) {
            QStringList args;
            args << "a" << destinationFile;
            for (const auto& s : sourcePaths) args << s;
            proc.start("7z", args);
            proc.waitForFinished(-1);
            success = (proc.exitCode() == 0);
        }

        QMetaObject::invokeMethod(this, [this, success, destinationFile]() {
            m_progress->setRunning(false);
            emit operationFinished(success, success ? tr("Created %1").arg(QFileInfo(destinationFile).fileName()) : tr("Archive creation failed"));
        });
    });
}

void FileOperations::deleteFiles(const QStringList& paths, bool permanent) {
    if (!permanent) {
        moveToTrash(paths);
        return;
    }

    m_progress->setRunning(true);
    m_progress->setStatusText(tr("Deleting files..."));

    (void)QtConcurrent::run([this, paths]() {
        bool allSuccess = true;
        for (const QString& p : paths) {
            if (!removeRecursively(p)) {
                allSuccess = false;
            }
        }

        QMetaObject::invokeMethod(this, [this, allSuccess]() {
            m_progress->setRunning(false);
            emit operationFinished(allSuccess, allSuccess ? tr("Deleted files") : tr("Failed to delete some files"));
        });
    });
}

void FileOperations::moveToTrash(const QStringList& paths) {
    m_progress->setRunning(true);
    m_progress->setStatusText(tr("Moving to trash..."));

    (void)QtConcurrent::run([this, paths]() {
        QString trashDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/Trash";
        QString filesDir = trashDir + "/files";
        QString infoDir = trashDir + "/info";

        QDir().mkpath(filesDir);
        QDir().mkpath(infoDir);

        bool allSuccess = true;

        for (const QString& p : paths) {
            QFileInfo fi(p);
            if (!fi.exists())
                continue;

            QString fileName = fi.fileName();
            QString destFile = filesDir + "/" + fileName;
            QString infoFile = infoDir + "/" + fileName + ".trashinfo";

            int counter = 1;
            while (QFile::exists(destFile) || QFile::exists(infoFile)) {
                QString uniqueName = QString("%1.%2").arg(fileName, QString::number(counter++));
                destFile = filesDir + "/" + uniqueName;
                infoFile = infoDir + "/" + uniqueName + ".trashinfo";
            }

            // Write trashinfo
            QFile info(infoFile);
            if (info.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QString deletionDate = QDateTime::currentDateTime().toString(Qt::ISODate);
                QString content = QString("[Trash Info]\nPath=%1\nDeletionDate=%2\n").arg(fi.absoluteFilePath(), deletionDate);
                info.write(content.toUtf8());
                info.close();
            }

            // Move file
            if (!QFile::rename(fi.absoluteFilePath(), destFile)) {
                // Fallback copy + remove
                qint64 total = fi.size();
                qint64 processed = 0;
                std::atomic<bool> dummyCancel{false};
                if (copyRecursively(fi.absoluteFilePath(), destFile, dummyCancel, processed, total)) {
                    removeRecursively(fi.absoluteFilePath());
                } else {
                    QFile::remove(infoFile);
                    allSuccess = false;
                }
            }
        }

        QMetaObject::invokeMethod(this, [this, allSuccess]() {
            m_progress->setRunning(false);
            emit operationFinished(allSuccess, allSuccess ? tr("Moved to trash") : tr("Failed to trash some items"));
        });
    });
}

void FileOperations::restoreFromTrash(const QString& targetPath) {
    QString trashDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/Trash";
    QString infoPath = targetPath;
    QString trashedFile = targetPath;

    if (targetPath.contains("/Trash/files/")) {
        QString name = QFileInfo(targetPath).fileName();
        infoPath = trashDir + "/info/" + name + ".trashinfo";
        trashedFile = targetPath;
    } else if (targetPath.endsWith(".trashinfo")) {
        QString baseName = QFileInfo(targetPath).completeBaseName();
        trashedFile = trashDir + "/files/" + baseName;
    }

    QFileInfo fi(infoPath);
    if (!fi.exists())
        return;

    QFile file(infoPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QString origPath;
    while (!file.atEnd()) {
        QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.startsWith("Path=")) {
            origPath = line.mid(5);
            break;
        }
    }
    file.close();

    if (origPath.isEmpty())
        return;

    QFileInfo destFi(origPath);
    QDir().mkpath(destFi.absolutePath());

    if (QFile::rename(trashedFile, origPath)) {
        QFile::remove(infoPath);
        emit operationFinished(true, tr("Restored %1").arg(destFi.fileName()));
    }
}

void FileOperations::emptyTrash() {
    QString trashDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/Trash";
    removeRecursively(trashDir + "/files");
    removeRecursively(trashDir + "/info");
    QDir().mkpath(trashDir + "/files");
    QDir().mkpath(trashDir + "/info");
    emit operationFinished(true, tr("Trash emptied"));
}

void FileOperations::renameFile(const QString& oldPath, const QString& newName) {
    QFileInfo fi(oldPath);
    QString newPath = fi.absolutePath() + "/" + newName;
    bool success = QFile::rename(oldPath, newPath);
    emit operationFinished(success, success ? tr("Renamed successfully") : tr("Rename failed"));
}

void FileOperations::createDirectory(const QString& parentDir, const QString& name) {
    QDir dir(parentDir);
    bool success = dir.mkdir(name);
    emit operationFinished(success, success ? tr("Folder created") : tr("Failed to create folder"));
}

void FileOperations::createFile(const QString& parentDir, const QString& name, const QString& content) {
    QString filePath = parentDir + "/" + name;
    QFile file(filePath);
    bool success = false;
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        if (!content.isEmpty()) {
            file.write(content.toUtf8());
        }
        file.close();
        success = true;
    }
    emit operationFinished(success, success ? tr("File created") : tr("Failed to create file"));
}

void FileOperations::duplicateFile(const QString& path) {
    QFileInfo fi(path);
    QString base = fi.completeBaseName();
    QString ext = fi.suffix().isEmpty() ? "" : "." + fi.suffix();
    QString parentDir = fi.absolutePath();

    int counter = 1;
    QString newPath = QString("%1/%2 (copy)%3").arg(parentDir, base, ext);
    while (QFile::exists(newPath)) {
        newPath = QString("%1/%2 (copy %3)%4").arg(parentDir, base, QString::number(counter++), ext);
    }

    copyFiles(QStringList{path}, parentDir);
}

void FileOperations::createSymlink(const QString& target, const QString& linkPath) {
    bool success = QFile::link(target, linkPath);
    emit operationFinished(success, success ? tr("Link created") : tr("Failed to create link"));
}

void FileOperations::pasteAsSymlink(const QString& destinationDir) {
    if (m_clipboardFiles.isEmpty() || destinationDir.isEmpty()) return;

    int successCount = 0;
    for (const QString& src : m_clipboardFiles) {
        QFileInfo fi(src);
        QString linkPath = destinationDir + "/" + fi.fileName();
        if (QFile::exists(linkPath)) {
            linkPath = destinationDir + "/" + fi.completeBaseName() + " (symlink)." + fi.suffix();
        }
        if (QFile::link(src, linkPath)) {
            successCount++;
        }
    }
    bool allSuccess = (successCount == m_clipboardFiles.size());
    emit operationFinished(allSuccess, allSuccess ? tr("Created symlink(s)") : tr("Failed to create some symlinks"));
}

void FileOperations::cancelOperation() {
    m_cancelRequested = true;
}

void FileOperations::startNativeDrag(const QStringList& filePaths) {
    if (filePaths.isEmpty()) return;

    QList<QUrl> urls;
    for (const QString& path : filePaths) {
        urls.append(QUrl::fromLocalFile(path));
    }

    auto* mimeData = new QMimeData();
    mimeData->setUrls(urls);
    mimeData->setText(filePaths.join("\n"));

    auto* drag = new QDrag(this);
    drag->setMimeData(mimeData);

    // Create a drag visual pill pixmap
    QPixmap pixmap(140, 40);
    pixmap.fill(Qt::transparent);
    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing);
    
    QColor bg(30, 32, 40, 230);
    painter.setBrush(bg);
    painter.setPen(QPen(QColor(130, 170, 255), 1.5));
    painter.drawRoundedRect(1, 1, 138, 38, 8, 8);

    painter.setPen(Qt::white);
    QFont font = painter.font();
    font.setPointSize(9);
    font.setBold(true);
    painter.setFont(font);
    
    QString text = filePaths.size() == 1 
        ? QFileInfo(filePaths.first()).fileName() 
        : QString("%1 items").arg(filePaths.size());
    painter.drawText(QRect(10, 0, 120, 40), Qt::AlignVCenter | Qt::AlignLeft, painter.fontMetrics().elidedText(text, Qt::ElideMiddle, 120));
    painter.end();

    drag->setPixmap(pixmap);
    drag->setHotSpot(QPoint(pixmap.width() / 2, pixmap.height() / 2));

    drag->exec(Qt::CopyAction | Qt::MoveAction, Qt::CopyAction);
}

} // namespace prism::core
