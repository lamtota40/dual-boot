# Tampilkan partisi
lsblk

# Siapkan partisi
sudo parted /dev/sda <<EOF
mklabel msdos
mkpart primary ntfs 1MiB 10GiB
mkpart primary fat32 10GiB 100%
set 2 boot on
quit
EOF

# Format dan mount partisi
mkfs.vfat -F 32 /dev/sda2
mkdir -p /mnt/sda2
mount /dev/sda2 /mnt/sda2

# Download ISO jika belum ada
if [ ! -f /mnt/sda2/win-xp.iso ]; then
    wget -O /mnt/sda2/win-xp.iso "https://archive.org/download/WinXPProSP3x86/en_windows_xp_professional_with_service_pack_3_x86_cd_vl_x14-73974.iso"
fi

# Ekstrak isi ISO ke partisi
mkdir -p /mnt/tmpiso
mount -o loop /mnt/sda2/win-xp.iso /mnt/tmpiso
cp -rT /mnt/tmpiso /mnt/sda2/
umount /mnt/tmpiso
rm -rf /mnt/tmpiso

# Download grub.exe dan ntldr support
wget -O /mnt/sda2/grub.exe "https://github.com/lamtota40/dual-boot/raw/refs/heads/main/winxp/grub.exe"
wget -O /mnt/sda2/firadisk.zip "https://github.com/lamtota40/dual-boot/raw/refs/heads/main/winxp/firadisk.zip"
unzip /mnt/sda2/firadisk.zip -d /mnt/sda2/
rm -f /mnt/sda2/firadisk.zip

# Copy ntldr dan ntdetect.com dari i386 ke root
cp /mnt/sda2/I386/NTLDR /mnt/sda2/
cp /mnt/sda2/I386/NTDETECT.COM /mnt/sda2/

# Siapkan GRUB4DOS menu.lst
cat > /mnt/sda2/menu.lst <<EOF
timeout 0
default 0

title Install Windows XP (Setup from HDD)
find --set-root /I386/SETUPLDR.BIN
chainloader /I386/SETUPLDR.BIN
EOF

# Buat GRUB menu untuk chainload grub4dos
mkdir -p /mnt/sda2/boot/grub
cat > /mnt/sda2/boot/grub/grub.cfg <<EOF
set timeout=5
set default=0

menuentry "Install Windows XP (grub4dos method)" {
    insmod fat
    insmod part_msdos
    ntldr /grub.exe
}
EOF

# Install GRUB ke MBR
grub-install --target=i386-pc --boot-directory=/mnt/sda2/boot /dev/sda
