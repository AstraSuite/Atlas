#pragma once

#include <QQmlEngine>
#include <QJSEngine>

#include <QObject>
#include <QString>
#include <QStringList>
#include <qqmlintegration.h>

namespace prism::core {

class IconCatalog : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int totalIcons READ totalIcons CONSTANT)

public:
    static IconCatalog* instance();
    static IconCatalog* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    int totalIcons() const { return m_icons.size(); }

    Q_INVOKABLE QStringList search(const QString& query, int limit = 0) const;
    Q_INVOKABLE QStringList getAllIcons() const { return m_icons; }

private:
    explicit IconCatalog(QObject* parent = nullptr);
    void loadIcons();
    QStringList m_icons;
};

} // namespace prism::core
