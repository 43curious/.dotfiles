# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.emacs.d/bin:$PATH"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

autoload -U colors && colors

# Theme
# Fast prompt: only uses zsh prompt escapes, no command substitution and no git calls.
ZSH_THEME=""
PROMPT='%K{#34373C}%F{#ffffff} %~ %k%f '


# Plugins
plugins=(
  zsh-syntax-highlighting
  zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh

# Script for searching local Development directory for projects
ff() {
  local dir
  dir=$(find $HOME/Dev -type d -maxdepth 1 ! -name '.*' | fzf --style minimal)
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

# Local tools
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

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

# --- tmux session shortcuts: BEGIN ---
# Interactive commands: tattach, tnew, tswitch, trename, tdetach,
# tremove, and tlast. Short forms: ta, tn, ts, tc/td, tk, and tl.
_tmux_pick_session() {
  emulate -L zsh

  command -v tmux >/dev/null 2>&1 || {
    print -u2 -- 'tmux is not installed'
    return 127
  }
  command -v fzf >/dev/null 2>&1 || {
    print -u2 -- 'fzf is not installed'
    return 127
  }
  command tmux list-sessions >/dev/null 2>&1 || {
    print -u2 -- 'No tmux sessions are running'
    return 1
  }

  command tmux list-sessions -F '#S' |
    command fzf --prompt='tmux session > ' --reverse --border
}

_tmux_attach_or_switch() {
  emulate -L zsh
  local session="$1"

  if [[ -n "${TMUX:-}" ]]; then
    command tmux switch-client -t "=$session"
  else
    command tmux attach-session -t "=$session"
  fi
}

tattach() {
  emulate -L zsh
  local session="${1:-}"

  [[ -n "$session" ]] || session="$(_tmux_pick_session)" || return
  _tmux_attach_or_switch "$session"
}

tswitch() {
  tattach "$@"
}

tnew() {
  emulate -L zsh
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    read "name?New tmux session name: "
  fi
  [[ -n "$name" ]] || return 1

  if command tmux has-session -t "=$name" 2>/dev/null; then
    _tmux_attach_or_switch "$name"
  elif [[ -n "${TMUX:-}" ]]; then
    command tmux new-session -d -s "$name" &&
      command tmux switch-client -t "=$name"
  else
    command tmux new-session -s "$name"
  fi
}

trename() {
  emulate -L zsh
  local target new_name="${1:-}"

  if [[ -n "${TMUX:-}" ]]; then
    target="$(command tmux display-message -p '#S')" || return
  else
    target="$(_tmux_pick_session)" || return
  fi
  if [[ -z "$new_name" ]]; then
    read "new_name?New name for $target: "
  fi
  [[ -n "$new_name" ]] || return 1

  command tmux rename-session -t "=$target" "$new_name"
}

tdetach() {
  emulate -L zsh
  [[ -n "${TMUX:-}" ]] || {
    print -u2 -- 'Not currently inside tmux'
    return 1
  }
  command tmux detach-client
}

tremove() {
  emulate -L zsh
  local session="${1:-}" answer

  [[ -n "$session" ]] || session="$(_tmux_pick_session)" || return
  read -q "answer?Remove tmux session '$session'? [y/N] "
  print
  [[ "$answer" == [yY] ]] || return 1
  command tmux kill-session -t "=$session"
}

tlast() {
  emulate -L zsh
  if [[ -n "${TMUX:-}" ]]; then
    command tmux switch-client -l
  else
    tattach
  fi
}

alias ta='tattach'
alias tn='tnew'
alias ts='tswitch'
alias tc='tdetach'
alias td='tdetach'
alias tk='tremove'
alias tl='tlast'

# Matching direct Ctrl shortcuts at a normal Zsh prompt. Inside tmux, tmux
# intercepts these keys first, so they also work while pi or another app runs.
_tmux_zle_switch() { BUFFER='tswitch'; zle accept-line; }
_tmux_zle_rename() { BUFFER='trename'; zle accept-line; }
_tmux_zle_open() { BUFFER='tnew'; zle accept-line; }
_tmux_zle_remove() { BUFFER='tremove'; zle accept-line; }
_tmux_zle_reattach() { BUFFER='tlast'; zle accept-line; }

zle -N _tmux_zle_switch
zle -N _tmux_zle_rename
zle -N _tmux_zle_open
zle -N _tmux_zle_remove
zle -N _tmux_zle_reattach

bindkey '^S' _tmux_zle_switch
bindkey '^T' _tmux_zle_rename
bindkey '^O' _tmux_zle_open
bindkey '^K' _tmux_zle_remove
bindkey '^A' _tmux_zle_reattach
# Ctrl-d keeps its normal EOF behavior outside tmux; inside tmux it detaches.
# --- tmux session shortcuts: END ---
