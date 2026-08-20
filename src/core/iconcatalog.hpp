#pragma once

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
    explicit IconCatalog(QObject* parent = nullptr);
    static IconCatalog* instance();

    int totalIcons() const { return m_icons.size(); }

    Q_INVOKABLE QStringList search(const QString& query, int limit = 120) const;
    Q_INVOKABLE QStringList getAllIcons() const { return m_icons; }

private:
    void loadIcons();
    QStringList m_icons;
};

} // namespace prism::core
