#pragma once

#include <QString>
#include <QVariantList>

namespace atlas::core {

class ExifReader {
public:
    ExifReader() = delete;

    // Ordered {label, value} rows extracted from an image file.
    // Empty when built without Exiv2, on parse failure, or when no metadata exists.
    [[nodiscard]] static QVariantList read(const QString& filePath);

    // True when compiled with Exiv2 support.
    [[nodiscard]] static bool available();

    // Writes an EXIF UserComment string to the image file.
    [[nodiscard]] static bool writeComment(const QString& filePath, const QString& comment);
};

} // namespace atlas::core
