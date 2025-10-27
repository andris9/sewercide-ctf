#!/bin/bash
set -e

# Universal Deputy Package Release Script
# Works with or without git, handles OVA packages, SDL files, and feature packages

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
    echo "Example (with package name): $0 0.2.0 -y -p my-package"
    echo ""
    echo "Options:"
    echo "  -y, --yes              Skip all confirmations (non-interactive mode)"
    echo "  -p, --package <name>   Specify package name (skip auto-detection prompt)"
    echo ""
    echo "This script:"
    echo "  - Updates version in package.toml"
    echo "  - Updates version in SDL files (if present)"
    echo "  - Commits and tags (if .git exists)"
    echo "  - Publishes to Deputy registry"
    echo "  - Works with OVA packages (allows uncommitted .ova files)"
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
    echo -e "${RED}Error: package.toml not found. Must run from package directory${NC}"
    exit 1
fi

# Check if git is available
HAS_GIT=false
if [ -d ".git" ]; then
    HAS_GIT=true
    echo -e "${BLUE}Git repository detected${NC}"
else
    echo -e "${YELLOW}No git repository detected - skipping git operations${NC}"
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

# Detect package type from package.toml
PACKAGE_TYPE=$(grep '^\[content\]' package.toml -A 1 | grep '^type = ' | sed 's/type = "\(.*\)"/\1/')
echo -e "${BLUE}Package type: ${PACKAGE_TYPE}${NC}"

# Auto-detect SDL/exercise files (look for .sdl, .yml files)
SDL_FILES=()
for ext in sdl yml yaml; do
    while IFS= read -r -d '' file; do
        SDL_FILES+=("$file")
    done < <(find . -maxdepth 1 -name "*.${ext}" -print0 2>/dev/null)
done

