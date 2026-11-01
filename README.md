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

## Neovim in Rex

Run `nvim some/file.txt` in a Rex pane. Neovim uses Rex's live terminal palette,
including the statusline and Mist notes. See the [Neovim configuration](nvim/.config/nvim/README.md)
for theme and performance details.
