#include "appcontroller.hpp"
#include "fileutils.hpp"

#include <QGuiApplication>
#include <QJsonObject>
#include <QJsonDocument>
#include "iconprovider.hpp"
#include <QFileInfo>
#include <QSettings>
#include <iostream>

namespace atlas::core {

static const QStringList& defaultDetailsColumnOrder() {
    static const QStringList order = { "size", "type", "date", "perms", "origPath", "deleted" };
    return order;
}

static QStringList sanitiseDetailsColumnOrder(const QStringList& order) {
    const QStringList& known = defaultDetailsColumnOrder();
    QStringList result;
    result.reserve(known.size());
    for (const QString& key : order) {
        if (known.contains(key) && !result.contains(key))
            result.append(key);
    }
    for (const QString& key : known) {
        if (!result.contains(key))
            result.append(key);
    }
    return result;
}

AppController::AppController(QObject* parent)
    : QObject(parent) {
    QSettings settings("astra-atlas", "atlas");
    QSettings legacy1("caelestia", "prism");
    QSettings legacy2("Caelestia", "Prism");
    m_showHidden = settings.value("session/showHidden", legacy1.value("session/showHidden", legacy2.value("session/showHidden", false))).toBool();
    m_singleClick = settings.value("session/singleClick", legacy1.value("session/singleClick", legacy2.value("session/singleClick", false))).toBool();
    m_confirmPermanentDelete = settings.value("session/confirmPermanentDelete", true).toBool();
    m_restoreTabs = settings.value("preferences/restoreTabs", false).toBool();
    m_confirmMoveToTrash = settings.value("session/confirmMoveToTrash", false).toBool();
    m_defaultStartupDirectory = settings.value("preferences/startupDirectory", "home").toString();
    m_defaultViewMode = settings.value("preferences/defaultViewMode", 0).toInt();
    m_defaultSortField = settings.value("preferences/defaultSortField", 0).toInt();
    m_defaultSortOrder = settings.value("preferences/defaultSortOrder", 0).toInt();
    m_showDirsFirst = settings.value("preferences/showDirsFirst", true).toBool();
    m_caseSensitiveSort = settings.value("preferences/caseSensitiveSort", false).toBool();
    m_directorySpecificViews = settings.value("preferences/directorySpecificViews", false).toBool();

    const QByteArray viewsJson = settings.value("preferences/directoryViews").toString().toUtf8();
    if (!viewsJson.isEmpty())
        m_directoryViews = QJsonDocument::fromJson(viewsJson).object().toVariantMap();
    m_showFreeSpace = settings.value("preferences/showFreeSpace", true).toBool();
    m_placesIconSize = settings.value("preferences/placesIconSize", 20).toInt();
    m_iconZoomLevel = qBound(48, settings.value("session/iconZoomLevel", 80).toInt(), 180);
    m_folderItemCount = settings.value("preferences/folderItemCount", 0).toInt();
    FileUtils::setFolderCountMode(m_folderItemCount);
    m_dateFormat = settings.value("preferences/dateFormat", 1).toInt();
    m_customDateFormat = settings.value("preferences/customDateFormat", "yyyy-MM-dd hh:mm").toString();
    FileUtils::setCustomDateFormat(m_customDateFormat);
    FileUtils::setDateFormat(m_dateFormat);
    m_thumbnailsEnabled = settings.value("preferences/thumbnailsEnabled", true).toBool();
    m_thumbnailMaxMb = settings.value("preferences/thumbnailMaxMb", 0).toInt();
    FileUtils::setThumbnailsEnabled(m_thumbnailsEnabled);
    FileUtils::setThumbnailMaxBytes(static_cast<qint64>(m_thumbnailMaxMb) * 1024 * 1024);
    m_showSizeColumn = settings.value("preferences/showSizeColumn", true).toBool();
    m_showTypeColumn = settings.value("preferences/showTypeColumn", true).toBool();
    m_showDateColumn = settings.value("preferences/showDateColumn", true).toBool();
    m_showPermissionsColumn = settings.value("preferences/showPermissionsColumn", true).toBool();

    m_menuShowSecondaryEditor = settings.value("contextMenu/showSecondaryEditor", true).toBool();
    m_menuShowUploadOnline = settings.value("contextMenu/showUploadOnline", true).toBool();
    m_menuShowSendTo = settings.value("contextMenu/showSendTo", true).toBool();
    m_menuShowCompress = settings.value("contextMenu/showCompress", true).toBool();
    m_menuShowSymlink = settings.value("contextMenu/showSymlink", true).toBool();
    m_menuShowTerminal = settings.value("contextMenu/showTerminal", true).toBool();
    m_menuShowDelete = settings.value("contextMenu/showDelete", true).toBool();
    m_showNetworkSection = settings.value("preferences/showNetworkSection", false).toBool();
    m_scrollSpeed = settings.value("preferences/scrollSpeed", 1.0).toReal();
    if (m_scrollSpeed <= 0.05) {
        m_scrollSpeed = 1.0;
    }

    const QByteArray widthsJson = settings.value("preferences/detailsColumnWidths").toString().toUtf8();
    if (!widthsJson.isEmpty()) {
        m_detailsColumnWidths = QJsonDocument::fromJson(widthsJson).object().toVariantMap();
    }

    m_detailsColumnOrder = sanitiseDetailsColumnOrder(settings.value("preferences/detailsColumnOrder").toStringList());
}

AppController* AppController::instance() {
    static auto* s_instance = new AppController();
    return s_instance;
}

void AppController::setTitle(const QString& title) {
    if (m_title != title) {
        m_title = title;
        emit titleChanged();
    }
}

void AppController::setInitialDirectory(const QString& dir) {
    if (m_initialDirectory != dir) {
        m_initialDirectory = dir;
        emit initialDirectoryChanged();
    }
}

void AppController::setFilterLabel(const QString& label) {
    if (m_filterLabel != label) {
        m_filterLabel = label;
        emit filterLabelChanged();
    }
}

void AppController::setFilters(const QStringList& filters) {
    if (m_filters != filters) {
        m_filters = filters;
        emit filtersChanged();
    }
}

void AppController::setDirectoryOnly(bool dirOnly) {
    if (m_directoryOnly != dirOnly) {
        m_directoryOnly = dirOnly;
        emit directoryOnlyChanged();
    }
}

void AppController::setConfirmPermanentDelete(bool confirm) {
    if (m_confirmPermanentDelete != confirm) {
        m_confirmPermanentDelete = confirm;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("session/confirmPermanentDelete", confirm);
        emit confirmPermanentDeleteChanged();
    }
}

void AppController::setIconZoomLevel(int level) {
    const int clamped = qBound(48, level, 180);
    if (m_iconZoomLevel == clamped)
        return;

    m_iconZoomLevel = clamped;

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("session/iconZoomLevel", clamped);
    emit iconZoomLevelChanged();
}

void AppController::setCaseSensitiveSort(bool sensitive) {
    if (m_caseSensitiveSort != sensitive) {
        m_caseSensitiveSort = sensitive;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/caseSensitiveSort", sensitive);
        emit caseSensitiveSortChanged();
    }
}

void AppController::setDirectorySpecificViews(bool enabled) {
    if (m_directorySpecificViews == enabled)
        return;

    m_directorySpecificViews = enabled;

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("preferences/directorySpecificViews", enabled);
    emit directorySpecificViewsChanged();
}

QVariantMap AppController::directoryView(const QString& path) const {
    if (!m_directorySpecificViews || path.isEmpty())
        return {};
    return m_directoryViews.value(path).toMap();
}

void AppController::rememberDirectoryView(const QString& path, int viewMode, int sortField, int sortOrder) {
    if (!m_directorySpecificViews || path.isEmpty())
        return;

    QVariantMap entry;
    entry.insert(QStringLiteral("viewMode"), viewMode);
    entry.insert(QStringLiteral("sortField"), sortField);
    entry.insert(QStringLiteral("sortOrder"), sortOrder);

    if (m_directoryViews.value(path).toMap() == entry)
        return;

    m_directoryViews.remove(path);
    m_directoryViews.insert(path, entry);

    while (m_directoryViews.size() > 300)
        m_directoryViews.erase(m_directoryViews.begin());

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("preferences/directoryViews",
                      QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(m_directoryViews)).toJson(QJsonDocument::Compact)));
}

