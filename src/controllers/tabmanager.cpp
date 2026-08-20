#include "tabmanager.hpp"

#include <QDir>
#include <QFileInfo>

namespace prism::controllers {

TabItem::TabItem(const QString& initialPath, QObject* parent)
    : QObject(parent)
    , m_currentPath(initialPath.isEmpty() ? QDir::homePath() : initialPath)
    , m_splitPath(m_currentPath) {
    m_history.append(m_currentPath);
    m_historyIndex = 0;
    updateTitle();
}

void TabItem::updateTitle() {
    QString p = m_activePane == 1 ? m_splitPath : m_currentPath;
    if (p == QDir::homePath()) {
        m_title = tr("Home");
    } else if (p == "/") {
        m_title = tr("Root");
    } else {
        m_title = QFileInfo(p).fileName();
        if (m_title.isEmpty()) m_title = p;
    }
    emit titleChanged();
}

void TabItem::setCurrentPath(const QString& path) {
    if (m_currentPath != path) {
        m_currentPath = path;

        // Truncate forward history and append new path
        while (m_history.size() > m_historyIndex + 1) {
            m_history.removeLast();
        }
        m_history.append(m_currentPath);
        m_historyIndex = m_history.size() - 1;

        emit currentPathChanged();
        emit historyChanged();
        if (m_activePane == 0) updateTitle();
    }
}

void TabItem::setSplitPath(const QString& path) {
    if (m_splitPath != path) {
        m_splitPath = path;
        emit splitPathChanged();
        if (m_activePane == 1) updateTitle();
    }
}

void TabItem::setIsSplit(bool split) {
    if (m_isSplit != split) {
        m_isSplit = split;
        if (m_isSplit && m_splitPath.isEmpty()) {
            m_splitPath = m_currentPath;
        }
        emit isSplitChanged();
    }
}

void TabItem::setActivePane(int pane) {
    if (m_activePane != pane) {
        m_activePane = pane;
        emit activePaneChanged();
        updateTitle();
    }
}

void TabItem::setViewMode(int mode) {
    if (m_viewMode != mode) {
        m_viewMode = mode;
        emit viewModeChanged();
    }
}

void TabItem::goBack() {
    if (canGoBack()) {
        m_historyIndex--;
        m_currentPath = m_history.at(m_historyIndex);
        emit currentPathChanged();
        emit historyChanged();
        if (m_activePane == 0) updateTitle();
    }
}

void TabItem::goForward() {
    if (canGoForward()) {
        m_historyIndex++;
        m_currentPath = m_history.at(m_historyIndex);
        emit currentPathChanged();
        emit historyChanged();
        if (m_activePane == 0) updateTitle();
    }
}

void TabItem::goUp() {
    QDir dir(m_activePane == 1 ? m_splitPath : m_currentPath);
    if (dir.cdUp()) {
        if (m_activePane == 1) {
            setSplitPath(dir.absolutePath());
        } else {
            setCurrentPath(dir.absolutePath());
        }
    }
}

// TabManager
TabManager::TabManager(QObject* parent)
    : QAbstractListModel(parent) {
    newTab(QDir::homePath());
}

TabManager* TabManager::instance() {
    static auto* s_instance = new TabManager();
    return s_instance;
}

int TabManager::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_tabs.size());
}

QVariant TabManager::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tabs.size())
        return {};

    auto* tab = m_tabs.at(index.row());
    switch (role) {
    case TitleRole: return tab->title();
    case PathRole: return tab->currentPath();
    case TabItemRole: return QVariant::fromValue(tab);
    default:
        return {};
    }
}

QHash<int, QByteArray> TabManager::roleNames() const {
    return {
        { TitleRole, "title" },
        { PathRole, "path" },
        { TabItemRole, "tabItem" }
    };
}

TabItem* TabManager::currentTab() const {
    if (m_currentIndex >= 0 && m_currentIndex < m_tabs.size())
        return m_tabs.at(m_currentIndex);
    return nullptr;
}

void TabManager::setCurrentIndex(int index) {
    if (index >= 0 && index < m_tabs.size() && m_currentIndex != index) {
        m_currentIndex = index;
        emit currentIndexChanged();
        emit currentTabChanged();
    }
}

void TabManager::newTab(const QString& path) {
    QString p = path.isEmpty() ? (currentTab() ? currentTab()->currentPath() : QDir::homePath()) : path;
    int idx = m_tabs.size();
    beginInsertRows(QModelIndex(), idx, idx);
    auto* tab = new TabItem(p, this);
    connect(tab, &TabItem::titleChanged, this, [this, tab]() {
        int i = m_tabs.indexOf(tab);
        if (i >= 0) {
            auto mi = index(i, 0);
            emit dataChanged(mi, mi, { TitleRole });
        }
    });
    m_tabs.append(tab);
    endInsertRows();
    emit countChanged();
    setCurrentIndex(idx);
}

void TabManager::closeTab(int index) {
    if (m_tabs.size() <= 1 || index < 0 || index >= m_tabs.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    auto* tab = m_tabs.takeAt(index);
    tab->deleteLater();
    endRemoveRows();

    if (m_currentIndex >= m_tabs.size()) {
        m_currentIndex = m_tabs.size() - 1;
        emit currentIndexChanged();
    }
    emit currentTabChanged();
    emit countChanged();
}

void TabManager::duplicateTab(int index) {
    if (index >= 0 && index < static_cast<int>(m_tabs.size())) {
        newTab(m_tabs[index]->currentPath());
    }
}

void TabManager::moveTab(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= static_cast<int>(m_tabs.size()) ||
        toIndex < 0 || toIndex >= static_cast<int>(m_tabs.size()) ||
        fromIndex == toIndex) {
        return;
    }

    int destModelIndex = toIndex > fromIndex ? toIndex + 1 : toIndex;
    beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), destModelIndex);
    auto* tab = m_tabs.takeAt(fromIndex);
    m_tabs.insert(toIndex, tab);
    endMoveRows();

    if (m_currentIndex == fromIndex) {
        m_currentIndex = toIndex;
        emit currentIndexChanged();
        emit currentTabChanged();
    } else if (fromIndex < m_currentIndex && toIndex >= m_currentIndex) {
        m_currentIndex--;
        emit currentIndexChanged();
        emit currentTabChanged();
    } else if (fromIndex > m_currentIndex && toIndex <= m_currentIndex) {
        m_currentIndex++;
        emit currentIndexChanged();
        emit currentTabChanged();
    }
}

void TabManager::toggleSplitView() {
    if (auto* tab = currentTab()) {
        tab->setIsSplit(!tab->isSplit());
    }
}

} // namespace prism::controllers
