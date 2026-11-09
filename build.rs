use cxx_qt_build::{CxxQtBuilder, QmlModule};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// Every `#[cxx_qt::bridge]` lives in src/bridge: cxx-qt-build only accepts
/// one source directory per QML module.
fn bridges() -> Vec<String> {
    let mut files: Vec<String> = fs::read_dir("src/bridge")
        .expect("src/bridge")
        .flatten()
        .map(|e| e.path().to_string_lossy().replace('\\', "/"))
        .filter(|p| p.ends_with(".rs") && fs::read_to_string(p).is_ok_and(|s| s.contains("#[cxx_qt::bridge")))
        .collect();
    files.sort();
    files
}

/// Native C++ kept beside the Rust code: the theme tokens (QEasingCurve and
/// QFont gadgets), the two QML image providers, and the thin Qt helpers the
/// Rust side calls into. Headers are listed so moc runs on them.
const NATIVE: &[&str] = &[
    "native/theme/fontbuilder.hpp",
    "native/theme/font.hpp",
    "native/theme/tokens.hpp",
    "native/theme/fontbuilder.cpp",
    "native/theme/font.cpp",
    "native/theme/tokens.cpp",
    "native/providers/iconprovider.hpp",
    "native/providers/thumbnailprovider.hpp",
    "native/providers/iconprovider.cpp",
    "native/providers/thumbnailprovider.cpp",
    "native/qthelpers.cpp",
    "native/register.cpp",
];

/// Non-QML files baked into the binary next to the QML module, at the same
/// `:/qt/qml/atlas/...` paths `qt_add_qml_module` used to give them.
const RESOURCES: &[&str] = &[
    "qml/utils/FileNameHelper.js",
    "assets/fonts/GoogleSansFlex.ttf",
    "assets/fonts/MaterialSymbolsRounded.ttf",
    "assets/material_icons.txt",
    "assets/atlas.png",
    "assets/atlas.svg",
    "assets/runner/assets/default_200_percent/200-offline-sprite.png",
    "assets/runner/assets/default_200_percent/200-offline-sprite-inverted.png",
    "assets/runner/sounds/press.wav",
    "assets/runner/sounds/hit.wav",
    "assets/runner/sounds/reached.wav",
];

fn collect_qml(dir: &Path, out: &mut Vec<String>) {
    let Ok(entries) = fs::read_dir(dir) else { return };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_qml(&path, out);
        } else if path.extension().is_some_and(|e| e == "qml") {
            out.push(path.to_string_lossy().replace('\\', "/"));
        }
    }
}

/// Version from the latest `vX.Y.Z` tag, else the commit date as 0.YYYYMMDD,
/// matching what the CMake build used to do.
fn atlas_version() -> String {
    if let Ok(v) = std::env::var("ATLAS_VERSION") {
        if !v.is_empty() {
            return v;
        }
    }
    let git = |args: &[&str]| {
        Command::new("git")
            .args(args)
            .output()
            .ok()
            .filter(|o| o.status.success())
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .filter(|s| !s.is_empty())
    };
    if let Some(tag) = git(&["describe", "--tags", "--match", "v[0-9]*", "--abbrev=0", "HEAD"]) {
        return tag.trim_start_matches('v').to_string();
    }
    if let Some(date) = git(&["log", "-1", "--format=%cd", "--date=format:%Y%m%d"]) {
        return format!("0.{date}");
    }
    std::env::var("CARGO_PKG_VERSION").unwrap()
}

fn generate_qrc(repo_root: &Path, out_dir: &Path) -> PathBuf {
    let mut qrc = String::from("<!DOCTYPE RCC><RCC version=\"1.0\">\n<qresource prefix=\"/qt/qml/atlas\">\n");
    for f in RESOURCES {
        qrc.push_str(&format!("  <file alias=\"{f}\">{}</file>\n", repo_root.join(f).display()));
    }
    qrc.push_str("</qresource>\n</RCC>\n");
    let path = out_dir.join("atlas_resources.qrc");
    fs::write(&path, qrc).expect("failed to write atlas_resources.qrc");
    path
}

fn main() {
    let repo_root = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let out_dir = PathBuf::from(std::env::var("OUT_DIR").unwrap());

    println!("cargo:rustc-env=ATLAS_VERSION={}", atlas_version());
    println!("cargo:rerun-if-env-changed=ATLAS_VERSION");
    println!("cargo:rerun-if-changed=.git/HEAD");
    for dir in ["qml", "assets", "native", "src/bridge"] {
        println!("cargo:rerun-if-changed={}", repo_root.join(dir).display());
    }

    let mut qml_files = Vec::new();
    collect_qml(Path::new("qml"), &mut qml_files);
    qml_files.sort();

    let qrc = generate_qrc(&repo_root, &out_dir);

    let builder = CxxQtBuilder::new_qml_module(QmlModule::new("atlas").qml_files(qml_files))
        .files(bridges())
        .cpp_files(NATIVE.iter().map(|f| repo_root.join(f)))
        .qt_module("Quick")
        .qrc(qrc);
    // SAFETY: only adds an include path for the native/ headers.
    let builder = unsafe {
        builder.cc_builder(|cc| {
            cc.include(repo_root.join("native"));
        })
    };
    builder.build();
}
