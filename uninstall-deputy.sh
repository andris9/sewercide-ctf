#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Deputy CLI Uninstall${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

echo -e "${YELLOW}This will remove:${NC}"
echo "  - ~/.deputy/ directory (config and credentials)"
echo "  - ~/.local/bin/deputy wrapper script"
echo "  - deputy-ubuntu:24.04 Docker image"
echo "  - Dockerfile.deputy (if in current directory)"
echo ""
echo -ne "${RED}Are you sure you want to uninstall? (y/N):${NC} "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstall cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Uninstalling Deputy CLI...${NC}"

# Remove ~/.deputy directory
if [ -d "$HOME/.deputy" ]; then
    echo -n "Removing ~/.deputy... "
    rm -rf "$HOME/.deputy"
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "~/.deputy not found, skipping"
fi

# Remove deputy wrapper script
if [ -f "$HOME/.local/bin/deputy" ]; then
    echo -n "Removing ~/.local/bin/deputy... "
    rm -f "$HOME/.local/bin/deputy"
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "~/.local/bin/deputy not found, skipping"
fi

# Remove Docker image
if docker images | grep -q deputy-ubuntu; then
    echo -n "Removing deputy-ubuntu:24.04 Docker image... "
    docker rmi deputy-ubuntu:24.04 &> /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAILED]${NC}"
        echo -e "${YELLOW}You may need to stop running containers first${NC}"
    fi
else
    echo -e "deputy-ubuntu:24.04 Docker image not found, skipping"
fi

# Remove Dockerfile.deputy from current directory
if [ -f "Dockerfile.deputy" ]; then
    echo -n "Removing Dockerfile.deputy from current directory... "
    rm -f "Dockerfile.deputy"
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "Dockerfile.deputy not found in current directory, skipping"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Uninstall Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Note: If you added ~/.local/bin to your PATH in .bashrc or .zshrc,${NC}"
echo -e "${YELLOW}you may want to remove that line as well.${NC}"
