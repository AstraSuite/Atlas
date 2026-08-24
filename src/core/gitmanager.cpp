#include "gitmanager.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QtConcurrent>

namespace atlas::core {

GitManager::GitManager(QObject* parent) : QObject(parent) {}

GitManager* GitManager::instance() {
    static auto* s_instance = new GitManager();
    return s_instance;
}

void GitManager::setCurrentPath(const QString& path) {
    if (m_currentPath != path) {
        m_currentPath = path;
        emit currentPathChanged();
        checkRepo();
    }
}

QString GitManager::findGitRoot(const QString& startPath) const {
    if (startPath.isEmpty()) return QString();
    QDir dir(startPath);
    while (true) {
        if (QDir(dir.absoluteFilePath(".git")).exists() || QFile::exists(dir.absoluteFilePath(".git"))) {
            return dir.absolutePath();
        }
        if (!dir.cdUp() || dir.isRoot()) break;
    }
    return QString();
}

void GitManager::checkRepo() {
    if (m_currentPath.isEmpty()) {
        m_isGitRepo = false;
        m_branchName.clear();
        m_branches.clear();
        m_commits.clear();
        emit repoChanged();
        return;
    }

    QString searchDir = m_currentPath;
    (void)QtConcurrent::run([this, searchDir]() {
        QString root = findGitRoot(searchDir);
        if (root.isEmpty()) {
            QMetaObject::invokeMethod(this, [this]() {
                m_isGitRepo = false;
                m_branchName.clear();
                m_branches.clear();
                m_commits.clear();
                emit repoChanged();
            });
            return;
        }

        // Get current branch
        QString branch;
        QFile headFile(root + "/.git/HEAD");
        if (headFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString head = QString::fromUtf8(headFile.readLine()).trimmed();
            if (head.startsWith("ref: refs/heads/")) {
                branch = head.mid(16);
            } else if (head.length() >= 7) {
                branch = head.left(7);
            }
        }

        // Get local branch list
        QProcess branchProc;
        branchProc.setWorkingDirectory(root);
        branchProc.start("git", QStringList{ "branch", "--list", "--no-color" });
        branchProc.waitForFinished(2000);
        QStringList branches;
        if (branchProc.exitCode() == 0) {
            QString out = QString::fromUtf8(branchProc.readAllStandardOutput());
            for (QString line : out.split('\n', Qt::SkipEmptyParts)) {
                line = line.trimmed();
                if (line.startsWith('*')) line = line.mid(1).trimmed();
                if (!line.isEmpty()) branches.append(line);
            }
        }

        // Get recent commits
        QProcess logProc;
        logProc.setWorkingDirectory(root);
        logProc.start("git", QStringList{ "log", "-n", "20", "--format=%h|%s|%an|%cr" });
        logProc.waitForFinished(2000);
        QVariantList commits;
        if (logProc.exitCode() == 0) {
            QString out = QString::fromUtf8(logProc.readAllStandardOutput());
            for (const QString& line : out.split('\n', Qt::SkipEmptyParts)) {
                QStringList parts = line.split('|');
                if (parts.size() >= 4) {
                    QVariantMap c;
                    c["hash"] = parts[0];
                    c["subject"] = parts[1];
                    c["author"] = parts[2];
                    c["time"] = parts[3];
                    commits.append(c);
                }
            }
        }

        QMetaObject::invokeMethod(this, [this, branch, branches, commits]() {
            m_isGitRepo = true;
            m_branchName = branch;
            m_branches = branches;
            m_commits = commits;
            emit repoChanged();
        });
    });
}

void GitManager::switchBranch(const QString& branch) {
    if (branch.isEmpty()) return;
    QString root = findGitRoot(m_currentPath);
    if (root.isEmpty()) return;

    m_isOperating = true;
    m_lastStatusMessage = tr("Switching to branch %1...").arg(branch);
    emit operatingChanged();
    emit statusMessageChanged();

    (void)QtConcurrent::run([this, root, branch]() {
        QProcess proc;
        proc.setWorkingDirectory(root);
        proc.start("git", QStringList{ "switch", branch });
        proc.waitForFinished(5000);
        bool success = (proc.exitCode() == 0);
        QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

        QMetaObject::invokeMethod(this, [this, success, branch, err]() {
            m_isOperating = false;
            m_lastStatusMessage = success ? tr("Switched to %1").arg(branch) : (err.isEmpty() ? tr("Failed to switch branch") : err);
            emit operatingChanged();
            emit statusMessageChanged();
            checkRepo();
        });
    });
}

void GitManager::pull() {
    QString root = findGitRoot(m_currentPath);
    if (root.isEmpty()) return;

    m_isOperating = true;
    m_lastStatusMessage = tr("Pulling latest changes...");
    emit operatingChanged();
    emit statusMessageChanged();

    (void)QtConcurrent::run([this, root]() {
        QProcess proc;
        proc.setWorkingDirectory(root);
        proc.start("git", QStringList{ "pull" });
        proc.waitForFinished(15000);
        bool success = (proc.exitCode() == 0);
        QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

        QMetaObject::invokeMethod(this, [this, success, out, err]() {
            m_isOperating = false;
            m_lastStatusMessage = success ? (out.isEmpty() ? tr("Pull successful") : out) : (err.isEmpty() ? tr("Pull failed") : err);
            emit operatingChanged();
            emit statusMessageChanged();
            checkRepo();
        });
    });
}

void GitManager::fetch() {
    QString root = findGitRoot(m_currentPath);
    if (root.isEmpty()) return;

    m_isOperating = true;
    m_lastStatusMessage = tr("Fetching remote updates...");
    emit operatingChanged();
    emit statusMessageChanged();

    (void)QtConcurrent::run([this, root]() {
        QProcess proc;
        proc.setWorkingDirectory(root);
        proc.start("git", QStringList{ "fetch" });
        proc.waitForFinished(15000);
        bool success = (proc.exitCode() == 0);

        QMetaObject::invokeMethod(this, [this, success]() {
            m_isOperating = false;
            m_lastStatusMessage = success ? tr("Fetch completed") : tr("Fetch failed");
            emit operatingChanged();
            emit statusMessageChanged();
            checkRepo();
        });
    });
}

} // namespace atlas::core
