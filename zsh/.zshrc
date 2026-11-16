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

# Edit the Brewfile, update Homebrew, then reconcile installed packages.
function brewsync() {
    local brewfile="$HOME/.dotfiles/brewfile"

    if [[ ! -f "$brewfile" ]]; then
        print -u2 -- "Error: Brewfile no encontrado: $brewfile"
        return 1
    fi

    nvim "$brewfile" || return
    brew update || return
    brew bundle install --upgrade --file="$brewfile" || return

    # Keep required dependencies; remove undeclared Homebrew packages and taps.
    brew bundle cleanup --force --formula --cask --tap --file="$brewfile"
}

# Copy CZM2's contents to Bagheera over SSH; pass --dry-run to preview.
function pewtersync() {
    local source_dir="/Volumes/CZM2"
    local rsync_bin=rsync

    if [[ ! -d "$source_dir" || "$(/sbin/mount)" != *" on $source_dir ("* ]]; then
        print -u2 -- "Error: CZM2 is not mounted at $source_dir"
        return 1
    fi

    # Prefer Homebrew rsync over Apple's older bundled version.
    if [[ -x /opt/homebrew/bin/rsync ]]; then
        rsync_bin=/opt/homebrew/bin/rsync
    elif [[ -x /usr/local/bin/rsync ]]; then
        rsync_bin=/usr/local/bin/rsync
    fi

    "$rsync_bin" -ah --no-owner --no-group --itemize-changes \
        --partial-dir=.rsync-partial --progress \
        --exclude='/.DocumentRevisions-V100*/' \
        --exclude='/.Spotlight-V100/' \
        --exclude='/.TemporaryItems/' \
        --exclude='/.Trashes/' \
        --exclude='/.fseventsd/' \
        --exclude='.DS_Store' \
        "$@" -- "$source_dir/" "jon@bagheera:/srv/pewter/"
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

# Bitwarden Agents
export SSH_AUTH_SOCK=/Users/jcastro/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
