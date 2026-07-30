use anyhow::Context;
use std::path::Path;
use std::process::Command;

pub fn changed_files(repo: &Path, base: &str, compare: &str) -> anyhow::Result<Vec<String>> {
    let out = Command::new("git")
        .args(["diff", &format!("{base}...{compare}"), "--name-only"])
        .current_dir(repo)
        .output()
        .context("failed to run git diff --name-only")?;
    if !out.status.success() {
        return Ok(Vec::new());
    }
    Ok(String::from_utf8_lossy(&out.stdout)
        .lines()
        .filter(|l| !l.is_empty())
        .map(|l| l.to_string())
        .collect())
}

pub fn file_exists_in_ref(repo: &Path, git_ref: &str, file: &str) -> bool {
    Command::new("git")
        .args(["show", &format!("{git_ref}:{file}")])
        .current_dir(repo)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

pub fn diff(
    repo: &Path,
    base: &str,
    compare: &str,
    file: &str,
    ignore_whitespace: bool,
) -> anyhow::Result<String> {
    let range = format!("{base}...{compare}");
    let mut args = vec!["diff", &range];
    if ignore_whitespace {
        args.extend_from_slice(&["-w", "-b", "--ignore-blank-lines"]);
    }
    args.extend_from_slice(&["--", file]);
    let out = Command::new("git")
        .args(&args)
        .current_dir(repo)
        .output()
        .context("failed to run git diff")?;
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

pub fn diff_stat(repo: &Path, base: &str, compare: &str, file: &str) -> anyhow::Result<String> {
    let range = format!("{base}...{compare}");
    let out = Command::new("git")
        .args(["diff", &range, "--stat", "--", file])
        .current_dir(repo)
        .output()
        .context("failed to run git diff --stat")?;
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::process::Command;
    use tempfile::TempDir;

    fn setup_repo() -> TempDir {
        let dir = TempDir::new().unwrap();
        let p = dir.path();
        Command::new("git")
            .args(["init"])
            .current_dir(p)
            .output()
            .unwrap();
        Command::new("git")
            .args(["config", "user.email", "t@t"])
            .current_dir(p)
            .output()
            .unwrap();
        Command::new("git")
            .args(["config", "user.name", "t"])
            .current_dir(p)
            .output()
            .unwrap();
        fs::write(p.join("a.txt"), "line1\nline2\n").unwrap();
        commit(p, "init");
        dir
    }

    fn commit(p: &Path, msg: &str) {
        Command::new("git")
            .args(["add", "."])
            .current_dir(p)
            .output()
            .unwrap();
        Command::new("git")
            .args(["commit", "-m", msg])
            .env("GIT_AUTHOR_NAME", "t")
            .env("GIT_AUTHOR_EMAIL", "t@t")
            .env("GIT_COMMITTER_NAME", "t")
            .env("GIT_COMMITTER_EMAIL", "t@t")
            .current_dir(p)
            .output()
            .unwrap();
    }

    #[test]
    fn test_changed_files_detects_modification() {
        let dir = setup_repo();
        let p = dir.path();
        fs::write(p.join("a.txt"), "line1\nchanged\n").unwrap();
        commit(p, "change");
        let files = changed_files(p, "HEAD~1", "HEAD").unwrap();
        assert!(files.contains(&"a.txt".to_string()));
    }

    #[test]
    fn test_changed_files_empty_when_no_diff() {
        let dir = setup_repo();
        let files = changed_files(dir.path(), "HEAD", "HEAD").unwrap();
        assert!(files.is_empty());
    }

    #[test]
    fn test_file_exists_in_ref_present() {
        let dir = setup_repo();
        assert!(file_exists_in_ref(dir.path(), "HEAD", "a.txt"));
    }

    #[test]
    fn test_file_exists_in_ref_absent() {
        let dir = setup_repo();
        assert!(!file_exists_in_ref(dir.path(), "HEAD", "no-such-file.txt"));
    }

    #[test]
    fn test_file_not_in_base_after_being_added() {
        let dir = setup_repo();
        let p = dir.path();
        fs::write(p.join("new.txt"), "new\n").unwrap();
        commit(p, "add new");
        // new.txt does not exist in HEAD~1
        assert!(!file_exists_in_ref(p, "HEAD~1", "new.txt"));
        assert!(file_exists_in_ref(p, "HEAD", "new.txt"));
    }

    #[test]
    fn test_diff_whitespace_only_empty_with_flag() {
        let dir = setup_repo();
        let p = dir.path();
        fs::write(p.join("a.txt"), "line1\n  line2\n").unwrap();
        commit(p, "indent");
        let full = diff(p, "HEAD~1", "HEAD", "a.txt", false).unwrap();
        let ws = diff(p, "HEAD~1", "HEAD", "a.txt", true).unwrap();
        assert!(!full.is_empty());
        assert!(ws.is_empty());
    }

    #[test]
    fn test_diff_content_change_nonempty_with_flag() {
        let dir = setup_repo();
        let p = dir.path();
        fs::write(p.join("a.txt"), "line1\ncompletely different\n").unwrap();
        commit(p, "change");
        let ws = diff(p, "HEAD~1", "HEAD", "a.txt", true).unwrap();
        assert!(!ws.is_empty());
    }
}
