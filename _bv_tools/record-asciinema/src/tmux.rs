use anyhow::Context;
use std::process::Command;

pub fn new_session(session: &str, cols: u32, rows: u32) -> anyhow::Result<()> {
    let status = Command::new("tmux")
        .args([
            "new-session",
            "-d",
            "-s",
            session,
            "-x",
            &cols.to_string(),
            "-y",
            &rows.to_string(),
        ])
        .status()
        .context("failed to run tmux new-session")?;
    if !status.success() {
        anyhow::bail!("tmux new-session failed");
    }
    Ok(())
}

pub fn set_option(session: &str, key: &str, value: &str) -> anyhow::Result<()> {
    let target = format!("-t{}", session);
    let status = Command::new("tmux")
        .args(["set-option", &target, key, value])
        .status()
        .context("failed to run tmux set-option")?;
    if !status.success() {
        anyhow::bail!("tmux set-option failed for {} = {}", key, value);
    }
    Ok(())
}

pub fn split_window(session: &str, viewer_rows: u32) -> anyhow::Result<()> {
    let target = format!("{}:0.0", session);
    let status = Command::new("tmux")
        .args([
            "split-window",
            "-v",
            "-l",
            &viewer_rows.to_string(),
            "-t",
            &target,
        ])
        .status()
        .context("failed to run tmux split-window")?;
    if !status.success() {
        anyhow::bail!("tmux split-window failed");
    }
    Ok(())
}

pub fn select_pane(session: &str, pane: &str, title: &str) -> anyhow::Result<()> {
    let target = format!("{}:{}", session, pane);
    let status = Command::new("tmux")
        .args(["select-pane", "-t", &target, "-T", title])
        .status()
        .context("failed to run tmux select-pane")?;
    if !status.success() {
        anyhow::bail!("tmux select-pane failed");
    }
    Ok(())
}

pub fn send_keys_enter(target: &str, keys: &str) -> anyhow::Result<()> {
    let status = Command::new("tmux")
        .args(["send-keys", "-t", target, keys, "Enter"])
        .status()
        .context("failed to run tmux send-keys")?;
    if !status.success() {
        anyhow::bail!("tmux send-keys failed");
    }
    Ok(())
}

pub fn resize_window(session: &str, cols: u32, rows: u32) -> anyhow::Result<()> {
    let target = format!("-t{}", session);
    let status = Command::new("tmux")
        .args([
            "resize-window",
            &target,
            "-x",
            &cols.to_string(),
            "-y",
            &rows.to_string(),
        ])
        .status()
        .context("failed to run tmux resize-window")?;
    if !status.success() {
        anyhow::bail!("tmux resize-window failed");
    }
    Ok(())
}

pub fn kill_session(session: &str) {
    let _ = Command::new("tmux")
        .args(["kill-session", "-t", session])
        .status();
}

pub fn attach_session(session: &str) -> anyhow::Result<()> {
    let status = Command::new("tmux")
        .args(["attach-session", "-t", session])
        .status()
        .context("failed to run tmux attach-session")?;
    // attach-session exits non-zero when the session is killed, that's fine
    let _ = status;
    Ok(())
}
