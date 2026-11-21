#!/usr/bin/env bash
# Cria uma partição de PERSISTÊNCIA no espaço livre do pendrive onde a ISO do BOS foi gravada (modo imagem/DD),
# para seus arquivos e configurações não sumirem ao desligar.  Uso (num Linux, com o pendrive ligado):
#   sudo bash criar-persistencia.sh /dev/sdX        (troque sdX pelo pendrive: confira com 'lsblk'!)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Rode com sudo."; exit 1; }
D="${1:-}"; [[ "$D" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+|mmcblk[0-9]+)$ ]] || { echo "Uso: sudo bash $0 /dev/sdX"; exit 1; }
[ "$(cat /sys/block/$(basename "$D")/removable 2>/dev/null || echo 1)" = 1 ] || { echo "ATENCAO: $D nao parece removivel. Confira com lsblk. Abortando por seguranca."; exit 1; }
echo "Vai criar uma particao nova no espaco livre de $D (nao apaga a ISO). Continuar? (digite sim)"; read -r r; [ "$r" = sim ] || exit 0
N=$(lsblk -nlo NAME "$D" | grep -c .)
parted -s "$D" -- mkpart primary ext4 "$(parted -s "$D" unit MB print free | awk '/Free Space/{s=$1} END{print s}')" 100%
sleep 2; P=$(lsblk -nlo PATH "$D" | tail -1)
mkfs.ext4 -F -L persistence "$P"
M=$(mktemp -d); mount "$P" "$M"; echo "/ union" > "$M/persistence.conf"; umount "$M"; rmdir "$M"
echo "Pronto: $P (rotulo 'persistence'). No proximo boot do pendrive seus dados serao mantidos."
