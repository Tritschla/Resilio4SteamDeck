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

zenity --info --text="Welcome to the installation of R4SD - Resilio for Steam Deck. Click OK to start installation" --width=300 2> /dev/null

echo "Welcome to the installation of R4SD - Resilio for Steam Deck"
echo " "
echo "This installer will enable your Steam Deck to use Resilio Sync"
echo " "
echo " "

# Check for sudo access
set -e

if ! PASSWORD=$(zenity --password --title "Password required" --width=300 2> /dev/null); then
    zenity --error --text="Please enter your password" --width=300 2> /dev/null
    exit 1
fi

echo "$PASSWORD" | sudo -Sv || (zenity --error --text="Incorrect password" --width=300 2> /dev/null && exit 1)


# Deactivate readonly filesystem
echo "$PASSWORD" | sudo -S steamos-readonly disable


# Create a hidden directory for R4SD, if not present
mkdir -p "$HOME/.R4SD" &>/dev/null
cd "$HOME/.R4SD" || exit 1

# Create a folder for rslsync, if not present
mkdir -p "$HOME/rslsync" &>/dev/null
cd "$HOME/rslsync" || exit 1

# Start Log File in R4SD directory
cd "$HOME/.R4SD" || exit 1
log="$(date +'%Y-%m-%d_%H-%M-%S')_Install.txt"
touch $log
echo "All information is collected within the log file:"
echo $(pwd)/$log
echo " "
echo " "

# Initialize Arch Linux Keys
echo "Initialize Arch Linux Keys" | tee -a $log
echo "$PASSWORD" | sudo rm -rf /etc/pacman.d/gnupg >> "$log"
echo "$PASSWORD" | sudo pacman-key --init >> "$log"
echo "$PASSWORD" | sudo pacman-key --populate >> "$log"
echo "$PASSWORD" | sudo pacman -Sy archlinux-keyring --noconfirm >> "$log"
echo "$PASSWORD" | sudo pacman -Syy --noconfirm >> "$log"
echo "-> Initializing complete" | tee -a $log


# Install needed package
echo "Initialize needed package" | tee -a $log
echo "$PASSWORD" | sudo -S pacman -Syyu --noconfirm lib32-libxcrypt-compat >> "$log"


# Download the rslsync package from AUR
cd "$HOME" || exit 1
git clone https://aur.archlinux.org/rslsync.git >> "$log"
echo "-> Download rslsync complete" | tee -a $log

# Download i386 rslsync package:
cd "$HOME/.R4SD" || exit 1
wget https://download-cdn.resilio.com/stable/linux-i386/resilio-sync_i386.tar.gz >> "$log"
echo "-> Download Resilio Sync complete" | tee -a $log


# Extract i386 files to destination folder
tar -xzf resilio-sync_i386.tar.gz -C "$HOME/rslsync" >> "$log"
echo "-> Installation of rslsync complete" | tee -a $log


# Create Resilio rslsync_user.service
echo "Creating User Service" | tee -a $log
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
systemctl --user enable rslsync_user >> "$log"
systemctl --user start rslsync_user >> "$log"


# Download RepairR4SD
echo "Downloading R4SD Tools" | tee -a $log
cd "$HOME/.R4SD" || exit 1 >> "$log"
wget https://raw.githubusercontent.com/Tritschla/Resilio4SteamDeck/main/RepairR4SD.sh >> "$log"
chmod +x "$HOME/.R4SD/RepairR4SD.sh" >> "$log"


# Download of Uninstall-R4SD
cd "$HOME/.R4SD" || exit 1 >> "$log"
wget https://raw.githubusercontent.com/Tritschla/Resilio4SteamDeck/main/UninstallR4SD.sh >> "$log"
chmod +x "$HOME/.R4SD/UninstallR4SD.sh" >> "$log"

# Creation of Desktop Shortcuts
rm -rf "$HOME"/Desktop/RepairR4SD.desktop 2>/dev/null
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Repair R4SD
Comment=This tool updates all necessary tools & packages to get Resilio Sync working after a update to SteamOS
Exec=bash $HOME/.R4SD/RepairR4SD.sh
Icon=btsync-gui
Terminal=false
Type=Application
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
Type=Application
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
Exec=bash $HOME/.R4SD/UninstallR4SD.sh
Icon=btsync-gui
Terminal=false
Type=Application
Categories=Utility
StartupNotify=false" >"$HOME"/.local/share/applications/UninstallR4SD.desktop
chmod +x "$HOME"/.local/share/applications/UninstallR4SD.desktop


# Completion of the installation
zenity --info --text="R4SD / Resilio has been successfully installed and can be accessed through a browser (e.g. Google Chrome) using the following link: http://localhost:8888" --width=300 2> /dev/null
zenity --info --text="Please note: After a Steam Deck Update it might be necessary to run RepairR4SD (linked on your Desktop) in order to get R4SD working properly again" --width=300 2> /dev/null

echo "END OF INSTALLATION" >> $log
