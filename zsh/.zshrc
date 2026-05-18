# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.emacs.d/bin:$PATH"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

autoload -U colors && colors

# Theme
_git_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

_git_dirty() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      echo "dirty"
    fi
  fi
}

_build_prompt() {
  local arrow=$'\ue0b0'
  local branch_icon=$'\ue729'
  local real_path="${PWD/#$HOME/~}"
  local branch=$(_git_branch)
  local dirty=$(_git_dirty)
  local branch_bg="#5aa9e6"
  local p=""

  if [[ -n "$dirty" ]]; then
    branch_bg="#957fef"
  fi

  p+="%K{#34373C}%F{#ffffff} ${real_path} "

  if [[ -n "$branch" ]]; then
    p+="%F{#34373C}%K{${branch_bg}}${arrow}"
    p+="%F{#0d2b3e} ${branch_icon} ${branch} "
    p+="%k%F{${branch_bg}}${arrow}"
  else
    p+="%F{#34373C}%K{#5aa9e6}${arrow}"
    p+="%k%F{#5aa9e6}${arrow}"
  fi

  p+="%k%f "
  echo "$p"
}

setopt PROMPT_SUBST
ZSH_THEME=""
PROMPT='$(_build_prompt)'


# Plugins
plugins=(git
)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/oh-my-zsh.sh

# Script for searching local Development directory for projects
ff() {
  local dir
  dir=$(find $HOME/Development -type d -maxdepth 1 ! -name '.*' | fzf --style minimal)
  if [ -n "$dir" ]; then
    cd "$dir" || return
    nvim . || return
    clear  # Clear the terminal screen
  fi
}
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey -s '^F' 'ff\n'

# Brewsync
function brewsync() {
    # Referencia mi brewfile en el directorio de .dotfiles
    local BREWFILE="$HOME/.dotfiles/brewfile"
    
    # Verificar si el archivo existe
    [[ ! -f "$BREWFILE" ]] && echo "$fg[red] Error: Brewfile no
     encontrado" && return 1
	
    # Calcular el hash inicial, abrir Nvim y calcular el hash final
    local OLD_HASH=$(shasum -a 256 "$BREWFILE")
    nvim "$BREWFILE"
    local NEW_HASH=$(shasum -a 256 "$BREWFILE")
	
    # Comparar y ejecutar si hubo cambios
    if [[ "$OLD_HASH" != "$NEW_HASH" ]]; then
        echo "$fg[cyan]Cambios detectados. Sincronizando Brewfile..."
        
        # Entrar al directorio para que brew bundle detecte el archivo
        cd "$(dirname "$BREWFILE")" || return
        
        # Ejecutar instalación y limpieza
        brew bundle --quiet
        brew bundle cleanup --force --quiet
        brew update
        brew upgrade
        brew cleanup --prune=all

        # Volver al directorio anterior
        cd - > /dev/null
        echo "$fg[green] Sincronización completada."
    else
        echo "No hubo cambios en el archivo. Actualizando."
        brew update
        brew upgrade
        brew cleanup --prune=all
    fi
}

#Alias
alias bagheera="ssh jon@bagheera"
alias sd="ssh -t jon@bagheera 'sudo shutdown -h now'"

# Added by Antigravity
export PATH="/Users/jon/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/jon/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity
export PATH="/Users/jon/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "/Users/jon/.bun/_bun" ] && source "/Users/jon/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- Ghostty/Zsh Dired-like browser: BEGIN ---
# Usage: dired [start-directory]
# - Enter on a directory descends into it, like Dired browsing.
# - Enter on a file opens it in Neovim.
# - Ctrl-v opens the current directory in Neovim.
# - Ctrl-o opens selection with macOS `open`.
# - Esc/Ctrl-c quits.
dired() {
  emulate -L zsh
  setopt local_options no_nomatch

  local dir="${1:-$PWD}"
  local choice name target action

  dir="${dir:A}"
  [[ -d "$dir" ]] || { echo "dired: not a directory: $dir" >&2; return 1; }

  while true; do
    choice=$(
      {
        [[ "$dir" != "/" ]] && print -- "../"
        command find "$dir" -maxdepth 1 -mindepth 1 \( -name .git -o -name node_modules \) -prune -o -print 2>/dev/null |
          while IFS= read -r path; do
            name="${path:t}"
            [[ -d "$path" ]] && print -- "$name/" || print -- "$name"
          done | LC_ALL=C sort -f
      } | DIRED_DIR="$dir" fzf \
        --prompt="Dired ${dir/#$HOME/~}/ " \
        --height=100% \
        --reverse \
        --expect=enter,ctrl-v,ctrl-o \
        --preview='
          sel="{}"
          p="$DIRED_DIR/${sel%/}"
          [[ "$sel" == "../" ]] && p="$DIRED_DIR/.."
          if [[ -d "$p" ]]; then
            command eza -la --icons "$p" 2>/dev/null || command ls -la "$p"
          else
            command bat --style=numbers --color=always --line-range=:200 "$p" 2>/dev/null || command sed -n "1,200p" "$p"
          fi
        '
    ) || return

    action="${choice%%$'\n'*}"
    name="${choice#*$'\n'}"
    [[ -z "$name" ]] && return

    if [[ "$name" == "../" ]]; then
      target="${dir:h}"
    else
      target="$dir/${name%/}"
    fi

    case "$action" in
      ctrl-v)
        nvim "$dir"
        return
        ;;
      ctrl-o)
        open "$target" >/dev/null 2>&1
        continue
        ;;
    esac

    if [[ -d "$target" ]]; then
      dir="${target:A}"
    else
      nvim "$target"
      return
    fi
  done
}

# Optional keybinding, Emacs-style: Ctrl-x Ctrl-d launches the Dired-like browser.
bindkey -s '^X^D' 'dired\n'
# --- Ghostty/Zsh Dired-like browser: END ---
