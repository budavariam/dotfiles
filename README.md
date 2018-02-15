# dotfiles

> Because life's too short to manually setup my machine

## Getting started

You should check out this repository into `~/project/dotfiles` folder.
If you want to check out to another location make sure you change all references to that folder in this repository, before starting it.

> Make sure you **know** what you are doing! Check the scripts if it's necessary.

Run `./setup.sh`.

## How it works

The `setup.sh` script replaces some config files with symlinks pointing to this repository.
This gives you the possibility to revision your config files, and make it easy to set up your new workstation with similar settings as your current one.

## What it contains

These are **my** most common settings that I use day by day in my UNIX based systems.
These might change over time.
Feel free to fork it and customize it with your own needs.
It contains:

* aliases for shell
* git info for shell
* common gitignore patterns
* aliases and basic settings for git
* settings for vscode
* setings for vim
* npm init config to set my default data.

### Shell

Only the `.bash_profile` and `.bashrc` files are linked to the home directory. The others are referenced from `.bash_profile`.
If you modify those files, make sure you reload `.bash_profile`. You can do it with the `bashreload` alias without logging out.

## Acknowledgements

Inspiration and code was taken from many sources, including:

* @tay1orjones (Taylor Jones)  [dotfiles repository](https://github.com/tay1orjones/dotfiles)
* @mathiasbynens (Mathias Bynens) [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
* @paulirish (Paul Irish) [dotfiles repository](https://github.com/paulirish/dotfiles)
* @alrra (Cãtãlin Mariş) [dotfiles repository](https://github.com/alrra/dotfiles)
