#!/bin/bash

VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

sudo apt update
sudo apt upgrade -y
sudo apt install openssh-server -y
#desktop
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
#sudo snap install snap-store
#sudo snap install notepad-plus-plus

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i '/^#\?PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Autoremove & reboot
sudo apt autoremove -y

sudo apt install tigervnc-standalone-server tigervnc-common -y

# Setup password VNC dan buat sesi awal
sudo vncserver ---pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

sudo mkdir -p "$HOME_DIR/.vnc"
sudo bash -c "cat > ~/.vnc/xstartup" <<EOF
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF
sudo chmod +x ~/.vnc/xstartup

sudo chown -R "$active_user:$active_user" "$HOME_DIR"
sudo rm -f "$HOME_DIR/.vnc/*.pid"
sudo rm -f "$HOME_DIR/.Xauthority"
sudo mkdir -p "$HOME_DIR/.vnc"
sudo chown -R "$active_user:$active_user" "$HOME_DIR/.vnc"


# Buat systemd vnc server
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=Start TigerVNC server at startup for user $active_user (display :%i)
After=syslog.target network.target

[Service]
Type=forking
User=$active_user
PAMName=login
PIDFile=$HOME_DIR/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :* > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1024x768 -depth 16 -dpi 96 -localhost no
ExecStop=/usr/bin/vncserver -kill :*

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan aktifkan service
sudo systemctl daemon-reload
sudo systemctl enable "vncserver@$DISPLAY_NUM.service"

echo "VNC server untuk user $active_user sudah aktif di display :$DISPLAY_NUM"
echo "$s (port $((5900 + DISPLAY_NUM))) dengan password: $VNC_PASS"
