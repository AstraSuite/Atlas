#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVector>
#include <qqmlintegration.h>

namespace prism::controllers {

class TabItem : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QString splitTitle READ splitTitle NOTIFY splitPathChanged)
    Q_PROPERTY(QString currentPath READ currentPath WRITE setCurrentPath NOTIFY currentPathChanged)
    Q_PROPERTY(QString splitPath READ splitPath WRITE setSplitPath NOTIFY splitPathChanged)
    Q_PROPERTY(bool isSplit READ isSplit WRITE setIsSplit NOTIFY isSplitChanged)
    Q_PROPERTY(int activePane READ activePane WRITE setActivePane NOTIFY activePaneChanged)
    Q_PROPERTY(int viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY historyChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY historyChanged)

public:
    explicit TabItem(const QString& initialPath, QObject* parent = nullptr);

    QString title() const { return m_title; }
    QString splitTitle() const;
    QString currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString& path);

    QString splitPath() const { return m_splitPath; }
    void setSplitPath(const QString& path);

    bool isSplit() const { return m_isSplit; }
    void setIsSplit(bool split);

    int activePane() const { return m_activePane; }
    void setActivePane(int pane);

    int viewMode() const { return m_viewMode; }
    void setViewMode(int mode);

    bool canGoBack() const { return m_historyIndex > 0; }
    bool canGoForward() const { return m_historyIndex < m_history.size() - 1; }

    Q_INVOKABLE void goBack();
    Q_INVOKABLE void goForward();
    Q_INVOKABLE void goUp();

signals:
    void titleChanged();
    void currentPathChanged();
    void splitPathChanged();
    void isSplitChanged();
    void activePaneChanged();
    void viewModeChanged();
    void historyChanged();

private:
    void updateTitle();

    QString m_title;
    QString m_currentPath;
    QString m_splitPath;
    bool m_isSplit = false;
    int m_activePane = 0;
    int m_viewMode = 0;
    QStringList m_history;
    int m_historyIndex = 0;
};

class TabManager : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(prism::controllers::TabItem* currentTab READ currentTab NOTIFY currentTabChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum TabRoles {
        TitleRole = Qt::UserRole + 1,
        PathRole,
        IsSplitRole,
        SplitTitleRole,
        SplitPathRole,
        ActivePaneRole,
        TabItemRole
    };
    Q_ENUM(TabRoles)

    explicit TabManager(QObject* parent = nullptr);

    static TabManager* instance();

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int currentIndex() const { return m_currentIndex; }
    void setCurrentIndex(int index);

    TabItem* currentTab() const;
    int count() const { return static_cast<int>(m_tabs.size()); }

    Q_INVOKABLE void newTab(const QString& path = "");
    Q_INVOKABLE void closeTab(int index);
    Q_INVOKABLE void duplicateTab(int index);
    Q_INVOKABLE void moveTab(int fromIndex, int toIndex);
    Q_INVOKABLE void toggleSplitView();
    Q_INVOKABLE void splitTabWith(int tabIndex, const QString& secondaryPath);
    Q_INVOKABLE void closeSplitPane(int tabIndex, int paneIndex);

signals:
    void currentIndexChanged();
    void currentTabChanged();
    void countChanged();

private:
    QVector<TabItem*> m_tabs;
    int m_currentIndex = 0;
};

} // namespace prism::controllers
