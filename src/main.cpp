#include <QCommandLineParser>
#include <QDir>
#include <QFileInfo>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSurfaceFormat>

#include "config/colours.hpp"
#include "config/tokens.hpp"
#include "controllers/tabmanager.hpp"
#include "core/appcontroller.hpp"
#include "core/appintegration.hpp"
#include "core/filemetadata.hpp"
#include "core/fileoperations.hpp"
#include "core/fileutils.hpp"
#include "core/iconprovider.hpp"
#include "core/placesmodel.hpp"
#include "core/drivemanager.hpp"
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
    app.setApplicationName("Prism");
    app.setApplicationDisplayName("Prism");
    app.setOrganizationName("Caelestia");
    app.setApplicationVersion("1.0.0");

    // Load fonts
    QFontDatabase::addApplicationFont(":/qt/qml/prism/assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont(":/qt/qml/prism/assets/fonts/MaterialSymbolsRounded.ttf");

    QCommandLineParser parser;
    parser.setApplicationDescription("Prism: Modern Material 3 File Manager & File Picker");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption pickerOption(QStringList{ "p", "picker" }, "Launch in file picker mode");
    QCommandLineOption titleOption(QStringList{ "t", "title" }, "Dialog title", "title", "Select a file");
    QCommandLineOption dirOption(QStringList{ "d", "directory" }, "Initial directory", "dir", QDir::homePath());
    QCommandLineOption filterOption(QStringList{ "f", "filter" }, "File extensions filter, e.g. 'png,jpg' or '*.png,*.jpg'", "filter", "*");
    QCommandLineOption filterLabelOption(QStringList{ "l", "filter-label" }, "Filter label, e.g. 'Images'", "label", "All files");
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

    QString initialDir = parser.value(dirOption);
    const QStringList posArgs = parser.positionalArguments();
    if (!posArgs.isEmpty()) {
        QString p = posArgs.first();
        if (QDir(p).exists()) {
            initialDir = QFileInfo(p).absoluteFilePath();
        } else if (QFile::exists(p)) {
            initialDir = QFileInfo(p).absolutePath();
        }
    }

    bool isPickerMode = parser.isSet(pickerOption) || parser.isSet(titleOption) || parser.isSet(filterOption) || parser.isSet(dirOnlyOption);

    auto* controller = prism::core::AppController::instance();
    controller->setTitle(parser.value(titleOption));
    controller->setInitialDirectory(initialDir);
    controller->setFilterLabel(parser.value(filterLabelOption));

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
    controller->setDirectoryOnly(parser.isSet(dirOnlyOption));
    controller->setShowHidden(parser.isSet(hiddenOption));

    auto* colours = new prism::config::ColoursSingleton(&app);
    if (parser.isSet(lightOption)) {
        colours->setLight(true);
    } else if (parser.isSet(darkOption)) {
        colours->setLight(false);
    }

    auto* tokens = prism::config::TokensSingleton::instance();
    auto* fileUtils = new prism::core::FileUtils(&app);
    auto* fileOps = prism::core::FileOperations::instance();
    auto* tabManager = prism::controllers::TabManager::instance();
    if (!initialDir.isEmpty() && tabManager->currentTab()) {
        tabManager->currentTab()->setCurrentPath(initialDir);
    }
    auto* appIntegration = prism::core::AppIntegration::instance();
    auto* placesModel = new prism::core::PlacesModel(&app);
    auto* driveManager = new prism::core::DriveManager(&app);

    QQmlApplicationEngine engine;
    engine.addImageProvider("icon", new prism::core::IconImageProvider());

    // Register singletons and types into QML context
    engine.rootContext()->setContextProperty("Colours", colours);
    engine.rootContext()->setContextProperty("Tokens", tokens);
    engine.rootContext()->setContextProperty("AppController", controller);
    engine.rootContext()->setContextProperty("FileUtils", fileUtils);
    engine.rootContext()->setContextProperty("FileOperations", fileOps);
    engine.rootContext()->setContextProperty("TabManager", tabManager);
    engine.rootContext()->setContextProperty("AppIntegration", appIntegration);
    engine.rootContext()->setContextProperty("PlacesModel", placesModel);
    engine.rootContext()->setContextProperty("DriveManager", driveManager);
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