SDL_FILE=""
if [ ${#SDL_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No SDL/exercise file found${NC}"
elif [ ${#SDL_FILES[@]} -eq 1 ]; then
    SDL_FILE="${SDL_FILES[0]}"
    echo -e "${BLUE}SDL file: ${SDL_FILE}${NC}"
else
    echo -e "${YELLOW}Multiple SDL/exercise files found:${NC}"
    if [ "$NON_INTERACTIVE" = true ]; then
        SDL_FILE="${SDL_FILES[0]}"
        echo -e "${BLUE}Using first file: ${SDL_FILE}${NC}"
    else
        select SDL_FILE in "${SDL_FILES[@]}" "None"; do
            if [ "$SDL_FILE" = "None" ]; then
                SDL_FILE=""
            fi
            break
        done
    fi
fi

# Check for .ova files
OVA_FILES=(*.ova)
HAS_OVA=false
if [ -f "${OVA_FILES[0]}" ]; then
    HAS_OVA=true
    echo -e "${BLUE}OVA files detected: ${OVA_FILES[*]}${NC}"

    # Check if .ova is in .gitignore
    if [ -f ".gitignore" ] && grep -q '\.ova' .gitignore; then
        echo -e "${RED}WARNING: .ova files are in .gitignore!${NC}"
        echo -e "${RED}This will prevent Deputy from publishing the OVA files.${NC}"
        echo -e "${YELLOW}Consider removing *.ova from .gitignore${NC}"
        if [ "$NON_INTERACTIVE" = false ]; then
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}Note: .ova files will remain uncommitted (not pushed to git)${NC}"
    fi
fi

# Auto-detect git branch if git is available
if [ "$HAS_GIT" = true ]; then
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo -e "${BLUE}Git branch: ${GIT_BRANCH}${NC}"
fi

# Get current version from package.toml
CURRENT_VERSION=$(grep '^version = ' package.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
echo -e "${YELLOW}Current version: ${CURRENT_VERSION}${NC}"
echo -e "${YELLOW}New version: ${NEW_VERSION}${NC}"

# Confirm with user unless in non-interactive mode
if [ "$NON_INTERACTIVE" = false ]; then
    echo ""
    read -p "Continue with release? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release cancelled"
        exit 0
    fi
else
    echo -e "${GREEN}Non-interactive mode: proceeding with release${NC}"
fi

# Check for uncommitted changes (only if git is available)
if [ "$HAS_GIT" = true ]; then
    # Check for uncommitted changes excluding .ova files
    if [ "$HAS_OVA" = true ]; then
        # For OVA packages, check for changes excluding .ova files
        UNCOMMITTED=$(git status --porcelain | grep -v '\.ova$' || true)
        if [ -n "$UNCOMMITTED" ]; then
            echo -e "${RED}Error: You have uncommitted changes (excluding .ova files):${NC}"
            echo "$UNCOMMITTED"
            echo -e "${YELLOW}Commit or stash them first.${NC}"
            exit 1
        else
            echo -e "${GREEN}No uncommitted changes (excluding .ova files)${NC}"
        fi
    else
        # For non-OVA packages, check for any changes
        if ! git diff-index --quiet HEAD --; then
            echo -e "${RED}Error: You have uncommitted changes. Commit or stash them first.${NC}"
            git status --short
            exit 1
        fi
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting release process...${NC}"
echo -e "${GREEN}========================================${NC}"

# Calculate total steps
TOTAL_STEPS=3  # Base: update package.toml, deputy publish, verify
if [ -n "$SDL_FILE" ]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
if [ "$HAS_GIT" = true ]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 3))  # commit, tag, push
fi

STEP=1

# Step: Update package.toml
echo ""
echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Updating version in package.toml...${NC}"
sed -i.bak "s/^version = \".*\"/version = \"${NEW_VERSION}\"/" package.toml
rm package.toml.bak
STEP=$((STEP + 1))

FILES_TO_COMMIT="package.toml"

# Step: Update SDL file if present
if [ -n "$SDL_FILE" ] && [ -f "$SDL_FILE" ]; then
    echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Updating version in ${SDL_FILE}...${NC}"
    # Update version: field in SDL/YAML files
    sed -i.bak "s/version: [0-9]*\.[0-9]*\.[0-9]*/version: ${NEW_VERSION}/g" "$SDL_FILE"
    rm "${SDL_FILE}.bak"
    FILES_TO_COMMIT="$FILES_TO_COMMIT $SDL_FILE"
    STEP=$((STEP + 1))
fi

# Git operations (only if git is available)
if [ "$HAS_GIT" = true ]; then
    # Step: Commit version bump
    echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Committing version bump...${NC}"
    git add $FILES_TO_COMMIT
    if git diff --staged --quiet; then
        echo -e "${YELLOW}No version changes to commit (already at ${NEW_VERSION})${NC}"
    else
        git commit -m "Bump version to ${NEW_VERSION}"
    fi
    STEP=$((STEP + 1))

    # Step: Create git tag
    echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Creating git tag v${NEW_VERSION}...${NC}"
    if git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1; then
        echo -e "${YELLOW}Tag v${NEW_VERSION} already exists${NC}"
    else
        git tag "v${NEW_VERSION}"
    fi
    STEP=$((STEP + 1))

    # Step: Push to git origin
    echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Pushing to git origin...${NC}"
    git push origin "$GIT_BRANCH" || echo -e "${YELLOW}Warning: Push failed (may need to set upstream)${NC}"
    git push origin "v${NEW_VERSION}" || echo -e "${YELLOW}Warning: Tag push failed${NC}"
    STEP=$((STEP + 1))
fi

# Step: Publish to Deputy
echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Publishing to Deputy registry...${NC}"
docker run --rm \
    --platform linux/amd64 \
    -v "${HOME}/.deputy:/root/.deputy" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    deputy-ubuntu:24.04 \
    deputy publish
STEP=$((STEP + 1))

# Step: Verify publication
echo -e "${GREEN}[${STEP}/${TOTAL_STEPS}] Verifying package in registry...${NC}"
PACKAGE_INFO=$(docker run --rm \
    --platform linux/amd64 \
    -v "${HOME}/.deputy:/root/.deputy" \
    deputy-ubuntu:24.04 \
    sh -c "deputy list 2>&1 | grep '$PACKAGE_NAME'" 2>/dev/null || true)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Release ${NEW_VERSION} complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Package: ${PACKAGE_NAME}"
echo "Version: ${NEW_VERSION}"
echo "Type: ${PACKAGE_TYPE}"
if [ "$HAS_GIT" = true ]; then
    echo "Git tag: v${NEW_VERSION}"
fi
if [ "$HAS_OVA" = true ]; then
    echo -e "${YELLOW}Note: .ova files remain uncommitted (not pushed to git)${NC}"
fi
echo ""

if [ -n "$PACKAGE_INFO" ]; then
    echo -e "${GREEN}[OK] Package verified in registry:${NC}"
    echo "  $PACKAGE_INFO"
else
    echo -e "${RED}[WARNING] Could not verify package in registry${NC}"
    echo "  Run manually: docker run --rm --platform linux/amd64 -v \"\${HOME}/.deputy:/root/.deputy\" deputy-ubuntu:24.04 deputy info $PACKAGE_NAME"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
if [ "$PACKAGE_TYPE" = "vm" ] || [ "$PACKAGE_TYPE" = "feature" ]; then
    echo "  - Test the package in a deployment"
fi
if [ "$PACKAGE_TYPE" = "exercise" ]; then
    echo "  - Import exercise in Ranger"
    echo "  - Configure banner and deployment"
fi
echo "  - Verify package: deputy info ${PACKAGE_NAME}"
echo ""
