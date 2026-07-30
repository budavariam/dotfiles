use crate::args::Args;
use anyhow::Context;
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};

pub fn run_storycap(args: &Args, story_names: Option<&[String]>) -> anyhow::Result<()> {
    let mut cmd = Command::new("npx");
    cmd.arg("--yes")
        .arg("storycap@5.0.1")
        .arg(&args.url)
        .arg("--outDir")
        .arg(&args.output)
        .arg("--viewport")
        .arg(&args.viewport)
        .arg("--parallel")
        .arg(args.parallel.to_string())
        .env("npm_config_yes", "true");

    if args.delay > 0 {
        cmd.arg("--delay").arg(args.delay.to_string());
    }

    if let Some(names) = story_names {
        for name in names {
            cmd.arg("--include").arg(name);
        }
    }

    if args.silent {
        cmd.arg("--silent");
    }
    if args.verbose {
        cmd.arg("--verbose");
    }
    if args.flat {
        cmd.arg("--flat");
    }

    for extra in &args.extra {
        cmd.arg(extra);
    }

    if !args.extra.is_empty() {
        println!("Extra storycap args: {}", args.extra.join(" "));
    }

    let cmd_args: Vec<String> = std::iter::once("npx".to_string())
        .chain(
            cmd.get_args()
                .map(|a| a.to_string_lossy().into_owned()),
        )
        .collect();
    println!("Storycap command: {}", cmd_args.join(" "));
    println!();

    println!("Running storycap...");
    if args.delay > 0 {
        println!("  (with {}ms delay before each capture)", args.delay);
    }
    println!();

    cmd.stdout(Stdio::piped()).stderr(Stdio::inherit());

    let mut child = cmd.spawn().context("failed to spawn npx storycap")?;

    if let Some(stdout) = child.stdout.take() {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            println!("{}", line.context("failed to read storycap output")?);
        }
    }

    let status = child.wait().context("failed to wait for storycap")?;
    if !status.success() {
        anyhow::bail!("storycap exited with status {}", status);
    }

    Ok(())
}
