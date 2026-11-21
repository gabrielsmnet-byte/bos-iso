#!/usr/bin/env bash
# Constrói uma ISO bootável (Debian Live) que liga direto no WebOS, em tela cheia.
# Rode num Debian/Ubuntu (ou WSL com Debian/Ubuntu), com internet:   sudo bash construir-iso.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Rode com sudo:  sudo bash construir-iso.sh"; exit 1; }
AQUI="$(cd "$(dirname "$0")" && pwd)"
apt-get update && apt-get install -y live-build debootstrap xorriso squashfs-tools
W=/tmp/webos-iso-build; rm -rf "$W"; mkdir -p "$W"; cd "$W"

# BOS_INSTALADOR=0 desliga o instalador de disco (so modo live); por padrao a ISO inclui a opcao 'Install'
INST=live; [ "${BOS_INSTALADOR:-1}" = 0 ] && INST=none
lb config --distribution bookworm --architectures amd64 --binary-images iso-hybrid \
  --debian-installer "$INST" --debian-installer-gui false --apt-recommends false --iso-volume "WebOS" --iso-application "WebOS" \
  --bootappend-live "boot=live components quiet splash persistence locales=pt_BR.UTF-8 keyboard-layouts=br timezone=America/Sao_Paulo" \
  --archive-areas "main contrib non-free-firmware"

mkdir -p config/package-lists config/includes.chroot/opt/webos config/includes.chroot/etc/skel config/includes.chroot/etc/systemd/system/getty@tty1.service.d
cat > config/package-lists/webos.list.chroot <<'L'
xserver-xorg xserver-xorg-legacy xinit openbox x11-xserver-utils dbus-x11 dbus-user-session libpam-systemd sudo chromium chromium-l10n wine wine64 fonts-dejavu fonts-liberation fonts-noto-color-emoji
network-manager network-manager-gnome alsa-utils pulseaudio pulseaudio-utils firmware-linux-free firmware-iwlwifi firmware-realtek
xserver-xorg-video-all xserver-xorg-input-libinput libgl1-mesa-dri x11-xkb-utils
firmware-linux-nonfree firmware-atheros firmware-brcm80211 firmware-misc-nonfree intel-microcode amd64-microcode
aria2 wireguard-tools iproute2 openresolv brightnessctl udisks2 policykit-1 usbutils ntfs-3g exfat-fuse dosfstools
live-boot live-config systemd-sysv locales console-setup
L
install -m 755 "$AQUI/bos" config/includes.chroot/opt/webos/bos
# permissoes minimas para o BOS controlar VPN WireGuard e fuso horario sem senha
mkdir -p config/includes.chroot/etc/sudoers.d
cat > config/includes.chroot/etc/sudoers.d/bos <<'L'
user ALL=(root) NOPASSWD: /usr/bin/wg-quick, /usr/bin/wg, /usr/bin/timedatectl
L
chmod 440 config/includes.chroot/etc/sudoers.d/bos
# instalador (modo 'live'): usuario 'user' para o login automatico continuar funcionando depois de instalado
mkdir -p config/includes.installer
cat > config/includes.installer/preseed.cfg <<'L'
d-i debian-installer/locale string pt_BR.UTF-8
d-i keyboard-configuration/xkb-keymap select br
d-i time/zone string America/Sao_Paulo
d-i passwd/user-fullname string BOS
d-i passwd/username string user
d-i netcfg/get_hostname string bos
L

# login automático no console 1 e início do X
cat > config/includes.chroot/etc/systemd/system/getty@tty1.service.d/autologin.conf <<'L'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin user --noclear %I $TERM
L
cat > config/includes.chroot/etc/skel/.bash_profile <<'L'
if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then exec startx; fi
L
cat > config/includes.chroot/etc/skel/.xinitrc <<'L'
xset s off -dpms 2>/dev/null
setxkbmap br 2>/dev/null
mkdir -p "$HOME/Downloads" "$HOME/.bos"
pulseaudio --start 2>/dev/null
# cliente BitTorrent completo para o app Torrent do BOS (somente nesta maquina)
aria2c --enable-rpc --rpc-listen-all=false --rpc-listen-port=6800 --rpc-allow-origin-all --dir="$HOME/Downloads" \
  --seed-time=0 --enable-dht=true --bt-enable-lpd=true --max-connection-per-server=8 --daemon=true 2>/dev/null
openbox-session &
export BOS_POWEROFF=1 WEBOS_DIR="$HOME/.bos" WEBOS_EXTRA_ARGS="--disable-gpu|--disable-dev-shm-usage"
while true; do
  /opt/webos/bos
  [ $? -eq 42 ] && break   # 42 = o usuario escolheu Desligar
  sleep 1
done
L
lb build
cp -v live-image-amd64.hybrid.iso "$AQUI/WebOS.iso"
echo; echo "Pronto: $AQUI/WebOS.iso"
