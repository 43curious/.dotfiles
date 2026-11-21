set -l platform (uname -s)
if test "$platform" = Darwin
    if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv fish | source
    else if test -x /usr/local/bin/brew
        /usr/local/bin/brew shellenv fish | source
    end
    set -gx BUN_INSTALL "$HOME/.bun"
    fish_add_path --path "$BUN_INSTALL/bin" "$HOME/.antigravity/antigravity/bin" \
        "$HOME/.config/composer/vendor/bin" /usr/local/bin
end
fish_add_path --path "$HOME/.local/bin" "$HOME/bin"

if status is-interactive
    set -g fish_greeting
    set -g dotfiles_prompt_color brcyan
    if test "$platform" = Linux
        set -g dotfiles_prompt_color d787ff
        alias l 'ls -l'
    else
        alias l 'ls -lah'
    end
    if test "$platform" = Darwin
        alias bagheera 'ssh jon@bagheera'
    end
    alias .. 'cd ..'
    alias ... 'cd ../..'
end
