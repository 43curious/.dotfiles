# dotfiles

My dotfiles are stored in the `/.dotfiles` folder inside my machine. Then stowed (symlinked) to my home folder.  
This dotfiles [stow guide](https://www.jakewiesler.com/blog/managing-dotfiles) helped me while setting up my system. If you want to learn more about stow, you can read this guide as well as this [other guide](https://www.gnu.org/software/stow/manual/stow.html#Terminology) from GNU project.

My dotfiles have the config for the following:
- Git config
- My .zsrhc
- [Oh My Zsh](https://ohmyz.sh/) for shell customization with the following extensions
	- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
	- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- My [Ghostty](https://ghostty.org/) config and theme
- [neovim ](https://neovim.io/) theme and plugins 
- My [SKHD](https://github.com/koekeishiya/skhd) config for navigation

## Neorex

[Neorex](https://github.com/alexrlocke/neorex) is a standalone Neovim frontend for Rex. Run `neorex some/file.txt` inside a Rex pane to use the existing Neovim config with `:split` and `:vsplit` opening native Rex panes.

Install on macOS with Rex, Neovim and Zig 0.17 available:

```sh
git clone https://github.com/alexrlocke/neorex.git "$HOME/.local/share/neorex"
cd "$HOME/.local/share/neorex"
zig build -Doptimize=ReleaseSafe
zig build test
mkdir -p "$HOME/.local/bin"
ln -s "$HOME/.local/share/neorex/zig-out/bin/neorex" "$HOME/.local/bin/neorex"
```

The shell config already adds `~/.local/bin` to `PATH`. To update, run `git pull --ff-only` in the source directory and repeat the build and tests; the symlink continues to use the rebuilt binary.

Upstream develops against Neovim 0.13-dev; older versions may not display statuslines. Use Rex's controls to resize or move panes.
