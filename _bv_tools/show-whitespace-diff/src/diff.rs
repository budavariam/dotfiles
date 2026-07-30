pub struct Hunk {
    pub lines: Vec<String>,
}

pub fn parse_hunks(diff: &str) -> Vec<Hunk> {
    let mut hunks: Vec<Hunk> = Vec::new();
    let mut current: Vec<String> = Vec::new();

    for line in diff.lines() {
        if line.starts_with("@@") {
            if !current.is_empty() {
                hunks.push(Hunk { lines: current });
                current = Vec::new();
            }
            current.push(line.to_string());
        } else if !current.is_empty() {
            current.push(line.to_string());
        }
    }
    if !current.is_empty() {
        hunks.push(Hunk { lines: current });
    }
    hunks
}

fn strip_whitespace(s: &str) -> String {
    s.chars().filter(|c| !c.is_whitespace()).collect()
}

fn normalize(s: &str) -> String {
    s.chars()
        .filter(|c| !c.is_whitespace() && *c != ';')
        .collect()
}

pub fn is_whitespace_only(hunk: &Hunk) -> bool {
    let changed: Vec<&str> = hunk.lines[1..]
        .iter()
        .filter(|l| l.starts_with('+') || l.starts_with('-'))
        .map(|l| l.as_str())
        .collect();

    if changed.is_empty() {
        return false;
    }

    let mut removed: Vec<String> = changed
        .iter()
        .filter(|l| l.starts_with('-'))
        .map(|l| strip_whitespace(&l[1..]))
        .collect();
    let mut added: Vec<String> = changed
        .iter()
        .filter(|l| l.starts_with('+'))
        .map(|l| strip_whitespace(&l[1..]))
        .collect();

    removed.sort();
    added.sort();
    if removed == added {
        return true;
    }

    // Handles reformatting (e.g. multi-line collapsed to one line), with optional TS semicolons
    let removed_tokens = normalize(
        &changed
            .iter()
            .filter(|l| l.starts_with('-'))
            .map(|l| l[1..].to_string())
            .collect::<Vec<_>>()
            .join(""),
    );
    let added_tokens = normalize(
        &changed
            .iter()
            .filter(|l| l.starts_with('+'))
            .map(|l| l[1..].to_string())
            .collect::<Vec<_>>()
            .join(""),
    );

    removed_tokens == added_tokens
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_hunk(lines: &[&str]) -> Hunk {
        Hunk {
            lines: lines.iter().map(|s| s.to_string()).collect(),
        }
    }

    #[test]
    fn test_whitespace_only_indentation() {
        let hunk = make_hunk(&["@@ -1,3 +1,3 @@", "-  foo()", "+    foo()"]);
        assert!(is_whitespace_only(&hunk));
    }

    #[test]
    fn test_content_change_not_whitespace() {
        let hunk = make_hunk(&["@@ -1,3 +1,3 @@", "-  foo()", "+  bar()"]);
        assert!(!is_whitespace_only(&hunk));
    }

    #[test]
    fn test_reformat_multiline_to_single() {
        // multi-line collapsed to one line, same tokens
        let hunk = make_hunk(&[
            "@@ -1,4 +1,2 @@",
            "-const x =",
            "-  1 +",
            "-  2;",
            "+const x = 1 + 2;",
        ]);
        assert!(is_whitespace_only(&hunk));
    }

    #[test]
    fn test_semicolon_stripping() {
        // TypeScript: trailing semicolon added/removed counts as whitespace-only
        let hunk = make_hunk(&["@@ -1,2 +1,2 @@", "-const x = 1 + 2", "+const x = 1 + 2;"]);
        assert!(is_whitespace_only(&hunk));
    }

    #[test]
    fn test_no_changed_lines() {
        let hunk = make_hunk(&["@@ -1,3 +1,3 @@", " context line", " another context"]);
        assert!(!is_whitespace_only(&hunk));
    }

    #[test]
    fn test_parse_hunks_count() {
        let diff = "\
@@ -1,3 +1,3 @@
-foo
+foo
 context
@@ -10,2 +10,2 @@
-bar
+bar
";
        let hunks = parse_hunks(diff);
        assert_eq!(hunks.len(), 2);
    }

    #[test]
    fn test_parse_hunks_preserves_lines() {
        let diff = "@@ -1,2 +1,2 @@\n-old\n+new\n";
        let hunks = parse_hunks(diff);
        assert_eq!(hunks[0].lines.len(), 3);
        assert!(hunks[0].lines[0].starts_with("@@"));
    }

    #[test]
    fn test_empty_diff_produces_no_hunks() {
        assert!(parse_hunks("").is_empty());
    }

    #[test]
    fn test_diff_header_only_no_hunks() {
        let diff = "diff --git a/f.rs b/f.rs\nindex abc..def 100644\n--- a/f.rs\n+++ b/f.rs\n";
        assert!(parse_hunks(diff).is_empty());
    }

    #[test]
    fn test_added_only_hunk_not_whitespace() {
        // New block with no corresponding removed lines — not a whitespace change
        let hunk = make_hunk(&["@@ -0,0 +1,3 @@", "+line1", "+line2", "+line3"]);
        assert!(!is_whitespace_only(&hunk));
    }

    #[test]
    fn test_removed_only_hunk_not_whitespace() {
        let hunk = make_hunk(&["@@ -1,3 +0,0 @@", "-line1", "-line2", "-line3"]);
        assert!(!is_whitespace_only(&hunk));
    }

    #[test]
    fn test_mixed_hunks_independent() {
        // Verify is_whitespace_only is per-hunk, not across the whole diff
        let ws = make_hunk(&["@@ -1,2 +1,2 @@", "-  foo", "+    foo"]);
        let content = make_hunk(&["@@ -5,2 +5,2 @@", "-old_value", "+new_value"]);
        assert!(is_whitespace_only(&ws));
        assert!(!is_whitespace_only(&content));
    }

    #[test]
    fn test_reorder_lines_same_content() {
        // Same lines in different order — sorted comparison catches it
        let hunk = make_hunk(&["@@ -1,3 +1,3 @@", "-alpha", "-beta", "+beta", "+alpha"]);
        assert!(is_whitespace_only(&hunk));
    }
}
