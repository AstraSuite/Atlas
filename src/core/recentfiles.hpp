#pragma once

#include <QString>
#include <QStringList>

namespace atlas::core {

class RecentFiles {
public:
    static QString virtualPath();
    static bool isRecentPath(const QString& path);

    static QStringList paths(int limit = 200);
    static void forget(const QString& filePath);
};

} // namespace atlas::core
