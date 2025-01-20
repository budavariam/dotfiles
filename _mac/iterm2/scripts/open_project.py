# example usage:
# echo "cp open_config.tmpl.py open_config.py && vim open_config.py"
# source ~/project/dotfiles/_mac/iterm2/scripts/.venv/bin/activate; python3 ~/project/dotfiles/_mac/iterm2/scripts/open_project.py

import iterm2
from open_config import Iterm2Config

async def setup_session(session, path, command):
    if path:
        await session.async_send_text(f"cd {path}\n")
    if command:
        await session.async_send_text(f"{command}\n")

async def main(connection):
    # Open a new tab
    app = await iterm2.async_get_app(connection)
    window = app.current_window

    if window is None:
        print("No available window. Create a new one and try again.")
        return

    tab = await window.async_create_tab()
    session = tab.current_session

    # Load configuration
    config = Iterm2Config()

    change = iterm2.LocalWriteOnlyProfile()
    color = iterm2.Color(*config.tab_color)
    change.set_tab_color(color)
    change.set_use_tab_color(True)
    await session.async_set_profile_properties(change)

    await tab.async_set_title(config.tab_title)

    # Setup sessions
    top_left_session = session
    await setup_session(top_left_session, config.top_left_path, config.top_left_command)

    top_right_session = await session.async_split_pane(vertical=True)
    await setup_session(top_right_session, config.top_right_path, config.top_right_command)

    bottom_right_session = await top_right_session.async_split_pane(vertical=False)
    await setup_session(bottom_right_session, config.bottom_right_path, config.bottom_right_command)

    bottom_left_session = await top_left_session.async_split_pane(vertical=False)
    await setup_session(bottom_left_session, config.bottom_left_path, config.bottom_left_command)

if __name__ == "__main__":
    iterm2.run_until_complete(main)
