#!/bin/bash
# disable-lid-shutdown.sh
# Prevents system from suspending or shutting down when the laptop lid is closed

CONFIG_FILE="/etc/systemd/logind.conf"

# Backup the original config (only once)
if [ ! -f "${CONFIG_FILE}.bak" ]; then
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Update settings
sudo sed -i 's/^#*HandleLidSwitch=.*$/HandleLidSwitch=ignore/' "$CONFIG_FILE"
sudo sed -i 's/^#*HandleLidSwitchDocked=.*$/HandleLidSwitchDocked=ignore/' "$CONFIG_FILE"

# Restart logind to apply changes
sudo systemctl restart systemd-logind

echo "✅ Lid close actions disabled. System will stay running with the lid closed."
