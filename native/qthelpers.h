#pragma once

// The few Qt facilities the Rust side reaches through C++: QSettings (so the
// existing atlas.conf keeps its exact format), the shared MIME database,
// theme icons, QLocale date formatting, the clipboard, native drags, and
// application/engine setup.

#include <QSize>
#include <cstdint>
#include <QString>
#include <QStringList>
#include <QVariant>

class QQmlApplicationEngine;

namespace atlas::native {

struct ClipboardState;

// Application lifecycle
void preApplicationSetup();
void setupApplication(const QString& version);
void installEngine(QQmlApplicationEngine& engine);
void clearIconCache();
// Switches Tokens to the TTY look (see TokensSingleton::setTty).
void setTtyTokens(bool tty, const QString& preferredMono);
QStringList fontFamilies();

// QSettings. scope 0 is ("astra-atlas", "atlas"); 1 and 2 are the legacy
// ("caelestia", "prism") and ("Caelestia", "Prism") stores read for fallbacks.
bool settingsContains(int scope, const QString& key);
bool settingsBool(int scope, const QString& key, bool fallback);
int settingsInt(int scope, const QString& key, int fallback);
double settingsDouble(int scope, const QString& key, double fallback);
QString settingsString(int scope, const QString& key, const QString& fallback);
QStringList settingsStringList(int scope, const QString& key);
void settingsSetBool(const QString& key, bool value);
void settingsSetInt(const QString& key, int value);
void settingsSetDouble(const QString& key, double value);
void settingsSetString(const QString& key, const QString& value);
void settingsSetStringList(const QString& key, const QStringList& value);
void settingsRemove(const QString& key);

// Shared MIME database
QString mimeNameForFile(const QString& path);
QString mimeComment(const QString& name);
bool mimeInherits(const QString& name, const QString& parent);
QStringList mimeAliases(const QString& name);

// Icon theme
bool hasThemeIcon(const QString& name);
QStringList iconThemeSearchPaths();

// QKeySequence, for the shortcut registry
QString normalizeKeySequence(const QString& sequence);
QString keySequenceFromKey(int key, int modifiers);
bool isBareKeySequence(const QString& sequence);

// Misc
QString formatDateTime(std::int64_t msecs, int format, const QString& pattern);
int queryKeyboardModifiers();
QSize imageSize(const QString& path);

// Clipboard; changes are reported to Rust's clipboard_changed().
void clipboardWatch();
void clipboardSetFiles(const QStringList& paths, bool cut);
void clipboardSetText(const QString& text);
ClipboardState clipboardRead();

// Starts a drag of local files on the next event loop turn; reports to
// Rust's native_drag_finished() once it ends.
void startNativeDrag(const QStringList& paths, int cardWidth, int cardHeight, int iconSize);

} // namespace atlas::native
