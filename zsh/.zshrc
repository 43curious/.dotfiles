# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.emacs.d/bin:$PATH"
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

autoload -U colors && colors

# Theme
# Fast prompt: only uses zsh prompt escapes, no command substitution and no git calls.
autoload -Uz vcs_info
setopt PROMPT_SUBST

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%b'

precmd() {
  vcs_info

  if [[ -n "${vcs_info_msg_0_}" ]]; then
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      git_prompt=" %F{9}${vcs_info_msg_0_}%f"
    else
      git_prompt=" %F{9}${vcs_info_msg_0_}%f"
    fi
  else
    git_prompt=""
  fi
}

PROMPT='%F{12}%~%f${git_prompt}
%F{13}❯%f '


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

# Added by Antigravity CLI installer
export PATH="/Users/jcastro/.local/bin:$PATH"
