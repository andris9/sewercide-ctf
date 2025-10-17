#!/bin/bash
set -euo pipefail

echo "=== Sewercide CTF Challenge Installation ==="
echo "[i] Running as user: $(whoami)"
echo "[i] User ID: $(id -u)"
echo "[i] Groups: $(id -Gn)"
echo "[i] Working directory: $(pwd)"
echo "[i] Hostname: $(hostname)"
echo "[i] OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "[i] Sudo available: $(command -v sudo >/dev/null && echo 'yes' || echo 'no')"
echo "[i] Environment variables:"
env | grep -E '^(USER|PASSWORD|SUDO|ROLE)' || echo "  (no relevant env vars found)"
echo ""

# Prevent interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Cleanup function to remove installation traces
cleanup() {
    echo "[+] Cleaning up installation traces..."

    # Clear bash history for root
    history -c
    history -w
    > ~/.bash_history

    # Clear system logs that might contain installation commands
    truncate -s 0 /var/log/auth.log 2>/dev/null || true
    truncate -s 0 /var/log/syslog 2>/dev/null || true
    truncate -s 0 /var/log/kern.log 2>/dev/null || true
    truncate -s 0 /var/log/dpkg.log 2>/dev/null || true
    truncate -s 0 /var/log/apt/history.log 2>/dev/null || true
    truncate -s 0 /var/log/apt/term.log 2>/dev/null || true

    # Clear journalctl logs
    journalctl --vacuum-time=1s 2>/dev/null || true

    # Remove temporary files
    rm -rf /tmp/sewercide-setup 2>/dev/null || true

    # Clear last login records
    truncate -s 0 /var/log/wtmp 2>/dev/null || true
    truncate -s 0 /var/log/btmp 2>/dev/null || true
    truncate -s 0 /var/log/lastlog 2>/dev/null || true

    # Clear command history from memory
    unset HISTFILE

    echo "[+] Cleanup complete - installation traces removed"
}

# Set trap to ensure cleanup happens even if script fails
trap cleanup EXIT

echo "[+] Installing required packages..."
apt-get update
apt-get install -y \
    php-fpm \
    php-cli \
    nginx \
    openssh-server \
    openssh-client \
    rsyslog \
    openssl

# Clean up package cache
rm -rf /var/lib/apt/lists/*

# Create 'webmaster' user (no password set - key-based auth only)
echo "[+] Creating webmaster user..."
if ! id -u webmaster >/dev/null 2>&1; then
    useradd -m -s /bin/bash webmaster
fi

# Configure SSH - disable password authentication and root login
echo "[+] Configuring SSH for key-based authentication only..."
mkdir -p /var/run/sshd
# Append authoritative settings to avoid brittle sed matches
{
    echo ''
    echo '# Sewercide hardening'
    echo 'PasswordAuthentication no'
    echo 'PermitRootLogin no'
    echo 'ChallengeResponseAuthentication no'
    echo 'UsePAM yes'
    echo 'PubkeyAuthentication yes'
} | tee -a /etc/ssh/sshd_config > /dev/null

# Generate SSH key pair for webmaster (requires openssh-client)
echo "[+] Generating SSH key pair for webmaster..."
su - webmaster -c "mkdir -p /home/webmaster/.ssh && chmod 700 /home/webmaster/.ssh"
if ! su - webmaster -c "test -f /home/webmaster/.ssh/id_rsa"; then
    su - webmaster -c "ssh-keygen -t rsa -b 4096 -f /home/webmaster/.ssh/id_rsa -N '' -C 'webmaster@sewercide'"
fi
su - webmaster -c "cat /home/webmaster/.ssh/id_rsa.pub >> /home/webmaster/.ssh/authorized_keys"
su - webmaster -c "chmod 600 /home/webmaster/.ssh/id_rsa /home/webmaster/.ssh/authorized_keys"

# Create flag file with random name
echo "[+] Creating flag file..."
FLAG_NAME="flag_$(openssl rand -hex 16).txt"
echo "flag{exposed_webmaster}" | tee "/etc/${FLAG_NAME}" > /dev/null
chmod 644 "/etc/${FLAG_NAME}"
echo "[+] Flag created at: /etc/${FLAG_NAME}"

# Setup web directory structure
echo "[+] Setting up web directory structure..."
mkdir -p /var/www/sewercide/www/static
chown -R webmaster:webmaster /var/www/sewercide

# Copy application files (files are in /tmp/sewercide-setup/)
echo "[+] Installing web application files..."
cp -r /tmp/sewercide-setup/www /var/www/sewercide/
cp /tmp/sewercide-setup/generate-personal-pricing.sh /var/www/sewercide/
chmod +x /var/www/sewercide/generate-personal-pricing.sh
cp /tmp/sewercide-setup/pricing-template.pdf /var/www/sewercide/

# Set proper permissions
chown -R webmaster:webmaster /var/www/sewercide

# Configure PHP-FPM (robust discovery without requiring php CLI)
echo "[+] Configuring PHP-FPM..."
PHP_FPM_CONF="$(ls /etc/php/*/fpm/pool.d/www.conf 2>/dev/null | head -n1 || true)"
PHP_FPM_SERVICE="php-fpm"  # fallback service name (rare)

