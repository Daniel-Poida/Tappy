#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Tappy"
APP_VERSION="$(cat VERSION)"
BUILD_DIR="$PWD/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache"

# Produce a universal executable for Apple Silicon and Intel Macs.
for ARCH in arm64 x86_64; do
    swift build -c release --arch "$ARCH" --disable-sandbox --cache-path "$PWD/.build/package-cache"
done
ARM_BIN="$(swift build -c release --arch arm64 --show-bin-path --disable-sandbox)/$APP_NAME"
INTEL_BIN="$(swift build -c release --arch x86_64 --show-bin-path --disable-sandbox)/$APP_NAME"

# Render the icon from the production glove artwork.
"$ARM_BIN" --export-assets "$PWD/Assets"
iconutil -c icns "$PWD/Assets/Tappy.iconset" -o "$PWD/Assets/Tappy.icns"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
lipo -create "$ARM_BIN" "$INTEL_BIN" -output "$APP_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"
cp "Assets/$APP_NAME.icns" "$APP_PATH/Contents/Resources/$APP_NAME.icns"
cp -R "$(dirname "$ARM_BIN")/Tappy_Tappy.bundle" "$APP_PATH/Contents/Resources/"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>com.example.tappy</string>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$APP_VERSION</string>
    <key>CFBundleVersion</key><string>134</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleIconFile</key><string>$APP_NAME</string>
    <key>NSHumanReadableCopyright</key><string>Tappy · 2026</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
echo "Built $APP_PATH ($APP_VERSION, universal)"
