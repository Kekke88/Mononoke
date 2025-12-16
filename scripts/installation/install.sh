#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/boehpyk/Mononoke/raw/9de406b48bdc74ef690d0856cd136ba51beb996d/scripts/installation/mononoke-app.zip"
INSTALL_DIR="$(pwd)"

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print header
print_header() {
    echo ""
    print_message "$BLUE" "=================================="
    print_message "$BLUE" "  Mononoke App Installer"
    print_message "$BLUE" "=================================="
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_message "$YELLOW" "Checking prerequisites..."

    local missing_deps=()

    if ! command_exists docker; then
        missing_deps+=("docker")
    fi

    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
    fi

    if ! command_exists curl; then
        missing_deps+=("curl")
    fi

    if ! command_exists unzip; then
        missing_deps+=("unzip")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "$RED" "Error: Missing required dependencies: ${missing_deps[*]}"
        echo ""
        print_message "$YELLOW" "Please install the following:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                docker)
                    echo "  - Docker: https://docs.docker.com/get-docker/"
                    ;;
                docker-compose)
                    echo "  - Docker Compose: https://docs.docker.com/compose/install/"
                    ;;
                *)
                    echo "  - $dep"
                    ;;
            esac
        done
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_message "$RED" "Error: Docker daemon is not running."
        print_message "$YELLOW" "Please start Docker and try again."
        exit 1
    fi

    print_message "$GREEN" "✓ All prerequisites met"
}

# Download and extract application
download_app() {
    print_message "$YELLOW" "Downloading application..."

    # Create temporary directory
    TMP_DIR=$(mktemp -d)

    # Download archive
    if ! curl -fsSL "$REPO_URL" -o "$TMP_DIR/app.zip"; then
        print_message "$RED" "Error: Failed to download application"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    print_message "$GREEN" "✓ Download complete"

    print_message "$YELLOW" "Extracting files..."

    # Extract archive
    if ! unzip -q "$TMP_DIR/app.zip" -d "$TMP_DIR"; then
        print_message "$RED" "Error: Failed to extract archive"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Check if installation directory is writable
    if [ ! -w "$INSTALL_DIR" ]; then
        print_message "$RED" "Error: No write permission in current directory"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Check if installation directory exists and has files
    has_files=false
    for f in "$INSTALL_DIR"/* "$INSTALL_DIR"/.*; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        # Skip . and ..
        if [ "$base" != "." ] && [ "$base" != ".." ]; then
            has_files=true
            break
        fi
    done

    if $has_files; then
        print_message "$YELLOW" "Warning: Current directory is not empty"
        read -p "Do you want to continue and extract files here? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "$RED" "Installation cancelled"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    fi

    # Move extracted files to installation directory
    # GitHub archives typically extract to a directory named repo-branch
    EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    if [ -z "$EXTRACTED_DIR" ]; then
        print_message "$RED" "Error: Failed to find extracted files"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Copy contents from extracted directory to current directory
    # Use rsync if available for better handling, otherwise cp
    if command_exists rsync; then
        if ! rsync -a "$EXTRACTED_DIR/" "$INSTALL_DIR/"; then
            print_message "$RED" "Error: Failed to copy files"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    else
        # Copy visible files and directories
        if ! cp -r "$EXTRACTED_DIR"/* "$INSTALL_DIR/" 2>/dev/null; then
            if [ "$(ls -A $EXTRACTED_DIR)" ]; then
                print_message "$RED" "Error: Failed to copy files"
                rm -rf "$TMP_DIR"
                exit 1
            fi
        fi
        # Copy hidden files (excluding . and ..)
        if ! cp -r "$EXTRACTED_DIR"/.[!.]* "$INSTALL_DIR"/ 2>/dev/null; then
            true  # It's okay if there are no hidden files
        fi
    fi

    # Cleanup
    rm -rf "$TMP_DIR"

    print_message "$GREEN" "✓ Files extracted to $INSTALL_DIR"
}
# Setup environment
setup_environment() {
    print_message "$YELLOW" "Setting up environment..."

    cd "$INSTALL_DIR" || exit 1

    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_message "$GREEN" "✓ Created .env file from .env.example"
        fi
    fi

    print_message "$GREEN" "✓ Environment setup complete"
}

# Build and start containers
start_application() {
    print_message "$YELLOW" "Building and starting Docker containers..."

    cd "$INSTALL_DIR" || exit 1


    # Build and start containers
    if ! docker compose -f docker-compose.dev.yml build --no-cache ; then
        print_message "$RED" "Error: Failed to build application container"
        exit 1
    fi

    print_message "$GREEN" "✓ Application started successfully"
}

# Print success message
print_success() {
    echo ""
    print_message "$GREEN" "=================================="
    print_message "$GREEN" "  Installation Complete!"
    print_message "$GREEN" "=================================="
    echo ""
    print_message "$BLUE" "Application installed at: $INSTALL_DIR"
    echo ""
    make help
    echo ""
}

# Main installation flow
main() {
    print_header
    check_prerequisites
    download_app
    setup_environment
    start_application
    print_success
}

# Run main function
main