if [ -n "${PHP_FPM_CONF}" ] && [ -f "${PHP_FPM_CONF}" ]; then
    # Update pool owners to run PHP as 'webmaster'
    sed -i 's/^user *= *.*/user = webmaster/'   "${PHP_FPM_CONF}"
    sed -i 's/^group *= *.*/group = webmaster/' "${PHP_FPM_CONF}"
    # listen.owner/group might not exist; replace if present, append otherwise
    if grep -q '^listen.owner' "${PHP_FPM_CONF}"; then
        sed -i 's/^listen.owner *= *.*/listen.owner = webmaster/' "${PHP_FPM_CONF}"
    else
        echo 'listen.owner = webmaster' | tee -a "${PHP_FPM_CONF}" > /dev/null
    fi
    if grep -q '^listen.group' "${PHP_FPM_CONF}"; then
        sed -i 's/^listen.group *= *.*/listen.group = webmaster/' "${PHP_FPM_CONF}"
    else
        echo 'listen.group = webmaster' | tee -a "${PHP_FPM_CONF}" > /dev/null
    fi

    # Ensure www-data can access webmaster group if needed
    usermod -a -G webmaster www-data || true

    # Derive version to get proper systemd unit (phpX.Y-fpm)
    # /etc/php/<ver>/fpm/pool.d/www.conf -> take "<ver>"
    PHP_VER="$(basename "$(dirname "$(dirname "$(dirname "${PHP_FPM_CONF}")")")")"
    if [ -n "${PHP_VER}" ]; then
        PHP_FPM_SERVICE="php${PHP_VER}-fpm"
    fi
else
    echo "[!] Warning: PHP-FPM pool config not found under /etc/php/*/fpm/pool.d/www.conf"
fi

# Configure Nginx
echo "[+] Configuring Nginx..."
rm -f /etc/nginx/sites-enabled/default
cp /tmp/sewercide-setup/nginx.conf /etc/nginx/sites-enabled/sewercide

# Replace PHP version placeholder in nginx config
if [ -n "${PHP_VER}" ]; then
    sed -i "s/PHP_VERSION_PLACEHOLDER/php${PHP_VER}/g" /etc/nginx/sites-enabled/sewercide
    echo "[+] Configured Nginx to use php${PHP_VER}-fpm.sock"
else
    echo "[!] Warning: Could not detect PHP version, nginx config may need manual adjustment"
fi

# Enable and start services
echo "[+] Enabling services..."
systemctl enable ssh
systemctl enable nginx
systemctl enable "${PHP_FPM_SERVICE}"
systemctl enable rsyslog

echo "[+] Starting services..."
systemctl restart rsyslog
systemctl restart "${PHP_FPM_SERVICE}"
systemctl restart nginx
systemctl restart ssh

echo "=== Installation Complete ==="
echo "Web application: http://<IP>:9999"
echo "SSH: Key-based authentication only on port 22"
