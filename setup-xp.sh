mklabel msdos
mkpart primary ntfs 1MiB 13GiB
set 1 boot on
mkpart primary ext4 13GiB 28GiB
mkpart primary ntfs 28GiB 38GiB
mkpart primary linux-swap 38GiB 100%
quit

mkfs.ntfs -f /dev/sda1     # untuk XP
mkfs.ext4 /dev/sda2        # untuk Ubuntu
mkfs.ntfs -f /dev/sda3     # untuk Data
mkswap /dev/sda4           # untuk swap

