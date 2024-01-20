#!/bin/bash

# Author: Tritschla
# 2023-04

# This script initializes Arch Linux keys, installs a needed package
# and enables / starts the rslsync_user service.

set -e

# Check for sudo access
if ! PASSWORD=$(zenity --password --title "Sudo Password" --width=300 2> /dev/null); then
    zenity --error --text="Please enter your sudo password." --width=300 2> /dev/null
    exit 1
fi

echo "$PASSWORD" | sudo -Sv || (zenity --error --text="Incorrect password." --width=300 2> /dev/null && exit 1)

# Deactivate readonly filesystem
echo "$PASSWORD" | sudo -S steamos-readonly disable

# Remove folder with certificate information
echo "$PASSWORD" | sudo rm -rf /etc/pacman.d/gnupg

# Initialize Arch Linux Keys
#echo "$PASSWORD" | sudo -S pacman-key --populate archlinux
echo "$PASSWORD" | sudo pacman-key --init
echo "$PASSWORD" | sudo pacman-key --populate
echo "$PASSWORD" | sudo pacman -Sy archlinux-keyring --noconfirm
echo "$PASSWORD" | sudo pacman -Syy --noconfirm

# Install needed package
echo "$PASSWORD" | sudo -S pacman -Syyu --noconfirm lib32-libxcrypt-compat

# Enable and start rslsync_user service
systemctl --user enable rslsync_user
systemctl --user start rslsync_user

# Completion of script
zenity --info --text "Resilio has been successfully repaired and can be accessed through a browser (e.g. Google Chrome) using the following link: http://localhost:8888" --width=300 2> /dev/null
