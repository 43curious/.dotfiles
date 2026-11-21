# Edit the Brewfile, update Homebrew, then reconcile installed packages.
function brewsync
    set -l brewfile "$HOME/.dotfiles/brewfile"
    if not test -f "$brewfile"
        printf 'Error: Brewfile no encontrado: %s\n' "$brewfile" >&2
        return 1
    end

    nvim "$brewfile"; or return
    brew update; or return
    brew bundle install --upgrade --file="$brewfile"; or return

    # Keep required dependencies and remove undeclared packages and taps.
    brew bundle cleanup --force --formula --cask --tap --file="$brewfile"
end
