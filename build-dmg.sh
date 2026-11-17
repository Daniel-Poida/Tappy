#!/bin/bash
set -e

APP_NAME="Tappy"
APP_PATH="build/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-1.0.dmg"
DMG_PATH="build/${DMG_NAME}"
TMP_DIR="$(mktemp -d)"

if [ ! -d "$APP_PATH" ]; then
    echo "Building $APP_NAME.app first..."
    ./build-app.sh
fi

echo "Creating DMG..."
mkdir -p "$TMP_DIR/.background"

# Copy app
cp -R "$APP_PATH" "$TMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DIR/Applications"

# Create the DMG
hdiutil create -srcfolder "$TMP_DIR" -volname "$APP_NAME" -fs HFS+ -format UDZO -size 20m "$DMG_PATH"

# Clean up
rm -rf "$TMP_DIR"

# Ad-hoc sign
codesign --force --sign - "$DMG_PATH"

echo "Built $DMG_PATH"
