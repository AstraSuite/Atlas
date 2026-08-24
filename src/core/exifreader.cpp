#include "exifreader.hpp"
#include "fileutils.hpp"

#include <QDateTime>
#include <QStringList>

#ifdef PRISM_HAVE_EXIV2
#include <exiv2/exiv2.hpp>
#endif

namespace atlas::core {
namespace {

void appendRow(QVariantList& rows, const QString& label, const QString& value) {
    if (!value.simplified().isEmpty()) {
        rows.append(QVariantMap{{"label", label}, {"value", value}});
    }
}

#ifdef PRISM_HAVE_EXIV2

// "48/1 8/1 4506/100" + "N" -> "48.1459° N"
QString formatGpsCoordinate(const QString& rationals, const QString& ref) {
    const QStringList parts = rationals.split(' ', Qt::SkipEmptyParts);
    if (parts.size() != 3 || ref.isEmpty()) return QString();

    double degrees[3] = {0.0, 0.0, 0.0};
    for (int i = 0; i < 3; ++i) {
        const QStringList frac = parts[i].split('/');
        bool okNum = false, okDen = false;
        const double numerator = frac.value(0).toDouble(&okNum);
        const double denominator = frac.value(1).toDouble(&okDen);
        if (!okNum || !okDen || denominator == 0.0) return QString();
        degrees[i] = numerator / denominator;
    }

    const double decimal = degrees[0] + degrees[1] / 60.0 + degrees[2] / 3600.0;
    return QStringLiteral("%1° %2").arg(decimal, 0, 'f', 4).arg(ref.at(0));
}

// "1/250" -> "1/250 s", "2" -> "2 s"
QString formatExposure(const QString& rational) {
    if (rational.isEmpty()) return QString();
    const QStringList frac = rational.split('/');
    if (frac.size() == 2 && frac[1].toDouble() > 0.0) {
        const double seconds = frac[0].toDouble() / frac[1].toDouble();
        if (seconds >= 10.0) return QStringLiteral("%1 s").arg(QString::number(seconds, 'f', 0));
        return QStringLiteral("%1 s").arg(rational);
    }
    return QStringLiteral("%1 s").arg(rational);
}

QString stripCharsetPrefix(QString comment) {
    qsizetype start = 0;
    if (comment.startsWith(QLatin1String("charset=\""), Qt::CaseInsensitive)) {
        start = sizeof("charset=\"") - 1;
        const qsizetype end = comment.indexOf(u'"', start);
        if (end >= 0) start = end + 1;
    } else if (comment.startsWith(QLatin1String("charset="), Qt::CaseInsensitive)) {
        const qsizetype space = comment.indexOf(u' ');
        if (space >= 0) start = space + 1;
    }
    return comment.mid(start).trimmed();
}

#endif // PRISM_HAVE_EXIV2

} // namespace

QVariantList ExifReader::read(const QString& filePath) {
    QVariantList rows;

#ifdef PRISM_HAVE_EXIV2
    if (filePath.isEmpty()) return rows;

    try {
        auto image = Exiv2::ImageFactory::open(filePath.toStdString());
        image->readMetadata();
        const Exiv2::ExifData& exif = image->exifData();
        if (exif.empty()) return rows;

        auto find = [&exif](const std::string& key) {
            return exif.findKey(Exiv2::ExifKey(key));
        };
        auto str = [&find, &exif](const std::string& key) -> QString {
            auto it = find(key);
            return it != exif.end() ? QString::fromUtf8(it->toString().c_str()) : QString();
        };
        auto num = [&find, &exif](const std::string& key) -> double {
            auto it = find(key);
            return it != exif.end() ? it->toFloat() : 0.0;
        };

        // Date taken, formatted per the user's date preference
        const QDateTime taken =
            QDateTime::fromString(str("Exif.Photo.DateTimeOriginal"), QStringLiteral("yyyy:MM:dd HH:mm:ss"));
        appendRow(rows, "Date Taken", taken.isValid() ? FileUtils::formatDateTime(taken) : QString());

        // Camera and lens
        QString make = str("Exif.Image.Make");
        QString model = str("Exif.Image.Model");
        if (!make.isEmpty() && !model.isEmpty() && model.startsWith(make, Qt::CaseInsensitive)) {
            model = model.mid(make.length()).trimmed();
        }
        QString camera = QStringList{make, model}.join(QStringLiteral(" ")).simplified();
        appendRow(rows, "Camera", camera);
        appendRow(rows, "Lens", str("Exif.Photo.LensModel"));

        // Capture settings
        appendRow(rows, "Exposure", formatExposure(str("Exif.Photo.ExposureTime")));
        if (const double fNumber = num("Exif.Photo.FNumber"); fNumber > 0.0)
            appendRow(rows, "Aperture", QStringLiteral("f/%1").arg(QString::number(fNumber, 'f', 1)));

        QString iso;
        for (const auto* key : {"Exif.Photo.ISOSpeedRatings", "Exif.Image.ISOSpeedRatings", "Exif.Photo.ISOSpeed"}) {
            if (auto it = find(key); it != exif.end()) {
                iso = QString::number(it->toInt64());
                break;
            }
        }
        appendRow(rows, "ISO", iso);

        if (const double focal = num("Exif.Photo.FocalLength"); focal > 0.0)
            appendRow(rows, "Focal Length",
                      QStringLiteral("%1 mm").arg(focal == static_cast<double>(static_cast<int>(focal))
                                                      ? QString::number(static_cast<int>(focal))
                                                      : QString::number(focal, 'f', 1)));

        if (auto it = find("Exif.Photo.Flash"); it != exif.end())
            appendRow(rows, "Flash", it->toInt64() & 0x01 ? "Fired" : "Did not fire");

        if (auto it = find("Exif.Photo.WhiteBalance"); it != exif.end())
            appendRow(rows, "White Balance", it->toInt64() == 1 ? "Manual" : "Auto");

        // Location
        const QString latitude = formatGpsCoordinate(str("Exif.GPSInfo.GPSLatitude"), str("Exif.GPSInfo.GPSLatitudeRef"));
        const QString longitude =
            formatGpsCoordinate(str("Exif.GPSInfo.GPSLongitude"), str("Exif.GPSInfo.GPSLongitudeRef"));
        QString gps = latitude;
        if (!longitude.isEmpty()) gps += gps.isEmpty() ? longitude : QStringLiteral(", ") + longitude;
        appendRow(rows, "GPS Coordinates", gps);

        // Descriptive tags
        appendRow(rows, "Software", str("Exif.Image.Software"));
        const QString commentStr = stripCharsetPrefix(str("Exif.Photo.UserComment"));
        rows.append(QVariantMap{{"label", "Comment"}, {"value", commentStr}});
        appendRow(rows, "Description", str("Exif.Image.ImageDescription"));
        appendRow(rows, "Copyright", str("Exif.Image.Copyright"));
    } catch (const std::exception&) {
        return QVariantList();
    }
#endif

    return rows;
}

bool ExifReader::available() {
#if defined(ATLAS_HAVE_EXIV2) || defined(PRISM_HAVE_EXIV2)
    return true;
#else
    return false;
#endif
}

bool ExifReader::writeComment(const QString& filePath, const QString& comment) {
#if defined(ATLAS_HAVE_EXIV2) || defined(PRISM_HAVE_EXIV2)
    if (filePath.isEmpty()) return false;

    try {
        auto image = Exiv2::ImageFactory::open(filePath.toStdString());
        image->readMetadata();
        Exiv2::ExifData& exif = image->exifData();

        const std::string key = "Exif.Photo.UserComment";
        if (comment.trimmed().isEmpty()) {
            auto it = exif.findKey(Exiv2::ExifKey(key));
            if (it != exif.end()) exif.erase(it);
        } else {
            exif[key] = "charset=\"Ascii\" " + comment.toStdString();
        }
        image->writeMetadata();
        return true;
    } catch (const std::exception&) {
        return false;
    }
#else
    Q_UNUSED(filePath)
    Q_UNUSED(comment)
    return false;
#endif
}

} // namespace atlas::core
