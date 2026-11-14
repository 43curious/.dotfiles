# dotfiles

My dotfiles are stored in the `~/.dotfiles` folder inside my machine. Then stowed (symlinked) to my home folder.
This dotfiles [stow guide](https://www.jakewiesler.com/blog/managing-dotfiles) helped me while setting up my system. If you want to learn more about stow, you can read this guide as well as this [other guide](https://www.gnu.org/software/stow/manual/stow.html#Terminology) from GNU project.

My dotfiles have the config for the following:
- Git config
- My .zsrhc
- [Oh My Zsh](https://ohmyz.sh/) for shell customization with the following extensions
	- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
	- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- My [Ghostty](https://ghostty.org/) config and theme
- My [Rex](https://www.superlogical.com/rex/) Lua configuration
- [neovim ](https://neovim.io/) theme and plugins 
- My [SKHD](https://github.com/koekeishiya/skhd) config for navigation

## Rex

The `rex` Stow package tracks [init.lua](rex/.config/rex/init.lua). Install it with:

```sh
cd ~/.dotfiles
stow --target="$HOME" rex
```

Stow links `~/.config/rex` to `rex/.config/rex` in this repo. Editing either path
changes the same files, so future customizations appear in `git diff`.
Option + Down shows the next tab; Option + Up shows the previous tab.

After editing, run these commands in a Rex terminal on the machine running the server:

```sh
rex config check
rex config reload
```

The check validates the file without applying it. Reload applies it to connected
clients; Rex does not watch for file changes. You can check an unstowed draft with
`rex config check ~/.dotfiles/rex/.config/rex/init.lua`.

Rex runs `init.lua` as Lua on the server. Use `rex.bind` for shortcuts and
`rex.action` for custom actions. As the config grows, `require("keys")` can load a
`keys.lua` file beside `init.lua`. GUI shortcuts override Lua bindings.

This package tracks the Lua configuration. The current font, themes, and interface
preferences are stored separately by the macOS app and are not backed up here.
If `XDG_CONFIG_HOME` is set, Rex looks under that directory instead of `~/.config`;
`REX_CONFIG` can override the file path in the server's environment.

See the [Rex configuration documentation](https://www.superlogical.com/rex/docs/customize/config)
and [CLI guide](https://www.superlogical.com/rex/docs/automate/cli). Rex adds its CLI
to the PATH of terminals it opens.

## Neovim in Rex

Run `nvim some/file.txt` in a Rex pane. Neovim uses Rex's live terminal palette,
including the statusline and Mist notes. See the [Neovim configuration](nvim/.config/nvim/README.md)
for theme and performance details.
