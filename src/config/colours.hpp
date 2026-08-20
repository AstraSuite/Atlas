#pragma once

#include <QObject>
#include <QColor>
#include <QFileSystemWatcher>
#include <qqmlintegration.h>

namespace prism::config {

class M3Palette : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

#define PALETTE_PROP(name) \
    Q_PROPERTY(QColor name READ name WRITE set_##name NOTIFY paletteChanged) \
public: \
    QColor name() const { return m_##name; } \
    void set_##name(const QColor& c) { if (m_##name != c) { m_##name = c; emit paletteChanged(); } } \
private: \
    QColor m_##name;

    PALETTE_PROP(m3background)
    PALETTE_PROP(m3onBackground)
    PALETTE_PROP(m3surface)
    PALETTE_PROP(m3surfaceDim)
    PALETTE_PROP(m3surfaceBright)
    PALETTE_PROP(m3surfaceContainerLowest)
    PALETTE_PROP(m3surfaceContainerLow)
    PALETTE_PROP(m3surfaceContainer)
    PALETTE_PROP(m3surfaceContainerHigh)
    PALETTE_PROP(m3surfaceContainerHighest)
    PALETTE_PROP(m3onSurface)
    PALETTE_PROP(m3surfaceVariant)
    PALETTE_PROP(m3onSurfaceVariant)
    PALETTE_PROP(m3inverseSurface)
    PALETTE_PROP(m3inverseOnSurface)
    PALETTE_PROP(m3outline)
    PALETTE_PROP(m3outlineVariant)
    PALETTE_PROP(m3shadow)
    PALETTE_PROP(m3scrim)
    PALETTE_PROP(m3surfaceTint)
    PALETTE_PROP(m3primary)
    PALETTE_PROP(m3onPrimary)
    PALETTE_PROP(m3primaryContainer)
    PALETTE_PROP(m3onPrimaryContainer)
    PALETTE_PROP(m3secondary)
    PALETTE_PROP(m3onSecondary)
    PALETTE_PROP(m3secondaryContainer)
    PALETTE_PROP(m3onSecondaryContainer)
    PALETTE_PROP(m3tertiary)
    PALETTE_PROP(m3onTertiary)
    PALETTE_PROP(m3tertiaryContainer)
    PALETTE_PROP(m3onTertiaryContainer)
    PALETTE_PROP(m3error)
    PALETTE_PROP(m3onError)
    PALETTE_PROP(m3errorContainer)
    PALETTE_PROP(m3onErrorContainer)

#undef PALETTE_PROP

public:
    explicit M3Palette(bool light = false, QObject* parent = nullptr);
    void loadDefaults(bool light);

signals:
    void paletteChanged();
};

class ColoursSingleton : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool light READ light WRITE setLight NOTIFY lightChanged)
    Q_PROPERTY(prism::config::M3Palette* palette READ palette CONSTANT)
    Q_PROPERTY(prism::config::M3Palette* tPalette READ tPalette CONSTANT)

public:
    explicit ColoursSingleton(QObject* parent = nullptr);

    bool light() const { return m_light; }
    void setLight(bool light);

    M3Palette* palette() const { return m_palette; }
    M3Palette* tPalette() const { return m_tPalette; }

    Q_INVOKABLE void reload();
    void loadSchemeFile(const QString& filePath);

signals:
    void lightChanged();

private:
    bool m_light = false;
    M3Palette* m_palette = nullptr;
    M3Palette* m_tPalette = nullptr;
    QFileSystemWatcher m_watcher;
    QString m_schemeFilePath;
};

} // namespace prism::config
