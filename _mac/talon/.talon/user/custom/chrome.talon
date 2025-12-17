app: Chrome
-
# Chrome-specific voice commands for web development

# Tab management
new tab: key(cmd-t)
close tab: key(cmd-w)
reopen tab: key(cmd-shift-t)
next tab: key(cmd-alt-right)
previous tab: key(cmd-alt-left)
tab one: key(cmd-1)
tab two: key(cmd-2)
tab three: key(cmd-3)
tab four: key(cmd-4)
tab five: key(cmd-5)
tab six: key(cmd-6)
tab seven: key(cmd-7)
tab eight: key(cmd-8)
last tab: key(cmd-9)

# Window management
new window: key(cmd-n)
new private window: key(cmd-shift-n)
close window: key(cmd-shift-w)
fullscreen: key(cmd-ctrl-f)

# Navigation
go back: key(cmd-[)
go forward: key(cmd-])
reload: key(cmd-r)
hard reload: key(cmd-shift-r)
stop loading: key(cmd-.)
home: key(cmd-shift-h)

# Address bar and search
address bar: key(cmd-l)
search: key(cmd-l)
find: key(cmd-f)
find next: key(cmd-g)
find previous: key(cmd-shift-g)

# Developer tools
dev tools: key(cmd-alt-i)
console: key(cmd-alt-j)
inspect: key(cmd-shift-c)
toggle device: key(cmd-shift-m)
network tab:
    key(cmd-alt-i)
    sleep(100ms)
    key(cmd-])
sources tab:
    key(cmd-alt-i)
    sleep(100ms)
    key(cmd-])
    key(cmd-])

# Zoom
zoom in: key(cmd-+)
zoom out: key(cmd--)
zoom reset: key(cmd-0)

# Bookmarks
bookmark page: key(cmd-d)
show bookmarks: key(cmd-alt-b)
bookmark manager: key(cmd-shift-o)

# History
show history: key(cmd-y)

# Downloads
show downloads: key(cmd-shift-j)

# Page actions
print: key(cmd-p)
save page: key(cmd-s)
view source: key(cmd-alt-u)

# Scrolling
page down: key(space)
page up: key(shift-space)
top of page: key(cmd-up)
bottom of page: key(cmd-down)

# DevTools shortcuts (when DevTools is focused)
clear console: key(cmd-k)
search files: key(cmd-p)
command menu: key(cmd-shift-p)

# Screenshots (DevTools)
screenshot: key(cmd-shift-p)

# Multiple selections (for forms, etc)
select all: key(cmd-a)
