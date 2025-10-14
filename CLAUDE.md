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

- **Kali Linux 2025.2**: Attacker machine, participant accesses via OCR platform
- **Target Server**: Ubuntu-based vulnerable web server
- **Network**: Connected via virtual switch, IPs assigned via DHCP

### Challenge Flow

1. Participant accesses Kali VM through OCR platform (kali/kali)
2. Discover target IP via nmap scan
3. Find web app on port 9999
4. Exploit argument injection to exfiltrate SSH key
5. SSH to target using exfiltrated key as webmaster
6. Read flag from `/etc/flag_<random>.txt`

## Key Files

### Deputy Configuration

- **`package.toml`**: Deputy package metadata with assets configuration
- **`sewercide-ctf.sdl`**: SDL deployment file defining infrastructure, network, nodes, entities
- **`release.sh`**: Automated script for version bumping, git tagging, and Deputy publishing

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

### IP Assignment

Both VMs get IP addresses via DHCP from the network switch. Participants must discover the target IP through network scanning.

## Publishing Commands

### Release New Version

```bash
./release.sh 0.2.0  # Bumps version, commits, tags, pushes to git and Deputy
```

### Manual Publishing (if needed)

```bash
docker run --rm -v "$HOME/.deputy:/root/.deputy" -v "$(pwd):/workspace" -w /workspace deputy-ubuntu:24.04 deputy publish
```

## SDL Structure

The SDL file follows Open Cyber Range format (MVP version):

- **infrastructure**: Defines switch, VMs, and network links
- **nodes**: VM specifications (source, resources, roles, features) - switch must be defined here too
- **features**: Maps to sewercide-ctf Deputy package (assigned to roles)
- **entities**: Participant (Red) and Target (Blue) roles - note capitalization

Key syntax notes:

- Features use map format: `feature-name: role-name`
- Roles don't include passwords (handled by base images)
- Role names like Red/Blue are capitalized as proper nouns

## Documentation Structure

- **README.md**: Participant-facing challenge description (no solutions)
- **CLAUDE.md**: This file - guidance for Claude Code AI assistant

## Security Notes

This is a **CTF challenge** with intentional vulnerabilities:

- Argument injection in pricing form handler
- SSH keys intentionally exfiltrable
- Flag file world-readable at `/etc/flag_<random>.txt`
- Webmaster account has no password (key-only)

When modifying, maintain the vulnerability for educational purposes but ensure it's isolated to the challenge environment.

## Deployment Target

This package deploys to **Open Cyber Range** using the Deputy package manager. Not designed for Docker Compose (parent directory has separate Docker setup for local dev/testing).
