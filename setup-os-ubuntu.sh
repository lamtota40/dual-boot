#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install openssh-server -y
#desktop
#sudo apt install --no-install-recommends xinit xorg lightdm openbox lxsession lxpanel pcmanfm lxterminal file-roller -y
#sudo apt install -y lxde xinit xorg lightdm openbox-lxde-session
sudo apt install -y lxde-core xinit xorg lightdm openbox lxsession lxpanel pcmanfm lxterminal file-roller -y


echo "exec startlxde" > ~/.xsession
chmod +x ~/.xsession
if [ ! -f /etc/lightdm/lightdm.conf.bak ]; then
    sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
fi
sudo bash -c "cat > /etc/lightdm/lightdm.conf" <<EOF
[Seat:*]
user-session=LXDE
EOF

sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install firefox -y

#desktop until2
sudo apt install -y onboard gparted snapd zsh curl jq
sudo apt install gnome-software-plugin-snap -y
sudo snap install snap-store
sudo snap install notepad-plus-plus

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i '/^#\?PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Autoremove & reboot
sudo apt autoremove -y

sudo reboot



sudo systemctl disable lightdm
sudo systemctl stop lightdm
sudo apt install tigervnc-standalone-server tigervnc-common -y

# Setup password VNC dan buat sesi awal
sudo vncserver ---pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

mkdir -p "$HOME_DIR/.vnc"
sudo bash -c "cat > ~/.vnc/xstartup" <<EOF
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF
chmod +x ~/.vnc/xstartup

sudo vncserver -kill :*

vncserver :1 -geometry 1024x768 -depth 16 -dpi 96 -localhost no


sudo apt install lightdm openbox-lxde-session -y
sudo dpkg-reconfigure lightdm
cat /etc/X11/default-display-manager
sudo apt remove gdm3 -y
sudo apt install x11vnc net-tools -y
x11vnc -storepasswd <<EOF
$VNC_PASS
$VNC_PASS
y
EOF
sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=VNC Server for X11
Requires=display-manager.service

[Service]
ExecStart=/usr/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth $HOME/.vnc/passwd -rfbport 5900 -shared
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable x11vnc
sudo systemctl start x11vnc
sudo systemctl status x11vnc

echo '[Seat:*]
autologin-user=lubuntu
autologin-user-timeout=0
autologin-session=Lubuntu
greeter-session=lightdm-gtk-greeter' | sudo tee /etc/lightdm/lightdm.conf > /dev/null
sudo ln -sf /dev/null ~/.xsession-errors

sudo mkdir -p ~/.config/lxsession/Lubuntu
sudo tee ~/.config/lxsession/Lubuntu/autostart > /dev/null <<EOF
@xset s off
@xset -dpms
@xset s noblank
@lxsession -s Lubuntu -e LXDE
EOF

mkdir -p ~/.config/autostart
echo -e "[Desktop Entry]\nHidden=true" > ~/.config/autostart/xscreensaver.desktop

sudo apt remove --purge -y audacious gnome-mpv gnome-mines gnome-sudoku xpad simple-scan guvcview lxmusic sylpheed pidgin transmission-gtk xfburn
sudo apt autoremove -y
sudo apt clean

sudo systemctl stop cups
sudo systemctl disable cups

#sudo systemctl stop lightdm
#sudo systemctl disable lightdm
#reboot

VNC_PASS="pas123"
https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso
