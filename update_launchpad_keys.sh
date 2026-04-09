
#!/bin/bash

# Ensure HOME is set for cron
export HOME="/home/xsights"

SSH_DIR="$HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"
AUTH_KEYS_BAK="$SSH_DIR/authorized_keys.bak"
TMP_KEYS="/tmp/lp_keys_download.tmp"

# Ensure .ssh exists with correct permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 1. Fetch keys to a TEMPORARY file first
# -f fails on 404/500 errors, --connect-timeout prevents hanging during bridge flaps
if /usr/bin/curl -fsSL --connect-timeout 15 "https://launchpad.net/your_link/+sshkeys" -o "$TMP_KEYS"; then

    # 2. VALIDATION: Check if the download actually contains data
    if [ -s "$TMP_KEYS" ]; then
        
        # 3. BACKUP: Only backup if current file exists AND is NOT empty
        if [ -s "$AUTH_KEYS" ]; then
            cp "$AUTH_KEYS" "$AUTH_KEYS_BAK"
            chmod 600 "$AUTH_KEYS_BAK"
        fi

        # 4. DEPLOY: Atomic move to update keys
        mv "$TMP_KEYS" "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
    else
        echo "$(date): Download succeeded but keys were empty. Aborting update." >> "$HOME/shell_scripts/keys_error.log"
    fi
else
    # 5. FAILURE: Network/DNS error (Common if Bridge/VLAN is misconfigured)
    echo "$(date): Network failure (curl exit code $?). Keeping existing keys." >> "$HOME/shell_scripts/keys_error.log"
fi

# Clean up temp file if it exists
rm -f "$TMP_KEYS"
