# dotfiles

> Because life's too short to manually setup my machine

This repository came alive to help me **revision** and **sync** my config files, and make it easy to **setup any new workstation** with similar settings as the others.
These are **my** most common settings that I use day by day in my UNIX based systems. These might change over time.

Feel free to fork it and customize it with your own needs.

## Getting started

You should **check out** this repository into `~/project/dotfiles` folder.
If you want to check out to another location make sure you change all references to that folder in this repository, before starting it.

Make sure you **know** what you are doing! I advise you to check the scripts and remove the things you don't need.

> Use this at your own risk!

Run `./setup.sh`.

## How it works

The `setup.sh` script replaces some config files with symlinks pointing to this repository.

## What it contains

* shell **aliases**, **git** information in prompt
* git **aliases**, basic **settings** and common **ignore** patterns
* vscode **settings**, **keybindings**
* vim **setings**
* npm **init** config to set my default data.

### Shell

Only the `.bash_profile` and `.bashrc` files are linked to the home directory. The others are referenced from `.bash_profile`.
If you modify those files, make sure you reload `.bash_profile`. You can do it with the `bashreload` alias without logging out.

## Acknowledgements

Inspiration and code was taken from many sources, including:

* @tay1orjones (Taylor Jones)  [dotfiles repository](https://github.com/tay1orjones/dotfiles)
* @mathiasbynens (Mathias Bynens) [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
* @paulirish (Paul Irish) [dotfiles repository](https://github.com/paulirish/dotfiles)
* @alrra (Cãtãlin Mariş) [dotfiles repository](https://github.com/alrra/dotfiles)

More information with other **repositories**, **tips and tricks** and other **tools** can be found at [https://dotfiles.github.io](https://dotfiles.github.io).
