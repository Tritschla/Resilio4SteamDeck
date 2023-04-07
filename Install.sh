#!/bin/bash

# Author: Tritschla
# 2023-04

# This script does the following:
# 1. It is creating Resilio4SteamDeck (R4SD) environment
# 2. It is creating Resilio (rslsync) environment
# 3. It is initializing Pacman Arch Linux Keys
# 4. It is installing needed packages for Resilio
# 5. It is downloading the Resilio application
# 6. It is creating all needed entries for auto starting Resilio on System Boot, incl. GameMode
# 7. It is providing an Resilio4SteamRepair Script to reinstall needed packages, lost on SteamDeck OS updates
# 8. It is providing an Uninstaller for R4SD incl. Resilio


# Create a hidden directory for R4SD, if not present
mkdir -p "$HOME/.R4SD" &>/dev/null
cd "$HOME/.R4SD" || exit 1

# Create a folder for rslsync, if not present
mkdir -p "$HOME/rslsync" &>/dev/null
cd "$HOME/rslsync" || exit 1


# Check for sudo access
set -e

if ! PASSWORD=$(zenity --password --title "Password required" --width=300 2> /dev/null); then
    zenity --error --text="Please enter your password." --width=300 2> /dev/null
    exit 1
fi

echo "$PASSWORD" | sudo -Sv || (zenity --error --text="Incorrect password." --width=300 2> /dev/null && exit 1)


# Deactivate readonly filesystem
echo "$PASSWORD" | sudo -S steamos-readonly disable


# Initialize Arch Linux Keys
echo "$PASSWORD" | sudo -S pacman-key --init
echo "$PASSWORD" | sudo -S pacman-key --populate archlinux


# Install needed package
echo "$PASSWORD" | sudo -S pacman -Syyu --noconfirm lib32-libxcrypt-compat


# Download the rslsync package from AUR
cd "$HOME" || exit 1
git clone https://aur.archlinux.org/rslsync.git


# Download i386 rslsync package:
cd "$HOME/.R4SD" || exit 1
wget https://download-cdn.resilio.com/stable/linux-i386/resilio-sync_i386.tar.gz


# Extract i386 files to destination folder
tar -xzf resilio-sync_i386.tar.gz -C "$HOME/rslsync"


# Create Resilio rslsync_user.service
cat <<EOF >| "$HOME/.config/systemd/user/rslsync_user.service"
[Unit]
Description=Resilio Sync per-user service
After=network.target

[Service]
Type=simple
ExecStart=/home/deck/rslsync/rslsync --nodaemon
Restart=on-abort

[Install]
WantedBy=default.target

EOF


# Enable and start rslsync_user service
systemctl --user enable rslsync_user
systemctl --user start rslsync_user


# Download RepairR4SD
cd "$HOME/.R4SD" || exit 1
wget https://github.com/Tritschla/Resilio4SteamDeck/blob/main/RepairR4SD.sh


# Creation of Uninstall-R4SD
cat <<EOF >| "$HOME/.R4SD/UninstallR4SD.sh"
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

# Notify the user that the uninstallation is complete
zenity --info --title="Uninstall R4SD" --text="Resilio for Steam Deck has been successfully uninstalled." --width=300 2> /dev/null

EOF

# Creation of Desktop Shortcuts
rm -rf "$HOME"/Desktop/RepairR4SD.desktop 2>/dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Repair R4SD
Comment=This tool updates all necessary tools & packages to get Resilio Sync working after a update to SteamOS
Exec=bash $HOME/.R4SD/RepairR4SD.sh
Icon=btsync-gui
Terminal=false
StartupNotify=false" >"$HOME"/Desktop/RepairR4SD.desktop
chmod +x "$HOME"/Desktop/RepairR4SD.desktop

rm -rf "$HOME"/Desktop/UninstallR4SD.desktop 2>/dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Uninstall R4SD
Comment=This tool updates all necessary tools & packages to get Resilio Sync working after a update to SteamOS
Exec=bash $HOME/.R4SD/UninstallR4SD.sh
Icon=btsync-gui
Terminal=false
StartupNotify=false" >"$HOME"/Desktop/UninstallR4SD.desktop
chmod +x "$HOME"/Desktop/UninstallR4SD.desktop


# Creation of Start Menu entries
rm -rf "$HOME"/.local/share/applications/RepairR4SD.desktop 2>/dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Repair R4SD
Exec=bash $HOME/.R4SD/RepairR4SD.sh
Icon=btsync-gui
Terminal=false
Type=Application
Categories=Utility
StartupNotify=false" >"$HOME"/.local/share/applications/RepairR4SD.desktop
chmod +x "$HOME"/.local/share/applications/RepairR4SD.desktop

rm -rf "$HOME"/.local/share/applications/UninstallR4SD.desktop 2>/dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Uninstall R4SD
Exec=bash $HOME/.R4SD/RepairR4SD.sh
Icon=btsync-gui
Terminal=false
Type=Application
Categories=Utility
StartupNotify=false" >"$HOME"/.local/share/applications/UninstallR4SD.desktop
chmod +x "$HOME"/.local/share/applications/UninstallR4SD.desktop


# Completion of the installation
zenity --info --text="R4SD / Resilio has been successfully installed and can be accessed through a browser (e.g. Google Chrome) using the following link: http://localhost:8888" --width=300 2> /dev/null
