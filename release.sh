#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 0.2.0"
    exit 1
}

# Check if version argument is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    usage
fi

NEW_VERSION="$1"

# Validate version format (basic semver check)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 0.2.0)${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.toml" ] || [ ! -f "sewercide-ctf.sdl" ]; then
    echo -e "${RED}Error: Must run from deputy-package directory${NC}"
    exit 1
fi

# Get current version from package.toml
CURRENT_VERSION=$(grep '^version = ' package.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
echo -e "${YELLOW}Current version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}New version: ${NEW_VERSION}${NC}"

# Confirm with user
read -p "Continue with release? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled"
    exit 0
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: You have uncommitted changes. Commit or stash them first.${NC}"
    exit 1
fi

echo -e "${GREEN}[1/6] Updating version in package.toml...${NC}"
sed -i.bak "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" package.toml
rm package.toml.bak

echo -e "${GREEN}[2/6] Updating version in sewercide-ctf.sdl...${NC}"
sed -i.bak "s/version: [0-9]*\.[0-9]*\.[0-9]*/version: ${NEW_VERSION}/" sewercide-ctf.sdl
rm sewercide-ctf.sdl.bak

echo -e "${GREEN}[3/6] Committing version bump...${NC}"
git add package.toml sewercide-ctf.sdl
git commit -m "Bump version to ${NEW_VERSION}"

echo -e "${GREEN}[4/6] Creating git tag v${NEW_VERSION}...${NC}"
git tag "v${NEW_VERSION}"

echo -e "${GREEN}[5/6] Pushing to git origin...${NC}"
git push origin master
git push origin "v${NEW_VERSION}"

echo -e "${GREEN}[6/6] Publishing to Deputy registry...${NC}"
docker run --rm \
    -v "${HOME}/.deputy:/root/.deputy" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    deputy-ubuntu:24.04 \
    deputy publish

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Release ${NEW_VERSION} complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Package published to Deputy registry"
echo "Git tag: v${NEW_VERSION}"
echo ""
echo "Verify with:"
echo "  docker run --rm -v \"\${HOME}/.deputy:/root/.deputy\" deputy-ubuntu:24.04 sh -c 'deputy list 2>&1 | grep sewercide'"
