//! Command-line options, parsed before Qt starts and read by the services
//! that care about them as the QML engine creates them.

use crate::core::{paths, recent};
use std::sync::OnceLock;

#[derive(Default, Debug)]
pub struct Options {
    /// Folder to open: `[path]` or `--directory`, already resolved.
    pub initial_dir: Option<String>,
    pub show_hidden: bool,
    /// Some(true) for --light, Some(false) for --dark.
    pub force_light: Option<bool>,
    /// --tty: the TTY look for this run, whatever the preference says.
    pub force_tty: bool,
}

static OPTIONS: OnceLock<Options> = OnceLock::new();

pub fn options() -> &'static Options {
    OPTIONS.get_or_init(Options::default)
}

const HELP: &str = "Usage: atlas [options] [path]
Atlas: Modern Material 3 File Manager

Options:
  -h, --help             Displays help on commandline options.
  -v, --version          Displays version information.
  -d, --directory <dir>  Initial directory
  --hidden               Show hidden files by default
  --light                Force light theme
  --dark                 Force dark theme
  --tty                  Use the TTY look for this run

Arguments:
  path                   Directory or file path to open";

fn local_path(arg: &str) -> String {
    if arg.starts_with("file://") {
        paths::from_file_url(arg)
    } else {
        arg.to_string()
    }
}

/// A folder to open for `arg`: the folder itself, or a file's folder.
fn folder_for(arg: &str) -> Option<String> {
    let path = local_path(arg);
    let meta = std::fs::metadata(&path).ok()?;
    let abs = std::fs::canonicalize(&path).map(|p| p.to_string_lossy().into_owned()).unwrap_or(path);
    Some(if meta.is_dir() { abs } else { paths::parent(&abs) })
}

/// Parses argv. Exits the process for --help, --version and bad options.
pub fn parse() {
    let mut options = Options::default();
    let mut args = std::env::args().skip(1);
    let mut positional: Vec<String> = Vec::new();
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" | "--help-all" => {
                println!("{HELP}");
                std::process::exit(0);
            }
            "-v" | "--version" => {
                println!("atlas {}", env!("ATLAS_VERSION"));
                std::process::exit(0);
            }
            "--hidden" => options.show_hidden = true,
            "--light" => options.force_light = Some(true),
            "--tty" => options.force_tty = true,
            "--dark" => options.force_light = options.force_light.or(Some(false)),
            "-d" | "--directory" => match args.next() {
                Some(dir) => {
                    let dir = local_path(&dir);
                    options.initial_dir = Some(folder_for(&dir).unwrap_or(dir));
                }
                None => {
                    eprintln!("Missing value after '{arg}'.");
                    std::process::exit(1);
                }
            },
            _ if arg.starts_with("--directory=") => {
                let dir = local_path(&arg["--directory=".len()..]);
                options.initial_dir = Some(folder_for(&dir).unwrap_or(dir));
            }
            _ if arg.starts_with('-') && arg.len() > 1 => {
                eprintln!("Unknown option '{arg}'.");
                std::process::exit(1);
            }
            _ => positional.push(arg),
        }
    }
    if let Some(first) = positional.first() {
        let path = local_path(first);
        if recent::is_recent_path(&path) {
            options.initial_dir = Some(path);
        } else if let Some(folder) = folder_for(&path) {
            options.initial_dir = Some(folder);
        }
    }
    let _ = OPTIONS.set(options);
}
