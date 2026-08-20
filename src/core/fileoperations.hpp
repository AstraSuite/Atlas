#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFutureWatcher>
#include <atomic>
#include <qqmlintegration.h>

namespace prism::core {

class FileOperationProgress : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString currentItem READ currentItem NOTIFY currentItemChanged)

public:
    explicit FileOperationProgress(QObject* parent = nullptr) : QObject(parent) {}

    bool running() const { return m_running; }
    qreal progress() const { return m_progress; }
    QString statusText() const { return m_statusText; }
    QString currentItem() const { return m_currentItem; }

    void setRunning(bool r) { if (m_running != r) { m_running = r; emit runningChanged(); } }
    void setProgress(qreal p) { if (m_progress != p) { m_progress = p; emit progressChanged(); } }
    void setStatusText(const QString& s) { if (m_statusText != s) { m_statusText = s; emit statusTextChanged(); } }
    void setCurrentItem(const QString& i) { if (m_currentItem != i) { m_currentItem = i; emit currentItemChanged(); } }

signals:
    void runningChanged();
    void progressChanged();
    void statusTextChanged();
    void currentItemChanged();

private:
    bool m_running = false;
    qreal m_progress = 0.0;
    QString m_statusText;
    QString m_currentItem;
};

class FileOperations : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(prism::core::FileOperationProgress* progress READ progress CONSTANT)
    Q_PROPERTY(QStringList clipboardFiles READ clipboardFiles NOTIFY clipboardChanged)
    Q_PROPERTY(bool isCutOperation READ isCutOperation NOTIFY clipboardChanged)
    Q_PROPERTY(bool canPaste READ canPaste NOTIFY clipboardChanged)
    Q_PROPERTY(QStringList activeDragFiles READ activeDragFiles NOTIFY activeDragFilesChanged)

public:
    explicit FileOperations(QObject* parent = nullptr);

    static FileOperations* instance();

    FileOperationProgress* progress() const { return m_progress; }
    QStringList clipboardFiles() const { return m_clipboardFiles; }
    QStringList activeDragFiles() const { return m_activeDragFiles; }
    bool isCutOperation() const { return m_isCut; }
    bool canPaste() const { return !m_clipboardFiles.isEmpty(); }

    Q_INVOKABLE bool isPathCut(const QString& path) const {
        return m_isCut && m_clipboardFiles.contains(path);
    }

    Q_INVOKABLE void copyToClipboard(const QStringList& paths);
    Q_INVOKABLE void cutToClipboard(const QStringList& paths);
    Q_INVOKABLE void copyPaths(const QStringList& paths) { copyToClipboard(paths); }
    Q_INVOKABLE void cutPaths(const QStringList& paths) { cutToClipboard(paths); }
    Q_INVOKABLE void clearClipboard();
    Q_INVOKABLE void paste(const QString& destinationDir);
    Q_INVOKABLE void copyTextToClipboard(const QString& text);

    enum TransferEngine {
        StandardEngine = 0,
        RsyncEngine = 1,
        CustomEngine = 2
    };
    Q_ENUM(TransferEngine)

    Q_PROPERTY(int transferEngine READ transferEngine WRITE setTransferEngine NOTIFY transferEngineChanged)
    Q_PROPERTY(QString customCommand READ customCommand WRITE setCustomCommand NOTIFY customCommandChanged)

    int transferEngine() const { return m_transferEngine; }
    void setTransferEngine(int engine);
    QString customCommand() const { return m_customCommand; }
    void setCustomCommand(const QString& cmd);

    Q_INVOKABLE void extractArchive(const QString& archivePath, const QString& destinationDir = "");
    Q_INVOKABLE void createArchive(const QStringList& sourcePaths, const QString& destinationFile, const QString& format = "zip");

    Q_INVOKABLE void copyFiles(const QStringList& sources, const QString& destinationDir);
    Q_INVOKABLE void moveFiles(const QStringList& sources, const QString& destinationDir);
    Q_INVOKABLE void deleteFiles(const QStringList& paths, bool permanent = false);
    Q_INVOKABLE void moveToTrash(const QStringList& paths);
    Q_INVOKABLE void restoreFromTrash(const QString& trashInfoPath);
    Q_INVOKABLE void emptyTrash();
    Q_INVOKABLE void renameFile(const QString& oldPath, const QString& newName);
    Q_INVOKABLE void createDirectory(const QString& parentDir, const QString& name);
    Q_INVOKABLE void createFile(const QString& parentDir, const QString& name, const QString& content = "");
    Q_INVOKABLE void duplicateFile(const QString& path);
    Q_INVOKABLE void createSymlink(const QString& target, const QString& linkPath);
    Q_INVOKABLE void pasteAsSymlink(const QString& destinationDir);

    Q_INVOKABLE void cancelOperation();
    Q_INVOKABLE void startNativeDrag(const QStringList& filePaths, int cardWidth = 0, int cardHeight = 0, int iconSize = 0);

signals:
    void clipboardChanged();
    void activeDragFilesChanged();
    void transferEngineChanged();
    void customCommandChanged();
    void operationFinished(bool success, const QString& message);
    void conflictOccurred(const QString& source, const QString& destination);

private:
    bool copyRecursively(const QString& src, const QString& dest, std::atomic<bool>& cancelFlag, qint64& processedBytes, qint64 totalBytes);
    bool removeRecursively(const QString& path);
    qint64 calculateTotalSize(const QStringList& paths);

    FileOperationProgress* m_progress = nullptr;
    QStringList m_clipboardFiles;
    QStringList m_activeDragFiles;
    bool m_isCut = false;
    int m_transferEngine = StandardEngine;
    QString m_customCommand;
    std::atomic<bool> m_cancelRequested{false};
};

} // namespace prism::core
