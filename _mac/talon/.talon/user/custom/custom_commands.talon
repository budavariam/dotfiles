open todo:
    user.open_iterm_cli_tool("cd ~/project/todolog; npm run todo")

# To create the symlink for this command, run in terminal:
# ln -s /full/path/to/your/actual/project.code-workspace ~/current_project.code-workspace
# Example: 
#    ln -s ~/project/myapp/myapp.code-workspace ~/current_project.code-workspace
# To switch projects:
#    rm ~/current_project.code-workspace && ln -s /path/to/other.code-workspace ~/current_project.code-workspace

open workspace:
    user.open_vscode_folder("~/current_project.code-workspace")
    # user.system_command("code ~/current_project.code-workspace")

