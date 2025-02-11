#!/usr/bin/env osascript

-- https://nikitabobko.github.io/AeroSpace/commands#list-windows
set aerospaceOutput to do shell script "aerospace list-windows --all --format \"%{workspace}\t|\t%{app-name} (%{window-title})\" |  cut -c 1-30 |  sort"
set aerospaceLines to paragraphs of aerospaceOutput
set displayText to "Workspace | App Name\n-----------------------\n" & return

repeat with aCell in aerospaceLines
    set displayText to displayText & aCell & return
end repeat
display dialog displayText with title "Aerospace Workspaces" buttons {"OK"} default button "OK"
