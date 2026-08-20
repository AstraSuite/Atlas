#pragma once

#include <QObject>
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
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(QString selectedPath READ selectedPath NOTIFY selectedPathChanged)

public:
    explicit AppController(QObject* parent = nullptr);

    static AppController* instance();

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

    [[nodiscard]] bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool show);

    [[nodiscard]] QString selectedPath() const { return m_selectedPath; }

    Q_INVOKABLE void accept(const QString& path);
    Q_INVOKABLE void reject();

signals:
    void titleChanged();
    void initialDirectoryChanged();
    void filterLabelChanged();
    void filtersChanged();
    void directoryOnlyChanged();
    void showHiddenChanged();
    void selectedPathChanged();
    void accepted(const QString& path);
    void rejected();

private:
    QString m_title = "Select a file";
    QString m_initialDirectory;
    QString m_filterLabel = "All files";
    QStringList m_filters = { "*" };
    bool m_directoryOnly = false;
    bool m_showHidden = false;
    QString m_selectedPath;
};

} // namespace prism::core
