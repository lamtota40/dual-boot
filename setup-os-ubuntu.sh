#!/bin/bash

VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update
sudo apt install firefox -y

#app inti lxde
apt install --no-install-recommends lxde-core -y
apt install lxterminal policykit-1 notification-daemon -y

sudo apt install -y xinit xorg lightdm dbus-x11 openbox lxsession lxpanel pcmanfm file-roller -y

echo "exec startlxde" | sudo tee "$HOME_DIR/.xsession" > /dev/null
sudo chmod +x "$HOME_DIR/.xsession"
sudo chown "$active_user:$active_user" "$HOME_DIR/.xsession"

[ -f /etc/lightdm/lightdm.conf ] && sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
sudo bash -c "cat > /etc/lightdm/lightdm.conf" <<EOF
[Seat:*]
user-session=LXDE
EOF

#desktop until2
#sudo apt install -y onboard gparted snapd zsh curl jq
#sudo apt install gnome-software-plugin-snap -y
#sudo snap install snap-store
#sudo snap install notepad-plus-plus

sudo apt install tigervnc-standalone-server tigervnc-common -y

touch ~/.Xauthority
sudo chmod 600 ~/.Xauthority
sudo chown "$active_user:$active_user" "$HOME_DIR/.Xauthority"

# Setup password VNC dan buat sesi awal
sudo vncserver ---pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

sudo vncserver -kill :*
sudo rm -rf "$HOME_DIR/.vnc/*.pid"

sudo mkdir -p "$HOME_DIR/.vnc"
sudo chown -R "$active_user:$active_user" "$HOME_DIR"
sudo chown -R "$active_user:$active_user" "$HOME_DIR/.vnc"

sudo tee "$HOME_DIR/.vnc/xstartup" > /dev/null <<EOF
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF

sudo chmod +x "$HOME_DIR/.vnc/xstartup"
sudo chown "$active_user:$active_user" "$HOME_DIR/.vnc/xstartup"

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
#sudo systemctl enable lightdm

echo "VNC server untuk user $active_user sudah aktif di display :$DISPLAY_NUM"
echo "VNC aktif di port $((5900 + DISPLAY_NUM)) dengan password: $VNC_PASS"

