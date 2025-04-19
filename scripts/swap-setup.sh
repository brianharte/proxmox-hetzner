# Creates swap space on the two drives /dev/vda /dev/vdb and set them up for Concurrent usage

#!/usr/bin/bash
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
