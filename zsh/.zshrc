# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

autoload -U colors && colors

# Theme
_git_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

_git_dirty() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    if ! git diff --quiet 2>/dev/null; then
      echo "unstaged"
    elif ! git diff --cached --quiet 2>/dev/null; then
      echo "staged"
    fi
  fi
}

_build_prompt() {
  local arrow=$'\ue0b0'
  local branch_icon=$'\ue729'
  local real_path="${PWD/#$HOME/~}"
  local branch=$(_git_branch)
  local dirty=$(_git_dirty)
  local p=""

  p+="%K{#34373C}%F{#ffffff} ${real_path} "

  if [[ -n "$branch" ]]; then
    p+="%F{#34373C}%K{#5aa9e6}${arrow}"
    if [[ "$dirty" == "unstaged" ]]; then
      p+="%F{#0D2B3E} ${branch_icon}%F{#0d2b3e} ${branch} "
    else
      p+="%F{#0d2b3e} ${branch_icon} ${branch} "
    fi
    p+="%k%F{#5aa9e6}${arrow}"
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
  dir=$(find $HOME/Development -type d -maxdepth 1 ! -name '.*' | fzf)
  if [ -n "$dir" ]; then
    cd "$dir" || return
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
