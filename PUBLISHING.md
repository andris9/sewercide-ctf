# Publishing Sewercide CTF to Open Cyber Range

This guide explains how to publish the Sewercide CTF challenge as a Deputy package and deploy it on Open Cyber Range.

## Prerequisites

1. **Deputy CLI installed**
   - Follow installation instructions at: https://documentation.opencyberrange.ee/docs/getting-started/install-deputy

2. **Deputy Account & Token**
   - Create account on Open Cyber Range platform
   - Generate API token from your account settings

3. **VM Preparation**
   - You need to create an OVA file from Ubuntu 24.04 base image
   - Or use the base Ubuntu 24.04 image available in the Deputy library

## Option 1: Build on Base Image (Recommended)

If there's a base Ubuntu 24.04 image available in Deputy:

1. Update `package.toml` to reference the base image
2. Create a post-deployment script that runs `install.sh`
3. Publish the package with just the application files

## Option 2: Create Custom OVA

If you need to create a complete OVA:

### Step 1: Prepare the VM

1. Start with Ubuntu 24.04 Server
2. Copy installation files:
   ```bash
   sudo mkdir -p /tmp/sewercide-setup
   sudo cp -r src/* /tmp/sewercide-setup/
   ```

3. Run the installation script:
   ```bash
   sudo bash /tmp/sewercide-setup/install.sh
   ```

4. Verify services are running:
   ```bash
   systemctl status nginx
   systemctl status ssh
   systemctl status php8.3-fpm
   ```

5. Test the web application:
   ```bash
   curl http://localhost:9999
   ```

6. Clean up:
   ```bash
   sudo rm -rf /tmp/sewercide-setup
   sudo apt-get clean
   sudo history -c
   ```

### Step 2: Export as OVA

Using VMware/VirtualBox:
- Shutdown the VM cleanly
- Export as OVA format
- Place the OVA file at: `src/sewercide-ctf.ova`

Or using OVFTool:
```bash
ovftool --name=sewercide-ctf \
  /path/to/vm.vmx \
  src/sewercide-ctf.ova
```

### Step 3: Update package.toml

Verify the OVA path in `package.toml`:
```toml
[virtual-machine]
file_path = "src/sewercide-ctf.ova"
```

## Publishing the Package

1. **Login to Deputy**
   ```bash
   deputy login
   ```
   Enter your API token when prompted.

2. **Validate the package**
   ```bash
   deputy validate
   ```

3. **Publish the package**
   ```bash
   deputy publish
   ```

## Deploying the Exercise

1. **Upload the SDL file**
   - Go to Open Cyber Range web interface
   - Navigate to Deployments
   - Upload `sewercide-ctf.sdl`

2. **Configure deployment**
   - Set exercise duration (default: 4 hours)
   - Configure participant access
   - Set resource allocation

3. **Start the exercise**
   - Deploy the infrastructure
   - Provide access information to participants
   - Monitor through the dashboard

## Exercise Information for Participants

Once deployed, participants will receive:
- Access to a VM with the web application on port 9999
- SSH access on port 22 (requires key extraction)
- Challenge objectives and optional hints

## Updating the Package

To publish updates:

1. Modify the files in `src/`
2. Update version in `package.toml`:
   ```toml
   version = "0.2.0"
   ```
3. Run `deputy publish` again

## Troubleshooting

### Package Validation Fails
- Check `package.toml` syntax
- Verify OVA file exists and is readable
- Ensure all referenced files are in `src/`

### Services Don't Start in VM
- Check systemd logs: `journalctl -xe`
- Verify PHP version compatibility
- Check nginx configuration syntax

### Web Application Not Accessible
- Verify nginx is running: `systemctl status nginx`
- Check nginx logs: `/var/log/nginx/error.log`
- Verify port 9999 is open

### SSH Key Authentication Issues
- Verify SSH keys were generated: `ls /home/webmaster/.ssh/`
- Check SSH configuration: `sshd -T | grep -i password`
- Review SSH logs: `journalctl -u ssh`

## Support

For issues with:
- **Deputy/Open Cyber Range**: Check documentation at https://documentation.opencyberrange.ee
- **Challenge functionality**: Review the DEPLOYMENT.md file
- **SDL syntax**: See SDL reference guide

## Package Contents Summary

```
deputy-package/
├── package.toml              # Package metadata
├── README.md                 # Participant documentation
├── DEPLOYMENT.md            # Admin deployment notes
├── PUBLISHING.md            # This file
├── sewercide-ctf.sdl        # SDL deployment configuration
├── test-install.sh          # Local testing script
└── src/
    ├── install.sh           # VM installation script
    ├── www/                 # Web application
    ├── generate-personal-pricing.sh
    ├── pricing-template.pdf
    └── nginx.conf
```
