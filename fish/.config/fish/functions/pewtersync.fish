# Copy CZM2 to Bagheera over SSH. Pass --dry-run to preview the transfer.
function pewtersync
    set -l source_dir /Volumes/CZM2
    if not test -d "$source_dir"; or not /sbin/mount | string match -q -- "* on $source_dir (*"
        printf 'Error: CZM2 is not mounted at %s\n' "$source_dir" >&2
        return 1
    end

    # Prefer Homebrew rsync over Apple's older bundled version.
    set -l rsync_bin rsync
    if test -x /opt/homebrew/bin/rsync
        set rsync_bin /opt/homebrew/bin/rsync
    else if test -x /usr/local/bin/rsync
        set rsync_bin /usr/local/bin/rsync
    end

    command "$rsync_bin" -ah --no-owner --no-group --itemize-changes \
        --partial-dir=.rsync-partial --progress \
        --exclude='/.DocumentRevisions-V100*/' \
        --exclude='/.Spotlight-V100/' \
        --exclude='/.TemporaryItems/' \
        --exclude='/.Trashes/' \
        --exclude='/.fseventsd/' \
        --exclude='.DS_Store' \
        $argv -- "$source_dir/" "jon@bagheera:/srv/pewter/"
end
