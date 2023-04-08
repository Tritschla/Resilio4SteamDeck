#!/bin/bash

# Author: Tritschla
# 2023-04

# Ask the user if they want to uninstall R4SD
if ! zenity --question --title="Uninstall R4SD?" --text="Are you sure you want to uninstall Resilio for Steam Deck?" --width=300 2> /dev/null ; then
    exit 0
fi

# Stop and disable rslsync user
systemctl --user daemon-reload
systemctl --user stop rslsync_user
systemctl --user disable rslsync_user

# Delete rslsync_user.service file
rm -f "$HOME/.config/systemd/user/rslsync_user.service"

# Recursively delete rslsync & R4SD folder
rm -rf "$HOME/rslsync"
rm -rf "$HOME/.R4SD"

# Delete Desktop Icons
rm -rf "$HOME/Desktop/RepairR4SD.desktop"
rm -rf "$HOME/Desktop/UninstallR4SD.desktop"

# Delete Start Menue entries
rm -rf "$HOME"/.local/share/applications/RepairR4SD.desktop
rm -rf "$HOME"/.local/share/applications/UninstallR4SD.desktop

# Notify the user that the uninstallation is complete
zenity --info --title="Uninstall R4SD" --text="Resilio for Steam Deck has been successfully uninstalled." --width=300 2> /dev/null
