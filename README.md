# Sewercide CTF Challenge - Reference Deputy Package

## Purpose

This Deputy package serves as a **reference example** for creating Open Cyber Range (OCR) exercises targeting Linux/web environments. It demonstrates a multi-VM CTF deployment with network isolation, feature packages, and banner integration.

## Package Structure

This is a complete OCR exercise implementation consisting of:

- **Deputy Feature Package** (`package.toml`) - Installs vulnerable web application
- **SDL Deployment File** (`sewercide-ctf.sdl`) - Defines infrastructure and network topology
- **Provisioning Scripts** (`src/install.sh`) - Automated VM configuration
- **Web Application** (`src/www/`) - Vulnerable PHP application with intentional security flaws
- **Banner Package** (separate: `sewercide-banner`) - Challenge briefing displayed to participants

## Exercise Overview

**Sewercide Plumbing CTF** is a web exploitation challenge featuring an argument injection vulnerability in a development web application.

### Scenario

Participants are tasked with infiltrating Sewercide Plumbing Co.'s development web infrastructure to retrieve a hidden flag file. The company is running a development version of their website with exposed sensitive information due to misconfigurations.

### Architecture

**Multi-VM Network:**

- **Kali Linux 2025.2** (10.1.1.10) - Attacker machine with full pentesting suite
- **Ubuntu 24.04 Server** (10.1.1.20) - Target server running vulnerable web application
- **Virtual Network Switch** - Isolated network segment (10.1.1.0/24)

**Challenge Flow:**

1. Participant accesses Kali VM through OCR platform (credentials: kali/kali)
2. Performs network reconnaissance to discover target server on 10.1.1.0/24
3. Identifies web application running on non-standard port 8080
4. Exploits argument injection vulnerability in pricing form
5. Exfiltrates SSH private key for webmaster account
6. SSH into target server using stolen key
7. Reads flag from `/etc/flag_<random>.txt`

## Using as Reference

### For Linux/Web OCR Exercises

This package demonstrates:

1. **Multi-VM topology** with attacker and target machines
2. **Static IP configuration** using Deputy packages
3. **Feature package structure** for software installation
4. **Provisioning script patterns** (user creation, service config, cleanup)
5. **Banner integration** for participant briefing
6. **SDL file structure** with comprehensive comments

### Adapting for Your Exercise

1. Copy this package structure as template
2. Modify `package.toml` name, description, version
3. Update SDL file with your VM specifications and network topology
4. Replace vulnerable application in `src/` with your challenge
5. Update `install.sh` provisioning script for your requirements
6. Create separate banner package for challenge briefing
7. Publish using `deputy publish`

## Deployment

### Prerequisites

- Open Cyber Range platform access
- Deputy CLI installed
- Base images available: `kali_2025_2`, `ubuntu2404-base-web`

### Publishing Package

```bash
# 1. Update version in package.toml and sewercide-ctf.sdl
# 2. Publish to Deputy registry
deputy publish
```

## License

MIT License - Free to use as reference for your own OCR exercises.

## Author

Andris <andris@postalsys.com>
