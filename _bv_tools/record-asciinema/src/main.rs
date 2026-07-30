mod args;
mod screenplay;
mod scripts;
mod tmux;

use anyhow::Context;
use clap::Parser;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use tempfile::{Builder, NamedTempFile, TempDir};

use args::{Args, Shell};
use scripts::{RcParams, ViewerParams};

fn check_dep(name: &str) -> anyhow::Result<()> {
    let ok = Command::new("which")
        .arg(name)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);
    if !ok {
        anyhow::bail!("'{}' not found — please install it first", name);
    }
    Ok(())
}

fn epoch() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn resolve_absolute(p: &Path) -> anyhow::Result<PathBuf> {
    let abs = if p.is_absolute() {
        p.to_path_buf()
    } else {
        std::env::current_dir()
            .context("failed to get cwd")?
            .join(p)
    };
    Ok(abs)
}

fn expand_home(s: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_default();
    if s == "~" {
        home
    } else if let Some(rest) = s.strip_prefix("~/") {
        format!("{}/{}", home, rest)
    } else {
        s.to_string()
    }
}

fn detect_recording_dir(screenplay_abs: &Path, shell: &str) -> Option<String> {
    // Source the screenplay with all API calls stubbed out and capture RECORDING_DIR
    // via an EXIT trap — mirrors the original bash implementation so any shell
    // expression (~, $HOME, $(...), variables, etc.) expands naturally.
    let script = concat!(
        "run() { :; }; type_text() { :; }; enter() { :; }; ctrl_c() { :; }; ",
        "pause() { :; }; clear_screen() { :; }; blank_lines() { :; }; _prog_line() { :; }; ",
        "pause_recording() { :; }; continue_recording() { :; }; stop_recording() { exit 0; }; ",
        "trap 'printf \"%s\" \"$RECORDING_DIR\"' EXIT; ",
        "source \"$1\""
    );

    let output = Command::new(shell)
        .args(["-c", script, "_", &screenplay_abs.to_string_lossy()])
        .stderr(std::process::Stdio::null())
        .output()
        .ok()?;

    let val = String::from_utf8(output.stdout).ok()?;
    let val = val.trim().to_string();
    if val.is_empty() {
        return None;
    }

    // Relative paths are resolved against the screenplay's directory.
    let path = Path::new(&val);
    if path.is_absolute() {
        Some(val)
    } else {
        let base = screenplay_abs.parent().unwrap_or(Path::new("."));
        Some(base.join(path).to_string_lossy().into_owned())
    }
}

#[cfg(test)]
fn detect_recording_dir_from_str(source: &str) -> Option<String> {
    for line in source.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix("RECORDING_DIR=") {
            let val = rest.trim_matches('"').trim_matches('\'').to_string();
            if !val.is_empty() {
                return Some(val);
            }
        }
    }
    None
}

struct TempFiles {
    _helper: NamedTempFile,
    processed: NamedTempFile,
    rcfile: NamedTempFile,
    viewer: NamedTempFile,
    progress: NamedTempFile,
    _pause: NamedTempFile,
    _no_quit: NamedTempFile,
    _zdotdir: Option<TempDir>,
    session: String,
}

impl Drop for TempFiles {
    fn drop(&mut self) {
        tmux::kill_session(&self.session);
    }
}

pub fn write_transcript(cast_path: &Path, transcript_path: &Path) -> anyhow::Result<()> {
    let file = fs::File::open(cast_path).context("failed to open cast file")?;
    let reader = BufReader::new(file);
    let mut out = fs::File::create(transcript_path).context("failed to create transcript file")?;

    let mut lines = reader.lines();
    // skip header line
    lines.next();

    for line in lines {
        let line = line.context("failed to read cast line")?;
        if line.trim().is_empty() {
            continue;
        }
        if let Ok(arr) = serde_json::from_str::<serde_json::Value>(&line) {
            if let Some(arr) = arr.as_array() {
                if arr.len() >= 3 && arr[1].as_str() == Some("o") {
                    if let Some(data) = arr[2].as_str() {
                        let stripped = strip_ansi(data);
                        out.write_all(stripped.as_bytes())
                            .context("failed to write transcript")?;
                    }
                }
            }
        }
    }
    Ok(())
}