void AppController::forgetDirectoryViews() {
    if (m_directoryViews.isEmpty())
        return;

    m_directoryViews.clear();

    QSettings settings("astra-atlas", "atlas");
    settings.remove("preferences/directoryViews");
}

void AppController::setFolderItemCount(int mode) {
    if (m_folderItemCount != mode) {
        m_folderItemCount = mode;
        FileUtils::setFolderCountMode(mode);
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/folderItemCount", mode);
        emit folderItemCountChanged();
    }
}

void AppController::setShowFreeSpace(bool show) {
    if (m_showFreeSpace != show) {
        m_showFreeSpace = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showFreeSpace", show);
        emit showFreeSpaceChanged();
    }
}

void AppController::setCustomDateFormat(const QString& pattern) {
    if (m_customDateFormat == pattern)
        return;

    m_customDateFormat = pattern;
    FileUtils::setCustomDateFormat(pattern);

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("preferences/customDateFormat", pattern);
    emit customDateFormatChanged();
}

void AppController::setRestoreTabs(bool restore) {
    if (m_restoreTabs != restore) {
        m_restoreTabs = restore;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/restoreTabs", restore);
        emit restoreTabsChanged();
    }
}

void AppController::setConfirmMoveToTrash(bool confirm) {
    if (m_confirmMoveToTrash != confirm) {
        m_confirmMoveToTrash = confirm;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("session/confirmMoveToTrash", confirm);
        emit confirmMoveToTrashChanged();
    }
}

