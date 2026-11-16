# Sincronización de Pewter

`pewtersync` copies the contents of `/Volumes/CZM2/` to
`jon@bagheera:/srv/pewter/` over SSH. Load the updated function and preview it:

```zsh
source ~/.zshrc
pewtersync --dry-run
pewtersync
```

The source drive must be mounted. The function prefers Homebrew rsync, displays
changes and transfer progress, and keeps interrupted transfers in
`.rsync-partial` for the next run. It preserves file timestamps, permissions,
and symlinks, using the destination account's ownership. macOS volume metadata
and `.DS_Store` files are excluded. Trailing slashes copy the drive's contents
directly into `pewter`, without adding a `CZM2` subdirectory.

By default, destination-only files are kept. For an exact mirror, first preview
`pewtersync --dry-run --delete`, then run `pewtersync --delete`. This deletes
destination files missing from CZM2, except excluded paths. Other rsync options,
such as `--bwlimit=20m`, can also be passed through.

### Prepare Bagheera

Rsync is already installed on Bagheera. `/srv/pewter` must be on storage large
enough for the source data and writable by `jon`. If using a separate data disk,
mount it there first, then run this **on Bagheera**:

```sh
sudo chown jon:jon /srv/pewter
```

On the sending Mac, unlock the existing SSH key and test the connection:

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh jon@bagheera 'test -w /srv/pewter && rsync --version'
```

### Distribute to other computers

Use one direction: `CZM2 -> Bagheera -> receiving computers`. Keep CZM2 as the
source of truth; rsync does not merge conflicting edits from multiple machines.

Each receiver needs rsync, SSH access to `jon@bagheera`, and a dedicated local
destination directory. A receiver can pull its copy while it is online:

```sh
mkdir -p "$HOME/pewter"
rsync -ah --no-owner --no-group --partial-dir=.rsync-partial --progress \
    jon@bagheera:/srv/pewter/ "$HOME/pewter/"
```

Alternatively, enable SSH login on each receiver and authorize a Bagheera SSH
public key for its destination account. From Bagheera, push to each computer
using its actual username, hostname, and destination path:

```sh
rsync -ah --no-owner --no-group --partial-dir=.rsync-partial --progress \
    /srv/pewter/ USER@COMPUTER:/path/to/pewter/
```

Start with `--dry-run`. Add `--delete` only when that destination should exactly
mirror the server. These transfers keep their own `.rsync-partial` files out of
the copies.

Rsync runs when invoked. For automatic pulls, schedule each receiver's command
with a macOS launchd agent or a Linux systemd timer, for example every 15 minutes.
For server-driven pushes, schedule the push commands on Bagheera or run them
after a successful upload. Scheduled jobs need absolute executable paths and
SSH authentication that works without an interactive password or passphrase
prompt. Avoid overlapping syncs to the same destination; a completed upload
should precede distribution when receivers need a consistent set of files.

See the [rsync manual](https://rsync.samba.org/ftp/rsync/rsync.1.html),
[Apple's launchd guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html),
and [systemd timer documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html).
