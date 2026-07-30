# bv_tools

Personal CLI utilities written in Rust, living inside the dotfiles repo. Not published to crates.io, not versioned separately — just small tools that got complex enough to deserve proper argument parsing, tests, and type safety over bash/Python.

## Tools

| Command | Replaces | Description |
|---|---|---|
| `record-asciinema_rs` | `record-asciinema` (bash) | Record a terminal session from a screenplay script using tmux + asciinema |
| `screenshot-stories_rs` | `screenshot-stories` / `screenshot-stories.py` | Capture Storybook screenshots via Storycap, with tag filtering and image annotation |
| `show-whitespace-diff_rs` | `show-whitespace-diff` (bash+Python) | Find git diff hunks that are whitespace/formatting-only changes |

The originals remain in place under `~/scripts` until each Rust version is validated.

## How it works

The workspace lives at `~/project/dotfiles/_bv_tools/`. Each tool is a separate Cargo binary crate. Release binaries are written to `target/release/` and are **not committed** (`.gitignore` covers `target/`).

The `_rs`-suffixed wrapper scripts in `~/scripts/` (stowed from `_mac/scripts/scripts/`) handle the build-on-demand logic: before executing the binary they check whether any `.rs` source file is newer than the binary and rebuild the whole workspace if so. You wait for the build the first time or after editing source; subsequent invocations are instant.

```
dotfiles/
  _bv_tools/
    Cargo.toml                  ← workspace root
    build.sh / clippy.sh / fmt.sh
    record-asciinema/           ← binary crate
    screenshot-stories/         ← binary crate
    show-whitespace-diff/       ← binary crate
    target/release/             ← compiled binaries (gitignored)
  _mac/scripts/scripts/
    record-asciinema_rs         ← wrapper: staleness check → exec binary
    screenshot-stories_rs       ← wrapper: staleness check → exec binary
    show-whitespace-diff_rs     ← wrapper: staleness check → exec binary
```

## Development

```sh
# Build / lint / format — whole workspace, or a single crate
./build.sh
./build.sh record-asciinema

./clippy.sh
./clippy.sh show-whitespace-diff

./fmt.sh
./fmt.sh screenshot-stories

# Run tests across the workspace (or a single crate)
cargo test --manifest-path Cargo.toml
cargo test --manifest-path Cargo.toml -p show-whitespace-diff
```

## Adding a new tool

1. `cargo new --bin <name>` inside `_bv_tools/`
2. Add `"<name>"` to the `members` array in `Cargo.toml`
3. Add `clap` (derive) and `anyhow` to the crate's `Cargo.toml`
4. Write a wrapper script in `_mac/scripts/scripts/<name>_rs` (copy any existing one — only the `_bin` path changes)
5. `chmod +x` the wrapper
