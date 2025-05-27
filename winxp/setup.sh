# File: xp-boot-rev1.sh

lsblk
sudo parted /dev/sda <<EOF
mklabel msdos
mkpart primary ntfs 1MiB 10GiB
mkpart primary ntfs 10GiB 100%
set 2 boot on
quit
EOF

mkfs.vfat -F 32 "/dev/sda2"
mkdir -p /mnt/sda2
mount /dev/sda2 /mnt/sda2

# Download Windows XP ISO jika belum ada
if [ ! -f "/mnt/sda2/win-xp.iso" ]; then
    wget https://archive.org/download/WinXPProSP3x86/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso -O "/mnt/sda2/win-xp.iso"
else
    echo "File win-xp.iso sudah ada."
fi

# Download grub.exe dari grub4dos dan firadisk.zip
wget -O /mnt/sda2/grub.exe "https://github.com/lamtota40/dual-boot/raw/refs/heads/main/winxp/grub.exe"
wget -O /mnt/sda2/firadisk.zip "https://github.com/lamtota40/dual-boot/raw/refs/heads/main/winxp/firadisk.zip"
command -v unzip >/dev/null || (apt update && apt install -y unzip)
unzip /mnt/sda2/firadisk.zip -d /mnt/sda2/

# Pasang GRUB untuk i386-pc
mkdir -p /mnt/sda2/boot/grub
cat > /mnt/sda2/boot/grub/grub.cfg <<EOF
set timeout=5
set default=0

menuentry "Install Windows XP dari ISO (via grub4dos)" {
    insmod ntfs
    ntldr /grub.exe
}
EOF

# Install GRUB ke MBR
grub-install --target=i386-pc --boot-directory=/mnt/sda2/boot /dev/sda

# Siapkan menu.lst untuk grub4dos
cat > /mnt/sda2/menu.lst <<EOF
timeout 0
default 0

title Install Windows XP dari ISO (dengan FiraDisk)
find --set-root /win-xp.iso
map /win-xp.iso (0xff) || map --mem /win-xp.iso (0xff)
map --hook
chainloader (0xff)
EOF
