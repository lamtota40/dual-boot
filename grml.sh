#!/bin/bash

sudo apt update
#sudo apt upgrade -y
sudo apt install grml-rescueboot zsh -y
sudo mkdir -p /boot/grml
 if [ ! -f /boot/grml/grml-small-2024.12-amd64.iso ]; then
  sudo wget https://mirror-hk.koddos.net/grml/grml-small-2024.12-amd64.iso -P /boot/grml/
 fi
sudo mkdir -p /etc/grml/partconf
sudo wget raw.githubusercontent.com/lamtota40/dual-boot/main/autorungrml.sh -P /etc/grml/partconf
sudo bash -c "echo 'CUSTOM_BOOTOPTIONS=\"ssh=pas123 dns=8.8.8.8,8.8.4.4 netscript=raw.githubusercontent.com/lamtota40/install-ulang/main/autorun-grml.sh partconf=/dev/vda3 toram\"' >> /etc/default/grml-rescueboot"
sudo update-grub
read -p "tekan [ENTER] untuk reboot"
sudo grub-reboot 'Grml Rescue System (grml-small-2024.12-amd64.iso)'
sudo reboot
