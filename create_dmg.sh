#!/bin/bash
# Script to create a distributable DMG for ClipWizard

# Error handling
set -e
trap 'echo "An error occurred. Cleaning up..."; rm -rf "$DMG_DIR"; exit 1' ERR

# Configuration
APP_NAME="ClipWizard"

# Extract version from project settings instead of changelog
# Extract version from CHANGELOG.md - Get the first version number found in the file
VERSION=$(head -n 5 ./CHANGELOG.md | grep -o -E 'Version ([0-9]+\.[0-9]+\.[0-9]+)' | head -n 1 | cut -d ' ' -f 2)

# Fallback to Info.plist if CHANGELOG extraction fails
if [ -z "$VERSION" ]; then
    echo "Warning: Could not extract version from CHANGELOG.md, trying Info.plist..."
    VERSION=$(plutil -p "./ClipWizard/Info.plist" | grep CFBundleShortVersionString | sed -E 's/.*"([0-9]+\.[0-9]+)".*/\1.0/g')
    
    # If still no version, use a default
    if [ -z "$VERSION" ]; then
        echo "Warning: Could not extract version from Info.plist either. Using default version."
        VERSION="0.0.0"
    fi
fi

echo "Using version: $VERSION"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="./build"
DMG_DIR="${BUILD_DIR}/dmg_contents"
DERIVED_DATA_PATH="/Users/danebalia/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "ClipWizard.app" -type d | grep -i "Build/Products/Release" | head -n 1)

# Print header
echo "Creating distributable DMG for ${APP_NAME} version ${VERSION}"
echo "------------------------------------------------------------"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "create-dmg not found. Installing via Homebrew..."
    brew install create-dmg || { echo "Error installing create-dmg. Please install manually."; exit 1; }
fi

# Ensure Xcode build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Build directory not found. Building the app first..."
    xcodebuild -project "${APP_NAME}.xcodeproj" -scheme "${APP_NAME}" -configuration Release -derivedDataPath "./build" clean build || { echo "Build failed"; exit 1; }
fi

# Check if app exists after build
if [ ! -d "$APP_PATH" ]; then
    echo "App not found at ${APP_PATH} after build."
    echo "Please build the app manually with Xcode and try again."
    exit 1
fi

# Clean up any previous files
echo "Cleaning up previous build files..."
rm -rf "$DMG_DIR"
rm -f "${DMG_NAME}"
# Remove any temporary DMG files from failed previous attempts
find . -name "rw.*\.${DMG_NAME}" -delete

# Create clean DMG directory
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
echo "Copying ${APP_NAME}.app to DMG contents directory..."
cp -R "$APP_PATH" "$DMG_DIR"

# Create a symbolic link to /Applications for easy drag-and-drop installation
echo "Creating Applications symlink for drag-and-drop installation..."
ln -s /Applications "${DMG_DIR}/Applications"

# Create the DMG
echo "Creating DMG file..."

create-dmg \
    --volname "${APP_NAME} ${VERSION}" \
    --volicon "./ClipWizard.icns" \
    --background "./original.png" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 200 190 \
    --hide-extension "${APP_NAME}.app" \
    --skip-jenkins \
    --no-internet-enable \
    "${DMG_NAME}" \
    "${DMG_DIR}" || { 
        echo "DMG creation failed"; 
        # Clean up after failure
        rm -rf "$DMG_DIR"; 
        exit 1; 
    }

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$DMG_DIR"

# Success message
echo "------------------------------------------------------------"
echo "Successfully created ${DMG_NAME}"
echo "The DMG file is ready for distribution."
echo "------------------------------------------------------------"