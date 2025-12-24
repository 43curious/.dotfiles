# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

autoload -U colors && colors

# Theme
ZSH_THEME="castro"

plugins=(git
)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/oh-my-zsh.sh

# Script for searching local Development directory for projects
ff() {
  local dir
  dir=$(find $HOME/Development -type d -maxdepth 3 ! -name '.*' | fzf)
  if [ -n "$dir" ]; then
    cd "$dir" || return
    clear  # Clear the terminal screen
  fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey -s '^F' 'ff\n'

# Function to open a file or folder from the external drive CZM2
open_czm2() {
  local drive_path="/Volumes/CZM2"

  # Check if the external drive is mounted
  if [[ ! -d "$drive_path" ]]; then
    echo "Drive CZM2 is not mounted."
    return 1
  fi

  # Use find to list files and folders (max depth 3), excluding system files
  local selection
  selection=$(find "$drive_path" -maxdepth 1\
    ! -path "*/.*" ! -name ".DS_Store" 2>/dev/null | fzf --prompt="Select a file or folder: ")

  # If nothing was selected, exit
  [[ -z "$selection" ]] && return 1
  
  # Clear the terminal session
  clear

  # Open the selected file or folder
  open "$selection"
}

# Bind the function to Ctrl+B
bindkey -s '^B' 'open_czm2\n'

# Function to open a file or folder from the external drive CZM2
open_home() {
  local drive_path="$HOME"

  # Use find to list files and folders (max depth 3), excluding system files
  local selection
  selection=$(find "$drive_path" -maxdepth 3 -mindepth 1 \
    ! -path "*/.*" ! -name ".DS_Store" 2>/dev/null | fzf --prompt="Select a file or folder: ")

  # If nothing was selected, exit
  [[ -z "$selection" ]] && return 1
  
  # Clear the terminal session
  clear

  # Open the selected file or folder
  open "$selection"
}

function brewsync() {
    local BREWFILE="$HOME/.dotfiles/brewfile"
    
    # Verificar si el archivo existe
    [[ ! -f "$BREWFILE" ]] && echo "$fg[red] Error: Brewfile no encontrado" && return 1

    # Calcular el hash inicial, abrir Nvim y calcular el hash final
    local OLD_HASH=$(shasum -a 256 "$BREWFILE")
    nvim "$BREWFILE"
    local NEW_HASH=$(shasum -a 256 "$BREWFILE")

    # Comparar y ejecutar si hubo cambios
    if [[ "$OLD_HASH" != "$NEW_HASH" ]]; then
        echo "$fg[cyan] Cambios detectados. Sincronizando Brewfile..."
        
        # Entrar al directorio para que brew bundle detecte el archivo
        cd "$(dirname "$BREWFILE")" || return
        
        # Ejecutar instalación y limpieza
        brew bundle --quiet
        brew bundle cleanup --force --quiet
        brew update 
        brew upgrade
 
        # Volver al directorio anterior
        cd - > /dev/null
        echo "$fg[green] Sincronización completada."
    else
        echo "No hubo cambios en el archivo. Nada que hacer."
    fi
}

# Bind the function to Ctrl+B
bindkey -s '^H' 'open_home\n'

alias bagheera="ssh jon@bagheera"
alias sd="ssh -t jon@bagheera 'sudo shutdown -h now'"

# Added by Antigravity
export PATH="/Users/castro/.antigravity/antigravity/bin:$PATH"
