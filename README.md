# Sewercide CTF Challenge - Reference Deputy Package

**GitHub Repository:** https://github.com/andris9/sewercide-ctf

## Related Packages

- **Banner Package:** https://github.com/andris9/sewercide-banner - Challenge briefing HTML content
- **Static IP Setter:** https://github.com/andris9/static-ip-setter - Network configuration utility used by this exercise

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

- **Kali Linux 2025.2** (10.1.1.10) - Standard Kali Linux image with full pentesting suite
  - Base image: `kali_2025_2`
  - Default credentials: `kali` / `kali`
  - No additional configuration applied (standard Kali installation)

- **Ubuntu 24.04 Server** (10.1.1.20) - Target server running vulnerable web application
  - Base image: `ubuntu2404-base-web`
  - Pre-installed: SSH, nginx, PHP 8.3, MySQL
  - Services disabled by default: SSH, nginx, MySQL, PHP-FPM
  - Services enabled by exercise install script as needed

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

### Deploying in Ranger

#### Creating the Exercise

1. **Create New Exercise** - In Ranger, create a new exercise
2. **Configure Dashboard**:
   - Exercise name: Enter exercise name (e.g., "Sewercide Web")
   - Deployment group: Specify deployment group
   - AD Group: Specify Active Directory group
3. **Import SDL** - Copy the contents of `sewercide-ctf.sdl` and paste into the Scenario SDL text area
4. **Submit Dashboard Changes** - Click "Submit" button to save exercise configuration
5. **Configure Banner** - Navigate to the Banner screen and select banner from Deputy:
   - Click "Get banner from Deputy package"
   - Package name: `sewercide-banner`
   - Package version: Select latest version
   - Click "Add" to attach banner to exercise
   - Scroll down and click "Update" to apply banner changes

#### Creating a Deployment

1. **Create New Deployment** - Click "Create a new deployment" button
2. **Configure Deployment Parameters**:
   - Deployment group: Specify deployment group name
   - Deployment name: Enter descriptive name for this instance
   - Start time: Set deployment start time
   - End time: Set deployment end time
   - Number of deployments: Typically `1`
   - AD Group: Specify Active Directory group
3. **Add Deployment** - Click "Add" to create the deployment instance

#### Assigning Participants

1. **Open Deployment** - Navigate to the created deployment from the Deployments list
2. **Open Entity Selector** - Access the deployment's Entity Connector screen
3. **Connect Participant** - Assign the single participant for this deployment:
   - Entity: `red-team.participant` (use dot notation for nested entities)
   - Username: Enter participant's username
   - Click "Connect" to assign participant to entity

## License

MIT License - Free to use as reference for your own OCR exercises.

## Author

Andris <andris@postalsys.com>
