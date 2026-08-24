#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <qqmlintegration.h>

namespace atlas::core {

class GitManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString currentPath READ currentPath WRITE setCurrentPath NOTIFY currentPathChanged)
    Q_PROPERTY(bool isGitRepo READ isGitRepo NOTIFY repoChanged)
    Q_PROPERTY(QString branchName READ branchName NOTIFY repoChanged)
    Q_PROPERTY(QStringList branches READ branches NOTIFY repoChanged)
    Q_PROPERTY(QVariantList commits READ commits NOTIFY repoChanged)
    Q_PROPERTY(bool isOperating READ isOperating NOTIFY operatingChanged)
    Q_PROPERTY(QString lastStatusMessage READ lastStatusMessage NOTIFY statusMessageChanged)

public:
    static GitManager* instance();
    static GitManager* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    QString currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString& path);

    bool isGitRepo() const { return m_isGitRepo; }
    QString branchName() const { return m_branchName; }
    QStringList branches() const { return m_branches; }
    QVariantList commits() const { return m_commits; }
    bool isOperating() const { return m_isOperating; }
    QString lastStatusMessage() const { return m_lastStatusMessage; }

    Q_INVOKABLE void checkRepo();
    Q_INVOKABLE void switchBranch(const QString& branch);
    Q_INVOKABLE void pull();
    Q_INVOKABLE void fetch();

signals:
    void currentPathChanged();
    void repoChanged();
    void operatingChanged();
    void statusMessageChanged();

private:
    explicit GitManager(QObject* parent = nullptr);
    QString findGitRoot(const QString& startPath) const;

    QString m_currentPath;
    bool m_isGitRepo = false;
    QString m_branchName;
    QStringList m_branches;
    QVariantList m_commits;
    bool m_isOperating = false;
    QString m_lastStatusMessage;
};

} // namespace atlas::core
