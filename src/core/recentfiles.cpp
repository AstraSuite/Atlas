#include "recentfiles.hpp"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUrl>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

#include <algorithm>

namespace prism::core {

static QString storePath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
         + QStringLiteral("/recently-used.xbel");
}

QString RecentFiles::virtualPath() {
    return QStringLiteral("recent:///");
}

bool RecentFiles::isRecentPath(const QString& path) {
    return path.startsWith(QStringLiteral("recent:"));
}

QStringList RecentFiles::paths(int limit) {
    QFile file(storePath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    struct Entry {
        QString path;
        QDateTime visited;
    };
    QList<Entry> entries;

    QXmlStreamReader xml(&file);
    while (!xml.atEnd()) {
        if (xml.readNext() != QXmlStreamReader::StartElement)
            continue;
        if (xml.name() != QLatin1String("bookmark"))
            continue;

        const QString href = xml.attributes().value(QLatin1String("href")).toString();
        if (href.isEmpty() || !href.startsWith(QLatin1String("file://")))
            continue;

        const QString local = QUrl(href).toLocalFile();
        if (local.isEmpty() || !QFileInfo::exists(local))
            continue;

        Entry entry;
        entry.path = local;
        entry.visited = QDateTime::fromString(xml.attributes().value(QLatin1String("visited")).toString(), Qt::ISODate);
        entries.append(entry);
    }

    std::sort(entries.begin(), entries.end(), [](const Entry& a, const Entry& b) {
        return a.visited > b.visited;
    });

    QStringList result;
    result.reserve(qMin(limit, static_cast<int>(entries.size())));
    for (const Entry& entry : std::as_const(entries)) {
        if (result.size() >= limit)
            break;
        if (!result.contains(entry.path))
            result.append(entry.path);
    }

    return result;
}

void RecentFiles::forget(const QString& filePath) {
    const QString store = storePath();
    QFile file(store);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    const QString target = QUrl::fromLocalFile(filePath).toString();
    QByteArray output;
    QXmlStreamReader xml(&file);
    QXmlStreamWriter writer(&output);
    writer.setAutoFormatting(true);

    int skipDepth = -1;
    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.hasError())
            return;

        if (xml.isStartElement() && xml.name() == QLatin1String("bookmark")
            && xml.attributes().value(QLatin1String("href")).toString() == target) {
            skipDepth = 0;
            continue;
        }

        if (skipDepth >= 0) {
            if (xml.isStartElement())
                ++skipDepth;
            else if (xml.isEndElement()) {
                if (skipDepth == 0) {
                    skipDepth = -1;
                    continue;
                }
                --skipDepth;
            }
            continue;
        }

        if (!xml.isWhitespace())
            writer.writeCurrentToken(xml);
    }
    file.close();

    if (output.isEmpty())
        return;

    QFile out(store);
    if (out.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        out.write(output);
}

} // namespace prism::core