void AppController::setDateFormat(int format) {
    if (m_dateFormat != format) {
        m_dateFormat = format;
        FileUtils::setDateFormat(format);
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/dateFormat", format);
        emit dateFormatChanged();
    }
}

bool AppController::shiftPressed() {
    return QGuiApplication::queryKeyboardModifiers().testFlag(Qt::ShiftModifier);
}

void AppController::setThumbnailsEnabled(bool enabled) {
    if (m_thumbnailsEnabled != enabled) {
        m_thumbnailsEnabled = enabled;
        FileUtils::setThumbnailsEnabled(enabled);
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/thumbnailsEnabled", enabled);
        emit thumbnailsEnabledChanged();
    }
}

void AppController::setThumbnailMaxMb(int mb) {
    if (m_thumbnailMaxMb != mb) {
        m_thumbnailMaxMb = mb;
        FileUtils::setThumbnailMaxBytes(static_cast<qint64>(mb) * 1024 * 1024);
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/thumbnailMaxMb", mb);
        emit thumbnailMaxMbChanged();
    }
}

void AppController::setShowSizeColumn(bool show) {
    if (m_showSizeColumn != show) {
        m_showSizeColumn = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showSizeColumn", show);
        emit showSizeColumnChanged();
    }
}

void AppController::setShowTypeColumn(bool show) {
    if (m_showTypeColumn != show) {
        m_showTypeColumn = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showTypeColumn", show);
        emit showTypeColumnChanged();
    }
}

void AppController::setShowDateColumn(bool show) {
    if (m_showDateColumn != show) {
        m_showDateColumn = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showDateColumn", show);
        emit showDateColumnChanged();
    }
}

void AppController::setShowPermissionsColumn(bool show) {
    if (m_showPermissionsColumn != show) {
        m_showPermissionsColumn = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showPermissionsColumn", show);
        emit showPermissionsColumnChanged();
    }
}

void AppController::setDetailsColumnWidth(const QString& key, int width) {
    const int clamped = qBound(48, width, 800);
    if (m_detailsColumnWidths.value(key).toInt() == clamped)
        return;

    m_detailsColumnWidths.insert(key, clamped);

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("preferences/detailsColumnWidths",
                      QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(m_detailsColumnWidths)).toJson(QJsonDocument::Compact)));
    emit detailsColumnWidthsChanged();
}

void AppController::resetDetailsColumnWidths() {
    if (m_detailsColumnWidths.isEmpty())
        return;

    m_detailsColumnWidths.clear();

    QSettings settings("astra-atlas", "atlas");
    settings.remove("preferences/detailsColumnWidths");
    emit detailsColumnWidthsChanged();
}

void AppController::setDetailsColumnOrder(const QStringList& order) {
    const QStringList sanitised = sanitiseDetailsColumnOrder(order);
    if (m_detailsColumnOrder == sanitised)
        return;

    m_detailsColumnOrder = sanitised;

    QSettings settings("astra-atlas", "atlas");
    settings.setValue("preferences/detailsColumnOrder", m_detailsColumnOrder);
    emit detailsColumnOrderChanged();
}

