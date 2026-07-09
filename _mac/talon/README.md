# Talon Voice Configuration

Custom Talon Voice configurations for voice-controlled navigation and interaction with macOS applications.

## Setup

1. Install Talon Voice from [talonvoice.com](https://talonvoice.com/)
2. Run `./setup-mac.sh` from the dotfiles root
3. Restart Talon Voice

### Optional: Add Community Repository

The community repository provides comprehensive voice commands for coding and navigation.

1. Add submodule:

   ```bash
   git submodule add https://github.com/talonhub/community.git _mac/talon/.talon/user/community
   git submodule update --init --recursive
   ```

2. Run `./setup-mac.sh` again

## Included Configurations

- `aerospace.talon` - AeroSpace workspace navigation (numbered workspaces, move, go back)
- `vscode.talon` - VSCode editor commands
- `iterm2.talon` - iTerm2 terminal commands (includes Ctrl+R fzf reverse search)
- `chrome.talon` - Chrome web development commands
- `slack.talon` - Slack navigation, messaging, and formatting commands

See the `.talon` files for all available voice commands.

## Customization

Create new `.talon` files in `_mac/talon/.talon/user/custom/`:

```talon
app: MyApp
-
my command: key(cmd-shift-x)
```

## Resources

- [Talon Documentation](https://talon.wiki/)
- [Community Repository](https://github.com/talonhub/community)
- [Talon Slack](https://talonvoice.com/chat)

## Quick reference

### Global

```txt
help active                     list commands for the focused app
help symbols
help alphabet
help close

sleep all                       pause Talon
wake up                         resume Talon
dictation mode                  free-text input mode
command mode                    back to voice commands
press escape
enter
```

### App focus (`focus <app name>`)

```txt
focus code
focus chrome
focus iterm
```

### AeroSpace

```
workspace [one..nine]           switch to workspace 1-9
go workspace [one..nine]
move workspace [one..nine]      move current window to workspace 1-9
go back / workspace back        previous workspace

focus left / right / up / down  focus neighboring window
move left / right / up / down   move window in layout

layout horizontal / vertical / accordion
fullscreen
flatten                         collapse nested containers
resize smaller / bigger
service mode
```

### Chrome

```txt
# Tabs & windows
new tab                         cmd-t
close tab                       cmd-w
reopen tab                      cmd-shift-t
next tab / previous tab
tab [one..eight] / last tab     jump to tab by position
new window / new private window / close window
fullscreen

# Navigation
go back / history back / go forward / history forward
reload / hard reload
stop loading
address bar / search            open omnibox  (cmd-l)
home
find / find next / find previous

# Scrolling
scroll down / scroll up         page down / up  (community command)
page down / page up
scroll to top / top of page     cmd-↑
scroll to bottom / bottom of page  cmd-↓

# Developer tools
dev tools                       open DevTools              cmd-alt-i
console                         open DevTools → Console    cmd-alt-j
inspect                         element picker             cmd-shift-c
toggle device                   responsive / device mode   cmd-shift-m
sources tab                     DevTools → Sources         (from Elements: cmd-] ×2)
network tab                     DevTools → Network         (from Elements: cmd-] ×3)
clear console                   cmd-k        (DevTools focused)
search files                    cmd-p        (DevTools focused)
command menu                    cmd-shift-p  (DevTools focused)
view source

# Other
zoom in / zoom out / zoom reset
bookmark page / show bookmarks / bookmark manager
show history / show downloads
save page / print / select all
profile switch
tab search / tab search <text>
```

### VSCode

```txt
# Files
open file / go file             quick-open  (cmd-p)
save file / close file / new file
recent files

# Search & navigation
find / find all
find next / find previous
go to line
go to symbol
go to definition                F12
go back / history back / go forward / history forward            ctrl-- / ctrl-shift--

# Editing
comment line / comment block
format document
rename symbol
quick fix
add cursor above / add cursor below
select all occurrences

# Scrolling
scroll down / scroll up         (community: page down/up action)
scroll to top                   cmd-home
scroll to bottom                cmd-end

# Layout & panels
toggle sidebar
split right
next editor / previous editor
toggle terminal / focus terminal / new terminal / kill terminal
show problems / show output / show debug console
show source control
command palette                 cmd-shift-p

# Debugging
start debugging / stop debugging
step over / step into / step out
toggle breakpoint
```

### Slack

```txt
# Workspace & channels
workspace <number>              jump to workspace 1-9
previous workspace / next workspace
channel                         open channel picker  (cmd-k)
channel <name>                  open channel picker + type name
channel up / channel down       previous / next channel
unread next / unread previous   jump between unread channels

# History
go back / history back
go forward / history forward

# Views
threads                         cmd-shift-t
direct messages                 cmd-shift-k
activity                        cmd-shift-m
unread                          cmd-shift-a
starred / directory
channel info                    cmd-shift-i
toggle left sidebar / toggle right sidebar
fullscreen
search                          cmd-f
mark read / mark all read

# Compose & formatting
add line                        shift-enter  (newline without sending)
react                           add emoji reaction
upload file
bold / italic / strikethrough
insert code / insert link / insert command
bulleted list / numbered list
quote / snippet

# Calls
huddle

# Help
shortcuts                       cmd-/
```

### iTerm2

```txt
# Tabs & panes
new tab / close tab
next tab / previous tab
tab [one..nine]
split vertical / split horizontal
next pane / previous pane / close pane

# Shell
reverse search / history search ctrl-r
clear screen
interrupt                       ctrl-c
end of file                     ctrl-d
line start / line end           ctrl-a / ctrl-e
word back / word forward        alt-b / alt-f
kill line / kill word           ctrl-k / ctrl-w

# Text size
bigger text / smaller text / reset text
```
