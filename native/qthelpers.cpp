#include "qthelpers.h"

#include "atlas/src/bridge/native.cxx.h"
#include "providers/iconprovider.hpp"

#include <QBuffer>
#include <QClipboard>
#include <QDrag>
#include <QFileInfo>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QImageReader>
#include <QLocale>
#include <QMimeData>
#include <QMimeDatabase>
#include <QPainter>
#include <QPixmap>
#include <QPointer>
#include <QSettings>
#include <QSurfaceFormat>
#include <QTimer>
#include <QUrl>

namespace atlas::native {

void preApplicationSetup() {
    // Explicit 32-bit RGBA8888 surface format to avoid RGB565 colour banding.
    QSurfaceFormat format;
    format.setRedBufferSize(8);
    format.setGreenBufferSize(8);
    format.setBlueBufferSize(8);
    format.setAlphaBufferSize(8);
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);
}

static void adoptPreviousSettings() {
    QSettings target("astra-atlas", "atlas");
    if (!target.allKeys().isEmpty())
        return;

    QSettings source("prism", "prism");
    const QStringList keys = source.allKeys();
    if (keys.isEmpty())
        return;

    for (const QString& key : keys)
        target.setValue(key, source.value(key));
    target.sync();
}

void setupApplication(const QString& version) {
    QGuiApplication::setApplicationName("atlas");
    QGuiApplication::setApplicationDisplayName("Atlas");
    QGuiApplication::setOrganizationName("astra-atlas");
    QGuiApplication::setApplicationVersion(version);

    adoptPreviousSettings();

    QFontDatabase::addApplicationFont(":/qt/qml/atlas/assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont(":/qt/qml/atlas/assets/fonts/MaterialSymbolsRounded.ttf");
    QGuiApplication::setWindowIcon(QIcon(":/qt/qml/atlas/assets/atlas.svg"));
    // Initialise the icon theme engine on the main thread.
    (void)QIcon::fromTheme("folder");
}

void clearIconCache() {
    atlas::core::IconImageProvider::clearCache();
}

// ---- QSettings ----

static QSettings& store(int scope) {
    static QSettings current("astra-atlas", "atlas");
    static QSettings legacy1("caelestia", "prism");
    static QSettings legacy2("Caelestia", "Prism");
    switch (scope) {
    case 1: return legacy1;
    case 2: return legacy2;
    default: return current;
    }
}

bool settingsContains(int scope, const QString& key) {
    return store(scope).contains(key);
}

bool settingsBool(int scope, const QString& key, bool fallback) {
    return store(scope).value(key, fallback).toBool();
}

int settingsInt(int scope, const QString& key, int fallback) {
    return store(scope).value(key, fallback).toInt();
}

double settingsDouble(int scope, const QString& key, double fallback) {
    return store(scope).value(key, fallback).toDouble();
}

QString settingsString(int scope, const QString& key, const QString& fallback) {
    return store(scope).value(key, fallback).toString();
}

QStringList settingsStringList(int scope, const QString& key) {
    return store(scope).value(key).toStringList();
}

void settingsSetBool(const QString& key, bool value) {
    store(0).setValue(key, value);
}

void settingsSetInt(const QString& key, int value) {
    store(0).setValue(key, value);
}

void settingsSetDouble(const QString& key, double value) {
    store(0).setValue(key, value);
}

void settingsSetString(const QString& key, const QString& value) {
    store(0).setValue(key, value);
}

void settingsSetStringList(const QString& key, const QStringList& value) {
    store(0).setValue(key, value);
}

void settingsRemove(const QString& key) {
    store(0).remove(key);
}

// ---- MIME ----

static const QMimeDatabase& mimeDb() {
    static const QMimeDatabase db;
    return db;
}

QString mimeNameForFile(const QString& path) {
    if (path.isEmpty())
        return {};
    return mimeDb().mimeTypeForFile(path).name();
}

QString mimeNameForFileName(const QString& fileName) {
    return mimeDb().mimeTypeForFile(fileName, QMimeDatabase::MatchExtension).name();
}

QString mimeComment(const QString& name) {
    return mimeDb().mimeTypeForName(name).comment();
}

QString mimeIconName(const QString& name) {
    return mimeDb().mimeTypeForName(name).iconName();
}

QString mimeGenericIconName(const QString& name) {
    return mimeDb().mimeTypeForName(name).genericIconName();
}

bool mimeInherits(const QString& name, const QString& parent) {
    return mimeDb().mimeTypeForName(name).inherits(parent);
}

QStringList mimeAliases(const QString& name) {
    return mimeDb().mimeTypeForName(name).aliases();
}

// ---- Icons ----

bool hasThemeIcon(const QString& name) {
    return QIcon::hasThemeIcon(name);
}

QStringList iconThemeSearchPaths() {
    return QIcon::themeSearchPaths();
}

// ---- Misc ----

QString formatDateTime(std::int64_t msecs, int format, const QString& pattern) {
    const QDateTime dt = QDateTime::fromMSecsSinceEpoch(msecs);
    switch (format) {
    case 0:
        return QLocale::system().toString(dt, QLocale::ShortFormat);
    case 2:
        return QLocale::system().toString(dt, QLocale::LongFormat);
    case 3: {
        const QString rendered = QLocale::system().toString(dt, pattern);
        return rendered.isEmpty() ? dt.toString(QStringLiteral("yyyy-MM-dd hh:mm")) : rendered;
    }
    default:
        return dt.toString(QStringLiteral("yyyy-MM-dd hh:mm"));
    }
}

int queryKeyboardModifiers() {
    return static_cast<int>(QGuiApplication::queryKeyboardModifiers());
}

QSize imageSize(const QString& path) {
    QImageReader reader(path);
    return reader.size();
}

// ---- Clipboard ----

void clipboardWatch() {
    QObject::connect(QGuiApplication::clipboard(), &QClipboard::dataChanged, qApp, []() { clipboard_changed(); });
}

void clipboardSetFiles(const QStringList& paths, bool cut) {
    QList<QUrl> urls;
    urls.reserve(paths.size());
    for (const QString& path : paths)
        urls.append(QUrl::fromLocalFile(path));

    auto* mimeData = new QMimeData();
    mimeData->setUrls(urls);
    mimeData->setData(QStringLiteral("application/x-kde-cutselection"), cut ? QByteArrayLiteral("1") : QByteArrayLiteral("0"));
    QGuiApplication::clipboard()->setMimeData(mimeData);
}

void clipboardSetText(const QString& text) {
    QGuiApplication::clipboard()->setText(text);
}

ClipboardState clipboardRead() {
    ClipboardState state;
    state.cut = false;
    const QMimeData* mimeData = QGuiApplication::clipboard()->mimeData();
    if (!mimeData)
        return state;

    if (mimeData->hasFormat(QStringLiteral("text/uri-list"))) {
        const QByteArray cutSelection = mimeData->data(QStringLiteral("application/x-kde-cutselection"));
        state.cut = !cutSelection.isEmpty() && cutSelection.at(0) == '1';
        for (const QUrl& url : mimeData->urls()) {
            if (url.isLocalFile())
                state.files.append(url.toLocalFile());
        }
    }

    // Image data (screenshots, copied images, ...), re-encoded as PNG.
    QImage image;
    if (mimeData->hasImage())
        image = qvariant_cast<QImage>(mimeData->imageData());
    if (image.isNull()) {
        static const char* kImageFormats[] = { "image/png", "image/jpeg", "image/bmp", "image/gif", "image/webp" };
        for (const char* fmt : kImageFormats) {
            if (mimeData->hasFormat(fmt)) {
                image = QImage::fromData(mimeData->data(fmt));
                if (!image.isNull())
                    break;
            }
        }
    }
    if (!image.isNull()) {
        QByteArray pngData;
        QBuffer buffer(&pngData);
        buffer.open(QIODevice::WriteOnly);
        image.save(&buffer, "PNG");
        state.imagePngBase64 = QString::fromLatin1(pngData.toBase64());
    }
    return state;
}

// ---- Native drag ----

static QString dragIconName(const QFileInfo& fi) {
    if (fi.isDir()) {
        static const QStringList specialDirs = { "Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos" };
        if (specialDirs.contains(fi.fileName())) {
            const QString name = QString("folder-%1").arg(fi.fileName().toLower());
            if (QIcon::hasThemeIcon(name))
                return name;
        }
        return QStringLiteral("inode-directory");
    }
    const QMimeType mime = mimeDb().mimeTypeForFile(fi);
    QString mimeIcon = mime.name();
    mimeIcon.replace('/', '-');
    if (QIcon::hasThemeIcon(mimeIcon))
        return mimeIcon;
    if (QIcon::hasThemeIcon(mime.iconName()))
        return mime.iconName();
    if (QIcon::hasThemeIcon(mime.genericIconName()))
        return mime.genericIconName();
    return QStringLiteral("text-plain");
}

// A card like the grid view's: icon or thumbnail, elided name, and a "+N"
// badge when several items are dragged. Colours are the default dark palette.
static QPixmap renderDragCard(const QStringList& paths, int cardW, int cardH, int iSize) {
    QPixmap pixmap(cardW, cardH);
    pixmap.fill(Qt::transparent);

    QPainter painter(&pixmap);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::SmoothPixmapTransform);
    painter.setRenderHint(QPainter::TextAntialiasing);

    const QColor cardBg("#5a3f48");
    const QColor onCard("#ffd9e3");
    const QColor primary("#ffb0ca");
    const QColor onPrimary("#541d34");

    painter.setBrush(cardBg);
    painter.setPen(Qt::NoPen);
    painter.drawRoundedRect(0, 0, cardW, cardH, 16, 16);

    const QFileInfo firstFi(paths.first());
    QPixmap iconPix;
    const QString suffix = firstFi.suffix().toLower();
    if (suffix == "png" || suffix == "jpg" || suffix == "jpeg" || suffix == "webp" || suffix == "svg") {
        const QImage img(firstFi.filePath());
        if (!img.isNull())
            iconPix = QPixmap::fromImage(img.scaled(iSize, iSize, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    }
    if (iconPix.isNull()) {
        QIcon icon = QIcon::fromTheme(dragIconName(firstFi));
        if (icon.isNull())
            icon = QIcon::fromTheme("folder");
        if (icon.isNull())
            icon = QIcon::fromTheme("text-plain");
        iconPix = icon.pixmap(iSize, iSize);
    }

    const int iconY = 8;
    painter.drawPixmap((cardW - iconPix.width()) / 2, iconY, iconPix);

    painter.setPen(onCard);
    QFont font = qApp->font();
    font.setPixelSize(12);
    font.setWeight(QFont::Normal);
    painter.setFont(font);
    QString label = firstFi.fileName();
    if (label.isEmpty())
        label = firstFi.filePath();
    const QRect textRect(8, iconY + iSize + 6, cardW - 16, cardH - (iconY + iSize + 6) - 4);
    painter.drawText(textRect, Qt::AlignHCenter | Qt::AlignTop, painter.fontMetrics().elidedText(label, Qt::ElideMiddle, cardW - 16));

    if (paths.size() > 1) {
        const QRect badgeRect(cardW - 26 - 6, 6, 26, 20);
        painter.setBrush(primary);
        painter.setPen(Qt::NoPen);
        painter.drawRoundedRect(badgeRect, 10, 10);
        painter.setPen(onPrimary);
        QFont badgeFont = painter.font();
        badgeFont.setPointSize(8);
        badgeFont.setBold(true);
        painter.setFont(badgeFont);
        painter.drawText(badgeRect, Qt::AlignCenter, QString("+%1").arg(paths.size() - 1));
    }
    painter.end();
    return pixmap;
}

void startNativeDrag(const QStringList& paths, int cardWidth, int cardHeight, int iconSize) {
    if (paths.isEmpty()) {
        native_drag_finished();
        return;
    }

    QList<QUrl> urls;
    for (const QString& path : paths)
        urls.append(QUrl::fromLocalFile(path));
    auto* mimeData = new QMimeData();
    mimeData->setUrls(urls);
    mimeData->setText(paths.join("\n"));

    const int cardW = cardWidth > 0 ? cardWidth : 140;
    const int cardH = cardHeight > 0 ? cardHeight : 110;
    const int iSize = iconSize > 0 ? iconSize : 48;

    auto* drag = new QDrag(qApp);
    drag->setMimeData(mimeData);
    drag->setPixmap(renderDragCard(paths, cardW, cardH, iSize));
    drag->setHotSpot(QPoint(cardW / 2, cardH / 2));

    // Defer exec() out of the caller's QML signal handler: exec() runs a
    // nested event loop, and if the dragged item gets destroyed mid-drag
    // (e.g. switching tabs via hover-to-open resets the view), returning
    // into the destroyed handler frame would abort.
    QPointer<QDrag> dragGuard(drag);
    QTimer::singleShot(0, qApp, [dragGuard]() {
        if (dragGuard)
            dragGuard->exec(Qt::CopyAction | Qt::MoveAction, Qt::CopyAction);
        if (dragGuard)
            dragGuard->deleteLater();
        native_drag_finished();
    });
}

} // namespace atlas::native
