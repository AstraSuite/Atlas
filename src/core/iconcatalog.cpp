#include "iconcatalog.hpp"

#include <QFile>
#include <QTextStream>

namespace prism::core {

IconCatalog::IconCatalog(QObject* parent)
    : QObject(parent) {
    loadIcons();
}

IconCatalog* IconCatalog::instance() {
    static auto* s_instance = new IconCatalog();
    return s_instance;
}

void IconCatalog::loadIcons() {
    QFile file(":/qt/qml/prism/assets/material_icons.txt");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        // Fallback to direct file path if running from build
        file.setFileName("assets/material_icons.txt");
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            return;
        }
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (!line.isEmpty()) {
            m_icons.append(line);
        }
    }
}

QStringList IconCatalog::search(const QString& query, int limit) const {
    QString q = query.trimmed().toLower();
    if (q.isEmpty()) {
        if (limit > 0 && limit < m_icons.size()) {
            return m_icons.mid(0, limit);
        }
        return m_icons;
    }

    QStringList exactMatches;
    QStringList prefixMatches;
    QStringList substringMatches;

    for (const QString& icon : m_icons) {
        if (icon == q) {
            exactMatches.append(icon);
        } else if (icon.startsWith(q)) {
            prefixMatches.append(icon);
        } else if (icon.contains(q)) {
            substringMatches.append(icon);
        }

        if (limit > 0 && (exactMatches.size() + prefixMatches.size() + substringMatches.size()) >= limit * 2) {
            break;
        }
    }

    QStringList result = exactMatches + prefixMatches + substringMatches;
    if (limit > 0 && result.size() > limit) {
        return result.mid(0, limit);
    }
    return result;
}

} // namespace prism::core