void AppController::resetDetailsColumnOrder() {
    if (m_detailsColumnOrder == defaultDetailsColumnOrder())
        return;

    m_detailsColumnOrder = defaultDetailsColumnOrder();

    QSettings settings("astra-atlas", "atlas");
    settings.remove("preferences/detailsColumnOrder");
    emit detailsColumnOrderChanged();
}
void AppController::setShowHidden(bool show) {
    if (m_showHidden != show) {
        m_showHidden = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("session/showHidden", show);
        emit showHiddenChanged();
    }
}

void AppController::setSingleClick(bool single) {
    if (m_singleClick != single) {
        m_singleClick = single;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("session/singleClick", single);
        emit singleClickChanged();
    }
}

void AppController::setDefaultStartupDirectory(const QString& dir) {
    if (m_defaultStartupDirectory != dir) {
        m_defaultStartupDirectory = dir;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/startupDirectory", dir);
        emit defaultStartupDirectoryChanged();
    }
}

void AppController::setDefaultViewMode(int mode) {
    if (m_defaultViewMode != mode) {
        m_defaultViewMode = mode;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/defaultViewMode", mode);
        emit defaultViewModeChanged();
    }
}

void AppController::setDefaultSortField(int field) {
    if (m_defaultSortField != field) {
        m_defaultSortField = field;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/defaultSortField", field);
        emit defaultSortFieldChanged();
    }
}

void AppController::setDefaultSortOrder(int order) {
    if (m_defaultSortOrder != order) {
        m_defaultSortOrder = order;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/defaultSortOrder", order);
        emit defaultSortOrderChanged();
    }
}

void AppController::setShowDirsFirst(bool dirsFirst) {
    if (m_showDirsFirst != dirsFirst) {
        m_showDirsFirst = dirsFirst;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showDirsFirst", dirsFirst);
        emit showDirsFirstChanged();
    }
}

void AppController::setPlacesIconSize(int size) {
    if (m_placesIconSize != size && size > 0) {
        m_placesIconSize = size;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/placesIconSize", size);
        emit placesIconSizeChanged();
    }
}

void AppController::setSaveMode(bool save) {
    if (m_saveMode != save) {
        m_saveMode = save;
        emit saveModeChanged();
    }
}

void AppController::setSuggestedName(const QString& name) {
    if (m_suggestedName != name) {
        m_suggestedName = name;
        emit suggestedNameChanged();
    }
}

bool AppController::fileExists(const QString& path) {
    return QFileInfo::exists(path);
}

void AppController::accept(const QString& path) {
    m_selectedPath = path;
    emit selectedPathChanged();
    emit accepted(path);
    std::cout << path.toStdString() << std::endl;
    QGuiApplication::exit(0);
}

void AppController::reject() {
    emit rejected();
    QGuiApplication::exit(1);
}

void AppController::setMenuShowSecondaryEditor(bool val) {
    if (m_menuShowSecondaryEditor != val) {
        m_menuShowSecondaryEditor = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showSecondaryEditor", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowUploadOnline(bool val) {
    if (m_menuShowUploadOnline != val) {
        m_menuShowUploadOnline = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showUploadOnline", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowSendTo(bool val) {
    if (m_menuShowSendTo != val) {
        m_menuShowSendTo = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showSendTo", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowCompress(bool val) {
    if (m_menuShowCompress != val) {
        m_menuShowCompress = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showCompress", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowSymlink(bool val) {
    if (m_menuShowSymlink != val) {
        m_menuShowSymlink = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showSymlink", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowTerminal(bool val) {
    if (m_menuShowTerminal != val) {
        m_menuShowTerminal = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showTerminal", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setMenuShowDelete(bool val) {
    if (m_menuShowDelete != val) {
        m_menuShowDelete = val;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("contextMenu/showDelete", val);
        emit menuPreferencesChanged();
    }
}

void AppController::setShowNetworkSection(bool show) {
    if (m_showNetworkSection != show) {
        m_showNetworkSection = show;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/showNetworkSection", show);
        emit showNetworkSectionChanged();
    }
}

void AppController::setScrollSpeed(qreal speed) {
    if (!qFuzzyCompare(m_scrollSpeed + 1.0, speed + 1.0)) {
        m_scrollSpeed = speed;
        QSettings settings("astra-atlas", "atlas");
        settings.setValue("preferences/scrollSpeed", speed);
        emit scrollSpeedChanged();
    }
}

void AppController::resetScrollSpeed() {
    setScrollSpeed(1.0);
}

void AppController::triggerIconReload() {
    IconImageProvider::clearCache();
    m_iconThemeVersion++;
    emit iconThemeVersionChanged();
}

} // namespace atlas::core
