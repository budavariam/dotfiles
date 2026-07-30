use std::path::Path;

pub struct PreprocessResult {
    pub content: String,
    pub total_actions: usize,
}

fn detect_heredoc_delimiter(line: &str) -> Option<String> {
    // Look for << or <<- in the line
    let mut rest = line;
    while let Some(pos) = rest.find("<<") {
        let after_lt = &rest[pos + 2..];
        // skip optional '-'
        let after_dash = after_lt.strip_prefix('-').unwrap_or(after_lt);
        // skip spaces
        let after_spaces = after_dash.trim_start_matches(' ');
        // skip optional quote
        let (after_quote, _quoted) = if let Some(s) = after_spaces.strip_prefix('\'') {
            (s, true)
        } else {
            (after_spaces, false)
        };
        // read identifier
        let ident: String = after_quote
            .chars()
            .take_while(|c| c.is_ascii_alphabetic() || *c == '_' || c.is_ascii_alphanumeric())
            .collect();
        if !ident.is_empty() {
            // first char must be alpha or _
            let first = ident.chars().next().unwrap();
            if first.is_ascii_alphabetic() || first == '_' {
                return Some(ident);
            }
        }
        // advance past this <<
        rest = &rest[pos + 2..];
    }
    None
}

pub fn preprocess(source: &str, helper_path: &Path) -> PreprocessResult {
    let helper_source_line = format!(". \"{}\"", helper_path.display());
    let mut output = String::new();
    let mut total_actions = 0usize;
    let mut heredoc_delim: Option<String> = None;

    output.push_str(&helper_source_line);
    output.push('\n');

    for line in source.lines() {
        if let Some(ref delim) = heredoc_delim.clone() {
            // Check for closing delimiter (exact match, trimmed)
            if line.trim() == delim.as_str() {
                heredoc_delim = None;
            }
            output.push_str(line);
            output.push('\n');
            continue;
        }

        // Check for heredoc opener
        if let Some(delim) = detect_heredoc_delimiter(line) {
            heredoc_delim = Some(delim);
        }

        // Check if this line counts as an action
        let stripped = line.trim_start();
        if !stripped.is_empty() && !stripped.starts_with('#') {
            total_actions += 1;
            output.push_str(&format!("_prog_line {}\n", total_actions));
        }

        output.push_str(line);
        output.push('\n');
    }

    PreprocessResult {
        content: output,
        total_actions,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    fn helper_path() -> &'static Path {
        Path::new("/tmp/helper.sh")
    }

    #[test]
    fn test_basic_injection() {
        let source = "cmd1\ncmd2\ncmd3\n";
        let result = preprocess(source, helper_path());
        assert_eq!(result.total_actions, 3);
        assert!(result.content.contains("_prog_line 1"));
        assert!(result.content.contains("_prog_line 2"));
        assert!(result.content.contains("_prog_line 3"));
    }

    #[test]
    fn test_comment_lines_skipped() {
        let source = "# this is a comment\ncmd1\n# another comment\n";
        let result = preprocess(source, helper_path());
        assert_eq!(result.total_actions, 1);
        assert!(result.content.contains("_prog_line 1"));
        assert!(!result.content.contains("_prog_line 2"));
    }

    #[test]
    fn test_blank_lines_skipped() {
        let source = "\n\ncmd1\n\ncmd2\n";
        let result = preprocess(source, helper_path());
        assert_eq!(result.total_actions, 2);
    }

    #[test]
    fn test_heredoc_interior_not_injected() {
        let source = "cat <<EOF\nline inside heredoc\nEOF\n";
        let result = preprocess(source, helper_path());
        // Only the cat <<EOF line gets _prog_line, not the interior
        assert_eq!(result.total_actions, 1);
        // The interior line should not have a _prog_line before it
        let lines: Vec<&str> = result.content.lines().collect();
        let heredoc_interior_idx = lines
            .iter()
            .position(|l| *l == "line inside heredoc")
            .unwrap();
        assert!(heredoc_interior_idx > 0);
        assert!(!lines[heredoc_interior_idx - 1].starts_with("_prog_line"));
    }

    #[test]
    fn test_heredoc_opener_gets_injected() {
        let source = "cat <<EOF\nsome content\nEOF\n";
        let result = preprocess(source, helper_path());
        let lines: Vec<&str> = result.content.lines().collect();
        let opener_idx = lines.iter().position(|l| l.contains("<<EOF")).unwrap();
        assert!(opener_idx > 0 && lines[opener_idx - 1].starts_with("_prog_line"));
    }

    #[test]
    fn test_heredoc_quoted_delimiter() {
        let source = "cat <<'EOF'\nsome content\nEOF\n";
        let result = preprocess(source, helper_path());
        assert_eq!(result.total_actions, 1);
    }

    #[test]
    fn test_total_actions_count() {
        let source = "# comment\ncmd1\ncmd2\n\ncmd3\n";
        let result = preprocess(source, helper_path());
        assert_eq!(result.total_actions, 3);
        let count = result.content.matches("_prog_line").count();
        assert_eq!(count, 3);
    }

    #[test]
    fn test_helper_sourced_first() {
        let source = "cmd1\n";
        let result = preprocess(source, helper_path());
        let first_line = result.content.lines().next().unwrap();
        assert!(first_line.starts_with(". \""));
        assert!(first_line.contains("helper.sh"));
    }
}
