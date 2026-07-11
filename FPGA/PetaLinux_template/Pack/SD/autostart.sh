#!/bin/sh 
echo  "============================= autostart.sh =============================" 
cp -rf /media/sd-mmcblk1p1/lib /usr
echo  "QT DISPLAY 0.0" 
export DISPLAY=:0.0
source /media/sd-mmcblk1p1/
xrandr --output DP-1 --mode 1280x720
cp -rf /media/sd-mmcblk1p1/appLink.desktop /usr/share/applications/
ifconfig eth0 192.168.137.2 netmask 255.255.255.0
echo  "========================================================================" 