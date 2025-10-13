# Sewercide CTF - Deployment Instructions

This document provides instructions for deploying the Sewercide CTF challenge in Open Cyber Range.

## Challenge Architecture

This challenge consists of **two VMs** connected via a virtual switch:

1. **Attacker Machine (Kali Linux 2025.2)**
   - IP Address: `10.1.1.10/30`
   - Participant's entry point
   - Credentials: kali / kali
   - SSH enabled for participant access
   - Full penetration testing toolkit

2. **Target Server (Sewercide CTF)**
   - IP Address: `10.1.1.9/30`
   - Ubuntu-based web server
   - Web application on port 9999
   - SSH server on port 22 (key-based only)
   - Contains the flag

3. **Network Configuration**
   - Subnet: `10.1.1.8/30` (4 addresses: .8 - .11)
   - Usable IPs: .9 and .10
   - Network switch connects both VMs
   - Isolated private network

## Package Structure

```
sewercide-ctf/
├── package.toml              # Deputy package metadata
├── README.md                 # Participant-facing documentation
├── DEPLOYMENT.md            # This file
└── src/
    ├── install.sh           # Installation script (run on VM provisioning)
    ├── www/                 # Web application files
    ├── generate-personal-pricing.sh
    ├── pricing-template.pdf
    └── nginx.conf
```

## Installation Process

When the VM is provisioned, the `install.sh` script should be executed. This script:

1. Installs required packages (PHP, Nginx, SSH, rsyslog)
2. Creates the `webmaster` user (no password)
3. Configures SSH for key-based authentication only
4. Generates SSH key pair for webmaster
5. Creates random flag file at `/etc/flag_<random>.txt`
6. Sets up web application in `/var/www/sewercide/`
7. Configures PHP-FPM to run as webmaster
8. Configures Nginx on port 9999
9. Starts all services

## Manual VM Preparation (If needed)

If you're creating the OVA file manually:

1. Start with Ubuntu 24.04 Server base image
2. Copy all files from `src/` to `/tmp/sewercide-setup/`
3. Run the installation script:
   ```bash
   sudo cp -r src/* /tmp/sewercide-setup/
   sudo bash /tmp/sewercide-setup/install.sh
   ```
4. Clean up:
   ```bash
   sudo rm -rf /tmp/sewercide-setup
   ```
5. Export as OVA and place in `src/sewercide-ctf.ova`

## Services

- **Web Application**: Port 9999 (nginx)
- **SSH Server**: Port 22 (key-based authentication only)

## Challenge Details

**Goal**: Retrieve the flag from `/etc/flag_<random>.txt`

**Vulnerability**: Argument injection in the pricing form

**Attack Path**:
1. From Kali (10.1.1.10), scan target network to discover 10.1.1.9
2. Identify web service on port 9999
3. Exploit argument injection to exfiltrate webmaster's SSH private key
4. SSH from Kali to target (10.1.1.9) using exfiltrated key
5. Read flag file from `/etc/flag_*.txt`

## Network Requirements

The deployment creates an isolated /30 network (10.1.1.8/30):
- **Network**: 10.1.1.8/30
- **Target Server**: 10.1.1.9/30
- **Kali Attacker**: 10.1.1.10/30
- **Virtual Switch**: Connects both VMs

Network characteristics:
- Only 2 usable IP addresses (.9 and .10)
- Kali VM accessible from outside via SSH
- Target VM only accessible from Kali
- Participants connect via SSH to Kali and conduct attacks from there

## Credentials

### Kali Linux (Attacker)
- **Username**: kali
- **Password**: kali
- SSH access enabled for participant connection

### Sewercide Server (Target)
- **webmaster**: No password, SSH key-based authentication only
- SSH private key is located at `/home/webmaster/.ssh/id_rsa` (target for exploitation)

## Testing Checklist

### Kali VM
- [ ] SSH accessible with kali/kali credentials
- [ ] Network connectivity to target VM
- [ ] Standard tools available (nmap, curl, etc.)

### Target VM (Sewercide Server)
- [ ] Web application accessible on port 9999 from Kali
- [ ] SSH server running on port 22
- [ ] SSH password authentication disabled
- [ ] Webmaster SSH keys generated
- [ ] Flag file created with random name
- [ ] Vulnerability is exploitable from Kali
- [ ] Flag is accessible after exploitation

### Network
- [ ] Both VMs can communicate via switch
- [ ] Target VM is NOT directly accessible from outside
- [ ] Only Kali VM is accessible to participants
