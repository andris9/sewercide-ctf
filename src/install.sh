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

# Note: ubuntu2404-base-web 'user' already has NOPASSWD sudo access

# Cleanup function to remove installation traces
cleanup() {

    echo "[+] Cleaning up installation traces..."

    # Clear bash history for current user
    history -c
    history -w
    > ~/.bash_history

    # Clear system logs that might contain installation commands
    sudo truncate -s 0 /var/log/auth.log 2>/dev/null || true
    sudo truncate -s 0 /var/log/syslog 2>/dev/null || true
    sudo truncate -s 0 /var/log/kern.log 2>/dev/null || true
    sudo truncate -s 0 /var/log/dpkg.log 2>/dev/null || true
    sudo truncate -s 0 /var/log/apt/history.log 2>/dev/null || true
    sudo truncate -s 0 /var/log/apt/term.log 2>/dev/null || true

    # Clear journalctl logs
    sudo journalctl --vacuum-time=1s 2>/dev/null || true

    # Remove temporary files
    sudo rm -rf /tmp/sewercide-setup 2>/dev/null || true

    # Clear last login records
    sudo truncate -s 0 /var/log/wtmp 2>/dev/null || true
    sudo truncate -s 0 /var/log/btmp 2>/dev/null || true
    sudo truncate -s 0 /var/log/lastlog 2>/dev/null || true

    # Clear command history from memory
    unset HISTFILE

    echo "[+] Cleanup complete - installation traces removed"
}

# Set trap to ensure cleanup happens even if script fails
trap cleanup EXIT

echo "[+] Verifying required packages are installed..."
# ubuntu2404-base-web includes nginx and php8.3-fpm pre-installed (but disabled)
for pkg in nginx php8.3-fpm php8.3-cli openssh-server openssh-client; do
    if dpkg -l | grep -q "^ii.*${pkg}"; then
        echo "[i] ${pkg} already installed"
    else
        echo "[!] Warning: ${pkg} not found - ubuntu2404-base-web should include nginx and php8.3-fpm"
    fi
done

# Create 'webmaster' user (no password set - key-based auth only)
echo "[+] Creating webmaster user..."
if ! id -u webmaster >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash webmaster
fi

# Configure SSH - disable password authentication and root login
echo "[+] Configuring SSH for key-based authentication only..."
sudo mkdir -p /var/run/sshd
# Append authoritative settings to avoid brittle sed matches
{
    echo ''
    echo '# Sewercide hardening'
    echo 'PasswordAuthentication no'
    echo 'PermitRootLogin no'
    echo 'ChallengeResponseAuthentication no'
    echo 'UsePAM yes'
    echo 'PubkeyAuthentication yes'
} | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Generate SSH key pair for webmaster (requires openssh-client)
echo "[+] Generating SSH key pair for webmaster..."
sudo su - webmaster -c "mkdir -p /home/webmaster/.ssh && chmod 700 /home/webmaster/.ssh"
if ! sudo su - webmaster -c "test -f /home/webmaster/.ssh/id_rsa"; then
    sudo su - webmaster -c "ssh-keygen -t rsa -b 4096 -f /home/webmaster/.ssh/id_rsa -N '' -C 'webmaster@sewercide'"
fi
sudo su - webmaster -c "cat /home/webmaster/.ssh/id_rsa.pub >> /home/webmaster/.ssh/authorized_keys"
sudo su - webmaster -c "chmod 600 /home/webmaster/.ssh/id_rsa /home/webmaster/.ssh/authorized_keys"

# Create flag file with random name
echo "[+] Creating flag file..."
FLAG_NAME="flag_$(openssl rand -hex 16).txt"
echo "flag{exposed_webmaster}" | sudo tee "/etc/${FLAG_NAME}" > /dev/null
sudo chmod 644 "/etc/${FLAG_NAME}"
echo "[+] Flag created at: /etc/${FLAG_NAME}"

# Setup web directory structure
echo "[+] Setting up web directory structure..."
sudo mkdir -p /var/www/sewercide/www/static
sudo chown -R webmaster:webmaster /var/www/sewercide

# Copy application files (files are in /tmp/sewercide-setup/)
echo "[+] Installing web application files..."
sudo cp -r /tmp/sewercide-setup/www /var/www/sewercide/
sudo cp /tmp/sewercide-setup/generate-personal-pricing.sh /var/www/sewercide/
sudo chmod +x /var/www/sewercide/generate-personal-pricing.sh
sudo cp /tmp/sewercide-setup/pricing-template.pdf /var/www/sewercide/

