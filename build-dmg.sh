#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Tappy"
APP_VERSION="1.1"
APP_PATH="$PWD/build/$APP_NAME.app"
DMG_PATH="$PWD/build/$APP_NAME-$APP_VERSION.dmg"
if [[ "${1:-}" != "--skip-build" ]]; then ./build-app.sh; fi
[[ -d "$APP_PATH" ]] || { echo "Missing app bundle: $APP_PATH" >&2; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")" == "$APP_VERSION" ]] || { echo "App version does not match DMG version" >&2; exit 1; }
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
cat > "$STAGING_DIR/Start here.txt" <<'README'
TAPPY 1.1 — THE MAGIC UPDATE

Drag Tappy into Applications, then open it.
Choose your character and try clicking the preview.
Enable Tappy with the switch or Control + Option + P.

Four characters, four sounds:
• Classic cartoon glove — Cartoon knock
• Sailor Moon inspired wand — Moon chime
• Princess Star inspired wand — Star sparkle
• Wizard's magic wand — Magic swish

Click faster for a bigger cartoon reaction and a louder sound.
Adjust personality, pointer size, shadow and master volume in Settings.

Control + Option + P — enable / disable Tappy
Control + Option + T — enable / exit Presentation Mode

Presentation Mode needs Accessibility access. It blocks mouse clicks
and scrolling; your keyboard stays live. Use the shortcut to exit.
Normal pointer mode and shortcuts do not require Accessibility.

For calls and recordings, share the entire screen to include Tappy.
To share the effects, also enable system audio in your calling app.

Requires macOS 13 or later. Universal: Apple Silicon + Intel.
README
hdiutil create -ov -srcfolder "$STAGING_DIR" -volname "$APP_NAME $APP_VERSION" -fs HFS+ -format UDZO "$DMG_PATH"
codesign --force --sign - "$DMG_PATH"
hdiutil verify "$DMG_PATH"
shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
echo "Built $DMG_PATH"
