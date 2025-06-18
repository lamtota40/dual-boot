#!/bin/bash

VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

sudo add-apt-repository -y ppa:mozillateam/ppa
echo | sudo add-apt-repository ppa:notepadqq-team/notepadqq
sudo apt update

#app inti lxde
sudo apt install --no-install-recommends lxde-core -y
sudo apt install lightdm-gtk-greeter lxterminal policykit-1 notification-daemon -y
sudo apt install -y xinit xorg lightdm dbus-x11 openbox lxsession lxpanel pcmanfm file-roller x11-utils libgtk-3-0 -y

sudo sed -i 's|^Exec=lxterminal$|Exec=lxterminal --command '\''bash --login'\''|' /usr/share/applications/lxterminal.desktop

echo "exec startlxde" | sudo tee "$HOME_DIR/.xsession" > /dev/null
sudo chmod +x "$HOME_DIR/.xsession"
sudo chown "$active_user:$active_user" "$HOME_DIR/.xsession"

[ -f /etc/lightdm/lightdm.conf ] && sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
sudo bash -c "cat > /etc/lightdm/lightdm.conf" <<EOF
[Seat:*]
user-session=LXDE
EOF

#desktop until2
sudo apt install -y onboard gparted firefox notepadqq

sudo apt install tigervnc-standalone-server tigervnc-common -y

sudo touch "$HOME_DIR/.Xauthority"
sudo chmod 600 "$HOME_DIR/.Xauthority"
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
export HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
cd "$HOME"
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
startlxde &
EOF

sudo chmod +x "$HOME_DIR/.vnc/xstartup"
sudo chown "$active_user:$active_user" "$HOME_DIR/.vnc/xstartup"
export DISPLAY=:1

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

echo "VNC server sudah selesai di install"
echo "Silahkan catat VNC SERVER IP Address: $(wget -qO- https://ipinfo.io/ip) Port: $((5900 + DISPLAY_NUM)) dengan Password: $VNC_PASS"
