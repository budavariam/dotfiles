pub fn helper_script_content() -> &'static str {
    r#"_rec_paused() { [[ -f "$_REC_PAUSE_FILE" ]]; }

type_text() {
    _rec_paused && return
    local text="$1" i ch delay_ms
    local base_ms
    base_ms=$(awk "BEGIN{print int($_REC_CHAR_DELAY * 1000)}")
    if [[ "$_REC_JITTER" == "1" ]]; then
        local spread jitter
        spread=$(( base_ms * 3 / 4 ))
        [[ $spread -lt 1 ]] && spread=1
    fi
    for ((i = 0; i < ${#text}; i++)); do
        ch="${text:$i:1}"
        tmux send-keys -t "$_REC_TARGET" -l "$ch"
        if [[ "$_REC_JITTER" == "1" ]]; then
            jitter=$(( (RANDOM % (spread * 2 + 1)) - spread ))
            delay_ms=$(( base_ms + jitter ))
            [[ "$ch" == " " ]] && delay_ms=$(( delay_ms + RANDOM % 60 ))
            [[ $delay_ms -lt 10  ]] && delay_ms=10
            [[ $delay_ms -gt 999 ]] && delay_ms=999
            sleep "0.$(printf '%03d' $delay_ms)"
        else
            sleep "$_REC_CHAR_DELAY"
        fi
    done
}
run()         { _rec_paused && return; type_text "$1"; sleep 0.3; tmux send-keys -t "$_REC_TARGET" Enter; sleep 0.3; }
enter()       { _rec_paused && return; tmux send-keys -t "$_REC_TARGET" Enter; }
ctrl_c()      { _rec_paused && return; tmux send-keys -t "$_REC_TARGET" C-c; sleep 0.3; }
pause()       { sleep "${1:-1}"; }
clear_screen(){ _rec_paused && return; tmux send-keys -t "$_REC_TARGET" "clear" Enter; sleep 0.5; }
blank_lines() {
    _rec_paused && return
    local n="${1:-1}" i
    for ((i = 0; i < n; i++)); do tmux send-keys -t "$_REC_TARGET" Enter; done
    sleep 0.2
}
_prog_line()       { echo "$1" > "$_REC_PROGRESS_FILE"; }
stop_recording()   { exit 0; }
pause_recording()  { touch "$_REC_PAUSE_FILE"; }
continue_recording(){ rm -f "$_REC_PAUSE_FILE"; }
"#
}

pub struct ViewerParams {
    pub screenplay_abs: String,
    pub progress_file: String,
    pub pause_file: String,
    pub no_quit_file: String,
    pub total_actions: usize,
    pub recording_pane: String,
    pub session_name: String,
    pub output_basename: String,
    pub context: u32,
}

pub fn viewer_script_content(p: &ViewerParams) -> String {
    // Pre-compute the footer snippet with the no_quit_file path already baked in,
    // then pass it as {footer} so the main format string stays readable.
    let footer = format!(
        "    if [[ $step -eq $TOTAL_ACTIONS && $TOTAL_ACTIONS -gt 0 && -f \"{nqf}\" ]]; then\n\
         \x20\x20\x20\x20    printf '\\033[1;32m  Recording done — inspect freely.  \\033[90m[q] quit  [n] release\\033[0m\\n'\n\
         \x20\x20\x20\x20else\n\
         \x20\x20\x20\x20    printf '\\033[90m  [q] stop   [p] pause/resume   [n] keep-alive\\033[0m\\n'\n\
         \x20\x20\x20\x20fi",
        nqf = p.no_quit_file,
    );

    // The viewer script uses bash arrays and parameter expansions.
    // We expand our Rust variables now and use {{ }} to escape literal { } in the format string.
    format!(
        "#!/usr/bin/env bash\n\
SCREENPLAY_ABS=\"{screenplay_abs}\"\n\
PROGRESS_FILE=\"{progress_file}\"\n\
PAUSE_FILE=\"{pause_file}\"\n\
NO_QUIT_FILE=\"{no_quit_file}\"\n\
TOTAL_ACTIONS={total_actions}\n\
RECORDING_PANE=\"{recording_pane}\"\n\
SESSION_NAME=\"{session_name}\"\n\
\n\
echo -ne \"\\033]2;progress - {output_basename}\\007\"\n\
\n\
mapfile -t SCREENPLAY_LINES < \"$SCREENPLAY_ABS\"\n\
TOTAL_SOURCE_LINES=${{#SCREENPLAY_LINES[@]}}\n\
\n\
_find_source_line() {{\n\
    local target_action=$1\n\
    local action_num=0\n\
    for ((i = 0; i < TOTAL_SOURCE_LINES; i++)); do\n\
        local line=\"${{SCREENPLAY_LINES[i]}}\"\n\
        local stripped=\"${{line#\"${{line%%[![:space:]]*}}\"}}\"\n\
        if [[ -n \"$stripped\" && \"${{stripped:0:1}}\" != '#' ]]; then\n\
            action_num=$((action_num + 1))\n\
            [[ $action_num -eq $target_action ]] && {{ echo $((i + 1)); return; }}\n\
        fi\n\
    done\n\
    echo 0\n\
}}\n\
\n\
_draw_bar() {{\n\
    local step=$1 total=$2 width=40\n\
    local filled=0 empty=$width pct=0\n\
    if [[ $total -gt 0 ]]; then\n\
        filled=$((step * width / total))\n\
        [[ $filled -gt $width ]] && filled=$width\n\
        empty=$((width - filled))\n\
        pct=$((step * 100 / total))\n\
    fi\n\
    printf '  ['\n\
    local i\n\
    for ((i = 0; i < filled; i++)); do printf '\\033[32m\\xe2\\x96\\x88\\033[0m'; done\n\
    for ((i = 0; i < empty;  i++)); do printf '\\033[90m\\xe2\\x96\\x91\\033[0m'; done\n\
    if [[ -f \"{pause_file}\" ]]; then\n\
        printf '] \\033[1m%d%%\\033[0m  \\033[1;33m[PAUSED]\\033[0m\\n' \"$pct\"\n\
    elif [[ -f \"{no_quit_file}\" ]]; then\n\
        printf '] \\033[1m%d%%\\033[0m  \\033[1;35m[KEEP]\\033[0m\\n' \"$pct\"\n\
    else\n\
        printf '] \\033[1m%d%%\\033[0m\\n' \"$pct\"\n\
    fi\n\
}}\n\
\n\
prev_step=-1\n\
prev_paused=-1\n\
while true; do\n\
    read -t 0.1 -n 1 -s key 2>/dev/null\n\
    case \"$key\" in\n\
        q|Q)\n\
            tmux send-keys -t \"$RECORDING_PANE\" \"\" \"C-d\"\n\
            sleep 2\n\
            tmux kill-session -t \"$SESSION_NAME\" 2>/dev/null\n\
            exit 0 ;;\n\
        p|P|' ')\n\
            if [[ -f \"{pause_file}\" ]]; then\n\
                rm -f \"{pause_file}\"\n\
            else\n\
                touch \"{pause_file}\"\n\
            fi ;;\n\
        n|N)\n\
            if [[ -f \"{no_quit_file}\" ]]; then\n\
                rm -f \"{no_quit_file}\"\n\
            else\n\
                touch \"{no_quit_file}\"\n\
            fi ;;\n\
    esac\n\
\n\
    step=$(cat \"$PROGRESS_FILE\" 2>/dev/null || echo \"0\")\n\
    step=${{step:-0}}\n\
    paused=$([[ -f \"{pause_file}\" ]] && echo 1 || echo 0)\n\
    no_quit=$([[ -f \"{no_quit_file}\" ]] && echo 1 || echo 0)\n\
\n\
    [[ $step -eq $prev_step && $paused -eq $prev_paused && $no_quit -eq ${{prev_no_quit:-0}} ]] && continue\n\
    prev_step=$step\n\
    prev_paused=$paused\n\
    prev_no_quit=$no_quit\n\
\n\
    current_line=$(_find_source_line \"$step\")\n\
\n\
    printf '\\033[2J\\033[H'\n\
    printf '\\033[1;36m  %s\\033[0m  \\xe2\\x86\\x92  \\033[1;33m%s\\033[0m  %d / %d\\n' \"$(basename \"$SCREENPLAY_ABS\")\" \"{output_basename}\" \"$step\" \"$TOTAL_ACTIONS\"\n\
    _draw_bar \"$step\" \"$TOTAL_ACTIONS\"\n\
    printf '\\n'\n\
\n\
    win={context}\n\
    for (( offset = -win; offset <= win; offset++ )); do\n\
        lineno=$((current_line + offset))\n\
        if [[ $lineno -lt 1 || $lineno -gt TOTAL_SOURCE_LINES ]]; then\n\
            printf '\\n'\n\
        else\n\
            i=$((lineno - 1))\n\
            line=\"${{SCREENPLAY_LINES[i]:-}}\"\n\
            if [[ $offset -eq 0 ]]; then\n\
                printf '  \\033[1;32m\\xe2\\x96\\xba%3d  %s\\033[0m\\n' \"$lineno\" \"$line\"\n\
            else\n\
                printf '   %3d  \\033[90m%s\\033[0m\\n'   \"$lineno\" \"$line\"\n\
            fi\n\
        fi\n\
    done\n\
\n\
{footer}\n\
done\n",
        screenplay_abs = p.screenplay_abs,
        progress_file = p.progress_file,
        pause_file = p.pause_file,
        no_quit_file = p.no_quit_file,
        total_actions = p.total_actions,
        recording_pane = p.recording_pane,
        session_name = p.session_name,
        output_basename = p.output_basename,
        context = p.context,
        footer = footer,
    )
}

pub struct RcParams {
    pub custom_ps1: Option<String>,
    pub start_dir: Option<String>,
}

pub fn bash_rcfile_content(p: &RcParams) -> String {
    let ps1_expr = match &p.custom_ps1 {
        Some(ps1) => format!("export PS1='{}'", ps1),
        None => r"export PS1='\[\033[0;32m\]$(_parent_dir)/\W\[\033[0;33m\]$(_git_branch)\[\033[0m\]\$ '".to_string(),
    };
    let cd_line = match &p.start_dir {
        Some(dir) => format!("cd '{}'", dir),
        None => String::new(),
    };
    format!(
        "export HISTFILE=/dev/null HISTSIZE=0\n\
export CARGO_TERM_PROGRESS_WHEN=never\n\
_git_branch() {{ git -C . rev-parse --abbrev-ref HEAD 2>/dev/null | grep -v '^HEAD$' | sed 's/.*/ (&)/'; }}\n\
_parent_dir() {{ basename \"$(dirname \"$PWD\")\"; }}\n\
[ -f /etc/profile ] && source /etc/profile 2>/dev/null || true\n\
{ps1_expr}\n\
PROMPT_COMMAND='printf \"\\033]2;recording\\007\"'\n\
bind 'set enable-bracketed-paste off' 2>/dev/null || true\n\
{cd_line}\n",
        ps1_expr = ps1_expr,
        cd_line = cd_line,
    )
}

pub fn zsh_rcfile_content(p: &RcParams) -> String {
    let prompt_expr = match &p.custom_ps1 {
        Some(ps1) => format!("PROMPT='{}'", ps1),
        None => "PROMPT='%1~$(_git_branch)%# '".to_string(),
    };
    let cd_line = match &p.start_dir {
        Some(dir) => format!("cd '{}'", dir),
        None => String::new(),
    };
    format!(
        "unset HISTFILE; HISTSIZE=0; SAVEHIST=0\n\
export CARGO_TERM_PROGRESS_WHEN=never\n\
_git_branch() {{ git -C . rev-parse --abbrev-ref HEAD 2>/dev/null | grep -v '^HEAD$' | sed 's/.*/ (&)/'; }}\n\
setopt PROMPT_SUBST\n\
{prompt_expr}\n\
precmd() {{ print -Pn \"\\e]2;recording\\a\" }}\n\
{cd_line}\n",
        prompt_expr = prompt_expr,
        cd_line = cd_line,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    // helper_script_content

    #[test]
    fn test_helper_contains_all_api_functions() {
        let c = helper_script_content();
        for name in &[
            "type_text",
            "run",
            "enter",
            "ctrl_c",
            "pause",
            "clear_screen",
            "blank_lines",
            "_prog_line",
            "stop_recording",
            "pause_recording",
            "continue_recording",
        ] {
            assert!(c.contains(name), "missing: {name}");
        }
    }

    #[test]
    fn test_helper_uses_env_vars() {
        let c = helper_script_content();
        assert!(c.contains("$_REC_TARGET"));
        assert!(c.contains("$_REC_PAUSE_FILE"));
        assert!(c.contains("$_REC_CHAR_DELAY"));
        assert!(c.contains("$_REC_JITTER"));
    }

    // bash_rcfile_content

    #[test]
    fn test_bash_rcfile_disables_history() {
        let c = bash_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: None,
        });
        assert!(c.contains("HISTFILE=/dev/null"));
        assert!(c.contains("HISTSIZE=0"));
    }

    #[test]
    fn test_bash_rcfile_custom_ps1() {
        let c = bash_rcfile_content(&RcParams {
            custom_ps1: Some(r"\w $ ".to_string()),
            start_dir: None,
        });
        assert!(c.contains(r"PS1='\w $ '"));
    }

    #[test]
    fn test_bash_rcfile_default_ps1_has_git_branch() {
        let c = bash_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: None,
        });
        assert!(c.contains("_git_branch"));
    }

    #[test]
    fn test_bash_rcfile_cd_when_dir_set() {
        let c = bash_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: Some("/tmp/project".to_string()),
        });
        assert!(c.contains("cd '/tmp/project'"));
    }

    #[test]
    fn test_bash_rcfile_no_cd_when_dir_absent() {
        let c = bash_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: None,
        });
        assert!(!c.contains("cd '"));
    }

    // zsh_rcfile_content

    #[test]
    fn test_zsh_rcfile_disables_history() {
        let c = zsh_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: None,
        });
        assert!(c.contains("HISTSIZE=0"));
        assert!(c.contains("SAVEHIST=0"));
    }

    #[test]
    fn test_zsh_rcfile_custom_prompt() {
        let c = zsh_rcfile_content(&RcParams {
            custom_ps1: Some("→ ".to_string()),
            start_dir: None,
        });
        assert!(c.contains("PROMPT='→ '"));
    }

    #[test]
    fn test_zsh_rcfile_cd_when_dir_set() {
        let c = zsh_rcfile_content(&RcParams {
            custom_ps1: None,
            start_dir: Some("/tmp/rec".to_string()),
        });
        assert!(c.contains("cd '/tmp/rec'"));
    }

    // viewer_script_content

    #[test]
    fn test_viewer_script_bakes_in_params() {
        let p = ViewerParams {
            screenplay_abs: "/tmp/play.sh".to_string(),
            progress_file: "/tmp/prog".to_string(),
            pause_file: "/tmp/pause".to_string(),
            no_quit_file: "/tmp/no_quit".to_string(),
            total_actions: 42,
            recording_pane: "sess:0.0".to_string(),
            session_name: "sess".to_string(),
            output_basename: "demo.cast".to_string(),
            context: 4,
        };
        let c = viewer_script_content(&p);
        assert!(c.contains("TOTAL_ACTIONS=42"));
        assert!(c.contains("SESSION_NAME=\"sess\""));
        assert!(c.contains("/tmp/play.sh"));
        assert!(c.contains("demo.cast"));
    }

    #[test]
    fn test_viewer_script_has_key_handlers() {
        let p = ViewerParams {
            screenplay_abs: "/s".to_string(),
            progress_file: "/p".to_string(),
            pause_file: "/u".to_string(),
            no_quit_file: "/n".to_string(),
            total_actions: 1,
            recording_pane: "s:0.0".to_string(),
            session_name: "s".to_string(),
            output_basename: "o.cast".to_string(),
            context: 4,
        };
        let c = viewer_script_content(&p);
        assert!(c.contains("q|Q)"));
        assert!(c.contains("p|P|' ')"));
        assert!(c.contains("_draw_bar"));
    }
}
