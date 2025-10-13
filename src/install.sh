#!/bin/bash
set -e

echo "=== Sewercide CTF Challenge Installation ==="

# Prevent interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Install required packages
echo "[+] Installing required packages..."
apt-get update
apt-get install -y \
    php-fpm \
    nginx \
    openssh-server \
    rsyslog \
    openssl

# Clean up package cache
rm -rf /var/lib/apt/lists/*

# Create webmaster user (no password set - key-based auth only)
echo "[+] Creating webmaster user..."
if ! id -u webmaster > /dev/null 2>&1; then
    useradd -m -s /bin/bash webmaster
fi

# Configure SSH - disable password authentication
echo "[+] Configuring SSH for key-based authentication only..."
mkdir -p /var/run/sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Generate SSH key pair for webmaster
echo "[+] Generating SSH key pair for webmaster..."
su - webmaster -c "mkdir -p /home/webmaster/.ssh && chmod 700 /home/webmaster/.ssh"
su - webmaster -c "ssh-keygen -t rsa -b 4096 -f /home/webmaster/.ssh/id_rsa -N '' -C 'webmaster@sewercide'"
su - webmaster -c "cat /home/webmaster/.ssh/id_rsa.pub >> /home/webmaster/.ssh/authorized_keys"
su - webmaster -c "chmod 600 /home/webmaster/.ssh/id_rsa /home/webmaster/.ssh/authorized_keys"

# Create flag file with random name
echo "[+] Creating flag file..."
FLAG_NAME="flag_$(openssl rand -hex 16).txt"
echo "flag{exposed_webmaster}" > "/etc/$FLAG_NAME"
chmod 644 "/etc/$FLAG_NAME"
echo "[+] Flag created at: /etc/$FLAG_NAME"

# Setup web directory structure
echo "[+] Setting up web directory structure..."
mkdir -p /var/www/sewercide/www/static
chown -R webmaster:webmaster /var/www/sewercide

# Copy application files (assumes files are in /tmp/sewercide-setup/)
echo "[+] Installing web application files..."
if [ -d "/tmp/sewercide-setup/www" ]; then
    cp -r /tmp/sewercide-setup/www/* /var/www/sewercide/www/
fi
if [ -f "/tmp/sewercide-setup/generate-personal-pricing.sh" ]; then
    cp /tmp/sewercide-setup/generate-personal-pricing.sh /var/www/sewercide/
    chmod +x /var/www/sewercide/generate-personal-pricing.sh
fi
if [ -f "/tmp/sewercide-setup/pricing-template.pdf" ]; then
    cp /tmp/sewercide-setup/pricing-template.pdf /var/www/sewercide/
fi

# Set proper permissions
chown -R webmaster:webmaster /var/www/sewercide

# Detect PHP-FPM version
echo "[+] Configuring PHP-FPM..."
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

if [ -f "$PHP_FPM_CONF" ]; then
    sed -i 's/^user = www-data/user = webmaster/' "$PHP_FPM_CONF"
    sed -i 's/^group = www-data/group = webmaster/' "$PHP_FPM_CONF"
    sed -i 's/^listen.owner = www-data/listen.owner = webmaster/' "$PHP_FPM_CONF"
    sed -i 's/^listen.group = www-data/listen.group = webmaster/' "$PHP_FPM_CONF"
    usermod -a -G webmaster www-data
else
    echo "[!] Warning: PHP-FPM config not found at $PHP_FPM_CONF"
fi

# Configure Nginx
echo "[+] Configuring Nginx..."
rm -f /etc/nginx/sites-enabled/default
if [ -f "/tmp/sewercide-setup/nginx.conf" ]; then
    cp /tmp/sewercide-setup/nginx.conf /etc/nginx/sites-enabled/sewercide
fi

# Enable and start services
echo "[+] Enabling services..."
systemctl enable ssh
systemctl enable nginx
systemctl enable php${PHP_VERSION}-fpm
systemctl enable rsyslog

echo "[+] Starting services..."
systemctl start rsyslog
systemctl start php${PHP_VERSION}-fpm
systemctl start nginx
systemctl start ssh

echo "=== Installation Complete ==="
echo "Web application: http://<IP>:9999"
echo "SSH: Key-based authentication only on port 22"
