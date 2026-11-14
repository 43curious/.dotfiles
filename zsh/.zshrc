# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
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
      git_prompt=" %F{8}${vcs_info_msg_0_}%f"
    fi
  else
    git_prompt=""
  fi
}

PROMPT='%F{14}%~%f${git_prompt}
%F{14}❯%f '


# Plugins
plugins=(
  zsh-syntax-highlighting
  zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh

# Install missing Brewfile packages and upgrade declared tools.
function brewsync() {
    local brewfile="$HOME/.dotfiles/brewfile"

    if [[ ! -f "$brewfile" ]]; then
        print -u2 -- "Error: Brewfile no encontrado: $brewfile"
        return 1
    fi

    brew bundle install --file="$brewfile"
}

#Alias
alias bagheera="ssh jon@bagheera"

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
