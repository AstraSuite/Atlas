#include <QCommandLineParser>
#include <QDir>
#include <QFileInfo>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSurfaceFormat>

#include <QSettings>

#include "core/recentfiles.hpp"
#include <QMouseEvent>

#include "config/colours.hpp"
#include "config/tokens.hpp"
#include "controllers/tabmanager.hpp"
#include "core/appcontroller.hpp"
#include "core/appintegration.hpp"
#include "core/filemetadata.hpp"
#include "core/fileoperations.hpp"
#include "core/catboxuploader.hpp"
#include "core/fileutils.hpp"
#include "core/mediatools.hpp"
#include "core/iconprovider.hpp"
#include "core/papiruswatcher.hpp"
#include "core/thumbnailprovider.hpp"
#include "core/placesmodel.hpp"
#include "core/drivemanager.hpp"
#include "core/networkmanager.hpp"
#include "core/runnergame.hpp"
#include "models/filesystemmodel.hpp"

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

int main(int argc, char* argv[]) {
    // Explicitly configure 32-bit RGBA8888 surface format to avoid RGB565 color quantization
    QSurfaceFormat format;
    format.setRedBufferSize(8);
    format.setGreenBufferSize(8);
    format.setBlueBufferSize(8);
    format.setAlphaBufferSize(8);
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);
    app.setApplicationName("atlas");
    app.setApplicationDisplayName("Atlas");
    app.setOrganizationName("astra-atlas");
    app.setApplicationVersion("1.0.0");

    adoptPreviousSettings();

    // Load fonts, window icon, and initialize icon theme engine on main thread
    QFontDatabase::addApplicationFont(":/qt/qml/atlas/assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont(":/qt/qml/atlas/assets/fonts/MaterialSymbolsRounded.ttf");
    app.setWindowIcon(QIcon(":/qt/qml/atlas/assets/atlas.svg"));
    (void)QIcon::fromTheme("folder");

    QCommandLineParser parser;
    parser.setApplicationDescription("Atlas: Modern Material 3 File Manager");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption dirOption(QStringList{ "d", "directory" }, "Initial directory", "dir");
    QCommandLineOption hiddenOption(QStringList{ "hidden" }, "Show hidden files by default");
    QCommandLineOption lightOption(QStringList{ "light" }, "Force light theme");
    QCommandLineOption darkOption(QStringList{ "dark" }, "Force dark theme");

    parser.addOption(dirOption);
    parser.addOption(hiddenOption);
    parser.addOption(lightOption);
    parser.addOption(darkOption);
    parser.addPositionalArgument("path", "Directory or file path to open", "[path]");

    parser.process(app);

    QString initialDir;
    if (parser.isSet(dirOption)) {
        initialDir = parser.value(dirOption);
        if (initialDir.startsWith(QLatin1String("file://"))) {
            initialDir = QUrl(initialDir).toLocalFile();
        }
        QFileInfo fi(initialDir);
        if (fi.exists() && !fi.isDir()) {
            initialDir = fi.absolutePath();
        }
    }
    const QStringList posArgs = parser.positionalArguments();
    if (!posArgs.isEmpty()) {
        QString p = posArgs.first();
        if (p.startsWith(QLatin1String("file://"))) {
            p = QUrl(p).toLocalFile();
        }
        if (atlas::core::RecentFiles::isRecentPath(p)) {
            initialDir = p;
        } else {
            QFileInfo fi(p);
            if (fi.exists()) {
                initialDir = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();
            }
        }
    }

    auto* controller = atlas::core::AppController::instance();
    if (!initialDir.isEmpty()) {
        controller->setInitialDirectory(initialDir);
    }
    if (parser.isSet(hiddenOption)) {
        controller->setShowHidden(true);
    }

    auto* colours = new atlas::config::ColoursSingleton(&app);
    if (parser.isSet(lightOption)) {
        colours->setLight(true);
    } else if (parser.isSet(darkOption)) {
        colours->setLight(false);
    }

    auto* tokens = atlas::config::TokensSingleton::instance();
    auto* fileUtils = new atlas::core::FileUtils(&app);
    auto* fileOps = atlas::core::FileOperations::instance();
    auto* catboxUploader = atlas::core::CatboxUploader::instance();
    auto* tabManager = atlas::controllers::TabManager::instance();

    // If explicit path was provided on command line, navigate there
    if (!initialDir.isEmpty() && tabManager->currentTab()) {
        tabManager->currentTab()->setCurrentPath(initialDir);
    }

    auto* appIntegration = atlas::core::AppIntegration::instance();
    auto* papirusWatcher = atlas::core::PapirusWatcher::instance();
    auto* placesModel = atlas::core::PlacesModel::instance();
    auto* driveManager = new atlas::core::DriveManager(&app);
    auto* networkManager = atlas::core::NetworkManager::instance();

    QQmlApplicationEngine engine;
    engine.addImageProvider("icon", new atlas::core::IconImageProvider());
    engine.addImageProvider("thumb", new atlas::core::ThumbnailImageProvider());

    // Register singletons and types into QML context
    engine.rootContext()->setContextProperty("Colours", colours);
    engine.rootContext()->setContextProperty("Tokens", tokens);
    engine.rootContext()->setContextProperty("AppController", controller);
    engine.rootContext()->setContextProperty("FileUtils", fileUtils);
    engine.rootContext()->setContextProperty("FileOperations", fileOps);
    engine.rootContext()->setContextProperty("MediaTools", atlas::core::MediaTools::instance());
    engine.rootContext()->setContextProperty("CatboxUploader", catboxUploader);
    engine.rootContext()->setContextProperty("TabManager", tabManager);
    engine.rootContext()->setContextProperty("AppIntegration", appIntegration);
    engine.rootContext()->setContextProperty("PapirusWatcher", papirusWatcher);
    engine.rootContext()->setContextProperty("PlacesModel", placesModel);
    engine.rootContext()->setContextProperty("DriveManager", driveManager);
    engine.rootContext()->setContextProperty("NetworkManager", networkManager);
    engine.rootContext()->setContextProperty("RunnerGame", atlas::core::RunnerGame::instance());

    const QUrl url(QStringLiteral("qrc:/qt/qml/atlas/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QGuiApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