# Set proper permissions
sudo chown -R webmaster:webmaster /var/www/sewercide

# Configure PHP-FPM (robust discovery without requiring php CLI)
echo "[+] Configuring PHP-FPM..."
PHP_FPM_CONF="$(ls /etc/php/*/fpm/pool.d/www.conf 2>/dev/null | head -n1 || true)"
PHP_FPM_SERVICE="php-fpm"  # fallback service name (rare)

if [ -n "${PHP_FPM_CONF}" ] && [ -f "${PHP_FPM_CONF}" ]; then
    # Update pool owners to run PHP as 'webmaster'
    sudo sed -i 's/^user *= *.*/user = webmaster/'   "${PHP_FPM_CONF}"
    sudo sed -i 's/^group *= *.*/group = webmaster/' "${PHP_FPM_CONF}"
    # listen.owner/group might not exist; replace if present, append otherwise
    if grep -q '^listen.owner' "${PHP_FPM_CONF}"; then
        sudo sed -i 's/^listen.owner *= *.*/listen.owner = webmaster/' "${PHP_FPM_CONF}"
    else
        echo 'listen.owner = webmaster' | sudo tee -a "${PHP_FPM_CONF}" > /dev/null
    fi
    if grep -q '^listen.group' "${PHP_FPM_CONF}"; then
        sudo sed -i 's/^listen.group *= *.*/listen.group = webmaster/' "${PHP_FPM_CONF}"
    else
        echo 'listen.group = webmaster' | sudo tee -a "${PHP_FPM_CONF}" > /dev/null
    fi

    # Ensure www-data can access webmaster group if needed
    sudo usermod -a -G webmaster www-data || true

    # Derive version to get proper systemd unit (phpX.Y-fpm)
    # /etc/php/<ver>/fpm/pool.d/www.conf -> take "<ver>"
    PHP_VER="$(basename "$(dirname "$(dirname "$(dirname "${PHP_FPM_CONF}")")")")"
    if [ -n "${PHP_VER}" ]; then
        PHP_FPM_SERVICE="php${PHP_VER}-fpm"
    fi
else
    echo "[!] Warning: PHP-FPM pool config not found under /etc/php/*/fpm/pool.d/www.conf"
    # Try to detect PHP version from installed packages
    PHP_VER="$(dpkg -l | grep php.*-fpm | head -1 | awk '{print $2}' | grep -oP 'php\K[0-9.]+' || echo '8.3')"
    if [ -n "${PHP_VER}" ]; then
        PHP_FPM_SERVICE="php${PHP_VER}-fpm"
        echo "[i] Detected PHP version: ${PHP_VER}"
    fi
fi

# Configure Nginx
echo "[+] Configuring Nginx..."
sudo mkdir -p /etc/nginx/sites-enabled
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp /tmp/sewercide-setup/nginx.conf /etc/nginx/sites-enabled/sewercide

# Replace PHP version placeholder in nginx config
if [ -n "${PHP_VER}" ]; then
    sudo sed -i "s/PHP_VERSION_PLACEHOLDER/php${PHP_VER}/g" /etc/nginx/sites-enabled/sewercide
    echo "[+] Configured Nginx to use php${PHP_VER}-fpm.sock"
else
    echo "[!] Warning: Could not detect PHP version, nginx config may need manual adjustment"
fi

# Enable and start services
echo "[+] Enabling and starting services..."
# Use || true to continue even if service doesn't exist
sudo systemctl enable ssh 2>/dev/null || echo "[!] SSH service not available"
sudo systemctl enable nginx 2>/dev/null || echo "[!] Nginx service not available"
sudo systemctl enable "${PHP_FPM_SERVICE}" 2>/dev/null || echo "[!] PHP-FPM service not available"
sudo systemctl enable rsyslog 2>/dev/null || echo "[!] Rsyslog service not available"

sudo systemctl restart rsyslog 2>/dev/null || echo "[!] Could not restart rsyslog"
sudo systemctl restart "${PHP_FPM_SERVICE}" 2>/dev/null || echo "[!] Could not restart ${PHP_FPM_SERVICE}"
sudo systemctl restart nginx 2>/dev/null || echo "[!] Could not restart nginx"
sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || echo "[!] Could not restart SSH"

echo "=== Installation Complete ==="
echo "Web application: http://<IP>:8080"
echo "SSH: Key-based authentication only on port 22"
