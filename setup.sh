#!/bin/bash
#fix
#
# windows 15GB
# linux 15GB
# data 8GB
# swap 3GB

sudo apt install grml-rescueboot zsh -y
sudo mkdir -p /boot/grml
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    echo "Terdeteksi sistem 64-bit"
    if [ ! -f /boot/grml/grml-small-2024.12-amd64.iso ]; then
    sudo wget https://mirror-hk.koddos.net/grml/grml-small-2024.12-amd64.iso -P /boot/grml/
    fi
    GRML_ENTRY='Grml Rescue System (grml-small-2024.12-amd64.iso)'
elif [[ "$ARCH" == "i386" || "$ARCH" == "i686" ]]; then
    echo "Terdeteksi sistem 32-bit"
    if [ ! -f /boot/grml/grml32-small_2024.02.iso ]; then
    sudo wget https://mirror.kku.ac.th/grml/grml32-small_2024.02.iso -P /boot/grml/
    fi
    GRML_ENTRY='Grml Rescue System (grml32-small_2024.02.iso)'
else
    echo "Arsitektur tidak dikenali: $ARCH"
    GRML_ENTRY=''
    exit 1
fi
sudo mkdir -p /etc/grml/partconf
sudo wget raw.githubusercontent.com/lamtota40/install-ulang/main/autorun-grml.sh -P /etc/grml/partconf
sudo bash -c "echo 'CUSTOM_BOOTOPTIONS=\"ssh=pas123 dns=8.8.8.8,8.8.4.4 netscript=raw.githubusercontent.com/lamtota40/install-ulang/main/autorun-grml.sh toram\"' >> /etc/default/grml-rescueboot"
sudo update-grub
sudo grub-reboot "$GRML_ENTRY"


######################################################

lsblk
sudo parted /dev/sda
print
rm 3
mklabel msdos
mkpart primary ntfs 1MiB 13GiB
mkpart primary ext4 13GiB 28GiB
mkpart primary ntfs 28GiB 38GiB
set 1 boot on
mkpart primary linux-swap 38GiB 100%
quit

# === KONFIGURASI ===
mkfs.vfat -F 32 "/dev/sda2"
mkdir -p "/mnt/sda2"
mount "/dev/sda2" "/mnt/sda2"
if [ ! -f "/mnt/vda3/win-xp.iso" ]; then
    wget https://archive.org/download/WinXPProSP3x86/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso -O "/mnt/vda3/win-xp.iso"
else
    echo "File win-xp.iso sudah ada di /mnt/vda3."
fi

cp "/usr/lib/syslinux/memdisk" "/mnt/vda3/" || { echo "!! memdisk tidak ditemukan!"; exit 1; }

mkdir -p "/mnt/vda3/boot/grub"
cat > "/mnt/vda3/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0

menuentry "Install Windows XP dari ISO" {
    linux16 /memdisk iso raw
    initrd16 /win-xp.iso
}
EOF

grub-install --target=i386-pc --boot-directory="/mnt/vda3/boot" "/dev/vda"
############################################
sudo apt update
sudo apt install grub-pc-bin grub-common syslinux dosfstools
