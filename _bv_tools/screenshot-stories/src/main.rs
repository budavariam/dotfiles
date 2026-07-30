mod annotate;
mod args;
mod rename;
mod storybook;
mod storycap;

use anyhow::Context;
use clap::Parser;
use std::collections::HashMap;
use std::fs;
use std::process::{Child, Command};

use args::Args;

const GREEN: &str = "\x1b[0;32m";
const BLUE: &str = "\x1b[0;34m";
const YELLOW: &str = "\x1b[1;33m";
const RESET: &str = "\x1b[0m";

struct StorybookGuard(Option<Child>);

impl Drop for StorybookGuard {
    fn drop(&mut self) {
        if let Some(mut child) = self.0.take() {
            println!("\nStopping Storybook...");
            let _ = child.kill();
            let _ = child.wait();
            println!("Storybook stopped");
        }
    }
}

fn start_storybook(url: &str) -> anyhow::Result<Child> {
    println!(
        "{}Warning: Storybook is not running at {}{}",
        YELLOW, url, RESET
    );
    println!("\nStarting Storybook...");

    let log = fs::File::create("/tmp/storybook.log").context("failed to create storybook log")?;
    let child = Command::new("npm")
        .args(["run", "storybook"])
        .stdout(log.try_clone()?)
        .stderr(log)
        .spawn()
        .context("failed to start storybook")?;

    println!("Waiting for Storybook to start...");
    for _ in 0..60 {
        if storybook::is_storybook_running(url) {
            println!("{}Storybook is ready!{}", GREEN, RESET);
            return Ok(child);
        }
        std::thread::sleep(std::time::Duration::from_secs(1));
    }

    anyhow::bail!("Storybook failed to start. Check /tmp/storybook.log");
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    println!(
        "{}Storybook Screenshot Tool (using Storycap){}",
        BLUE, RESET
    );
    println!();

    let storybook_started: bool;
    let _guard: StorybookGuard;

    if !storybook::is_storybook_running(&args.url) {
        if args.no_start {
            println!(
                "{}Storybook is not running at {}{}",
                YELLOW, args.url, RESET
            );
            println!("Hint: Remove --no-start to auto-start Storybook");
            std::process::exit(1);
        }
        let child = start_storybook(&args.url)?;
        storybook_started = true;
        _guard = StorybookGuard(Some(child));
    } else {
        println!("{}Storybook is running{}", GREEN, RESET);
        storybook_started = false;
        _guard = StorybookGuard(None);
    }

    println!("\nConfiguration:");
    println!("  URL: {}", args.url);
    println!("  Output: {}", args.output);
    println!("  Viewport: {}", args.viewport);
    println!("  Parallel: {}", args.parallel);
    if args.delay > 0 {
        println!("  Delay: {}ms", args.delay);
    }
    if let Some(ref tags) = args.tags {
        println!("  Tags: {}", tags);
        if args.use_ids {
            println!("  Format: Story IDs (dashes)");
        } else {
            println!("  Format: Story Names (slashes)");
        }
    }
    if let Some(ref stories) = args.stories {
        println!("  Stories: {}", stories);
    }
    println!();

    let output_path = std::path::Path::new(&args.output);
    fs::create_dir_all(output_path).context("failed to create output directory")?;

    // Use IndexMap-style ordering: insertion order, last write wins for dupes.
    let mut merged: Vec<String> = Vec::new();
    let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();
    let mut id_name_map: HashMap<String, String> = HashMap::new();

    if let Some(ref stories_str) = args.stories {
        let names: Vec<String> = stories_str
            .split(',')
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect();
        if names.is_empty() {
            println!(
                "{}Warning: --stories value is empty, ignoring{}",
                YELLOW, RESET
            );
        } else {
            println!("Direct stories: {}", names.len());
            for name in &names {
                if seen.insert(name.clone()) {
                    merged.push(name.clone());
                }
            }
        }
    }

    if let Some(ref tags_str) = args.tags {
        let tags: Vec<&str> = tags_str.split(',').map(|t| t.trim()).collect();
        println!("Fetching stories with tags: {}", tags.join(", "));

        let stories_data = storybook::fetch_stories(&args.url)?;
        let (list, map) = storybook::filter_stories_by_tags(&stories_data, &tags, false);

        if list.is_empty() {
            println!(
                "{}Warning: No stories found with tags: {}{}",
                YELLOW, tags_str, RESET
            );
        } else {
            println!("Stories from tags: {}", list.len());
            for name in &list {
                if seen.insert(name.clone()) {
                    merged.push(name.clone());
                }
            }
            id_name_map = map;
        }
    }

    let story_names: Option<Vec<String>> = if args.stories.is_some() || args.tags.is_some() {
        if merged.is_empty() {
            println!("{}Warning: No stories matched any filter, running without filter{}", YELLOW, RESET);
            None
        } else {
            println!("Total unique stories to capture: {}", merged.len());
            for name in merged.iter().take(10) {
                println!("  - {}", name);
            }
            if merged.len() > 10 {
                println!("  ... and {} more", merged.len() - 10);
            }
            println!();
            Some(merged)
        }
    } else {
        None
    };

    storycap::run_storycap(&args, story_names.as_deref())?;

    if !id_name_map.is_empty() {
        println!();
        println!("{}", "=".repeat(60));
        rename::rename_screenshots(output_path, &id_name_map, args.use_ids)?;
    }

    if args.annotate {
        println!();
        println!("{}", "=".repeat(60));
        annotate::annotate_screenshots(output_path, &id_name_map, args.use_ids)?;
    }

    println!();
    println!(
        "{}Done! Screenshots saved to: {}{}",
        GREEN, args.output, RESET
    );

    let _ = storybook_started;
    Ok(())
}
