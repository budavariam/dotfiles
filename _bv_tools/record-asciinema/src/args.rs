use clap::Parser;
use std::path::PathBuf;

#[derive(Clone, Debug)]
pub enum Shell {
    Bash,
    Zsh,
}

pub fn parse_shell(s: &str) -> Result<Shell, String> {
    match s {
        "bash" => Ok(Shell::Bash),
        "zsh" => Ok(Shell::Zsh),
        other => Err(format!("--shell must be 'bash' or 'zsh', got '{}'", other)),
    }
}

#[derive(Parser, Debug)]
#[command(
    name = "record-asciinema",
    about = "Record a terminal session from a screenplay script",
    after_help = r#"Usage:
  record-asciinema <screenplay.sh> [output.cast] [options]
  record-asciinema <screenplay.sh> demo.cast --cols 160 --rows 40
  record-asciinema <screenplay.sh> demo.cast --ps1 '\w $ '

Options:
  --cols N        recording terminal width  (default: 120)
  --rows N        recording terminal height (default: 30)
  --char-delay N  seconds between keystrokes (default: 0.04)
  --no-jitter     use a fixed delay per keystroke instead of randomised timing
  --context N     screenplay lines shown above/below current line (default: 4)
                  viewer pane height is derived: N×2 + 5
  --ps1 PROMPT    override the PS1 shown in the recording
                  (default: green dirname + yellow git branch)
                  Example values:
                    --ps1 '\w $ '               plain path + dollar
                    --ps1 '→ '                  minimal arrow
                    --ps1 '\[\e[36m\]\W\[\e[0m\] % '  cyan dirname + percent
  --dir PATH      starting directory for the recording shell (default: current dir)
  --transcript F  save a plain-text transcript of the recording to F

The tool automatically attaches to a tmux session showing:
  top pane    — the driven shell (exactly what asciinema records)
  bottom pane — screenplay viewer with progress bar and highlighted current line

Tmux chrome and the bottom pane are NOT in the recording.

── Screenplay API ────────────────────────────────────────────────────────────

Screenplays are plain bash scripts — variables, loops, and conditionals all
work. The functions below are available as regular bash functions:

  run "command"        type the command char-by-char, then press Enter
  type_text "text"     type text char-by-char (no Enter)
  enter                press Enter
  ctrl_c               send Ctrl-C
  pause [seconds]      wait (default: 1s)
  clear_screen         send clear + Enter
  blank_lines [n]      press Enter n times (default: 1)
  stop_recording       end the recording early and save
  pause_recording      mute all shell commands until continue_recording
  continue_recording   resume sending commands to the shell

Requirements: tmux, asciinema"#
)]
pub struct Args {
    pub screenplay: PathBuf,

    #[arg(default_value = "demo.cast")]
    pub output: PathBuf,

    #[arg(long, default_value_t = 120)]
    pub cols: u32,

    #[arg(long, default_value_t = 30)]
    pub rows: u32,

    #[arg(long, default_value = "0.04")]
    pub char_delay: f64,

    #[arg(long)]
    pub no_jitter: bool,

    #[arg(long, default_value_t = 4)]
    pub context: u32,

    #[arg(long)]
    pub ps1: Option<String>,

    #[arg(long)]
    pub dir: Option<PathBuf>,

    #[arg(long)]
    pub transcript: Option<PathBuf>,

    #[arg(long, default_value = "bash", value_parser = parse_shell)]
    pub shell: Shell,
}
