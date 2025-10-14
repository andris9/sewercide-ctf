# Deputy CLI Setup

This guide explains how to set up the Deputy CLI on a new development machine using Docker.

## Prerequisites

1. **Docker installed**

   - Download from: https://docs.docker.com/get-docker/
   - Verify: `docker --version`

2. **Deputy API Token**
   - Get from your Deputy registry (default: https://deputy.ee-ng-cyber.ocr.cr14.net)
   - Navigate to your account settings
   - Generate a new API token

The setup script will automatically:
- Create `Dockerfile.deputy` if it doesn't exist
- Build the `deputy-ubuntu:24.04` Docker image if it's not already built

## Quick Setup

Run the automated setup script:

```bash
./setup-deputy.sh
```

The script will:

1. Check for Docker installation
2. Create `Dockerfile.deputy` if it doesn't exist
3. Build `deputy-ubuntu:24.04` image (if not already built)
4. Prompt for Deputy registry URL (defaults to https://deputy.ee-ng-cyber.ocr.cr14.net)
5. Prompt for your API token (input is hidden)
6. Create `~/.deputy/configuration.toml`
7. Create `~/.deputy/credentials.toml` with your token
8. Create `~/.local/bin/deputy` wrapper script
9. Test the connection

## Manual Setup

If you prefer to set up manually:

### 1. Create Configuration Directory

```bash
mkdir -p ~/.deputy
```

### 2. Create Configuration File

Create `~/.deputy/configuration.toml`:

```toml
[registries]
main-registry = { api = "https://deputy.ee-ng-cyber.ocr.cr14.net" }

[package]
download_path = "~/.deputy/downloads/"
```

### 3. Create Credentials File

Create `~/.deputy/credentials.toml`:

```toml
[[credentials]]
registry = "main-registry"
token = "YOUR_TOKEN_HERE"
```

Set secure permissions:

```bash
chmod 600 ~/.deputy/credentials.toml
```

### 4. Create Deputy Wrapper Script

Create `~/.local/bin/deputy`:

```bash
#!/bin/bash
docker run --rm \
    -v "${HOME}/.deputy:/root/.deputy" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    deputy-ubuntu:24.04 \
    deputy "$@"
```

Make it executable:

```bash
chmod +x ~/.local/bin/deputy
```

### 5. Add to PATH

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Reload your shell:

```bash
source ~/.bashrc  # or ~/.zshrc
```

## Verify Installation

Test the Deputy CLI:

```bash
deputy list
```

You should see a list of available packages including:

- `kali_2025_2/VM`
- `ubuntu2404-server/VM`
- `sewercide-ctf/Feature`

## Common Commands

### List Packages

```bash
deputy list
```

### Publish Package

```bash
cd /path/to/deputy-package
deputy publish
```

### Automated Release

```bash
./release.sh 0.2.0
```

This will:

1. Bump version in `package.toml` and `sewercide-ctf.sdl`
2. Commit changes to git
3. Create git tag
4. Push to origin
5. Publish to Deputy registry

## Troubleshooting

### Docker Image Not Found

If you get an error about missing `deputy-ubuntu:24.04` image:

1. Check available images:

   ```bash
   docker images | grep deputy
   ```

2. Load the image if you have a tar file:

   ```bash
   docker load -i deputy-ubuntu.tar
   ```

3. Or pull from registry if available:
   ```bash
   docker pull <registry>/deputy-ubuntu:24.04
   ```

### Connection Timeout

If `deputy list` times out:

1. Check you're on the correct network (VPN is required)
2. Verify the registry URL is correct
3. Check your API token is valid

### Permission Denied

If you get permission errors:

1. Check credentials file permissions:

   ```bash
   chmod 600 ~/.deputy/credentials.toml
   ```

2. Verify Docker has access to mounted volumes

## Files Created

After setup, you'll have:

```
~/.deputy/
├── configuration.toml    # Registry configuration
├── credentials.toml      # API token (keep secret!)
└── downloads/            # Downloaded packages

~/.local/bin/
└── deputy               # Wrapper script
```

## Security Notes

- **Never commit** `~/.deputy/credentials.toml` to git
- Keep your API token secret
- The credentials file has restrictive permissions (600)
- Rotate your token periodically

## Additional Resources

- Deputy Documentation: https://documentation.opencyberrange.ee/docs/deputy/
- Open Cyber Range Docs: https://documentation.opencyberrange.ee/
- SDL Reference: https://documentation.opencyberrange.ee/docs/sdl/reference
