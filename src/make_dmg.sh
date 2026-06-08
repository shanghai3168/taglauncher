#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="TagLauncher"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGING="$BUILD_DIR/dmg_staging"

echo "==> Preparing DMG staging..."
rm -rf "$STAGING"
mkdir -p "$STAGING"

echo "==> Copying $APP_NAME.app..."
cp -R "$APP_BUNDLE" "$STAGING/"

echo "==> Creating Applications symlink..."
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG..."
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

echo "==> Cleaning up staging..."
rm -rf "$STAGING"

SIZE=$(du -sh "$DMG_PATH" | awk '{print $1}')
echo ""
echo "✅ DMG created: $DMG_PATH ($SIZE)"
echo "   Open: open $DMG_PATH"