fn strip_ansi(s: &str) -> String {
    let mut result = String::with_capacity(s.len());
    let bytes = s.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == 0x1b {
            if i + 1 < bytes.len() && bytes[i + 1] == b'[' {
                // skip ESC [ ... letter
                i += 2;
                while i < bytes.len() && !bytes[i].is_ascii_alphabetic() {
                    i += 1;
                }
                if i < bytes.len() {
                    i += 1; // skip the terminating letter
                }
            } else {
                // ESC followed by non-[: skip ESC and next byte
                i += 2;
            }
        } else {
            result.push(bytes[i] as char);
            i += 1;
        }
    }
    result
}

fn main() -> anyhow::Result<()> {
    check_dep("tmux")?;
    check_dep("asciinema")?;

    let args = Args::parse();

    if !args.screenplay.exists() {
        anyhow::bail!("screenplay not found: {}", args.screenplay.display());
    }

    let output = {
        let mut out = args.output.clone();
        if out.exists() {
            let ts = epoch();
            let base = out
                .file_stem()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string();
            let ext = out.extension().map(|e| e.to_string_lossy().to_string());
            out = match ext {
                Some(e) => PathBuf::from(format!("{}-{}.{}", base, ts, e)),
                None => PathBuf::from(format!("{}-{}", base, ts)),
            };
            eprintln!("Output file already exists — saving to: {}", out.display());
        }
        out
    };

    let screenplay_abs = resolve_absolute(&args.screenplay)?;
    let output_abs = resolve_absolute(&output)?;

    let shell_name = match args.shell {
        Shell::Bash => "bash",
        Shell::Zsh => "zsh",
    };

    let start_dir = if let Some(ref d) = args.dir {
        Some(expand_home(&d.to_string_lossy()))
    } else {
        detect_recording_dir(&screenplay_abs, shell_name)
    };

    if let Some(ref dir) = start_dir {
        fs::create_dir_all(dir).context("failed to create start dir")?;
    }

    let screenplay_source =
        fs::read_to_string(&screenplay_abs).context("failed to read screenplay")?;

    // Write helper script to temp file
    let mut helper = Builder::new()
        .prefix("asciinema-helper-")
        .suffix(".sh")
        .tempfile()
        .context("failed to create helper temp file")?;
    write!(helper, "{}", scripts::helper_script_content())?;
    let helper_path = helper.path().to_path_buf();

    // Preprocess screenplay
    let preprocess_result = screenplay::preprocess(&screenplay_source, &helper_path);
    let total_actions = preprocess_result.total_actions;

    let mut processed = Builder::new()
        .prefix("asciinema-proc-")
        .suffix(".sh")
        .tempfile()
        .context("failed to create processed temp file")?;
    write!(processed, "{}", preprocess_result.content)?;

    // Progress and pause files
    let mut progress = Builder::new()
        .prefix("asciinema-prog-")
        .tempfile()
        .context("failed to create progress temp file")?;
    write!(progress, "0")?;
    progress.flush()?;

    let pause = Builder::new()
        .prefix("asciinema-pause-")
        .tempfile()
        .context("failed to create pause temp file")?;
    // Remove the pause file so "absent = recording active"
    let pause_path = pause.path().to_path_buf();
    let _ = fs::remove_file(&pause_path);

    let no_quit = Builder::new()
        .prefix("asciinema-noquit-")
        .tempfile()
        .context("failed to create no-quit temp file")?;
    // Remove so "absent = auto-quit after recording"
    let no_quit_path = no_quit.path().to_path_buf();
    let _ = fs::remove_file(&no_quit_path);

    // RC file and zdotdir
    let rc_params = RcParams {
        custom_ps1: args.ps1.clone(),
        start_dir: start_dir.clone(),
    };

    let shell = args.shell.clone();

    let (rcfile, zdotdir): (NamedTempFile, Option<TempDir>) = match shell {
        Shell::Zsh => {
            let zdotdir = Builder::new()
                .prefix("asciinema-zsh-")
                .tempdir()
                .context("failed to create zdotdir")?;
            let rc_path = zdotdir.path().join(".zshrc");
            fs::write(&rc_path, scripts::zsh_rcfile_content(&rc_params))?;
            let rcfile = Builder::new()
                .prefix("asciinema-rc-")
                .tempfile()
                .context("failed to create rcfile temp")?;
            (rcfile, Some(zdotdir))
        }
        Shell::Bash => {
            let mut rcfile = Builder::new()
                .prefix("asciinema-rc-")
                .tempfile()
                .context("failed to create rcfile temp file")?;
            write!(rcfile, "{}", scripts::bash_rcfile_content(&rc_params))?;
            rcfile.flush()?;
            (rcfile, None)
        }
    };

    let session = format!("asciinema-rec-{}", std::process::id());

    // Viewer script
    let jitter = if args.no_jitter { 0u32 } else { 1u32 };
    let viewer_rows = args.context * 2 + 6;
    let total_rows = args.rows + viewer_rows + 1;

    let output_basename = output_abs
        .file_name()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();

    let viewer_params = ViewerParams {
        screenplay_abs: screenplay_abs.to_string_lossy().to_string(),
        progress_file: progress.path().to_string_lossy().to_string(),
        pause_file: pause_path.to_string_lossy().to_string(),
        no_quit_file: no_quit_path.to_string_lossy().to_string(),
        total_actions,
        recording_pane: format!("{}:0.0", session),
        session_name: session.clone(),
        output_basename: output_basename.clone(),
        context: args.context,
    };

    let mut viewer = Builder::new()
        .prefix("asciinema-viewer-")
        .suffix(".sh")
        .tempfile()
        .context("failed to create viewer temp file")?;
    write!(viewer, "{}", scripts::viewer_script_content(&viewer_params))?;
    viewer.flush()?;

    let _temp_files = TempFiles {
        _helper: helper,
        processed,
        rcfile,
        viewer,
        progress,
        _pause: pause,
        _no_quit: no_quit,
        _zdotdir: zdotdir,
        session: session.clone(),
    };

    // Set up tmux
    tmux::new_session(&session, args.cols, total_rows)?;
    tmux::set_option(&session, "status", "off")?;
    tmux::split_window(&session, viewer_rows)?;
    tmux::select_pane(&session, "0.0", "recording")?;
    tmux::select_pane(&session, "0.1", &format!("progress - {}", output_basename))?;

    let target_pane = format!("{}:0.0", session);
    tmux::send_keys_enter(&target_pane, "clear")?;
    std::thread::sleep(std::time::Duration::from_millis(100));

    let shell_cmd_str = match args.shell {
        Shell::Zsh => {
            let zdot = _temp_files
                ._zdotdir
                .as_ref()
                .map(|d| d.path().to_string_lossy().to_string())
                .unwrap_or_default();
            format!("ZDOTDIR={} zsh -i", zdot)
        }
        Shell::Bash => {
            format!("bash --rcfile {}", _temp_files.rcfile.path().display())
        }
    };

    let asciinema_cmd = format!(
        "exec asciinema rec --window-size {}x{} -q '{}' --command '{}'",
        args.cols,
        args.rows,
        output_abs.display(),
        shell_cmd_str
    );
    tmux::send_keys_enter(&target_pane, &asciinema_cmd)?;

    let viewer_path = _temp_files.viewer.path().to_string_lossy().to_string();
    let viewer_pane = format!("{}:0.1", session);
    tmux::send_keys_enter(
        &viewer_pane,
        &format!("clear && bash '{}'; exit", viewer_path),
    )?;

    println!("record-asciinema");
    println!("  screenplay : {}", screenplay_abs.display());
    println!("  output     : {}", output_abs.display());
    println!(
        "  terminal   : {}x{}  (+ {} row viewer)",
        args.cols, args.rows, viewer_rows
    );
    println!();

    // Spawn runner thread
    let processed_path = _temp_files.processed.path().to_string_lossy().to_string();
    let progress_path = _temp_files.progress.path().to_string_lossy().to_string();
    let pause_file_path = pause_path.to_string_lossy().to_string();
    let no_quit_file_path = no_quit_path.to_string_lossy().to_string();
    let target_pane_clone = target_pane.clone();
    let session_clone = session.clone();
    let char_delay = args.char_delay.to_string();
    let cols_str = args.cols.to_string();
    let rows_str = args.rows.to_string();
    let jitter_str = jitter.to_string();

    let runner = std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_secs(2));
        let _ = Command::new("env")
            .env("_REC_TARGET", &target_pane_clone)
            .env("_REC_PROGRESS_FILE", &progress_path)
            .env("_REC_PAUSE_FILE", &pause_file_path)
            .env("_REC_CHAR_DELAY", &char_delay)
            .env("_REC_JITTER", &jitter_str)
            .env("_REC_COLS", &cols_str)
            .env("_REC_ROWS", &rows_str)
            .args(["bash", &processed_path])
            .status();

        std::thread::sleep(std::time::Duration::from_secs(1));
        let _ = Command::new("tmux")
            .args(["send-keys", "-t", &target_pane_clone, "", "C-d"])
            .status();
        if !std::path::Path::new(&no_quit_file_path).exists() {
            std::thread::sleep(std::time::Duration::from_secs(2));
            let _ = Command::new("tmux")
                .args(["kill-session", "-t", &session_clone])
                .status();
        }
    });

    // Lock window size
    tmux::set_option(&session, "window-size", "manual")?;
    tmux::resize_window(&session, args.cols, total_rows)?;
    tmux::select_pane(&session, "0.0", "recording")?;

    // Attach (blocks until session killed)
    let _ = tmux::attach_session(&session);

    let _ = runner.join();

    println!();
    println!("Saved: {}", output_abs.display());

    if let Some(ref transcript_path) = args.transcript {
        write_transcript(&output_abs, transcript_path).context("failed to write transcript")?;
        println!("Transcript: {}", transcript_path.display());
    }

    println!();
    println!("Play back with:");
    println!("  asciinema play '{}'", output_abs.display());

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    // strip_ansi

    #[test]
    fn test_strip_ansi_plain_text() {
        assert_eq!(strip_ansi("hello world"), "hello world");
    }

    #[test]
    fn test_strip_ansi_color_code() {
        assert_eq!(strip_ansi("\x1b[0;32mhello\x1b[0m"), "hello");
    }

    #[test]
    fn test_strip_ansi_bold() {
        assert_eq!(strip_ansi("\x1b[1mtext\x1b[0m"), "text");
    }

    #[test]
    fn test_strip_ansi_clear_screen() {
        assert_eq!(strip_ansi("\x1b[2J\x1b[H"), "");
    }

    #[test]
    fn test_strip_ansi_esc_non_bracket() {
        assert_eq!(strip_ansi("\x1bMtext"), "text");
    }

    #[test]
    fn test_strip_ansi_mixed() {
        assert_eq!(
            strip_ansi("before\x1b[1;33mcolored\x1b[0mafter"),
            "beforecoloredafter"
        );
    }

    #[test]
    fn test_strip_ansi_empty() {
        assert_eq!(strip_ansi(""), "");
    }

    // detect_recording_dir_from_str

    #[test]
    fn test_detect_recording_dir_bare() {
        let src = "RECORDING_DIR=/tmp/demo\nrun \"echo hi\"\n";
        assert_eq!(
            detect_recording_dir_from_str(src),
            Some("/tmp/demo".to_string())
        );
    }

    #[test]
    fn test_detect_recording_dir_quoted_double() {
        let src = "RECORDING_DIR=\"/home/user/project\"\n";
        assert_eq!(
            detect_recording_dir_from_str(src),
            Some("/home/user/project".to_string())
        );
    }

    #[test]
    fn test_detect_recording_dir_quoted_single() {
        let src = "RECORDING_DIR='/opt/demo'\n";
        assert_eq!(
            detect_recording_dir_from_str(src),
            Some("/opt/demo".to_string())
        );
    }

    #[test]
    fn test_detect_recording_dir_absent() {
        let src = "run \"echo hi\"\npause 2\n";
        assert_eq!(detect_recording_dir_from_str(src), None);
    }

    #[test]
    fn test_detect_recording_dir_indented_line() {
        let src = "  RECORDING_DIR=/tmp/indented\n";
        assert_eq!(
            detect_recording_dir_from_str(src),
            Some("/tmp/indented".to_string())
        );
    }

    // expand_home — used for the --dir CLI arg (shell may not have expanded a quoted tilde)

    #[test]
    fn test_expand_home_tilde_slash() {
        std::env::set_var("HOME", "/home/user");
        assert_eq!(expand_home("~/foo/bar"), "/home/user/foo/bar");
    }

    #[test]
    fn test_expand_home_tilde_alone() {
        std::env::set_var("HOME", "/home/user");
        assert_eq!(expand_home("~"), "/home/user");
    }

    #[test]
    fn test_expand_home_absolute_unchanged() {
        assert_eq!(expand_home("/tmp/demo"), "/tmp/demo");
    }
}
