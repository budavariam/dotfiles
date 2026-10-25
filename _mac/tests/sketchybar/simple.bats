#!/usr/bin/env bats
# Tests for the small event-driven plugins: focus_status, front_app, keyboard, notification,
# sidecar_toggle, space, vpn_status, wifi_status.
# Run: bats _mac/tests/sketchybar     (see _mac/tests/README.md)

load helper

setup() {
  setup_stubs
}

# --- focus_status ---

@test "focus_status: focus_mode_on shows the active icon" {
  SENDER=focus_mode_on sh "$PLUGINS/focus_status.sh"
  sb_has 'icon=􀆺 icon.color=0xff5e5ce6'
}

@test "focus_status: focus_mode_off shows the inactive icon" {
  SENDER=focus_mode_off sh "$PLUGINS/focus_status.sh"
  sb_has 'icon=􀆹 icon.color=0xFF888888'
}

@test "focus_status: forced reads the control center preference" {
  stub defaults 1
  SENDER=forced sh "$PLUGINS/focus_status.sh"
  sb_has 'icon=􀆺'
  : > "$SB_LOG"
  stub defaults 0
  SENDER=forced sh "$PLUGINS/focus_status.sh"
  sb_has 'icon=􀆹'
}

@test "focus_status: unknown events fall back to inactive" {
  SENDER=whatever sh "$PLUGINS/focus_status.sh"
  sb_has 'icon=􀆹'
}

# --- front_app ---

@test "front_app: front_app_switched sets the label from \$INFO" {
  SENDER=front_app_switched INFO="Visual Studio Code" sh "$PLUGINS/front_app.sh"
  sb_has '--set item label=Visual Studio Code'
}

@test "front_app: other events do nothing" {
  SENDER=forced INFO=x sh "$PLUGINS/front_app.sh"
  [ ! -s "$SB_LOG" ]
}

# --- keyboard ---

@test "keyboard: Hungarian layout shows the Hungarian flag" {
  stub defaults '(
    {
        "KeyboardLayout Name" = Hungarian;
    }
)'
  sh "$PLUGINS/keyboard.sh"
  sb_has 'icon=🇭🇺'
}

@test "keyboard: any other layout shows the US flag" {
  stub defaults '(
    {
        "KeyboardLayout Name" = "U.S.";
    }
)'
  sh "$PLUGINS/keyboard.sh"
  sb_has 'icon=🇺🇸'
}

# --- notification ---

@test "notification: notification_update shows the alert with \$VAR as label" {
  SENDER=notification_update VAR="3 new" sh "$PLUGINS/notification.sh"
  sb_has 'icon=􀍜 icon.color=0xfff7768e label=3 new label.drawing=on background.drawing=on'
}

@test "notification: click resets to the empty state" {
  SENDER=mouse.clicked sh "$PLUGINS/notification.sh"
  sb_has 'icon=􀣺 icon.color=0xaaffffff label= label.drawing=off background.drawing=off'
}

@test "notification: other events do nothing" {
  SENDER=forced sh "$PLUGINS/notification.sh"
  [ ! -s "$SB_LOG" ]
}

# --- space ---

@test "space: background follows \$SELECTED" {
  SELECTED=on sh "$PLUGINS/space.sh"
  sb_has '--set item background.drawing=on'
  : > "$SB_LOG"
  SELECTED=off sh "$PLUGINS/space.sh"
  sb_has '--set item background.drawing=off'
}

# --- vpn_status ---

@test "vpn_status: connected VPN shows the connected icon" {
  stub scutil '* (Connected)      ABC "Work VPN" [VPN:com.example]'
  sh "$PLUGINS/vpn_status.sh"
  sb_has 'icon=􀞙'
}

@test "vpn_status: no connection shows the disconnected icon" {
  stub scutil '* (Disconnected)   ABC "Work VPN" [VPN:com.example]'
  sh "$PLUGINS/vpn_status.sh"
  sb_has 'icon=􀞡'
}

