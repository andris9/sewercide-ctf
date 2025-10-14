#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Deputy CLI Setup for Docker${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if deputy-ubuntu image exists
if ! docker images | grep -q deputy-ubuntu; then
    echo -e "${YELLOW}Deputy Docker image not found${NC}"
    echo "Please provide the Deputy Docker image."
    echo "You can load it with: docker load -i deputy-ubuntu.tar"
    echo "Or pull it from a registry if available."
    exit 1
fi

echo -e "${GREEN}✓ Deputy Docker image found${NC}"

# Create Deputy configuration directory
DEPUTY_CONFIG_DIR="$HOME/.deputy"
DEPUTY_CONFIG_FILE="$DEPUTY_CONFIG_DIR/configuration.toml"

echo ""
echo -e "${YELLOW}Setting up Deputy configuration...${NC}"

# Create directory if it doesn't exist
mkdir -p "$DEPUTY_CONFIG_DIR"

# Prompt for API token
echo ""
echo -e "${BLUE}Please enter your Deputy API token:${NC}"
echo "(You can generate one at: https://deputy.ee-ng-cyber.ocr.cr14.net)"
read -s -p "Token: " DEPUTY_TOKEN
echo ""

if [ -z "$DEPUTY_TOKEN" ]; then
    echo -e "${RED}Error: Token cannot be empty${NC}"
    exit 1
fi

# Create configuration file
cat > "$DEPUTY_CONFIG_FILE" <<EOF
[registries]
main-registry = { api = "https://deputy.ee-ng-cyber.ocr.cr14.net" }

[package]
download_path = "~/.deputy/downloads/"
EOF

echo -e "${GREEN}✓ Configuration file created at: ${DEPUTY_CONFIG_FILE}${NC}"

# Create credentials file
DEPUTY_CREDENTIALS_FILE="$DEPUTY_CONFIG_DIR/credentials.toml"
cat > "$DEPUTY_CREDENTIALS_FILE" <<EOF
[[credentials]]
registry = "main-registry"
token = "${DEPUTY_TOKEN}"
EOF

chmod 600 "$DEPUTY_CREDENTIALS_FILE"
echo -e "${GREEN}✓ Credentials file created (permissions: 600)${NC}"

# Create deputy wrapper script
DEPUTY_WRAPPER="$HOME/.local/bin/deputy"
mkdir -p "$HOME/.local/bin"

cat > "$DEPUTY_WRAPPER" <<'EOF'
#!/bin/bash
# Deputy CLI wrapper for Docker on ARM Mac
docker run --rm \
    -v "${HOME}/.deputy:/root/.deputy" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    deputy-ubuntu:24.04 \
    deputy "$@"
EOF

chmod +x "$DEPUTY_WRAPPER"
echo -e "${GREEN}✓ Deputy wrapper script created at: ${DEPUTY_WRAPPER}${NC}"

# Test the configuration
echo ""
echo -e "${YELLOW}Testing Deputy CLI...${NC}"
if "$DEPUTY_WRAPPER" list &> /dev/null; then
    echo -e "${GREEN}✓ Deputy CLI is working!${NC}"
else
    echo -e "${YELLOW}⚠ Could not connect to Deputy registry${NC}"
    echo "This might be normal if you're not on the network."
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Configuration:"
echo "  Config: $DEPUTY_CONFIG_FILE"
echo "  Credentials: $DEPUTY_CREDENTIALS_FILE"
echo "  Wrapper: $DEPUTY_WRAPPER"
echo ""
echo "Usage:"
echo "  deputy list              # List available packages"
echo "  deputy publish           # Publish current package"
echo "  ./release.sh X.Y.Z       # Automated release workflow"
echo ""
echo "Add to PATH (if not already):"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo -e "${YELLOW}Note: The deputy command uses Docker, so it requires Docker to be running.${NC}"
