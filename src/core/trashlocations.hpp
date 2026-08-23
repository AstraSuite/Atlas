#pragma once

#include <QList>
#include <QString>

namespace prism::core {

struct TrashLocation {
    QString baseDir;
    QString filesDir;
    QString infoDir;
    QString topDir;

    [[nodiscard]] bool isValid() const { return !filesDir.isEmpty(); }
};

class TrashLocations {
public:
    static QString homeTrashDir();
    static QString homeTrashFilesDir();

    static bool isTrashRoot(const QString& path);

    static QList<TrashLocation> all();
    static TrashLocation forTrashedFile(const QString& trashedFilePath);
    static TrashLocation forSourceFile(const QString& sourcePath, bool create);

    static QString resolveOriginalPath(const TrashLocation& location, const QString& encodedPath);

private:
    static QString topDirFor(const QString& path);
    static QStringList mountPoints();
};

} // namespace prism::core
