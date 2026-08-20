#include "gitmanager.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QtConcurrent>

namespace prism::core {

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

void GitManager::checkRepo() {
    if (m_currentPath.isEmpty()) {
        m_isGitRepo = false;
        m_branchName.clear();
        emit repoChanged();
        return;
    }

    QString searchDir = m_currentPath;
    (void)QtConcurrent::run([this, searchDir]() {
        QDir dir(searchDir);
        bool found = false;
        QString branch;

        while (true) {
            QString gitDir = dir.absoluteFilePath(".git");
            if (QDir(gitDir).exists()) {
                found = true;
                // Read .git/HEAD
                QFile headFile(gitDir + "/HEAD");
                if (headFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QString head = QString::fromUtf8(headFile.readLine()).trimmed();
                    if (head.startsWith("ref: refs/heads/")) {
                        branch = head.mid(16);
                    } else if (head.length() >= 7) {
                        branch = head.left(7); // Detached HEAD SHA
                    }
                }
                break;
            } else if (QFile::exists(gitDir)) {
                // git worktree/submodule
                found = true;
                break;
            }

            if (!dir.cdUp() || dir.isRoot()) break;
        }

        QMetaObject::invokeMethod(this, [this, found, branch]() {
            m_isGitRepo = found;
            m_branchName = branch;
            emit repoChanged();
        });
    });
}

} // namespace prism::core
