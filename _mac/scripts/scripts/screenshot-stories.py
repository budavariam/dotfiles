#!/usr/bin/env python3

"""
Storybook Screenshot Script using Storycap
Storycap: https://storybook.js.org/addons/storycap

This script captures screenshots of Storybook stories without installing dependencies.
It uses npx to run storycap on-demand.

Requirements:
  - Python: 3.6+
  - Node.js/npm: Required for npx and storycap (npm install not needed, uses npx)
  - Pillow: Optional, only needed for --annotate flag (pip install Pillow)

Example usage:
  screenshot-stories.py --tags "demo" --delay 1000 --output ./screenshots --viewport 1280x720 --use-ids --annotate
  screenshot-stories.py --tags "demo" --delay 3000 --output ./screenshots --viewport 640x720 --use-ids  
  screenshot-stories.py --tags "demo" -- --captureTimeout 10000 --forwardConsoleLogs

Note: Any arguments after -- are passed directly to storycap

How it works:
1. Fetches story metadata from Storybook's index.json
2. Filters stories by tags if specified
3. Runs storycap with story names (e.g., "Components/Button/Primary")
4. Storycap creates files at: screenshots/Components/Button/Primary.png
5. If --use-ids is set, renames to: screenshots/story-id.png
   Otherwise, renames to: screenshots/Components-Button-Primary.png
6. If --annotate is set, adds timestamp and story name at the bottom of each image
   (requires ImageMagick: brew install imagemagick)
"""

import sys
import json
import time
import argparse
import subprocess
import urllib.request
import urllib.error
import os
from datetime import datetime
from typing import Optional, List, Dict, Tuple

