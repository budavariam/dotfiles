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

```
help active
help symbols
help alphabet
help close

focus code
   focus terminal
focus chrome
   next tab
   previous tab
   reload
   clear console
focus iterm
sleep all
wake up

dictation mode
command mode
press escape
enter
```