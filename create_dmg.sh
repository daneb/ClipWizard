#!/bin/bash
# Script to create a distributable DMG for ClipWizard

# Configuration
APP_NAME="ClipWizard"
VERSION=$(grep -A 1 "Current Beta" "./CHANGELOG.md" | grep "Version" | sed -E 's/.*Version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/g')
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="./build"
DMG_DIR="${BUILD_DIR}/dmg_contents"
APP_PATH="./build/Release/${APP_NAME}.app"

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

# Create DMG directory if it doesn't exist
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
    --app-drop-link 600 185 \
    "${DMG_NAME}" \
    "${DMG_DIR}" || { echo "DMG creation failed"; exit 1; }

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$DMG_DIR"

# Success message
echo "------------------------------------------------------------"
echo "Successfully created ${DMG_NAME}"
echo "The DMG file is ready for distribution."
echo "------------------------------------------------------------"