@test "vpn_status: hover shows the VPN name, leaving hides the label" {
  stub scutil '* (Connected)      ABC "Work VPN" [VPN:com.example]'
  SENDER=mouse.entered sh "$PLUGINS/vpn_status.sh"
  sb_has 'label.drawing=on label=Work VPN'
  : > "$SB_LOG"
  SENDER=mouse.exited sh "$PLUGINS/vpn_status.sh"
  sb_has 'label.drawing=off'
}

# --- wifi_status ---

@test "wifi_status: connected network shows the wifi icon" {
  stub networksetup 'Current Wi-Fi Network: Home'
  sh "$PLUGINS/wifi_status.sh"
  sb_has 'icon=􀤆'
}

@test "wifi_status: Off or empty shows the disconnected icon" {
  stub networksetup 'Current Wi-Fi Network: Off'
  sh "$PLUGINS/wifi_status.sh"
  sb_has 'icon=􁣡'
  : > "$SB_LOG"
  stub networksetup 'You are not associated with an AirPort network.'
  sh "$PLUGINS/wifi_status.sh"
  sb_has 'icon=􁣡'
}

@test "wifi_status: hover shows the network name" {
  stub networksetup 'Current Wi-Fi Network: Home'
  SENDER=mouse.entered sh "$PLUGINS/wifi_status.sh"
  sb_has 'label.drawing=on label=Home'
}

# --- sidecar_toggle ---

sidecar_setup() {
  export AEROSPACE_CONFIG="$BATS_TEST_TMPDIR/aerospace.toml"
  printf '%s\n' "$1" > "$AEROSPACE_CONFIG"
  stub_logged aerospace
}

@test "sidecar_toggle: non-click events do nothing" {
  sidecar_setup "outer.top = 0 # sidecar-gap"
  SENDER=forced sh "$PLUGINS/sidecar_toggle.sh"
  [ ! -s "$SB_LOG" ]
  [ -z "$(calls aerospace)" ]
}

@test "sidecar_toggle: gap off -> turns it on and reloads" {
  sidecar_setup "outer.top =        0 # sidecar-gap"
  SENDER=mouse.clicked sh "$PLUGINS/sidecar_toggle.sh"
  grep -qF "monitor.'sidecar' = 32" "$AEROSPACE_CONFIG"
  sb_has 'icon=▣'
  [ "$(calls aerospace)" = "reload-config" ]
}

@test "sidecar_toggle: gap on -> turns it off and reloads" {
  sidecar_setup "outer.top =        [{ monitor.'sidecar' = 32 }, 0] # sidecar-gap"
  SENDER=mouse.clicked sh "$PLUGINS/sidecar_toggle.sh"
  ! grep -qF "sidecar' = 32" "$AEROSPACE_CONFIG"
  grep -q 'outer.top = *0 # sidecar-gap' "$AEROSPACE_CONFIG"
  sb_has 'icon=□'
  [ "$(calls aerospace)" = "reload-config" ]
}

@test "sidecar_toggle: writes through a symlinked config and leaves other lines alone" {
  printf 'before\nouter.top = 0 # sidecar-gap\nafter\n' > "$BATS_TEST_TMPDIR/real.toml"
  ln -s "$BATS_TEST_TMPDIR/real.toml" "$BATS_TEST_TMPDIR/link.toml"
  export AEROSPACE_CONFIG="$BATS_TEST_TMPDIR/link.toml"
  stub_logged aerospace
  SENDER=mouse.clicked sh "$PLUGINS/sidecar_toggle.sh"
  [ -L "$AEROSPACE_CONFIG" ]
  grep -qF "monitor.'sidecar' = 32" "$BATS_TEST_TMPDIR/real.toml"
  [ "$(sed -n 1p "$BATS_TEST_TMPDIR/real.toml")" = before ]
  [ "$(sed -n 3p "$BATS_TEST_TMPDIR/real.toml")" = after ]
}
