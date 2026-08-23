#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QVariantMap>
#include <QString>
#include <QStringList>
#include <QGuiApplication>
#include <qqmlintegration.h>

namespace prism::core {

class AppController : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString initialDirectory READ initialDirectory WRITE setInitialDirectory NOTIFY initialDirectoryChanged)
    Q_PROPERTY(QString filterLabel READ filterLabel WRITE setFilterLabel NOTIFY filterLabelChanged)
    Q_PROPERTY(QStringList filters READ filters WRITE setFilters NOTIFY filtersChanged)
    Q_PROPERTY(bool directoryOnly READ directoryOnly WRITE setDirectoryOnly NOTIFY directoryOnlyChanged)
    Q_PROPERTY(bool saveMode READ saveMode NOTIFY saveModeChanged)
    Q_PROPERTY(QString suggestedName READ suggestedName NOTIFY suggestedNameChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(bool confirmPermanentDelete READ confirmPermanentDelete WRITE setConfirmPermanentDelete NOTIFY confirmPermanentDeleteChanged)
    Q_PROPERTY(bool restoreTabs READ restoreTabs WRITE setRestoreTabs NOTIFY restoreTabsChanged)
    Q_PROPERTY(bool confirmMoveToTrash READ confirmMoveToTrash WRITE setConfirmMoveToTrash NOTIFY confirmMoveToTrashChanged)
    Q_PROPERTY(int dateFormat READ dateFormat WRITE setDateFormat NOTIFY dateFormatChanged)
    Q_PROPERTY(QString customDateFormat READ customDateFormat WRITE setCustomDateFormat NOTIFY customDateFormatChanged)
    Q_PROPERTY(bool thumbnailsEnabled READ thumbnailsEnabled WRITE setThumbnailsEnabled NOTIFY thumbnailsEnabledChanged)
    Q_PROPERTY(int thumbnailMaxMb READ thumbnailMaxMb WRITE setThumbnailMaxMb NOTIFY thumbnailMaxMbChanged)
    Q_PROPERTY(bool showSizeColumn READ showSizeColumn WRITE setShowSizeColumn NOTIFY showSizeColumnChanged)
    Q_PROPERTY(bool showTypeColumn READ showTypeColumn WRITE setShowTypeColumn NOTIFY showTypeColumnChanged)
    Q_PROPERTY(bool showDateColumn READ showDateColumn WRITE setShowDateColumn NOTIFY showDateColumnChanged)
    Q_PROPERTY(bool showPermissionsColumn READ showPermissionsColumn WRITE setShowPermissionsColumn NOTIFY showPermissionsColumnChanged)
    Q_PROPERTY(QVariantMap detailsColumnWidths READ detailsColumnWidths NOTIFY detailsColumnWidthsChanged)
    Q_PROPERTY(QStringList detailsColumnOrder READ detailsColumnOrder NOTIFY detailsColumnOrderChanged)
    Q_PROPERTY(bool singleClick READ singleClick WRITE setSingleClick NOTIFY singleClickChanged)
    Q_PROPERTY(QString defaultStartupDirectory READ defaultStartupDirectory WRITE setDefaultStartupDirectory NOTIFY defaultStartupDirectoryChanged)
    Q_PROPERTY(int defaultViewMode READ defaultViewMode WRITE setDefaultViewMode NOTIFY defaultViewModeChanged)
    Q_PROPERTY(int defaultSortField READ defaultSortField WRITE setDefaultSortField NOTIFY defaultSortFieldChanged)
    Q_PROPERTY(int defaultSortOrder READ defaultSortOrder WRITE setDefaultSortOrder NOTIFY defaultSortOrderChanged)
    Q_PROPERTY(bool showDirsFirst READ showDirsFirst WRITE setShowDirsFirst NOTIFY showDirsFirstChanged)
    Q_PROPERTY(bool caseSensitiveSort READ caseSensitiveSort WRITE setCaseSensitiveSort NOTIFY caseSensitiveSortChanged)
    Q_PROPERTY(bool directorySpecificViews READ directorySpecificViews WRITE setDirectorySpecificViews NOTIFY directorySpecificViewsChanged)
    Q_PROPERTY(bool showFreeSpace READ showFreeSpace WRITE setShowFreeSpace NOTIFY showFreeSpaceChanged)
    Q_PROPERTY(int placesIconSize READ placesIconSize WRITE setPlacesIconSize NOTIFY placesIconSizeChanged)
    Q_PROPERTY(int folderItemCount READ folderItemCount WRITE setFolderItemCount NOTIFY folderItemCountChanged)
    Q_PROPERTY(QString selectedPath READ selectedPath NOTIFY selectedPathChanged)
    Q_PROPERTY(int iconThemeVersion READ iconThemeVersion NOTIFY iconThemeVersionChanged)
    Q_PROPERTY(bool menuShowSecondaryEditor READ menuShowSecondaryEditor WRITE setMenuShowSecondaryEditor NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowUploadOnline READ menuShowUploadOnline WRITE setMenuShowUploadOnline NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowSendTo READ menuShowSendTo WRITE setMenuShowSendTo NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowCompress READ menuShowCompress WRITE setMenuShowCompress NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowSymlink READ menuShowSymlink WRITE setMenuShowSymlink NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowTerminal READ menuShowTerminal WRITE setMenuShowTerminal NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool menuShowDelete READ menuShowDelete WRITE setMenuShowDelete NOTIFY menuPreferencesChanged)
    Q_PROPERTY(bool showNetworkSection READ showNetworkSection WRITE setShowNetworkSection NOTIFY showNetworkSectionChanged)

public:

    static AppController* instance();
    static AppController* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    [[nodiscard]] int iconThemeVersion() const { return m_iconThemeVersion; }
    Q_INVOKABLE void triggerIconReload();

    [[nodiscard]] QString title() const { return m_title; }
    void setTitle(const QString& title);

    [[nodiscard]] QString initialDirectory() const { return m_initialDirectory; }
    void setInitialDirectory(const QString& dir);

    [[nodiscard]] QString filterLabel() const { return m_filterLabel; }
    void setFilterLabel(const QString& label);

    [[nodiscard]] QStringList filters() const { return m_filters; }
    void setFilters(const QStringList& filters);

    [[nodiscard]] bool directoryOnly() const { return m_directoryOnly; }
    void setDirectoryOnly(bool dirOnly);

    [[nodiscard]] bool saveMode() const { return m_saveMode; }
    void setSaveMode(bool save);
    [[nodiscard]] QString suggestedName() const { return m_suggestedName; }
    void setSuggestedName(const QString& name);
    Q_INVOKABLE static bool fileExists(const QString& path);

    [[nodiscard]] bool showHidden() const { return m_showHidden; }
    [[nodiscard]] bool confirmPermanentDelete() const { return m_confirmPermanentDelete; }
    void setConfirmPermanentDelete(bool confirm);

    [[nodiscard]] bool restoreTabs() const { return m_restoreTabs; }
    void setRestoreTabs(bool restore);
    [[nodiscard]] bool confirmMoveToTrash() const { return m_confirmMoveToTrash; }
    void setConfirmMoveToTrash(bool confirm);
    [[nodiscard]] int dateFormat() const { return m_dateFormat; }
    void setDateFormat(int format);

    [[nodiscard]] QString customDateFormat() const { return m_customDateFormat; }
    void setCustomDateFormat(const QString& pattern);
    Q_INVOKABLE static bool shiftPressed();
    [[nodiscard]] bool thumbnailsEnabled() const { return m_thumbnailsEnabled; }
    void setThumbnailsEnabled(bool enabled);
    [[nodiscard]] int thumbnailMaxMb() const { return m_thumbnailMaxMb; }
    void setThumbnailMaxMb(int mb);
    [[nodiscard]] bool showSizeColumn() const { return m_showSizeColumn; }
    void setShowSizeColumn(bool show);
    [[nodiscard]] bool showTypeColumn() const { return m_showTypeColumn; }
    void setShowTypeColumn(bool show);
    [[nodiscard]] bool showDateColumn() const { return m_showDateColumn; }
    void setShowDateColumn(bool show);
    [[nodiscard]] bool showPermissionsColumn() const { return m_showPermissionsColumn; }
    void setShowPermissionsColumn(bool show);
    [[nodiscard]] QVariantMap detailsColumnWidths() const { return m_detailsColumnWidths; }
    Q_INVOKABLE void setDetailsColumnWidth(const QString& key, int width);
    Q_INVOKABLE void resetDetailsColumnWidths();

    [[nodiscard]] QStringList detailsColumnOrder() const { return m_detailsColumnOrder; }
    Q_INVOKABLE void setDetailsColumnOrder(const QStringList& order);
    Q_INVOKABLE void resetDetailsColumnOrder();
    void setShowHidden(bool show);

    [[nodiscard]] bool singleClick() const { return m_singleClick; }
    void setSingleClick(bool single);

    [[nodiscard]] QString defaultStartupDirectory() const { return m_defaultStartupDirectory; }
    void setDefaultStartupDirectory(const QString& dir);

    [[nodiscard]] int defaultViewMode() const { return m_defaultViewMode; }
    void setDefaultViewMode(int mode);

    [[nodiscard]] int defaultSortField() const { return m_defaultSortField; }
    void setDefaultSortField(int field);

    [[nodiscard]] int defaultSortOrder() const { return m_defaultSortOrder; }
    void setDefaultSortOrder(int order);

    [[nodiscard]] bool showDirsFirst() const { return m_showDirsFirst; }
    void setShowDirsFirst(bool dirsFirst);

    [[nodiscard]] bool caseSensitiveSort() const { return m_caseSensitiveSort; }
    void setCaseSensitiveSort(bool sensitive);
    [[nodiscard]] bool directorySpecificViews() const { return m_directorySpecificViews; }
    void setDirectorySpecificViews(bool enabled);
    Q_INVOKABLE QVariantMap directoryView(const QString& path) const;
    Q_INVOKABLE void rememberDirectoryView(const QString& path, int viewMode, int sortField, int sortOrder);
    Q_INVOKABLE void forgetDirectoryViews();
    [[nodiscard]] bool showFreeSpace() const { return m_showFreeSpace; }
    void setShowFreeSpace(bool show);

    [[nodiscard]] int placesIconSize() const { return m_placesIconSize; }
    void setPlacesIconSize(int size);

    [[nodiscard]] int folderItemCount() const { return m_folderItemCount; }
    void setFolderItemCount(int mode);

    [[nodiscard]] QString selectedPath() const { return m_selectedPath; }
    void setSelectedPath(const QString& path);

    [[nodiscard]] bool menuShowSecondaryEditor() const { return m_menuShowSecondaryEditor; }
    void setMenuShowSecondaryEditor(bool val);

    [[nodiscard]] bool menuShowUploadOnline() const { return m_menuShowUploadOnline; }
    void setMenuShowUploadOnline(bool val);

    [[nodiscard]] bool menuShowSendTo() const { return m_menuShowSendTo; }
    void setMenuShowSendTo(bool val);

    [[nodiscard]] bool menuShowCompress() const { return m_menuShowCompress; }
    void setMenuShowCompress(bool val);

    [[nodiscard]] bool menuShowSymlink() const { return m_menuShowSymlink; }
    void setMenuShowSymlink(bool val);

    [[nodiscard]] bool menuShowTerminal() const { return m_menuShowTerminal; }
    void setMenuShowTerminal(bool val);

    [[nodiscard]] bool menuShowDelete() const { return m_menuShowDelete; }
    void setMenuShowDelete(bool val);

    [[nodiscard]] bool showNetworkSection() const { return m_showNetworkSection; }
    void setShowNetworkSection(bool show);

    Q_INVOKABLE void accept(const QString& path);
    Q_INVOKABLE void reject();

signals:
    void titleChanged();
    void initialDirectoryChanged();
    void filterLabelChanged();
    void filtersChanged();
    void directoryOnlyChanged();
    void saveModeChanged();
    void suggestedNameChanged();
    void showHiddenChanged();
    void confirmPermanentDeleteChanged();
    void restoreTabsChanged();
    void confirmMoveToTrashChanged();
    void dateFormatChanged();
    void customDateFormatChanged();
    void thumbnailsEnabledChanged();
    void thumbnailMaxMbChanged();
    void showSizeColumnChanged();
    void showTypeColumnChanged();
    void showDateColumnChanged();
    void showPermissionsColumnChanged();
    void detailsColumnWidthsChanged();
    void detailsColumnOrderChanged();
    void singleClickChanged();
    void defaultStartupDirectoryChanged();
    void defaultViewModeChanged();
    void defaultSortFieldChanged();
    void defaultSortOrderChanged();
    void showDirsFirstChanged();
    void caseSensitiveSortChanged();
    void directorySpecificViewsChanged();
    void showFreeSpaceChanged();
    void placesIconSizeChanged();
    void folderItemCountChanged();
    void selectedPathChanged();
    void iconThemeVersionChanged();
    void menuPreferencesChanged();
    void showNetworkSectionChanged();
    void accepted(const QString& path);
    void rejected();

private:
    explicit AppController(QObject* parent = nullptr);
    QString m_title = "Select a file";
    QString m_initialDirectory;
    QString m_filterLabel = "All files";
    QStringList m_filters = { "*" };
    bool m_directoryOnly = false;
    bool m_saveMode = false;
    QString m_suggestedName;
    bool m_showHidden = false;
    bool m_confirmPermanentDelete = true;
    QString m_customDateFormat = QStringLiteral("yyyy-MM-dd hh:mm");
    bool m_restoreTabs = false;
    bool m_confirmMoveToTrash = false;
    int m_dateFormat = 1;
    bool m_thumbnailsEnabled = true;
    int m_thumbnailMaxMb = 0;
    bool m_showSizeColumn = true;
    bool m_showTypeColumn = true;
    bool m_showDateColumn = true;
    bool m_showPermissionsColumn = true;
    QVariantMap m_detailsColumnWidths;
    QStringList m_detailsColumnOrder;
    bool m_singleClick = false;
    QString m_defaultStartupDirectory = "home";
    int m_defaultViewMode = 0;
    int m_defaultSortField = 0;
    int m_defaultSortOrder = 0;
    bool m_showDirsFirst = true;
    bool m_caseSensitiveSort = false;
    bool m_directorySpecificViews = false;
    QVariantMap m_directoryViews;
    bool m_showFreeSpace = true;
    int m_placesIconSize = 20;
    int m_folderItemCount = 0;
    QString m_selectedPath;
    int m_iconThemeVersion = 0;
    bool m_menuShowSecondaryEditor = true;
    bool m_menuShowUploadOnline = true;
    bool m_menuShowSendTo = true;
    bool m_menuShowCompress = true;
    bool m_menuShowSymlink = true;
    bool m_menuShowTerminal = true;
    bool m_menuShowDelete = true;
    bool m_showNetworkSection = false;
};

} // namespace prism::core
