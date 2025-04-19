# Creates swap space on the two drives /dev/vda /dev/vdb and set them up for Concurrent usage

#!/usr/bin/bash
set -e

# Set up swap

for d in /dev/vda /dev/vdb; do
  # Get the number of the next available partition (e.g., 3)
  nextpart=$(parted --script $d print | awk '/^ /{print $1}' | tail -n1)
  nextpart=$((nextpart + 1))

  # Use all remaining space for swap
  parted --script $d mkpart primary linux-swap 100%FREE

  # Build the new partition path
  p="${d}${nextpart}"
  
  mkswap $p
  swapon $p
  echo "$p none swap sw 0 0" >> /etc/fstab
done

# Set up SSH

# --- CONFIGURATION ---
SSH_PUBKEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAnDOEwjyIp1AQzHk3oz959yVFir/AMFaEcsRKQYrStearmsUouRa6nN0RUEybNxv2dBnOJa0vP3FUqVJEoEtCm4CBfrbewzRrxG6SRziSfcf01r5hZOGsQFGlTkXhR5LIr5PEGYV35RqKEiPqmOT/9ViXysplmKt1zi4Vi1+Biuqh1BSiBKOQKK3YjwVf/vCNAmQOeLtya8jjQkf0PvOWZsfX2V5Xwgh1sD58RZZvdIO76YAPtZPT9MyT+FjUHklaVphZRBJwSHbFScQgoW/C7y0WPsKGfTQ/IkkmL4Ii4tCbBbLcB0s13AsnqJwX8RvMaP+JUTSAtWrUiBUjNmGvMw== Brian"

# --- Create /root/.ssh and authorized_keys ---
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "$SSH_PUBKEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# --- Harden SSH server config ---
SSH_CONFIG="/etc/ssh/sshd_config"

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSH_CONFIG"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"

# Reload SSH service (safe even if not currently active)
if command -v systemctl >/dev/null; then
    systemctl reload sshd || true
else
    service ssh restart || true
fi
