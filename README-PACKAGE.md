# Sewercide CTF - Deputy Package

This directory contains the complete Deputy package for deploying the Sewercide CTF challenge on Open Cyber Range.

## Package Overview

**Name**: sewercide-ctf
**Version**: 0.1.0
**Type**: Multi-VM network-based CTF challenge
**Difficulty**: Intermediate
**Category**: Web Exploitation, Argument Injection, Network Reconnaissance

## Architecture

This challenge deploys **two virtual machines** connected via a network switch:

1. **Kali Linux 2025.2 (Attacker Machine)**
   - Participant entry point
   - Credentials: kali / kali
   - Base image from Deputy library
   - Tools: nmap, burpsuite, curl, ssh, etc.

2. **Sewercide CTF Server (Target)**
   - Custom Ubuntu-based web server
   - Vulnerable web application on port 9999
   - SSH server on port 22 (key-based only)
   - Contains the flag in `/etc/flag_<random>.txt`

3. **Network Configuration**
   - Subnet: 10.1.1.8/30 (point-to-point network)
   - Kali Linux: 10.1.1.10/30
   - Target Server: 10.1.1.9/30
   - Virtual switch connecting both VMs
   - Isolated network - target not directly accessible from outside

## Package Structure

```
deputy-package/
├── package.toml              # Deputy package metadata and configuration
├── sewercide-ctf.sdl         # SDL deployment configuration for OCR
├── README.md                 # Participant-facing challenge documentation
├── DEPLOYMENT.md             # Administrator deployment notes
├── PUBLISHING.md             # Publishing guide for Deputy
├── README-PACKAGE.md         # This file
├── test-install.sh           # Docker-based local testing script
└── src/                      # Package source files
    ├── install.sh            # Automated installation script for VM
    ├── nginx.conf            # Nginx web server configuration
    ├── pricing-template.pdf  # PDF template used by the application
    ├── generate-personal-pricing.sh  # Vulnerable shell script
    └── www/                  # Web application files
        ├── index.php         # Main application with vulnerability
        └── static/           # Directory for generated files
```

## Quick Start

### For Local Development/Testing
```bash
# Test the installation script in Docker
./test-install.sh

# Or test with your existing Docker setup
cd ..
docker-compose up --build
```

### For Publishing to Open Cyber Range

1. **Prepare the OVA** (if not using base image):
   - Follow instructions in `PUBLISHING.md`

2. **Login to Deputy**:
   ```bash
   deputy login
   ```

3. **Publish the package**:
   ```bash
   deputy publish
   ```

4. **Deploy using SDL**:
   - Upload `sewercide-ctf.sdl` to OCR platform
   - Configure and start the exercise

## Challenge Details

### Participant Experience
1. **Access**: SSH into Kali Linux machine (kali / kali)
2. **Reconnaissance**: Discover the target server on the network
3. **Enumeration**: Scan for open ports and services
4. **Discovery**: Find web application on non-standard port 9999
5. **Exploitation**: Exploit argument injection vulnerability
6. **Lateral Movement**: Use exfiltrated SSH key to access target
7. **Flag Capture**: Retrieve flag from `/etc/flag_<random>.txt`

### Objective
Participants must:
1. Perform network reconnaissance from Kali Linux
2. Discover the web server running on port 9999
3. Identify and exploit an argument injection vulnerability
4. Exfiltrate the webmaster's SSH private key
5. Use the key to SSH into the server
6. Retrieve the flag from `/etc/flag_<random>.txt`

### Vulnerability
The application has an **argument injection** vulnerability:
- User input is validated against a whitelist
- Command injection is prevented (no `;`, `|`, `&`, etc.)
- However, the email field is passed **unquoted** to a shell script
- This allows argument splitting via spaces
- Attackers can manipulate positional arguments to exfiltrate files

### Services

**Kali Linux VM:**
- **SSH**: Port 22 (kali / kali)
- **Full pentesting toolkit**: nmap, burpsuite, metasploit, etc.

**Target Server VM:**
- **Web Application**: Port 9999 (nginx + PHP-FPM)
- **SSH Server**: Port 22 (key-based authentication only)

### User Accounts

**Kali Linux:**
- **kali**: Password: kali, sudo access

**Target Server:**
- **webmaster**: No password, SSH key at `/home/webmaster/.ssh/id_rsa`

### Flag Location
- Random filename: `/etc/flag_<random_hex>.txt`
- Flag format: `flag{exposed_webmaster}`

## Technical Architecture

### Installation Process
The `install.sh` script automates:
1. Package installation (PHP, nginx, SSH, rsyslog, openssl)
2. User creation (webmaster with no password)
3. SSH configuration (key-based only)
4. SSH key generation for webmaster
5. Random flag file creation
6. Web application deployment
7. PHP-FPM configuration (running as webmaster)
8. Nginx configuration (port 9999)
9. Service enablement and startup

### Security Configuration
- SSH password authentication: **DISABLED**
- Root login: **DISABLED**
- Webmaster account: **No password**
- SSH access: **Key-based only**
- PHP-FPM: **Runs as webmaster user**

## Documentation Files

| File | Audience | Purpose |
|------|----------|---------|
| `README.md` | Participants | Challenge description and access info |
| `DEPLOYMENT.md` | Administrators | Deployment checklist and testing |
| `PUBLISHING.md` | Publishers | Complete publishing workflow |
| `README-PACKAGE.md` | All | Package overview (this file) |

## Testing Checklist

Before publishing:
- [ ] Installation script runs without errors
- [ ] Web application accessible on port 9999
- [ ] SSH server running with key-auth only
- [ ] Webmaster SSH keys generated correctly
- [ ] Flag file created with random name
- [ ] Vulnerability is exploitable
- [ ] Flag is accessible after successful exploitation

## SDL Configuration

The `sewercide-ctf.sdl` file defines:
- **Infrastructure**:
  - Kali Linux VM (2 CPU, 4 GiB RAM) - participant access
  - Target server VM (2 CPU, 2 GiB RAM) - challenge target
  - Network switch connecting both VMs
- **Entities**:
  - Participant (RED team) - mapped to Kali VM
  - Target (BLUE team) - mapped to target server
- **Story**: 4-hour challenge timeline
- **Events**: Challenge start + 2 timed hints (at 1h and 2h)
- **Goals**: Flag retrieval (100 points)
- **Metrics**: Attempts, vulnerability discovery, flag retrieval

## Version History

### v0.1.0 (Initial Release)
- Complete CTF challenge implementation
- Argument injection vulnerability
- SSH key exfiltration attack path
- Deputy package structure
- SDL deployment configuration

## Support & Contributions

For issues or improvements:
1. Review the troubleshooting section in `PUBLISHING.md`
2. Check Open Cyber Range documentation
3. Test locally using `test-install.sh`

## License

MIT License - See parent project for details

## Credits

Created for CTF competition training on the Open Cyber Range platform.
