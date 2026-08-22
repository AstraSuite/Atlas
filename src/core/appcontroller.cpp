#include "appcontroller.hpp"
#include "fileutils.hpp"

#include <QGuiApplication>
#include <QJsonObject>
#include <QJsonDocument>
#include "iconprovider.hpp"
#include <QSettings>
#include <iostream>

namespace prism::core {

AppController::AppController(QObject* parent)
    : QObject(parent) {
    QSettings settings("prism", "prism");
    QSettings legacy1("caelestia", "prism");
    QSettings legacy2("Caelestia", "Prism");
    m_showHidden = settings.value("session/showHidden", legacy1.value("session/showHidden", legacy2.value("session/showHidden", false))).toBool();
    m_singleClick = settings.value("session/singleClick", legacy1.value("session/singleClick", legacy2.value("session/singleClick", false))).toBool();
    m_confirmPermanentDelete = settings.value("session/confirmPermanentDelete", true).toBool();
    m_defaultStartupDirectory = settings.value("preferences/startupDirectory", "home").toString();
    m_defaultViewMode = settings.value("preferences/defaultViewMode", 0).toInt();
    m_defaultSortField = settings.value("preferences/defaultSortField", 0).toInt();
    m_defaultSortOrder = settings.value("preferences/defaultSortOrder", 0).toInt();
    m_showDirsFirst = settings.value("preferences/showDirsFirst", true).toBool();
    m_placesIconSize = settings.value("preferences/placesIconSize", 20).toInt();
    m_dateFormat = settings.value("preferences/dateFormat", 1).toInt();
    FileUtils::setDateFormat(m_dateFormat);
    m_thumbnailsEnabled = settings.value("preferences/thumbnailsEnabled", true).toBool();
    m_thumbnailMaxMb = settings.value("preferences/thumbnailMaxMb", 0).toInt();
    FileUtils::setThumbnailsEnabled(m_thumbnailsEnabled);
    FileUtils::setThumbnailMaxBytes(static_cast<qint64>(m_thumbnailMaxMb) * 1024 * 1024);
    m_showSizeColumn = settings.value("preferences/showSizeColumn", true).toBool();
    m_showTypeColumn = settings.value("preferences/showTypeColumn", true).toBool();
    m_showDateColumn = settings.value("preferences/showDateColumn", true).toBool();
    m_showPermissionsColumn = settings.value("preferences/showPermissionsColumn", true).toBool();

    const QByteArray widthsJson = settings.value("preferences/detailsColumnWidths").toString().toUtf8();
    if (!widthsJson.isEmpty()) {
        m_detailsColumnWidths = QJsonDocument::fromJson(widthsJson).object().toVariantMap();
    }
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
        QSettings settings("prism", "prism");
        settings.setValue("session/confirmPermanentDelete", confirm);
        emit confirmPermanentDeleteChanged();
    }
}

void AppController::setDateFormat(int format) {
    if (m_dateFormat != format) {
        m_dateFormat = format;
        FileUtils::setDateFormat(format);
        QSettings settings("prism", "prism");
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
        QSettings settings("prism", "prism");
        settings.setValue("preferences/thumbnailsEnabled", enabled);
        emit thumbnailsEnabledChanged();
    }
}

void AppController::setThumbnailMaxMb(int mb) {
    if (m_thumbnailMaxMb != mb) {
        m_thumbnailMaxMb = mb;
        FileUtils::setThumbnailMaxBytes(static_cast<qint64>(mb) * 1024 * 1024);
        QSettings settings("prism", "prism");
        settings.setValue("preferences/thumbnailMaxMb", mb);
        emit thumbnailMaxMbChanged();
    }
}

void AppController::setShowSizeColumn(bool show) {
    if (m_showSizeColumn != show) {
        m_showSizeColumn = show;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/showSizeColumn", show);
        emit showSizeColumnChanged();
    }
}

void AppController::setShowTypeColumn(bool show) {
    if (m_showTypeColumn != show) {
        m_showTypeColumn = show;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/showTypeColumn", show);
        emit showTypeColumnChanged();
    }
}

void AppController::setShowDateColumn(bool show) {
    if (m_showDateColumn != show) {
        m_showDateColumn = show;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/showDateColumn", show);
        emit showDateColumnChanged();
    }
}

void AppController::setShowPermissionsColumn(bool show) {
    if (m_showPermissionsColumn != show) {
        m_showPermissionsColumn = show;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/showPermissionsColumn", show);
        emit showPermissionsColumnChanged();
    }
}

void AppController::setDetailsColumnWidth(const QString& key, int width) {
    const int clamped = qBound(48, width, 800);
    if (m_detailsColumnWidths.value(key).toInt() == clamped)
        return;

    m_detailsColumnWidths.insert(key, clamped);

    QSettings settings("prism", "prism");
    settings.setValue("preferences/detailsColumnWidths",
                      QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(m_detailsColumnWidths)).toJson(QJsonDocument::Compact)));
    emit detailsColumnWidthsChanged();
}

void AppController::resetDetailsColumnWidths() {
    if (m_detailsColumnWidths.isEmpty())
        return;

    m_detailsColumnWidths.clear();

    QSettings settings("prism", "prism");
    settings.remove("preferences/detailsColumnWidths");
    emit detailsColumnWidthsChanged();
}
void AppController::setShowHidden(bool show) {
    if (m_showHidden != show) {
        m_showHidden = show;
        QSettings settings("prism", "prism");
        settings.setValue("session/showHidden", show);
        emit showHiddenChanged();
    }
}

void AppController::setSingleClick(bool single) {
    if (m_singleClick != single) {
        m_singleClick = single;
        QSettings settings("prism", "prism");
        settings.setValue("session/singleClick", single);
        emit singleClickChanged();
    }
}

void AppController::setDefaultStartupDirectory(const QString& dir) {
    if (m_defaultStartupDirectory != dir) {
        m_defaultStartupDirectory = dir;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/startupDirectory", dir);
        emit defaultStartupDirectoryChanged();
    }
}

void AppController::setDefaultViewMode(int mode) {
    if (m_defaultViewMode != mode) {
        m_defaultViewMode = mode;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/defaultViewMode", mode);
        emit defaultViewModeChanged();
    }
}

void AppController::setDefaultSortField(int field) {
    if (m_defaultSortField != field) {
        m_defaultSortField = field;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/defaultSortField", field);
        emit defaultSortFieldChanged();
    }
}

void AppController::setDefaultSortOrder(int order) {
    if (m_defaultSortOrder != order) {
        m_defaultSortOrder = order;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/defaultSortOrder", order);
        emit defaultSortOrderChanged();
    }
}

void AppController::setShowDirsFirst(bool dirsFirst) {
    if (m_showDirsFirst != dirsFirst) {
        m_showDirsFirst = dirsFirst;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/showDirsFirst", dirsFirst);
        emit showDirsFirstChanged();
    }
}

void AppController::setPlacesIconSize(int size) {
    if (m_placesIconSize != size && size > 0) {
        m_placesIconSize = size;
        QSettings settings("prism", "prism");
        settings.setValue("preferences/placesIconSize", size);
        emit placesIconSizeChanged();
    }
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

void AppController::triggerIconReload() {
    IconImageProvider::clearCache();
    m_iconThemeVersion++;
    emit iconThemeVersionChanged();
}

} // namespace prism::core
