#!/bin/bash

# Function to log actions with a timestamp
script() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

script "Executing the script..."

# Update Network Configuration
NETPLAN_FILE="/etc/netplan/10-lxc.yaml"
if grep -q "192.168.16.21/24" "$NETPLAN_FILE"; then
    script "Network configuration is already correct."
else
    script "Updating network configuration to 192.168.16.21/24..."
    sudo sed -i 's/192.168.16.*/192.168.16.21\/24/' "$NETPLAN_FILE"
    sudo netplan apply
    script "Network configuration updated."
fi

# Update /etc/hosts
HOSTS_FILE="/etc/hosts"
if grep -q "192.168.16.21 server1" "$HOSTS_FILE"; then
    script "/etc/hosts is correct."
else
    script "Updating /etc/hosts to include 192.168.16.21 server1..."
    sudo sed -i '/server1/d' "$HOSTS_FILE"
    echo "192.168.16.21 server1" | sudo tee -a "$HOSTS_FILE"
    script "/etc/hosts updated."
fi

# Install Apache2
script "Checking and installing Apache2..."
if dpkg -l | grep -q apache2; then
    script "Apache2 is already installed."
else
    sudo apt update
    sudo apt install -y apache2
    script "Apache2 installed."
fi
sudo systemctl restart apache2
script "Apache2 service restarted."

# Install Squid
script "Checking and installing Squid..."
if dpkg -l | grep -q squid; then
    script "Squid is already installed."
else
    sudo apt install -y squid
    script "Squid installed."
fi
sudo systemctl restart squid
script "Squid service restarted."

# Create users and configure SSH keys
script "Creating user accounts and setting up SSH keys..."
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for USER in "${USERS[@]}"; do
    if id "$USER" &>/dev/null; then
        script "User $USER already exists."
    else
        sudo useradd -m -s /bin/bash "$USER"
        script "User $USER created."
    fi

    USER_SSH_DIR="/home/$USER/.ssh"
    if [ ! -d "$USER_SSH_DIR" ]; then
        sudo mkdir -p "$USER_SSH_DIR"
        sudo chmod 700 "$USER_SSH_DIR"
    fi

    if [ ! -f "$USER_SSH_DIR/authorized_keys" ]; then
        echo "$SSH_KEY" | sudo tee -a "$USER_SSH_DIR/authorized_keys"
        sudo chmod 600 "$USER_SSH_DIR/authorized_keys"
        script "SSH key added for $USER."
    fi
    sudo usermod -s /bin/bash "$USER"
done

# Add dennis to sudo group
if groups dennis | grep -q "\bsudo\b"; then
    script "User dennis already has sudo access."
else
    sudo usermod -aG sudo dennis
    script "User dennis added to the sudo group."
fi

script "Configuration complete. All actions have been applied."
