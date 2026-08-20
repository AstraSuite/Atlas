#include "colours.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDir>

namespace prism::config {

M3Palette::M3Palette(bool light, QObject* parent)
    : QObject(parent) {
    loadDefaults(light);
}

void M3Palette::loadDefaults(bool light) {
    if (!light) {
        // Dark theme defaults
        m_m3background = QColor("#191114");
        m_m3onBackground = QColor("#efdfe2");
        m_m3surface = QColor("#191114");
        m_m3surfaceDim = QColor("#191114");
        m_m3surfaceBright = QColor("#403739");
        m_m3surfaceContainerLowest = QColor("#130c0e");
        m_m3surfaceContainerLow = QColor("#22191c");
        m_m3surfaceContainer = QColor("#261d20");
        m_m3surfaceContainerHigh = QColor("#31282a");
        m_m3surfaceContainerHighest = QColor("#3c3235");
        m_m3onSurface = QColor("#efdfe2");
        m_m3surfaceVariant = QColor("#514347");
        m_m3onSurfaceVariant = QColor("#d5c2c6");
        m_m3inverseSurface = QColor("#efdfe2");
        m_m3inverseOnSurface = QColor("#372e30");
        m_m3outline = QColor("#9e8c91");
        m_m3outlineVariant = QColor("#514347");
        m_m3shadow = QColor("#000000");
        m_m3scrim = QColor("#000000");
        m_m3surfaceTint = QColor("#ffb0ca");
        m_m3primary = QColor("#ffb0ca");
        m_m3onPrimary = QColor("#541d34");
        m_m3primaryContainer = QColor("#6f334a");
        m_m3onPrimaryContainer = QColor("#ffd9e3");
        m_m3secondary = QColor("#e2bdc7");
        m_m3onSecondary = QColor("#422932");
        m_m3secondaryContainer = QColor("#5a3f48");
        m_m3onSecondaryContainer = QColor("#ffd9e3");
        m_m3tertiary = QColor("#f0bc95");
        m_m3onTertiary = QColor("#48290c");
        m_m3tertiaryContainer = QColor("#b58763");
        m_m3onTertiaryContainer = QColor("#000000");
        m_m3error = QColor("#ffb4ab");
        m_m3onError = QColor("#690005");
        m_m3errorContainer = QColor("#93000a");
        m_m3onErrorContainer = QColor("#ffdad6");
    } else {
        // Light theme defaults
        m_m3background = QColor("#fff8f8");
        m_m3onBackground = QColor("#22191c");
        m_m3surface = QColor("#fff8f8");
        m_m3surfaceDim = QColor("#e6dadc");
        m_m3surfaceBright = QColor("#fff8f8");
        m_m3surfaceContainerLowest = QColor("#ffffff");
        m_m3surfaceContainerLow = QColor("#fcf1f3");
        m_m3surfaceContainer = QColor("#f7ebed");
        m_m3surfaceContainerHigh = QColor("#f1e5e8");
        m_m3surfaceContainerHighest = QColor("#ebdfe2");
        m_m3onSurface = QColor("#22191c");
        m_m3surfaceVariant = QColor("#f2dde2");
        m_m3onSurfaceVariant = QColor("#514347");
        m_m3inverseSurface = QColor("#372e30");
        m_m3inverseOnSurface = QColor("#faeeef");
        m_m3outline = QColor("#837377");
        m_m3outlineVariant = QColor("#d5c2c6");
        m_m3shadow = QColor("#000000");
        m_m3scrim = QColor("#000000");
        m_m3surfaceTint = QColor("#8b4a62");
        m_m3primary = QColor("#8b4a62");
        m_m3onPrimary = QColor("#ffffff");
        m_m3primaryContainer = QColor("#ffd9e3");
        m_m3onPrimaryContainer = QColor("#39071f");
        m_m3secondary = QColor("#745660");
        m_m3onSecondary = QColor("#ffffff");
        m_m3secondaryContainer = QColor("#ffd9e3");
        m_m3onSecondaryContainer = QColor("#2b151d");
        m_m3tertiary = QColor("#7e5635");
        m_m3onTertiary = QColor("#ffffff");
        m_m3tertiaryContainer = QColor("#ffdcc3");
        m_m3onTertiaryContainer = QColor("#2f1500");
        m_m3error = QColor("#ba1a1a");
        m_m3onError = QColor("#ffffff");
        m_m3errorContainer = QColor("#ffdad6");
        m_m3onErrorContainer = QColor("#410002");
    }
    emit paletteChanged();
}

ColoursSingleton::ColoursSingleton(QObject* parent)
    : QObject(parent)
    , m_palette(new M3Palette(false, this))
    , m_tPalette(new M3Palette(false, this)) {
    // Check for scheme.json in ~/.local/state/caelestia/scheme.json
    QString home = QDir::homePath();
    QString stateScheme = home + "/.local/state/caelestia/scheme.json";
    if (QFile::exists(stateScheme)) {
        loadSchemeFile(stateScheme);
    }
}

void ColoursSingleton::setLight(bool light) {
    if (m_light != light) {
        m_light = light;
        m_palette->loadDefaults(m_light);
        m_tPalette->loadDefaults(m_light);
        emit lightChanged();
    }
}

void ColoursSingleton::loadSchemeFile(const QString& filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return;

    auto root = doc.object();
    m_light = (root.value("mode").toString() == "light");

    auto colours = root.value("colours").toObject();
    for (auto it = colours.constBegin(); it != colours.constEnd(); ++it) {
        QString propName = "m3" + it.key();
        QColor val(QString("#") + it.value().toString());
        if (val.isValid()) {
            m_palette->setProperty(propName.toUtf8().constData(), val);
            m_tPalette->setProperty(propName.toUtf8().constData(), val);
        }
    }
}

} // namespace prism::config
