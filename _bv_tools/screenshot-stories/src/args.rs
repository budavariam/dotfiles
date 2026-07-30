use clap::Parser;

#[derive(Parser, Debug)]
#[command(
    name = "screenshot-stories",
    about = "Capture screenshots of Storybook stories using Storycap",
    after_help = r#"Examples:
  # Basic usage
  screenshot-stories

  # Custom viewport and output
  screenshot-stories --viewport 1920x1080 --output ./pr-images

  # Filter by tags
  screenshot-stories --tags pr-screenshots,visual-test

  # Capture specific stories by name
  screenshot-stories --stories "Button/Primary,Button/Secondary"

  # With delay for animations
  screenshot-stories --delay 1000

  # High performance capture
  screenshot-stories --parallel 8 --viewport 2560x1440

  # Add timestamp and story name to screenshots
  screenshot-stories --annotate

  # Pass additional arguments to storycap (use -- separator)
  screenshot-stories --tags demo -- --captureTimeout 10000 --disableCssAnimation

  # Complete example with all features
  screenshot-stories --tags demo --annotate --viewport 1920x1080 --output ./screenshots -- --forwardConsoleLogs"#
)]
pub struct Args {
    #[arg(
        long,
        default_value = "http://localhost:6006",
        help = "Storybook server URL"
    )]
    pub url: String,

    #[arg(
        short,
        long,
        default_value = "./screenshots",
        help = "Output directory for screenshots"
    )]
    pub output: String,

    #[arg(
        short,
        long,
        default_value = "1280x720",
        help = "Viewport size in WIDTHxHEIGHT format"
    )]
    pub viewport: String,

    #[arg(short, long, help = "Comma-separated Storybook tags to filter stories")]
    pub tags: Option<String>,

    #[arg(
        long,
        help = "Comma-separated story names or IDs to capture (e.g. 'Button/Primary,Button/Secondary')"
    )]
    pub stories: Option<String>,

    #[arg(
        short,
        long,
        default_value_t = 0,
        help = "Delay in milliseconds before capturing each screenshot"
    )]
    pub delay: u32,

    #[arg(
        short,
        long,
        default_value_t = 4,
        help = "Number of parallel browser instances"
    )]
    pub parallel: u32,

    #[arg(long, help = "Do not auto-start Storybook if not running")]
    pub no_start: bool,

    #[arg(long, help = "Suppress storycap output")]
    pub silent: bool,

    #[arg(long, help = "Show detailed storycap logs")]
    pub verbose: bool,

    #[arg(long, help = "Flatten output filename structure")]
    pub flat: bool,

    #[arg(
        long,
        help = "Use story IDs (with dashes) for output filenames instead of names (with slashes)"
    )]
    pub use_ids: bool,

    #[arg(long, help = "Add timestamp and story name at bottom of screenshots")]
    pub annotate: bool,

    #[arg(last = true, help = "Extra arguments passed through to storycap")]
    pub extra: Vec<String>,
}
