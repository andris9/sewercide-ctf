#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <version> [-y|--yes] [-p|--package <name>]"
    echo "Example: $0 0.2.0"
    echo "Example (non-interactive): $0 0.2.0 -y"
    echo "Example (with package name): $0 0.2.0 -y -p sewercide-ctf"
    echo ""
    echo "Options:"
    echo "  -y, --yes              Skip all confirmations (non-interactive mode)"
    echo "  -p, --package <name>   Specify package name (skip auto-detection prompt)"
    exit 1
}

# Check if version argument is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    usage
fi

NEW_VERSION="$1"
shift

# Parse additional arguments
NON_INTERACTIVE=false
PACKAGE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            NON_INTERACTIVE=true
            shift
            ;;
        -p|--package)
            PACKAGE_NAME="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Validate version format (basic semver check)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 0.2.0)${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "package.toml" ]; then
    echo -e "${RED}Error: package.toml not found. Must run from deputy-package directory${NC}"
    exit 1
fi

# Auto-detect package name from package.toml
DEFAULT_PACKAGE_NAME=$(grep '^name = ' package.toml | head -1 | sed 's/name = "\(.*\)"/\1/')

# Ask for package name (with default) unless already provided
if [ -z "$PACKAGE_NAME" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
        PACKAGE_NAME="$DEFAULT_PACKAGE_NAME"
        echo -e "${BLUE}Package name: ${PACKAGE_NAME}${NC}"
    else
        echo -ne "${BLUE}Package name [${DEFAULT_PACKAGE_NAME}]:${NC} "
        read -r PACKAGE_NAME
        if [ -z "$PACKAGE_NAME" ]; then
            PACKAGE_NAME="$DEFAULT_PACKAGE_NAME"
        fi
    fi
else
    echo -e "${BLUE}Package name: ${PACKAGE_NAME}${NC}"
fi

# Auto-detect SDL file (look for .sdl files)
SDL_FILES=(*.sdl)
if [ ${#SDL_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}Warning: No .sdl file found${NC}"
    SDL_FILE=""
elif [ ${#SDL_FILES[@]} -eq 1 ]; then
    SDL_FILE="${SDL_FILES[0]}"
    echo -e "${BLUE}SDL file: ${SDL_FILE}${NC}"
else
    echo -e "${YELLOW}Multiple .sdl files found:${NC}"
    select SDL_FILE in "${SDL_FILES[@]}" "None"; do
        if [ "$SDL_FILE" = "None" ]; then
            SDL_FILE=""
        fi
        break
    done
fi

# Auto-detect git branch
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")

# Get current version from package.toml
CURRENT_VERSION=$(grep '^version = ' package.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
echo -e "${YELLOW}Current version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}New version: ${NEW_VERSION}${NC}"

# Confirm with user unless in non-interactive mode
if [ "$NON_INTERACTIVE" = false ]; then
    read -p "Continue with release? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled"
        exit 0
    fi
else
    echo -e "${GREEN}Non-interactive mode: proceeding with release${NC}"
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}Error: You have uncommitted changes. Commit or stash them first.${NC}"
    exit 1
fi

echo -e "${GREEN}[1/6] Updating version in package.toml...${NC}"
sed -i.bak "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" package.toml
rm package.toml.bak

FILES_TO_COMMIT="package.toml"

if [ -n "$SDL_FILE" ] && [ -f "$SDL_FILE" ]; then
    echo -e "${GREEN}[2/6] Updating version in ${SDL_FILE}...${NC}"
    sed -i.bak "s/version: [0-9]*\.[0-9]*\.[0-9]*/version: ${NEW_VERSION}/g" "$SDL_FILE"
    rm "${SDL_FILE}.bak"
    FILES_TO_COMMIT="$FILES_TO_COMMIT $SDL_FILE"
else
    echo -e "${YELLOW}[2/6] Skipping SDL update (no SDL file)${NC}"
fi

echo -e "${GREEN}[3/6] Committing version bump...${NC}"
git add $FILES_TO_COMMIT
git commit -m "Bump version to ${NEW_VERSION}"

echo -e "${GREEN}[4/6] Creating git tag v${NEW_VERSION}...${NC}"
git tag "v${NEW_VERSION}"

echo -e "${GREEN}[5/6] Pushing to git origin...${NC}"
git push origin "$GIT_BRANCH"
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
echo -e "${YELLOW}Verifying package in registry...${NC}"
PACKAGE_INFO=$(docker run --rm -v "${HOME}/.deputy:/root/.deputy" deputy-ubuntu:24.04 sh -c "deputy list 2>&1 | grep '$PACKAGE_NAME'" 2>/dev/null)

if [ -n "$PACKAGE_INFO" ]; then
    echo -e "${GREEN}[OK] Package verified:${NC} $PACKAGE_INFO"
else
    echo -e "${RED}[ERROR] Could not verify package in registry${NC}"
    echo "  Run manually: docker run --rm -v \"\${HOME}/.deputy:/root/.deputy\" deputy-ubuntu:24.04 sh -c \"deputy list 2>&1 | grep '$PACKAGE_NAME'\""
fi
