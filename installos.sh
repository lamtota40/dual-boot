#!/bin/bash

# Konfigurasi
LUBUNTU_ISO="/root/win-xp.iso"
LUBUNTU_IMG="/root/winxp.qcow2"
DIll
VNC_PASSWORD="pas123"
MONITOR_SOCKET="/tmp/qemu-monitor.sock"

qemu-system-x86_64 \
  -m 1024 \
  -smp 1 \
  -cpu host \
  -enable-kvm \
  -hda "$LUBUNTU_IMG" \
  -cdrom "$LUBUNTU_ISO" \
  -boot d \
  -vnc :1,password \
  -k en-us \
  -net nic \
  -net user \
  -monitor unix:$MONITOR_SOCKET,server,nowait &

sleep 5
# Set password VNC melalui monitor QEMU
{
  echo "change vnc password"
  echo "$VNC_PASSWORD"
} | socat - UNIX-CONNECT:$MONITOR_SOCKET
echo "Selesai. QEMU berjalan dengan VNC di localhost:5901"
