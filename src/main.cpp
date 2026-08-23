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
#include "core/iconprovider.hpp"
#include "core/papiruswatcher.hpp"
#include "core/thumbnailprovider.hpp"
#include "core/placesmodel.hpp"
#include "core/drivemanager.hpp"
#include "core/networkmanager.hpp"
#include "core/runnergame.hpp"
#include "models/filesystemmodel.hpp"

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
    app.setApplicationName("prism");
    app.setApplicationDisplayName("Prism");
    app.setOrganizationName("prism");
    app.setApplicationVersion("1.0.0");

    // Load fonts, window icon, and initialize icon theme engine on main thread
    QFontDatabase::addApplicationFont(":/qt/qml/prism/assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont(":/qt/qml/prism/assets/fonts/MaterialSymbolsRounded.ttf");
    app.setWindowIcon(QIcon(":/qt/qml/prism/assets/prism.svg"));
    (void)QIcon::fromTheme("folder");

    QCommandLineParser parser;
    parser.setApplicationDescription("Prism: Modern Material 3 File Manager & File Picker");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption pickerOption(QStringList{ "p", "picker" }, "Launch in file picker mode");
    QCommandLineOption titleOption(QStringList{ "t", "title" }, "Dialog title", "title");
    QCommandLineOption dirOption(QStringList{ "d", "directory" }, "Initial directory", "dir");
    QCommandLineOption filterOption(QStringList{ "f", "filter" }, "File extensions filter, e.g. 'png,jpg' or '*.png,*.jpg'", "filter");
    QCommandLineOption filterLabelOption(QStringList{ "l", "filter-label" }, "Filter label, e.g. 'Images'", "label");
    QCommandLineOption dirOnlyOption(QStringList{ "directory-only" }, "Select directories only");
    QCommandLineOption hiddenOption(QStringList{ "hidden" }, "Show hidden files by default");
    QCommandLineOption lightOption(QStringList{ "light" }, "Force light theme");
    QCommandLineOption darkOption(QStringList{ "dark" }, "Force dark theme");

    parser.addOption(pickerOption);
    parser.addOption(titleOption);
    parser.addOption(dirOption);
    parser.addOption(filterOption);
    parser.addOption(filterLabelOption);
    parser.addOption(dirOnlyOption);
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
        QFileInfo fi(p);
        if (fi.exists()) {
            initialDir = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();
        }
    }

    bool isPickerMode = parser.isSet(pickerOption) || parser.isSet(filterOption) || parser.isSet(dirOnlyOption);

    auto* controller = prism::core::AppController::instance();
    controller->setTitle(parser.isSet(titleOption) ? parser.value(titleOption) : QStringLiteral("Select a file"));
    if (!initialDir.isEmpty()) {
        controller->setInitialDirectory(initialDir);
    }
    controller->setFilterLabel(parser.isSet(filterLabelOption) ? parser.value(filterLabelOption) : QStringLiteral("All files"));

    if (parser.isSet(filterOption)) {
        QString filterStr = parser.value(filterOption);
        QStringList filters;
        for (QString f : filterStr.split(QChar(','), Qt::SkipEmptyParts)) {
            f = f.trimmed();
            if (f.startsWith("*."))
                f = f.mid(2);
            else if (f.startsWith('.'))
                f = f.mid(1);
            if (!f.isEmpty())
                filters << f;
        }
        if (filters.isEmpty())
            filters << "*";
        controller->setFilters(filters);
    }
    controller->setDirectoryOnly(parser.isSet(dirOnlyOption));
    if (parser.isSet(hiddenOption)) {
        controller->setShowHidden(true);
    }

    auto* colours = new prism::config::ColoursSingleton(&app);
    if (parser.isSet(lightOption)) {
        colours->setLight(true);
    } else if (parser.isSet(darkOption)) {
        colours->setLight(false);
    }

    auto* tokens = prism::config::TokensSingleton::instance();
    auto* fileUtils = new prism::core::FileUtils(&app);
    auto* fileOps = prism::core::FileOperations::instance();
    auto* catboxUploader = prism::core::CatboxUploader::instance();
    auto* tabManager = prism::controllers::TabManager::instance();

    // If explicit path was provided on command line, navigate there
    if (!initialDir.isEmpty() && tabManager->currentTab()) {
        tabManager->currentTab()->setCurrentPath(initialDir);
    }

    auto* appIntegration = prism::core::AppIntegration::instance();
    auto* papirusWatcher = prism::core::PapirusWatcher::instance();
    auto* placesModel = prism::core::PlacesModel::instance();
    auto* driveManager = new prism::core::DriveManager(&app);
    auto* networkManager = prism::core::NetworkManager::instance();

    QQmlApplicationEngine engine;
    engine.addImageProvider("icon", new prism::core::IconImageProvider());
    engine.addImageProvider("thumb", new prism::core::ThumbnailImageProvider());

    // Register singletons and types into QML context
    engine.rootContext()->setContextProperty("Colours", colours);
    engine.rootContext()->setContextProperty("Tokens", tokens);
    engine.rootContext()->setContextProperty("AppController", controller);
    engine.rootContext()->setContextProperty("FileUtils", fileUtils);
    engine.rootContext()->setContextProperty("FileOperations", fileOps);
    engine.rootContext()->setContextProperty("CatboxUploader", catboxUploader);
    engine.rootContext()->setContextProperty("TabManager", tabManager);
    engine.rootContext()->setContextProperty("AppIntegration", appIntegration);
    engine.rootContext()->setContextProperty("PapirusWatcher", papirusWatcher);
    engine.rootContext()->setContextProperty("PlacesModel", placesModel);
    engine.rootContext()->setContextProperty("DriveManager", driveManager);
    engine.rootContext()->setContextProperty("NetworkManager", networkManager);
    engine.rootContext()->setContextProperty("RunnerGame", prism::core::RunnerGame::instance());
    engine.rootContext()->setContextProperty("isPickerMode", isPickerMode);

    const QUrl url(QStringLiteral("qrc:/qt/qml/prism/qml/main.qml"));
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
