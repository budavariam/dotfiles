use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "show-whitespace-diff",
    about = "Show diff hunks that are whitespace/newline-only changes",
    after_help = "Examples:
  show-whitespace-diff api
  show-whitespace-diff ui main feat/new-info
  show-whitespace-diff . HEAD~5 HEAD"
)]
pub struct Args {
    #[arg(default_value = ".", help = "Path to the git repository")]
    pub repo: String,

    #[arg(default_value = "development", help = "Base branch or commit")]
    pub base: String,

    #[arg(default_value = "HEAD", help = "Branch or commit to compare")]
    pub compare: String,
}
