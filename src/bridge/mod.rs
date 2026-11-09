//! The cxx-qt bridges. Enums and signals that only QML uses look dead
//! to rustc, hence the allows on those modules.

pub mod appcontroller;
pub mod appintegration;
#[allow(dead_code)]
pub mod catboxuploader;
#[allow(dead_code)]
pub mod circularindicatormanager;
pub mod colours;
pub mod drivemanager;
pub mod filemetadata;
#[allow(dead_code)]
pub mod fileoperations;
#[allow(dead_code)]
pub mod filesystemmodel;
#[allow(dead_code)]
pub mod fileutils;
pub mod gitmanager;
pub mod iconcatalog;
#[allow(dead_code)]
pub mod mediatools;
pub mod mimeservice;
pub mod native;
pub mod networkmanager;
pub mod papiruswatcher;
pub mod placesmodel;
pub mod registry;
#[allow(dead_code)]
pub mod runnergame;
pub mod shortcutmanager;
pub mod tabmanager;
