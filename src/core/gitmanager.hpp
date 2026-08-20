#pragma once

#include <QObject>
#include <QString>
#include <qqmlintegration.h>

namespace prism::core {

class GitManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString currentPath READ currentPath WRITE setCurrentPath NOTIFY currentPathChanged)
    Q_PROPERTY(bool isGitRepo READ isGitRepo NOTIFY repoChanged)
    Q_PROPERTY(QString branchName READ branchName NOTIFY repoChanged)

public:
    explicit GitManager(QObject* parent = nullptr);
    static GitManager* instance();

    QString currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString& path);

    bool isGitRepo() const { return m_isGitRepo; }
    QString branchName() const { return m_branchName; }

    Q_INVOKABLE void checkRepo();

signals:
    void currentPathChanged();
    void repoChanged();

private:
    QString m_currentPath;
    bool m_isGitRepo = false;
    QString m_branchName;
};

} // namespace prism::core
