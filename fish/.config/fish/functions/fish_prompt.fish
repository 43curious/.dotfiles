function fish_prompt
    set_color $dotfiles_prompt_color
    printf '%s' (prompt_pwd --dir-length=0)
    set_color normal

    set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if test -z "$branch"
        set branch (command git rev-parse --short HEAD 2>/dev/null)
    end
    if test -n "$branch"
        set -l changes (command git --no-optional-locks status --porcelain 2>/dev/null)
        if set -q changes[1]
            set_color brred
        else
            set_color brblack
        end
        printf ' %s' "$branch"
        set_color normal
    end

    printf '\n'
    set_color $dotfiles_prompt_color
    printf '❯ '
    set_color normal
end
