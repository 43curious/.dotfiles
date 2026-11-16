# dotfiles

My dotfiles are stored in the `~/.dotfiles` folder inside my machine. Then stowed (symlinked) to my home folder.
This dotfiles [stow guide](https://www.jakewiesler.com/blog/managing-dotfiles) helped me while setting up my system. If you want to learn more about stow, you can read this guide as well as this [other guide](https://www.gnu.org/software/stow/manual/stow.html#Terminology) from GNU project.

My dotfiles have the config for the following:
- Git config
- My .zsrhc
- [Oh My Zsh](https://ohmyz.sh/) for shell customization with the following extensions
	- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
	- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- My [Rex](https://www.superlogical.com/rex/) Lua configuration
- [neovim ](https://neovim.io/) theme and plugins
- My [SKHD](https://github.com/koekeishiya/skhd) config for navigation

## Homebrew

[`brewfile`](brewfile) declares the Homebrew packages to keep. Run `brewsync` to:

1. Open the file in Neovim. Save and quit with `:wq` to continue.
2. Update Homebrew itself and its package definitions with `brew update`.
3. Install missing packages and upgrade declared packages with `brew bundle install --upgrade`.
4. Remove Homebrew formulae, casks, and taps absent from the file with `brew bundle cleanup --force`, keeping dependencies required by declared packages.

Use `brew "name"`, `cask "name"`, and `tap "owner/repo"` entries for tools, apps,
and additional repositories. Cleanup is limited to Homebrew packages and taps;
other package managers are outside this sync.

Exit Neovim with `:cq` to cancel before changing installed packages. Each step
stops on failure, so cleanup only runs after installation succeeds. Quitting
with `:q!` continues using the file already saved on disk.

See the [Homebrew Bundle documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile).

## Pewter file sync

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

## Set up Hirayama

[`scripts/setup-hirayama.sh`](scripts/setup-hirayama.sh) configures the Debian 13
host Hirayama. A copy is placed at `/home/platoa/setup-hirayama.sh` on that host.
Run it there:

```sh
sudo bash ~/setup-hirayama.sh
sudo reboot
```

After reboot, log in as `jon` with the same password, then run
`sudo bash ~/setup-hirayama.sh` again to choose the SMB password. Connect from
Finder with **Go → Connect to Server** and `smb://hirayama/iMac%20Plato`, using
`jon` and that SMB password. Over Tailscale, use
`smb://hirayama.mau-skate.ts.net/iMac%20Plato`.

New setups hide the filesystem's `lost+found` directory over SMB. To apply
that setting to an existing setup, run:

```sh
sudo bash ~/setup-hirayama.sh --hide-lost-found
```

This backs up and updates the share configuration, preserves existing veto
patterns, and reloads Samba without changing your password. Disconnect and
reconnect the share in Finder afterward. The directory stays on the disk.

The script installs zsh and copies Bagheera's two-line prompt with orange
(ANSI color 208) in place of purple. It keeps UID/GID 1000, the login password,
and `/home/platoa`, preserving existing application paths. The account and
primary group become `jon` at boot before login sessions start, and the rename
service then disables itself.

The existing ext4 drive labeled `iMac Plato` is mounted at `/srv/imac-plato`
by UUID through `/etc/fstab`. The script leaves its current desktop mount in
place until reboot and does not format the disk or recursively change its
permissions. Samba allows authenticated read/write access for `jon` and checks
that the correct disk is mounted before opening the share. UFW permits TCP 445
from the current Wi-Fi LAN (`192.168.29.0/24` on `wlp3s0`) and on `tailscale0`.
Update that LAN rule if the host changes networks.

Backups of account files, fstab, and any existing zsh configuration are kept
under `/var/backups/hirayama-setup.*`. The script refuses to replace an existing
Samba configuration that it did not create. If the rename fails, log in as
`platoa` and inspect `journalctl -b -u hirayama-rename`.

The boot rename follows the [Debian usermod requirements](https://manpages.debian.org/trixie/passwd/usermod.8.en.html).
SMB credentials use [Samba's smbpasswd](https://www.samba.org/samba/docs/current/man-html/smbpasswd.8.html).

## Rex

The `rex` Stow package tracks [init.lua](rex/.config/rex/init.lua). Install it with:

```sh
cd ~/.dotfiles
stow --target="$HOME" rex
```

Stow links `~/.config/rex` to `rex/.config/rex` in this repo. Editing either path
changes the same files, so future customizations appear in `git diff`.
Option + Down shows the next tab; Option + Up shows the previous tab.

After editing, run these commands in a Rex terminal on the machine running the server:

```sh
rex config check
rex config reload
```

The check validates the file without applying it. Reload applies it to connected
clients; Rex does not watch for file changes. You can check an unstowed draft with
`rex config check ~/.dotfiles/rex/.config/rex/init.lua`.

Rex runs `init.lua` as Lua on the server. Use `rex.bind` for shortcuts and
`rex.action` for custom actions. As the config grows, `require("keys")` can load a
`keys.lua` file beside `init.lua`. GUI shortcuts override Lua bindings.

This package tracks the Lua configuration. Captured macOS appearance settings,
including the Rex font and themes, are saved in [macos/preferences.json](macos/preferences.json).
If `XDG_CONFIG_HOME` is set, Rex looks under that directory instead of `~/.config`;
`REX_CONFIG` can override the file path in the server's environment.

See the [Rex configuration documentation](https://www.superlogical.com/rex/docs/customize/config)
and [CLI guide](https://www.superlogical.com/rex/docs/automate/cli). Rex adds its CLI
to the PATH of terminals it opens.

## Neovim in Rex

Run `nvim some/file.txt` in a Rex pane. Neovim uses Rex's live terminal palette,
including the statusline and Mist notes. See the [Neovim configuration](nvim/.config/nvim/README.md)
for theme and performance details.

## Captured settings

The configuration collected from the three machines is retained as a starting
point for the Bash setup scripts:

- [Machine and disk inventory](docs/inventory.md)
- [Credentials and data to recover separately](docs/secrets.md)
- macOS application versions and selected preferences in `macos/`
- Linux desktop preferences in `desktop/`
- Public SSH keys and known server identities in `keys/`
- Bagheera's Compose declaration in `workloads/bagheera/compose.yaml`

`macos/preferences.py` is a standalone helper for those selected preferences.
Its focused tests run with `python3 -m unittest discover -s tests`.
