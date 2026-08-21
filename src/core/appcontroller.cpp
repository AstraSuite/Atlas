#include "appcontroller.hpp"
#include <QSettings>
#include <iostream>

namespace prism::core {

AppController::AppController(QObject* parent)
    : QObject(parent) {
    QSettings settings("prism", "prism");
    QSettings legacy1("caelestia", "prism");
    QSettings legacy2("Caelestia", "Prism");
    m_showHidden = settings.value("session/showHidden", legacy1.value("session/showHidden", legacy2.value("session/showHidden", false))).toBool();
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

void AppController::setShowHidden(bool show) {
    if (m_showHidden != show) {
        m_showHidden = show;
        QSettings settings("prism", "prism");
        settings.setValue("session/showHidden", show);
        emit showHiddenChanged();
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

} // namespace prism::core
