#!/bin/bash
set -euo pipefail

APP_NAME="Apptag"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
SWIFT_DIR="$PROJECT_DIR/Apptag"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
TARGET="arm64-apple-macosx26.0"

echo "==> Cleaning..."
rm -rf "$BUILD_DIR"

echo "==> Creating bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Compiling Swift files..."
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    "$SWIFT_DIR"/*.swift

echo "==> Copying Info.plist..."
cp "$SWIFT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Copying AppIcon.icns..."
if [ -f "$PROJECT_DIR/icon-icns.icns" ]; then
    cp "$PROJECT_DIR/icon-icns.icns" "$RESOURCES_DIR/AppIcon.icns"
elif [ -f "$SWIFT_DIR/AppIcon.iconset/icon_512x512@2x.png" ]; then
    iconutil -c icns "$SWIFT_DIR/AppIcon.iconset" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null
fi

echo "==> Copying Localization files..."
cp -r "$SWIFT_DIR/Localization" "$RESOURCES_DIR/Localization"

echo "==> Setting permissions..."
chmod +x "$MACOS_DIR/$APP_NAME"

echo ""
echo "✅ App built at: $APP_BUNDLE"
echo "   Run: open $APP_BUNDLE"
