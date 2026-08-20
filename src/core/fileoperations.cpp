#include "fileoperations.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QtConcurrent>
#include <QStandardPaths>
#include <QLoggingCategory>

namespace prism::core {

Q_LOGGING_CATEGORY(lcFileOps, "prism.fileops", QtInfoMsg)

FileOperations::FileOperations(QObject* parent)
    : QObject(parent)
    , m_progress(new FileOperationProgress(this)) {}

FileOperations* FileOperations::instance() {
    static auto* s_instance = new FileOperations();
    return s_instance;
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
        qint64 total = calculateTotalSize(sources);
        qint64 processed = 0;
        bool allSuccess = true;

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

        QMetaObject::invokeMethod(this, [this, allSuccess]() {
            m_progress->setRunning(false);
            m_progress->setProgress(1.0);
            emit operationFinished(allSuccess, allSuccess ? tr("Move completed") : tr("Move failed or cancelled"));
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
        QString trashDir = QDir::homePath() + "/.local/share/Trash";
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

void FileOperations::restoreFromTrash(const QString& trashInfoPath) {
    QFileInfo fi(trashInfoPath);
    if (!fi.exists())
        return;

    QFile file(trashInfoPath);
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

    QString baseName = fi.completeBaseName();
    QString trashFilesDir = QDir::homePath() + "/.local/share/Trash/files";
    QString trashedFile = trashFilesDir + "/" + baseName;

    QFileInfo destFi(origPath);
    QDir().mkpath(destFi.absolutePath());

    if (QFile::rename(trashedFile, origPath)) {
        QFile::remove(trashInfoPath);
        emit operationFinished(true, tr("Restored file"));
    }
}

void FileOperations::emptyTrash() {
    QString trashDir = QDir::homePath() + "/.local/share/Trash";
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

void FileOperations::cancelOperation() {
    m_cancelRequested = true;
}

} // namespace prism::core
