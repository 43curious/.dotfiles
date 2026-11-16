#!/usr/bin/env bash
# Run on Hirayama, reboot, then run again as jon to set the SMB password.
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export LC_ALL=C

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

if [[ ${1:-} == --help ]]; then
    printf '%s\n' \
        'On hirayama: sudo bash ~/setup-hirayama.sh' \
        'Reboot, log in as jon with the existing password, then run it again.' \
        'The second run asks for the SMB password. The home stays /home/platoa.'
    exit 0
fi
[[ $# == 0 ]] || die 'Only --help is supported.'
[[ $EUID == 0 ]] || die 'Run with: sudo bash ~/setup-hirayama.sh'
[[ $(hostname -s) == hirayama ]] || die 'This script is only for hirayama.'
# shellcheck source=/dev/null
source /etc/os-release
[[ $ID == debian && $VERSION_ID == 13 ]] || die 'Expected Debian 13.'
umask 077

drive_uuid=7d3c1de4-00ab-4120-9b9a-7feccf2fbac6
share_path=/srv/imac-plato
state_dir=/var/lib/hirayama-setup

if [[ -f $state_dir/rename-complete ]]; then
    [[ $(id -u jon) == 1000 ]] || die 'Expected jon to have UID 1000.'
    findmnt -rn -M "$share_path" -S "UUID=$drive_uuid" >/dev/null || die 'iMac Plato is not mounted.'
    runuser -u jon -- test -w "$share_path" || die 'jon cannot write to iMac Plato.'
    printf 'Choose the SMB password for jon (it can match your login password).\n'
    smbpasswd -a jon
    testparm -s >/dev/null
    systemctl restart smbd
    printf '\nReady: smb://hirayama/iMac%%20Plato (username: jon)\n'
    exit 0
fi

[[ $(id -u platoa) == 1000 && $(id -g platoa) == 1000 ]] || die 'Expected platoa to have UID/GID 1000.'
! getent passwd jon >/dev/null || die 'An account named jon already exists.'
! getent group jon >/dev/null || die 'A group named jon already exists.'
[[ $(getent passwd platoa | cut -d: -f6) == /home/platoa ]] || die 'Unexpected home directory.'
[[ $(blkid -s TYPE -o value "/dev/disk/by-uuid/$drive_uuid") == ext4 ]] || die 'Cannot find the ext4 iMac Plato drive.'
fstab_line="UUID=$drive_uuid $share_path ext4 defaults,nofail,nosuid,nodev,x-systemd.device-timeout=10s 0 2"
if awk -v source="UUID=$drive_uuid" -v target="$share_path" \
    '$1 !~ /^#/ && ($1 == source || $2 == target) { found=1 } END { exit !found }' /etc/fstab; then
    grep -Fxq "$fstab_line" /etc/fstab || die 'The drive already has a different fstab entry.'
fi

backup_dir=$(mktemp -d /var/backups/hirayama-setup.XXXXXXXX)
cp -a /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/fstab "$backup_dir/"
if [[ -e /home/platoa/.zshrc || -L /home/platoa/.zshrc ]]; then
    cp -a /home/platoa/.zshrc "$backup_dir/zshrc"
fi
if [[ -f /etc/samba/smb.conf ]]; then
    cp -a /etc/samba/smb.conf "$backup_dir/smb.conf"
    grep -Fq '# Managed by setup-hirayama.sh' /etc/samba/smb.conf || \
        die "Existing Samba configuration saved in $backup_dir; review it before replacing it."
fi
printf 'Backups: %s\n' "$backup_dir"
apt-get update
apt-get install -y zsh git samba samba-vfs-modules

# Stage a normal fstab mount for the next boot; leave the desktop mount alone.
install -d -m 0755 "$share_path"
if ! grep -Fxq "$fstab_line" /etc/fstab; then
    printf '\n%s\n' "$fstab_line" >> /etc/fstab
fi

install -d -m 0700 "$state_dir"
cat > "$state_dir/zshrc" <<'ZSHRC'
# Interactive zsh configuration for Hirayama, matching Bagheera's layout.
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" $path)
export PATH

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

autoload -Uz compinit
compinit
bindkey -e
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

alias ls='ls --color=auto'
alias l='ls -l'
alias ll='ls -lh'
alias la='ls -lAh'
alias ..='cd ..'
alias ...='cd ../..'

autoload -U colors && colors
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

# Orange path and arrow; gray clean branches and red dirty branches.
PROMPT='%F{208}%~%f${git_prompt}
%F{208}❯%f '
ZSHRC
install -o 1000 -g 1000 -m 0644 "$state_dir/zshrc" /home/platoa/.zshrc
usermod --shell /usr/bin/zsh platoa

cat > /etc/samba/smb.conf <<'SMBCONF'
# Managed by setup-hirayama.sh; the original is in /var/backups/hirayama-setup.*
[global]
    workgroup = WORKGROUP
    server role = standalone server
    security = user
    map to guest = never
    server min protocol = SMB2
    smb ports = 445
    load printers = no
    disable spoolss = yes
    vfs objects = fruit streams_xattr

[iMac Plato]
    path = /srv/imac-plato
    browseable = yes
    read only = no
    guest ok = no
    valid users = jon
    create mask = 0600
    directory mask = 0700
    root preexec = /usr/bin/findmnt -rn -M /srv/imac-plato -S UUID=7d3c1de4-00ab-4120-9b9a-7feccf2fbac6
    root preexec close = yes
SMBCONF
chmod 0644 /etc/samba/smb.conf
testparm -s >/dev/null
install -d -m 0755 /etc/systemd/system/smbd.service.d
cat > /etc/systemd/system/smbd.service.d/imac-plato.conf <<'SMBUNIT'
[Unit]
RequiresMountsFor=/srv/imac-plato
SMBUNIT

# Rename before login sessions start. UID, GID, home, files and password stay intact.
cat > "$state_dir/rename.sh" <<'RENAME'
#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
if getent passwd platoa >/dev/null; then
    ! getent passwd jon >/dev/null || { echo 'jon already exists.' >&2; exit 1; }
    [[ $(id -u platoa) == 1000 ]]
    ! pgrep -u 1000 >/dev/null || { echo 'platoa still has running processes.' >&2; exit 1; }
    usermod --login jon platoa
fi
[[ $(id -u jon) == 1000 ]]
if getent group platoa >/dev/null; then
    ! getent group jon >/dev/null || { echo 'The jon group already exists.' >&2; exit 1; }
    groupmod --new-name jon platoa
fi
for folder in /var/spool/cron/crontabs /var/mail /var/lib/systemd/linger /var/lib/AccountsService/users; do
    if [[ -e $folder/platoa && ! -e $folder/jon ]]; then
        mv -- "$folder/platoa" "$folder/jon"
    fi
done
touch /var/lib/hirayama-setup/rename-complete
systemctl disable --no-reload hirayama-rename.service
RENAME
chmod 0700 "$state_dir/rename.sh"
cat > /etc/systemd/system/hirayama-rename.service <<'RENAMEUNIT'
[Unit]
Description=Rename platoa to jon before user sessions start
After=local-fs.target
Before=systemd-user-sessions.service user@1000.service lightdm.service accounts-daemon.service ssh.service ssh.socket smbd.service cron.service atd.service
RequiresMountsFor=/home/platoa
ConditionPathExists=!/var/lib/hirayama-setup/rename-complete

[Service]
Type=oneshot
ExecStart=/bin/bash /var/lib/hirayama-setup/rename.sh

[Install]
WantedBy=multi-user.target
RENAMEUNIT

# UFW is enabled on Hirayama. Allow direct SMB on its LAN and Tailscale.
if command -v ufw >/dev/null && ufw status | grep -q '^Status: active'; then
    ufw allow in on wlp3s0 from 192.168.29.0/24 to any port 445 proto tcp
    ufw allow in on tailscale0 to any port 445 proto tcp
fi
systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/hirayama-rename.service
systemctl enable hirayama-rename.service smbd.service
printf '\nPrepared. Save your work, then run: sudo reboot\n'
printf 'After reboot, log in as jon with your existing password and run:\n'
printf '  sudo bash %q\n' "$(readlink -f "$0")"
printf 'That final run sets your SMB password and starts the share.\n'
