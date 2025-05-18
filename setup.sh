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
mkfs.vfat -F 32 "/dev/vda3" || exit 1
mkdir -p "/mnt/vda3"
mount "/dev/vda3" "/mnt/vda3" || exit 1
if [ ! -f "win-xp.iso" ]; then
  echo "!! File win-xp.iso tidak ditemukan di direktori saat ini!"
  exit 1
fi
cp "win-xp.iso" "/mnt/vda3/"
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

grub-install --target=i386-pc --boot-directory="/mnt/vda3/boot" "/dev/vda" || exit 1
