from talon import Module, actions, app
import subprocess

mod = Module()


@mod.action_class
class Actions:
    def open_iterm_cli_tool(tool_name: str):
        """Open iTerm and run a specific CLI tool"""
        # AppleScript to open iTerm and run command
        script = f"""
        tell application "iTerm"
            activate
            tell current window
                create tab with default profile
                tell current session
                    write text "{tool_name}"
                end tell
            end tell
        end tell
        """
        subprocess.run(["osascript", "-e", script])

    def open_vscode_folder(folder_path: str):
        """Open VSCode with a specific folder"""
        subprocess.run(["code", folder_path])
