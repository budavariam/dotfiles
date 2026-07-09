app: slack
-
# Slack-specific voice commands for daily use

# Workspace navigation
workspace <number>: user.slack_open_workspace(number)
previous workspace: user.messaging_workspace_previous()
next workspace: user.messaging_workspace_next()

# Channel navigation
channel: user.messaging_open_channel_picker()
channel <user.text>:
    user.messaging_open_channel_picker()
    insert(user.formatted_text(user.text, "ALL_LOWERCASE"))
channel up: user.messaging_channel_previous()
channel down: user.messaging_channel_next()
unread next: user.messaging_unread_next()
unread previous: user.messaging_unread_previous()

# History
go back: user.slack_go_back()
history back: user.slack_go_back()
go forward: user.slack_go_forward()
history forward: user.slack_go_forward()

# Views
threads: user.slack_open_threads()
direct messages: user.slack_open_direct_messages()
activity: user.slack_open_activity()
unread: user.slack_open_unread_messages()
directory: user.slack_open_directory()
starred: user.slack_open_starred_items()
channel info: user.slack_show_channel_info()
toggle left sidebar: user.slack_toggle_left_sidebar()
toggle right sidebar: user.slack_toggle_right_sidebar()
fullscreen: user.slack_toggle_full_screen()

# Search
search: user.messaging_open_search()

# Messaging / compose
add line: key(shift-enter)
react: user.slack_add_reaction()
upload file: user.messaging_upload_file()
mark read: user.messaging_mark_channel_read()
mark all read: user.messaging_mark_workspace_read()

# Formatting
bold: user.slack_toggle_bold()
italic: user.slack_toggle_italic()
strikethrough: user.slack_toggle_strikethrough()
insert code: user.slack_insert_code()
insert link: user.slack_insert_link()
insert command: user.slack_insert_command()
bulleted list: user.slack_start_bulleted_list()
numbered list: user.slack_start_numbered_list()
quote: user.slack_insert_quotation()
snippet: user.slack_create_snippet()

# Calls / Huddle
huddle: user.slack_huddle()

# Help
shortcuts: user.slack_open_keyboard_shortcuts()
