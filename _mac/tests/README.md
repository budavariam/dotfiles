# Tests

[bats-core](https://github.com/bats-core/bats-core) suites for the shell scripts in this repo.
Currently covers the custom SketchyBar plugins (`../sketchybar/.config/sketchybar/plugins/`).
The tests live here, outside the `sketchybar` stow package, so `stow sketchybar` does not link them into `~`.

## Getting started

```sh
brew install bats-core jq   # once
_mac/tests/run.sh           # run everything
```

Run one suite, or one test by name:

```sh
_mac/tests/run.sh _mac/tests/sketchybar/ai.bats
_mac/tests/run.sh --filter "zero-padded" _mac/tests/sketchybar
```

`run.sh` checks the prerequisites (`bats`, `jq`, `python3`) and prints the install command if one is missing.
It exits non-zero when a test fails, so it can be used as a pre-push check.

## How the tests work

- No test touches the real system: no SketchyBar, no network, no `~/.claude`, no real `/tmp` state.
  Plugins call bare `sketchybar`, `osascript`, `pmset`, ... so each test puts stubs first on `PATH`.
  Everything a plugin tells SketchyBar is appended to `$SB_LOG` and asserted with `sb_has`.
- Shared helpers are in `sketchybar/helper.bash` (`load helper`): `setup_stubs`, `stub`, `stub_script`, `stub_logged`, `calls`, `sb_has`.
- Plugins whose state paths were hard-coded read them from environment variables with the old value as the default
  (for example `SB`, `FLAG_DIR`, `POPUP_FLAG` in `ai.sh`). Tests point them into `$BATS_TEST_TMPDIR`.

## Adding a test

1. Add a `@test` to the matching `.bats` file (or a new `<plugin>.bats` next to the others) starting with `load helper` and `setup_stubs`.
2. Stub every external command the plugin calls, run it with `SENDER`/`INFO`/`NAME` set as SketchyBar would, and assert on `$SB_LOG`.
3. If a plugin hard-codes a path you must stub, make it overridable with `${VAR:-default}`; don't change anything else.
