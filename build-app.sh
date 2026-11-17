#!/bin/bash
set -e

APP_NAME="Tappy"
BUNDLE_ID="com.example.tappy"
BUILD_DIR="$(pwd)/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

# Build release executable
swift build -c release

# Clean previous bundle
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp "$(pwd)/.build/release/$APP_NAME" "$APP_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

# Copy icon
if [ -f "Assets/$APP_NAME.icns" ]; then
    cp "Assets/$APP_NAME.icns" "$APP_PATH/Contents/Resources/$APP_NAME.icns"
fi

# Write Info.plist
cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
</dict>
</plist>
EOF

# Ad-hoc sign
codesign --force --deep --sign - "$APP_PATH"

echo "Built $APP_PATH"
