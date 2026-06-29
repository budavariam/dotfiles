#!/usr/bin/env bash

# Toggles the 32px AeroSpace outer.top gap on the Sidecar display.
# State is read directly from the config — no temp file needed.
# To trigger without the chip: service mode → b  (alt-shift-; then b)

[ "$SENDER" != "mouse.clicked" ] && exit 0


# sed -i '' does not follow symlinks on macOS; write through symlink via temp file
sed_inplace() {
    local pattern=$1 file=$2
    local tmp
    tmp=$(mktemp)
    sed "$pattern" "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
}

if grep -q "monitor.'sidecar' = 32" "$AEROSPACE_CONFIG"; then
    # Gap is ON → turn it off
    sed_inplace \
        "s/outer\\.top[[:space:]]*=.*# sidecar-gap/outer.top =        0 # sidecar-gap/" \
        "$AEROSPACE_CONFIG"
    sketchybar --set sidecar_toggle icon="□"
else
    # Gap is OFF → turn it on
    sed_inplace \
        "s/outer\\.top[[:space:]]*=.*# sidecar-gap/outer.top =        [{ monitor.'sidecar' = 32 }, 0] # sidecar-gap/" \
        "$AEROSPACE_CONFIG"
    sketchybar --set sidecar_toggle icon="▣"
fi

aerospace reload-config
