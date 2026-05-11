#!/bin/bash
set -euo pipefail

APP_NAME="TagLauncher"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
SWIFT_DIR="$PROJECT_DIR/Apptag"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
TARGET="arm64-apple-macosx15.0"

# --- Optional: App Store / Sandbox signing ---
# Set CODESIGN_IDENTITY to your "Apple Distribution" or "Mac Developer" cert name.
# Example: CODESIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
ENTITLEMENTS="$SWIFT_DIR/TagLauncher.entitlements"
APP_STORE_MODE=false

if [ -n "${APP_STORE:-}" ] && [ "$APP_STORE" = "1" ]; then
    APP_STORE_MODE=true
    if [ -z "$CODESIGN_IDENTITY" ]; then
        echo "⚠️  APP_STORE=1 but CODESIGN_IDENTITY not set. Will ad-hoc sign with entitlements."
    fi
fi

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
    -Osize \
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

echo "==> Embedding PkgInfo..."
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> Setting permissions..."
chmod +x "$MACOS_DIR/$APP_NAME"

echo "==> Stripping debug symbols..."
strip -x "$MACOS_DIR/$APP_NAME"

# --- Signing ---
if [ "$APP_STORE_MODE" = true ] || [ -n "$CODESIGN_IDENTITY" ]; then
    echo "==> Signing with entitlements..."
    if [ -n "$CODESIGN_IDENTITY" ]; then
        CODESIGN_ARGS="--sign \"$CODESIGN_IDENTITY\""
    else
        CODESIGN_ARGS="--sign -"
    fi

    if [ -f "$ENTITLEMENTS" ]; then
        eval codesign --force --deep $CODESIGN_ARGS --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
        echo "   Signed with entitlements: $ENTITLEMENTS"
    else
        eval codesign --force --deep $CODESIGN_ARGS "$APP_BUNDLE"
        echo "   Signed (no entitlements file found)"
    fi
else
    # Default: ad-hoc sign without entitlements (local dev)
    echo "==> Ad-hoc signing..."
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo ""
echo "✅ App built at: $APP_BUNDLE"
echo "   Run: open $APP_BUNDLE"

# --- App Store mode: remind about next steps ---
if [ "$APP_STORE_MODE" = true ]; then
    echo ""
    echo "📦 App Store build ready. Next steps:"
    echo "   1. Verify sandbox: spctl -a -v \"$APP_BUNDLE\""
    echo "   2. Test in sandbox: sandbox-exec -f <(echo '(version 1)(allow default)') open \"$APP_BUNDLE\""
    echo "   3. Upload via Transporter or 'xcrun altool --upload-app'"
fi
