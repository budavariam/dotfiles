mod args;
mod diff;
mod git;

use anyhow::Context;
use clap::Parser;
use std::path::Path;

use args::Args;

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let repo = Path::new(&args.repo);

    if !repo.exists() {
        anyhow::bail!("repo path not found: {}", args.repo);
    }

    let files = git::changed_files(repo, &args.base, &args.compare)
        .context("failed to get changed files")?;

    if files.is_empty() {
        println!(
            "No changed files between {} and {} in {}",
            args.base, args.compare, args.repo
        );
        return Ok(());
    }

    let mut entirely_whitespace = 0;
    let mut hunk_whitespace = 0;

    for file in &files {
        if !git::file_exists_in_ref(repo, &args.base, file) {
            continue;
        }

        let full = git::diff(repo, &args.base, &args.compare, file, false)?;
        if full.is_empty() {
            continue;
        }

        let ws = git::diff(repo, &args.base, &args.compare, file, true)?;
        if ws.is_empty() {
            let stat = git::diff_stat(repo, &args.base, &args.compare, file)?;
            println!("=== ENTIRELY WHITESPACE: {} ===", file);
            print!("{}", stat);
            println!();
            entirely_whitespace += 1;
            continue;
        }

        let hunks = diff::parse_hunks(&full);
        let ws_hunks: Vec<_> = hunks
            .iter()
            .filter(|h| diff::is_whitespace_only(h))
            .collect();

        if !ws_hunks.is_empty() {
            println!(
                "\n=== WHITESPACE-ONLY HUNKS in {} ({} hunk(s)) ===",
                file,
                ws_hunks.len()
            );
            for hunk in &ws_hunks {
                for line in &hunk.lines {
                    println!("{}", line);
                }
            }
            hunk_whitespace += ws_hunks.len();
        }
    }

    if entirely_whitespace == 0 && hunk_whitespace == 0 {
        println!(
            "No whitespace-only changes found between {} and {}",
            args.base, args.compare
        );
    }

    Ok(())
}
