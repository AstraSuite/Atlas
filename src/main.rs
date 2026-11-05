mod cli;
mod core;
mod bridge;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QString, QUrl};

fn main() {
    cli::parse();
    bridge::native::ffi::pre_application_setup();
    let mut app = QGuiApplication::new();
    bridge::native::ffi::setup_application(&QString::from(env!("ATLAS_VERSION")));
    let mut engine = QQmlApplicationEngine::new();
    if let Some(mut engine) = engine.as_mut() {
        bridge::native::ffi::install_engine(engine.as_mut());
        engine.load(&QUrl::from("qrc:/qt/qml/atlas/qml/main.qml"));
    }
    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