# ANSI color codes
GREEN = '\033[0;32m'
BLUE = '\033[0;34m'
YELLOW = '\033[1;33m'
NC = '\033[0m'  # No Color


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description='Capture screenshots of Storybook stories using Storycap',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage
  %(prog)s

  # Custom viewport and output
  %(prog)s --viewport 1920x1080 --output ./pr-images

  # Filter by tags
  %(prog)s --tags pr-screenshots,visual-test

  # With delay for animations
  %(prog)s --delay 1000

  # High performance capture
  %(prog)s --parallel 8 --viewport 2560x1440

  # Add timestamp and story name to screenshots
  %(prog)s --annotate

  # Pass additional arguments to storycap (use -- separator)
  %(prog)s --tags demo -- --captureTimeout 10000 --disableCssAnimation

  # Complete example with all features
  %(prog)s --tags demo --annotate --viewport 1920x1080 --output ./screenshots -- --forwardConsoleLogs
        """
    )

    parser.add_argument(
        '--url',
        default='http://localhost:6006',
        help='Storybook server URL (default: http://localhost:6006)'
    )

    parser.add_argument(
        '-o', '--output',
        default='./screenshots',
        help='Output directory for screenshots (default: ./screenshots)'
    )

    parser.add_argument(
        '-v', '--viewport',
        default='1280x720',
        help='Viewport size in WIDTHxHEIGHT format (default: 1280x720)'
    )

    parser.add_argument(
        '-t', '--tags',
        help='Comma-separated Storybook tags to filter stories (e.g., pr-screenshots,visual-test)'
    )

    parser.add_argument(
        '-d', '--delay',
        type=int,
        default=0,
        help='Delay in milliseconds before capturing each screenshot (default: 0)'
    )

    parser.add_argument(
        '-p', '--parallel',
        type=int,
        default=4,
        help='Number of parallel browser instances (default: 4)'
    )

    parser.add_argument(
        '--no-start',
        action='store_true',
        help='Do not auto-start Storybook if not running'
    )

    parser.add_argument(
        '--silent',
        action='store_true',
        help='Suppress storycap output'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Show detailed storycap logs'
    )

    parser.add_argument(
        '--flat',
        action='store_true',
        help='Flatten output filename structure'
    )

    parser.add_argument(
        '--use-ids',
        action='store_true',
        help='Use story IDs (with dashes) for output filenames instead of names (with slashes)'
    )

    parser.add_argument(
        '--annotate',
        action='store_true',
        help='Add timestamp and story name at bottom of screenshots (requires Pillow: pip install Pillow)'
    )

    # Parse known args and capture remaining args for storycap
    args, extra_args = parser.parse_known_args()
    args.extra_storycap_args = extra_args

    return args


def print_colored(color: str, message: str) -> None:
    """Print colored message to console."""
    print(f"{color}{message}{NC}")


def is_storybook_running(url: str) -> bool:
    """Check if Storybook is running at the given URL."""
    try:
        urllib.request.urlopen(url, timeout=2)
        return True
    except (urllib.error.URLError, TimeoutError):
        return False


def start_storybook(url: str) -> Optional[subprocess.Popen]:
    """Start Storybook in the background."""
    print_colored(YELLOW, f"⚠️  Storybook is not running at {url}")
    print("\nStarting Storybook...")

    with open('/tmp/storybook.log', 'w') as log_file:
        process = subprocess.Popen(
            ['npm', 'run', 'storybook'],
            stdout=log_file,
            stderr=log_file
        )

    print("Waiting for Storybook to start...")
    for i in range(60):
        if is_storybook_running(url):
            print_colored(GREEN, "✅ Storybook is ready!")
            return process
        time.sleep(1)

    print_colored(YELLOW, "❌ Storybook failed to start. Check /tmp/storybook.log")
    sys.exit(1)


def fetch_stories(url: str) -> dict:
    """Fetch stories index from Storybook."""
    try:
        with urllib.request.urlopen(f"{url}/index.json") as response:
            return json.loads(response.read())
    except Exception as e:
        print_colored(YELLOW, f"⚠️  Failed to fetch stories: {e}")
        return {}


def filter_stories_by_tags(stories_data: dict, tags: List[str], use_ids: bool = False) -> Tuple[List[str], Dict[str, str]]:
    """
    Filter stories by tags, returning both filtered list and ID-to-name mapping.

    Returns:
        tuple: (filtered_stories, id_name_map) where filtered_stories contains
               either IDs or names based on use_ids flag, and id_name_map is a
               dict mapping story IDs to their readable names.
    """
    if not stories_data or 'entries' not in stories_data:
        return [], {}

    filtered_stories = []
    id_name_map = {}

    for story_id, story_data in stories_data['entries'].items():
        story_tags = story_data.get('tags', [])
        if story_tags and any(tag in story_tags for tag in tags):
            # Build readable name
            title = story_data.get('title', '')
            name = story_data.get('name', '')
            if title and name:
                readable_name = f"{title}/{name}"
                id_name_map[story_id] = readable_name

                # Add either ID or name based on use_ids flag
                if use_ids:
                    filtered_stories.append(story_id)
                else:
                    filtered_stories.append(readable_name)

    return filtered_stories, id_name_map


def rename_screenshots(output_dir: str, id_name_map: Dict[str, str], use_ids: bool) -> None:
    """
    Rename screenshot files based on use_ids flag.

    Args:
        output_dir: Directory containing screenshots
        id_name_map: Mapping of story IDs to readable names
        use_ids: If True, rename to use IDs; if False, rename to use names
    """
    if not id_name_map:
        return

    print("Renaming screenshot files...")
    sys.stdout.flush()

    renamed_count = 0
    skipped_count = 0
    not_found_count = 0

    # Process each story we know about
    for i, (story_id, story_name) in enumerate(id_name_map.items(), 1):
        print(f"[{i}/{len(id_name_map)}] Processing: {story_name}")
        sys.stdout.flush()

        # Construct the path that storycap would have created
        # Format: screenshots/Components/Button/Primary.png
        expected_path = os.path.join(output_dir, f"{story_name}.png")

        # Check if the file exists
        if not os.path.exists(expected_path):
            print(f"    ⊘ File not found at expected path")
            print(f"       Expected: {expected_path}")
            sys.stdout.flush()
            not_found_count += 1
            continue

        # Determine new filename based on use_ids flag
        if use_ids:
            # Use ID-based naming: screenshots/story-id.png
            new_filename = f"{story_id}.png"
        else:
            # Use name-based naming with dashes: screenshots/Components-Button-Primary.png
            safe_name = story_name.replace('/', '-').replace(' ', '-')
            new_filename = f"{safe_name}.png"

        new_path = os.path.join(output_dir, new_filename)

        # Skip if already has the correct name
        if expected_path == new_path:
            print(f"    = Already correct")
            sys.stdout.flush()
            continue

        # Create target directory if needed
        target_dir = os.path.dirname(new_path)
        if target_dir and not os.path.exists(target_dir):
            os.makedirs(target_dir, exist_ok=True)

        # Rename the file (overwrite if target exists)
        try:
            os.replace(expected_path, new_path)
            renamed_count += 1
            print(f"    ✓ → {new_filename}")
            sys.stdout.flush()
        except OSError as e:
            print_colored(YELLOW, f"    ⚠️  Failed to rename: {e}")
            sys.stdout.flush()
            skipped_count += 1

    print(f"\n📊 Summary:")
    print(f"  Renamed: {renamed_count}")
    print(f"  Not found: {not_found_count}")
    print(f"  Skipped: {skipped_count}")
    sys.stdout.flush()


def run_storycap(args, story_names: Optional[List[str]] = None) -> None:
    """Run storycap to capture screenshots."""
    cmd = [
        'npx', 'storycap@5.0.1',
        args.url,
        '--outDir', args.output,
        '--viewport', args.viewport,
        '--parallel', str(args.parallel)
    ]

    # Add delay if specified
    if args.delay > 0:
        cmd.extend(['--delay', str(args.delay)])

    # Add story filter if specified
    # v5: --include is an array type; pass one flag per story name
    if story_names:
        for story_name in story_names:
            cmd.extend(['--include', story_name])

    # Add output options
    if args.silent:
        cmd.append('--silent')
    if args.verbose:
        cmd.append('--verbose')
    if args.flat:
        cmd.append('--flat')

    # Add any extra arguments passed after --
    if args.extra_storycap_args:
        cmd.extend(args.extra_storycap_args)
        print(f"Extra storycap args: {' '.join(args.extra_storycap_args)}")

    print("Running storycap...")
    if args.delay > 0:
        print(f"  (with {args.delay}ms delay before each capture)")
    print()
    sys.stdout.flush()

    # Run with real-time output to avoid appearance of hanging
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
        bufsize=1
    )

    # Stream output in real-time
    if process.stdout:
        for line in process.stdout:
            print(line, end='')
            sys.stdout.flush()

    # Wait for completion
    return_code = process.wait()

    if return_code != 0:
        raise subprocess.CalledProcessError(return_code, cmd)


def cleanup(storybook_process: Optional[subprocess.Popen]) -> None:
    """Stop Storybook if we started it."""
    if storybook_process:
        print("\nStopping Storybook...")
        sys.stdout.flush()
        storybook_process.terminate()
        try:
            storybook_process.wait(timeout=5)
            print("Storybook stopped successfully")
            sys.stdout.flush()
        except subprocess.TimeoutExpired:
            print("Storybook didn't stop gracefully, killing it...")
            sys.stdout.flush()
            storybook_process.kill()
            storybook_process.wait()
            print("Storybook killed")
            sys.stdout.flush()


def get_git_commit_hash() -> str:
    """Get the current git commit hash (short version)."""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
            universal_newlines=True,
            cwd=os.getcwd()
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown hash"


def annotate_screenshots(output_dir: str, id_name_map: Dict[str, str], use_ids: bool) -> None:
    """
    Add timestamp, git hash, and story name to the bottom of screenshots, extending the image.

    Args:
        output_dir: Directory containing screenshots
        id_name_map: Mapping of story IDs to readable names
        use_ids: If True, filenames use IDs; if False, filenames use names
    """
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print_colored(YELLOW, "⚠️  Pillow not found. Skipping annotation.")
        print("   Install with: pip install Pillow")
        return

    # Try common macOS system fonts; fall back to Pillow's built-in bitmap font
    font = None
    for font_path in [
        '/System/Library/Fonts/Helvetica.ttc',
        '/System/Library/Fonts/SFNSText.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
        '/Library/Fonts/Arial.ttf',
    ]:
        if os.path.exists(font_path):
            try:
                font = ImageFont.truetype(font_path, 14)
                break
            except Exception:
                continue
    if font is None:
        font = ImageFont.load_default()

    print("Adding annotations to screenshots...")
    sys.stdout.flush()

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    git_hash = get_git_commit_hash()
    annotated_count = 0
    failed_count = 0

    png_files = []
    for root, _, files in os.walk(output_dir):
        for file in files:
            if file.endswith('.png'):
                png_files.append(os.path.join(root, file))

    for i, png_path in enumerate(png_files, 1):
        filename = os.path.basename(png_path)
        story_name = filename[:-4]  # Remove .png extension

        if id_name_map:
            if use_ids:
                story_name = id_name_map.get(story_name, story_name)
            else:
                story_name = story_name.replace('-', ' / ')

        print(f"[{i}/{len(png_files)}] Annotating: {filename}")
        sys.stdout.flush()

        line1 = story_name
        line2 = f"{timestamp}  |  {git_hash}"

        try:
            img = Image.open(png_path).convert('RGB')
            bar_height = 60
            new_img = Image.new('RGB', (img.width, img.height + bar_height), 'white')
            new_img.paste(img, (0, 0))
            draw = ImageDraw.Draw(new_img)

            # Separator line
            draw.line([(0, img.height), (img.width, img.height)], fill='#cccccc', width=2)

            # Centered text (anchor='mt' = middle-top, requires Pillow 8+)
            cx = img.width // 2
            draw.text((cx, img.height + 10), line1, fill='black', font=font, anchor='mt')
            draw.text((cx, img.height + 36), line2, fill='black', font=font, anchor='mt')

            new_img.save(png_path)
            annotated_count += 1
            print(f"    ✓ Added: {line1}")
            print(f"           {line2}")
            sys.stdout.flush()

        except Exception as e:
            print_colored(YELLOW, f"    ⚠️  Failed to annotate: {e}")
            sys.stdout.flush()
            failed_count += 1

    print(f"\n📊 Annotation Summary:")
    print(f"  Annotated: {annotated_count}")
    print(f"  Failed: {failed_count}")
    sys.stdout.flush()



def main():
    """Main execution flow."""
    args = parse_args()

    print_colored(BLUE, "📸 Storybook Screenshot Tool (using Storycap)")
    print()

    storybook_process = None

    try:
        # Check if Storybook is running
        if not is_storybook_running(args.url):
            if args.no_start:
                print_colored(YELLOW, f"❌ Storybook is not running at {args.url}")
                print("Hint: Remove --no-start to auto-start Storybook")
                sys.exit(1)
            storybook_process = start_storybook(args.url)
        else:
            print_colored(GREEN, "✅ Storybook is running")

        # Print configuration
        print("\nConfiguration:")
        print(f"  URL: {args.url}")
        print(f"  Output: {args.output}")
        print(f"  Viewport: {args.viewport}")
        print(f"  Parallel: {args.parallel}")
        if args.delay > 0:
            print(f"  Delay: {args.delay}ms")
        if args.tags:
            print(f"  Tags: {args.tags}")
            if args.use_ids:
                print(f"  Format: Story IDs (dashes)")
            else:
                print(f"  Format: Story Names (slashes)")
        print()

        # Create output directory
        os.makedirs(args.output, exist_ok=True)

        # Filter stories by tags if specified
        story_names = None
        id_name_map = {}

        if args.tags:
            tags = [tag.strip() for tag in args.tags.split(',')]
            print(f"Fetching stories with tags: {', '.join(tags)}")
            sys.stdout.flush()

            stories_data = fetch_stories(args.url)
            # Always get both names and IDs for complete information
            story_list, id_name_map = filter_stories_by_tags(stories_data, tags, use_ids=False)

            if not story_list:
                print_colored(YELLOW, f"⚠️  No stories found with tags: {args.tags}")
                print("Running without tag filter...")
                sys.stdout.flush()
                story_names = None
            else:
                # Always use readable names for storycap filtering
                story_names = story_list
                print(f"Found {len(story_names)} stories:")
                for name in story_names[:10]:
                    print(f"  - {name}")
                if len(story_names) > 10:
                    print(f"  ... and {len(story_names) - 10} more")

                # Debug: Show what we're sending to storycap
                if args.verbose:
                    print(f"\n📝 Story filter pattern for storycap:")
                    print(f"   {story_names[0] if story_names else 'none'}")
                    if len(story_names) > 1:
                        print(f"   ... (total: {len(story_names)})")

                sys.stdout.flush()
            print()

        # Run storycap (always with readable names)
        run_storycap(args, story_names)

        # Rename files based on --use-ids flag if we have tag filtering
        if args.tags and id_name_map:
            print()
            print("=" * 60)
            sys.stdout.flush()
            rename_screenshots(args.output, id_name_map, args.use_ids)

        # Annotate screenshots if requested
        if args.annotate:
            print()
            print("=" * 60)
            sys.stdout.flush()
            annotate_screenshots(args.output, id_name_map, args.use_ids)

        print()
        print_colored(GREEN, f"✨ Done! Screenshots saved to: {args.output}")

    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print_colored(YELLOW, f"\n❌ Command failed: {e}")
        sys.exit(1)
    except Exception as e:
        print_colored(YELLOW, f"\n❌ Error: {e}")
        sys.exit(1)
    finally:
        cleanup(storybook_process)


if __name__ == '__main__':
    main()


# ============================================================================
# STORYCAP v5.0.1 OPTIONS REFERENCE
# ============================================================================
#
# Usage: storycap [options] storybook_url
#
# Core Options:
#   -o, --outDir <dir>              Output directory (default: __screenshots__)
#   -p, --parallel <n>              Number of browsers (default: 4)
#   -f, --flat                      Flatten output filename
#   -V, --viewport <WxH>            Viewport, repeatable (default: ["800x600"])
#       --delay <ms>                Delay before each capture (default: 0)
#
# Story Selection:
#   -i, --include <pattern>         Include rule, repeatable (array)
#   -e, --exclude <pattern>         Exclude rule, repeatable (array)
#       --shard <n/total>           Shard this run across multiple machines (default: 1/1)
#
# Capture Tuning:
#       --captureTimeout <ms>       Timeout per story (default: 5000)
#       --captureMaxRetryCount <n>  Retries on failure (default: 3)
#       --metricsWatchRetryCount <n>Retries until browser metrics stable (default: 1000)
#       --viewportDelay <ms>        Delay after viewport change (default: 300)
#       --stateChangeDelay <ms>     Delay after element state change (default: 0)
#       --reloadAfterChangeViewport Reload after viewport change (default: false)
#       --disableCssAnimation       Disable CSS animation/transition (default: true)
#       --disableWaitAssets         Skip waiting for asset loads (default: false)
#
# Server:
#       --serverCmd <cmd>           Command to launch Storybook
#       --serverTimeout <ms>        Timeout for server start (default: 60000)
#
# Browser:
#   -C, --chromiumChannel <ch>      "puppeteer"|"canary"|"stable"|"*" (default: "*")
#       --chromiumPath <path>       Explicit Chromium executable path
#       --puppeteerLaunchConfig <j> JSON launch config for Puppeteer
#       --forwardConsoleLogs        Forward in-page console logs
#       --trace                     Emit Chromium trace files
#
# Output:
#       --silent                    Suppress output
#       --verbose                   Show detailed logs
#       --listDevices               List available device descriptors
#
# Examples:
#
#   # Basic usage
#   python3 scripts/screenshot-stories.py
#
#   # Custom viewport and output
#   python3 scripts/screenshot-stories.py --viewport 1920x1080 --output ./pr-images
#
#   # Filter by tags - output files will use readable names
#   python3 scripts/screenshot-stories.py --tags pr-screenshots
#   # → Creates: Components-Button-Primary.png
#
#   # Filter by tags using story IDs for output filenames
#   python3 scripts/screenshot-stories.py --tags pr-screenshots --use-ids
#   # → Creates: components-button--primary.png
#
#   # Multiple tags (OR logic)
#   python3 scripts/screenshot-stories.py --tags pr-screenshots,visual-test
#
#   # With delay for animations
#   python3 scripts/screenshot-stories.py --delay 1000
#
#   # High performance capture
#   python3 scripts/screenshot-stories.py --parallel 8 --viewport 2560x1440
#
#   # Add timestamp and story name at bottom of screenshots (requires Pillow: pip install Pillow)
#   python3 scripts/screenshot-stories.py --tags demo --annotate
#
#   # Complete example with all features
#   python3 scripts/screenshot-stories.py --tags pr-screenshots --annotate --viewport 1920x1080 --output ./screenshots
#
#   # Pass extra arguments to storycap (after -- separator)
#   python3 scripts/screenshot-stories.py --tags demo -- --captureTimeout 10000 --disableCssAnimation
#   python3 scripts/screenshot-stories.py -- --forwardConsoleLogs --verbose
#
#   # Run storycap directly
#   npx storycap@5.0.1 http://localhost:6006 --outDir ./screenshots -i "Button/Primary"
#   npx storycap@5.0.1 http://localhost:6006 --outDir ./screenshots -e "**/Internal/**"
#   npx storycap@5.0.1 http://localhost:6006 -V 2560x1440 --delay 1000 --parallel 8
#
# For more information:
#   npx storycap@5.0.1 --help
#   https://github.com/reg-viz/storycap
