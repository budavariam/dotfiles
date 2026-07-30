use anyhow::Context;
use std::collections::HashMap;
use std::path::Path;

pub fn build_new_filename(story_id: &str, story_name: &str, use_ids: bool) -> String {
    if use_ids {
        format!("{}.png", story_id)
    } else {
        format!("{}.png", story_name.replace(['/', ' '], "-"))
    }
}

pub fn rename_screenshots(
    output_dir: &Path,
    id_name_map: &HashMap<String, String>,
    use_ids: bool,
) -> anyhow::Result<()> {
    println!("Renaming screenshot files...");

    let total = id_name_map.len();
    let mut renamed = 0;
    let mut not_found = 0;
    let mut skipped = 0;

    for (i, (story_id, story_name)) in id_name_map.iter().enumerate() {
        println!("[{}/{}] Processing: {}", i + 1, total, story_name);

        let src = output_dir.join(format!("{}.png", story_name));
        let new_filename = build_new_filename(story_id, story_name, use_ids);
        let dst = output_dir.join(&new_filename);

        if !src.exists() {
            println!("    \u{2298} File not found at expected path");
            println!("       Expected: {}", src.display());
            not_found += 1;
            continue;
        }

        if src == dst {
            println!("    = Already correct");
            skipped += 1;
            continue;
        }

        if let Some(parent) = dst.parent() {
            std::fs::create_dir_all(parent).context("failed to create target directory")?;
        }

        std::fs::rename(&src, &dst)
            .with_context(|| format!("failed to rename {} to {}", src.display(), dst.display()))?;
        renamed += 1;
        println!("    \u{2713} \u{2192} {}", new_filename);
    }

    println!("\nSummary:");
    println!("  Renamed: {}", renamed);
    println!("  Not found: {}", not_found);
    println!("  Skipped: {}", skipped);

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_use_ids_filename() {
        let result = build_new_filename(
            "components-button--primary",
            "Components/Button/Primary",
            true,
        );
        assert_eq!(result, "components-button--primary.png");
    }

    #[test]
    fn test_use_names_filename() {
        let result = build_new_filename(
            "components-button--primary",
            "Components/Button/Primary",
            false,
        );
        assert_eq!(result, "Components-Button-Primary.png");
    }

    #[test]
    fn test_use_names_filename_with_spaces() {
        let result = build_new_filename("some-id", "Some Component/My Button", false);
        assert_eq!(result, "Some-Component-My-Button.png");
    }
}
