#!/usr/bin/env bash
# Requires WSL2
# ALSO need to install this on the Windows side: https://github.com/dorssel/usbipd-win/releases
# https://devblogs.microsoft.com/commandline/connecting-usb-devices-to-wsl/
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WSL=$(if grep -q microsoft /proc/version; then echo 'true'; else echo 'false'; fi)
INSTALL_DIR="/usr/local/bin"

if [ $WSL == 'false' ]; then
    echo "This script must be run inside WSL2 only!"
    exit
fi

# Install USB-IP drivers in WSL2
sudo apt-get install -y linux-tools-virtual hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*/usbip 20   

# Copy scripts to INSTALL_DIR
cd "$SCRIPT_DIR"
sudo chmod +x *.sh
sudo chmod +x "usbip-automount-init"
sudo cp -f "usbip-attach.sh"  "$INSTALL_DIR/usbip-attach"
sudo cp -f "usbip-detach.sh"  "$INSTALL_DIR/usbip-detach"
sudo cp -f "usbip-list.sh"    "$INSTALL_DIR/usbip-list"
sudo cp -f "usbip-attach.bat" "$INSTALL_DIR/usbip-attach.bat"


# Install usbip-automount as an init.d service
service usbip-automount stop
sudo cp -f "usbip-automount-daemon.sh" "/usr/sbin/usbip-automount"
sudo cp -f "usbip-automount-init"      "/etc/init.d/usbip-automount"
sudo cp -f "usbip-automount-config"    "/etc/default/usbip-automount"

# Give user permissions to start udev service
APPEND="$USER ALL=(ALL) NOPASSWD: /etc/init.d/udev"
FILE="/etc/sudoers"
echo "Adding line: \"$APPEND\" to $FILE..."
if [ -z "$(sudo grep "$APPEND" "$FILE" )" ]; then
    echo "$APPEND" | sudo EDITOR='tee -a' visudo
fi

# Give user permissions to start usbip-automount service
APPEND="$USER ALL=(ALL) NOPASSWD: /etc/init.d/usbip-automount"
FILE="/etc/sudoers"
echo "Adding line: \"$APPEND\" to $FILE..."
if [ -z "$(sudo grep "$APPEND" "$FILE" )" ]; then
    echo "$APPEND" | sudo EDITOR='tee -a' visudo
fi

# Start udev service with ~/.profile
APPEND="(nohup sudo /etc/init.d/udev start </dev/null >/dev/null 2>&1 &)"
FILE="$HOME/.profile"
echo "Adding line: \"$APPEND\" to $FILE..."
grep -qxF "$APPEND" "$FILE" || echo "$APPEND" | tee -a "$FILE" > /dev/null

# Start usbip-automount service with ~/.profile
APPEND="(nohup service usbip-automount start </dev/null >/dev/null 2>&1 &)"
FILE="$HOME/.profile"
echo "Adding line: \"$APPEND\" to $FILE..."
grep -qxF "$APPEND" "$FILE" || echo "$APPEND" | tee -a "$FILE" > /dev/null

# done
echo "
The following scripts have been installed in \"$INSTALL_DIR\":
  usbip-list
  usbip-attach
  usbip-detach

Make sure you have downloaded and installed the latest version of USB-IP on Windows:
  https://github.com/dorssel/usbipd-win/releases

Please edit the config file to choose what devices to auto-attach to WSL:
  sudo nano /etc/default/usbip-automount

Then, restart your machine. Both 'udev' and 'usbip-automount' services should start automatically.
"
