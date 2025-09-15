#!/bin/bash
# cloudready-configerater.sh
# Configure CloudReady/ChromiumOS with Android + Play Store + Latest Chrome
# Author: You
# License: GPLv3

set -e

### COLORS ###
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

pause() { read -rp "Press Enter to continue..."; }

banner() {
  echo -e "${GREEN}"
  echo "============================================"
  echo "   CloudReady Configerater - Setup Tool     "
  echo "============================================"
  echo -e "${RESET}"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root!${RESET}"
    exit 1
  fi
}

### MENU ###
main_menu() {
  clear
  banner
  echo "1) System Info"
  echo "2) Install Waydroid (Android subsystem)"
  echo "3) Install OpenGApps (Google Play Store)"
  echo "4) Install Latest Chrome (Desktop shortcut)"
  echo "5) Exit"
  echo
  read -rp "Select an option: " choice

  case $choice in
    1) system_info ;;
    2) install_waydroid ;;
    3) install_opengapps ;;
    4) install_latest_chrome ;;
    5) exit 0 ;;
    *) echo "Invalid option"; pause ;;
  esac
  main_menu
}

### FUNCTIONS ###
system_info() {
  echo -e "${YELLOW}Collecting system information...${RESET}"
  uname -a
  echo
  lsmod | grep -E "binder|ashmem" || echo "⚠ Binder/Ashmem not found"
  pause
}

install_waydroid() {
  echo -e "${YELLOW}Installing Waydroid (Android container)...${RESET}"
  sudo apt update && sudo apt install -y curl unzip lzip python3 waydroid
  sudo waydroid init
  echo "-> Waydroid installed. Start with: sudo waydroid session start"
  pause
}

install_opengapps() {
  echo -e "${YELLOW}Installing OpenGApps (Google Play Store)...${RESET}"

  sudo waydroid session stop || true
  cd /var/lib/waydroid || exit

  echo "-> Downloading OpenGApps pico package (Android 11, arm64)..."
  wget https://sourceforge.net/projects/opengapps/files/arm64/20230814/open_gapps-arm64-11.0-pico-20230814.zip -O gapps.zip

  echo "-> Extracting..."
  unzip -q gapps.zip -d gapps_tmp

  echo "-> Injecting into Waydroid image..."
  sudo mount -o rw,loop waydroid_base.img /mnt
  sudo cp -r gapps_tmp/Core/* /mnt/system/priv-app/ || true
  sudo cp -r gapps_tmp/Core/* /mnt/system/app/ || true
  sudo umount /mnt

  rm -rf gapps.zip gapps_tmp
  sudo waydroid init -f

  echo -e "${GREEN}✔ Google Play Store installed!${RESET}"
  echo "Look for 'Play Store' inside your Android apps menu."
  pause
}

install_latest_chrome() {
  echo -e "${YELLOW}Fetching the latest Chromium build...${RESET}"

  mkdir -p ~/Desktop/LatestChrome
  cd ~/Desktop/LatestChrome || exit

  REV=$(curl -s https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/LAST_CHANGE)
  echo "-> Latest revision: $REV"

  wget -O chrome.zip "https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/${REV}/chrome-linux.zip"
  unzip -o chrome.zip
  rm chrome.zip

  mkdir -p ~/.local/share/applications
  cat <<EOF > ~/.local/share/applications/latest-chrome.desktop
[Desktop Entry]
Name=Latest Chrome
Exec=$HOME/Desktop/LatestChrome/chrome-linux/chrome
Icon=$HOME/Desktop/LatestChrome/chrome-linux/product_logo_64.png
Type=Application
Categories=Network;WebBrowser;
EOF

  echo -e "${GREEN}✔ Latest Chrome installed on Desktop at ~/Desktop/LatestChrome/${RESET}"
  echo "You can also find 'Latest Chrome' in your app menu."
  pause
}

### MAIN ###
check_root
main_menu
