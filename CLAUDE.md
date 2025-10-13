# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Rules

- **Git repository**: This deputy-package folder is a standalone git repository (parent folder is not tracked)
- **Git commits**: Do not include Claude as co-contributor in commit messages
- **No emojis**: Never use emojis in code, comments, or documentation

## Repository Overview

This is a **Deputy package** for deploying the "Sewercide CTF Challenge" on Open Cyber Range. It's a multi-VM CTF challenge featuring an **argument injection vulnerability** in a web application.

## Architecture

### Multi-VM Network Setup
- **Kali Linux 2025.2** (10.1.1.10/30): Attacker machine, participant entry point
- **Target Server** (10.1.1.9/30): Ubuntu-based vulnerable web server
- **Network**: Isolated /30 subnet with virtual switch

### Challenge Flow
1. Participant SSH into Kali (kali/kali)
2. Discover target via nmap scan
3. Find web app on port 9999
4. Exploit argument injection to exfiltrate SSH key
5. SSH to target using exfiltrated key
6. Read flag from `/etc/flag_<random>.txt`

## Key Files

### Deputy Configuration
- **`package.toml`**: Deputy package metadata (name, version, VM settings)
- **`sewercide-ctf.sdl`**: SDL deployment file defining infrastructure, network, entities, story timeline, events, and scoring

### Infrastructure
- **`src/install.sh`**: VM provisioning script - installs services, creates users, configures SSH (key-only), generates SSH keys, creates random flag file
- **`src/nginx.conf`**: Nginx config for port 9999
- **`src/www/index.php`**: Main web application (single-file PHP router)
- **`src/generate-personal-pricing.sh`**: Shell script with **intentional vulnerability** - accepts unquoted positional arguments

### Vulnerability Details
Located in `src/www/index.php` `handlePricingSubmission()` function:
- Email field filtered for shell metacharacters (`;`, `|`, `&`, etc.)
- Whitelist validation allows spaces and forward slashes
- **Critical flaw**: Email passed to shell script WITHOUT `escapeshellarg()`
- Line 657: `$email_escaped` is NOT shell-escaped, only filtered
- Line 653-659: Command built with sprintf, email inserted directly
- This enables **argument injection** via spaces in email field

The shell script (`generate-personal-pricing.sh`) uses positional arguments `$1`, `$2`, `$3` which can be manipulated when spaces split the email into multiple arguments.

## Network Configuration

### SDL Infrastructure Block
```yaml
infrastructure:
  network-switch: 1
  attacker-kali:
    count: 1
    links: [network-switch]
  sewercide-server:
    count: 1
    links: [network-switch]
```

### Static IP Assignment
Uses `debian-ip-setter` feature from Deputy library:
- Kali: `STATIC_IP=10.1.1.10/30`
- Target: `STATIC_IP=10.1.1.9/30`

## Testing Commands

### Local Docker Testing
```bash
./test-install.sh  # Tests installation script in Docker container
```

### Deputy Publishing
```bash
deputy login       # Authenticate with API token
deputy validate    # Validate package structure
deputy publish     # Upload to Deputy library
```

## SDL Structure

The SDL file follows Open Cyber Range format:
- **infrastructure**: Defines switch, VMs, and network links
- **nodes**: VM specifications (source, resources, roles, features)
- **features**: Static IP configuration via debian-ip-setter
- **entities**: Participant (RED) and Target (BLUE) roles
- **stories/scripts/events**: 4-hour timeline with timed hints at 1h and 2h
- **goals/conditions/metrics**: Scoring and tracking

## Documentation Structure

- **README.md**: Participant-facing (no solutions, emphasizes reconnaissance)
- **DEPLOYMENT.md**: Admin guide with architecture, credentials, testing checklist
- **PUBLISHING.md**: Complete workflow for creating OVA and publishing
- **NETWORK.md**: Detailed network topology and IP configuration
- **README-PACKAGE.md**: Package overview for all audiences

## Security Notes

This is a **CTF challenge** with intentional vulnerabilities:
- Argument injection in pricing form handler
- SSH keys intentionally exfiltrable
- Flag file world-readable at `/etc/flag_<random>.txt`
- Webmaster account has no password (key-only)

When modifying, maintain the vulnerability for educational purposes but ensure it's isolated to the challenge environment.

## Deployment Target

This package deploys to **Open Cyber Range** using the Deputy package manager. Not designed for Docker Compose (parent directory has separate Docker setup for local dev/testing).
