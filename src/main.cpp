#include "config/colours.hpp"
#include "config/font.hpp"
#include "config/fontbuilder.hpp"
#include "config/tokens.hpp"
#include "core/appcontroller.hpp"
#include "core/fileutils.hpp"
#include "core/iconprovider.hpp"
#include "models/filesystemmodel.hpp"

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QString>
#include <QStringList>

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("Prism");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("Caelestia");
    app.setOrganizationDomain("caelestia.org");

    // Load fonts
    QFontDatabase::addApplicationFont(":/prism/assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont(":/prism/assets/fonts/MaterialSymbolsRounded.ttf");
    QFontDatabase::addApplicationFont("assets/fonts/GoogleSansFlex.ttf");
    QFontDatabase::addApplicationFont("assets/fonts/MaterialSymbolsRounded.ttf");

    // Command line parser
    QCommandLineParser parser;
    parser.setApplicationDescription("Prism: Material 3 Standalone File Picker");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption titleOption(QStringList{ "t", "title" }, "Dialog title", "title", "Select a file");
    QCommandLineOption dirOption(QStringList{ "d", "directory" }, "Initial directory", "dir", QDir::homePath());
    QCommandLineOption filterOption(QStringList{ "f", "filter" }, "File extensions filter, e.g. 'png,jpg' or '*.png,*.jpg'", "filter", "*");
    QCommandLineOption filterLabelOption(QStringList{ "l", "filter-label" }, "Filter label, e.g. 'Images'", "label", "All files");
    QCommandLineOption dirOnlyOption(QStringList{ "directory-only" }, "Select directories only");
    QCommandLineOption hiddenOption(QStringList{ "hidden" }, "Show hidden files by default");
    QCommandLineOption lightOption(QStringList{ "light" }, "Force light theme");
    QCommandLineOption darkOption(QStringList{ "dark" }, "Force dark theme");

    parser.addOption(titleOption);
    parser.addOption(dirOption);
    parser.addOption(filterOption);
    parser.addOption(filterLabelOption);
    parser.addOption(dirOnlyOption);
    parser.addOption(hiddenOption);
    parser.addOption(lightOption);
    parser.addOption(darkOption);

    parser.process(app);

    auto* controller = prism::core::AppController::instance();
    controller->setTitle(parser.value(titleOption));
    controller->setInitialDirectory(parser.value(dirOption));
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

    QQmlApplicationEngine engine;
    engine.addImageProvider("icon", new prism::core::IconImageProvider());

    // Register singletons and types into QML context
    engine.rootContext()->setContextProperty("Colours", colours);
    engine.rootContext()->setContextProperty("Tokens", tokens);
    engine.rootContext()->setContextProperty("AppController", controller);
    engine.rootContext()->setContextProperty("FileUtils", fileUtils);

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
