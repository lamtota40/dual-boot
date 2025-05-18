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
    if [ ! -f /boot/grml/grml64-small_2024.02.iso ]; then
    sudo wget https://mirror.kku.ac.th/grml/grml64-small_2024.02.iso -P /boot/grml/
    fi
    GRML_ENTRY='Grml Rescue System (grml64-small_2024.02.iso)'
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


########################################################

sudo parted /dev/vda
unit GiB
print
rm 3
mklabel msdos
mkpart primary ntfs 1 14
mkpart primary ext4 14 29
set 2 boot on
mkpart primary ntfs 29 39
mkpart primary linux-swap 39 41
quit

# === KONFIGURASI ===
ISO_NAME="win-xp.iso"
TARGET_PART="/dev/vda3"
TARGET_DISK="/dev/vda"
MOUNT_DIR="/mnt/vda3"
GRUB_DIR="$MOUNT_DIR/boot/grub"
MEMDISK_SRC="/usr/lib/syslinux/memdisk"  # Path default di GRML

mkfs.vfat -F 32 "$TARGET_PART" || exit 1
mkdir -p "$MOUNT_DIR"
mount "$TARGET_PART" "$MOUNT_DIR" || exit 1
if [ ! -f "$ISO_NAME" ]; then
  echo "!! File $ISO_NAME tidak ditemukan di direktori saat ini!"
  exit 1
fi
cp "$ISO_NAME" "$MOUNT_DIR/"
cp "$MEMDISK_SRC" "$MOUNT_DIR/" || { echo "!! memdisk tidak ditemukan!"; exit 1; }

mkdir -p "$GRUB_DIR"
cat > "$GRUB_DIR/grub.cfg" <<EOF
set timeout=5
set default=0

menuentry "Install Windows XP dari ISO" {
    linux16 /memdisk iso raw
    initrd16 /$ISO_NAME
}
EOF

grub-install --target=i386-pc --boot-directory="$MOUNT_DIR/boot" "$TARGET_DISK" || exit 1
