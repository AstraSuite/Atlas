#include "filechooserportal.hpp"
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDebug>

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);
    app.setApplicationName("xdg-desktop-portal-astra-atlas");
    app.setOrganizationName("atlas");

    QCommandLineParser parser;
    parser.setApplicationDescription("Atlas XDG Desktop Portal FileChooser daemon");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption replaceOption(QStringList() << "r" << "replace", "Replace existing running portal daemon instance");
    parser.addOption(replaceOption);
    parser.process(app);

    auto connection = QDBusConnection::sessionBus();
    if (!connection.isConnected()) {
        qCritical() << "Failed to connect to D-Bus session bus.";
        return 1;
    }

    bool registered = false;
    if (parser.isSet(replaceOption) && connection.interface()) {
        auto reply = connection.interface()->registerService("org.freedesktop.impl.portal.desktop.astra-atlas",
                                                             QDBusConnectionInterface::ReplaceExistingService,
                                                             QDBusConnectionInterface::DontAllowReplacement);
        registered = (reply == QDBusConnectionInterface::ServiceRegistered);
    } else {
        registered = connection.registerService("org.freedesktop.impl.portal.desktop.astra-atlas");
    }

    if (!registered) {
        qInfo() << "xdg-desktop-portal-astra-atlas is already running on the D-Bus session bus.";
        qInfo() << "Use 'xdg-desktop-portal-astra-atlas --replace' or 'atlas-portal-openrc' to reload it.";
        return 0;
    }

    auto* portal = new atlas::portal::FileChooserPortal(&app);

    if (!connection.registerObject("/org/freedesktop/portal/desktop", portal,
                                   QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllProperties)) {
        qCritical() << "Failed to register object at /org/freedesktop/portal/desktop:"
                    << connection.lastError().message();
        return 1;
    }

    qInfo() << "xdg-desktop-portal-astra-atlas running on org.freedesktop.impl.portal.desktop.astra-atlas";

    return app.exec();
}
