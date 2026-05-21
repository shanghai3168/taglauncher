#!/bin/bash
set -euo pipefail

APP_NAME="TagLauncher"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
APP_INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
SWIFT_DIR="$PROJECT_DIR/Apptag"
INFO_PLIST="$SWIFT_DIR/Info.plist"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
TARGET="arm64-apple-macosx15.0"

APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
APP_BUILD="${APP_BUILD:-$(date '+%Y%m%d.%H%M')}"
SOURCE_INFO_PLIST_HASH_BEFORE=$(shasum -a 256 "$INFO_PLIST" | awk '{print $1}')
if [ -z "$APP_VERSION" ] || ! [[ "$APP_BUILD" =~ ^[0-9]{8}\.[0-9]{4}$ ]]; then
    echo "❌ Invalid version metadata in $INFO_PLIST: version='$APP_VERSION' build='$APP_BUILD'"
    exit 1
fi

echo "==> Packaging $APP_NAME $APP_VERSION ($APP_BUILD)"

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
    if [ ! -f "$ENTITLEMENTS" ]; then
        echo "❌ APP_STORE=1 requires entitlements at: $ENTITLEMENTS"
        exit 1
    fi
fi

echo "==> Cleaning..."
rm -rf "$BUILD_DIR"

echo "==> Creating bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Compiling Swift files..."
SWIFT_FILES=()
while IFS= read -r file; do
    SWIFT_FILES+=("$file")
done < <(find "$SWIFT_DIR" -name '*.swift' -print | sort)
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -framework CoreServices \
    -lcompression \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -Osize \
    "${SWIFT_FILES[@]}"

echo "==> Copying Info.plist..."
cp "$INFO_PLIST" "$APP_INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD" "$APP_INFO_PLIST"

echo "==> Copying AppIcon.icns..."
if [ -f "$PROJECT_DIR/icon-icns.icns" ]; then
    cp "$PROJECT_DIR/icon-icns.icns" "$RESOURCES_DIR/AppIcon.icns"
elif [ -f "$SWIFT_DIR/AppIcon.iconset/icon_512x512@2x.png" ]; then
    iconutil -c icns "$SWIFT_DIR/AppIcon.iconset" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null
fi

echo "==> Copying menu bar icon..."
if [ -f "$PROJECT_DIR/Research/logo/TagLauncherMenuBarIcon_v2_light.svg" ]; then
    cp "$PROJECT_DIR/Research/logo/TagLauncherMenuBarIcon_v2_light.svg" "$RESOURCES_DIR/TagLauncherMenuBarIcon.svg"
fi

echo "==> Copying Localization files..."
cp -r "$SWIFT_DIR/Localization" "$RESOURCES_DIR/Localization"

echo "==> Copying Smart Start catalog..."
SMARTSTART_SOURCE_DIR="$PROJECT_DIR/Research/SmartStart/UltimateDefaultCatalog"
for required in \
    "SmartStart_UltimateDefaultCatalog.base.json" \
    "SmartStart_UltimateDefaultCatalog.manifest.json" \
    "SmartStart_UltimateDefaultCatalog.notes.en.json" \
    "SmartStart_UltimateDefaultCatalog.notes.zh-Hans.json"; do
    if [ ! -f "$SMARTSTART_SOURCE_DIR/$required" ]; then
        echo "❌ Missing Smart Start split resource: $required"
        echo "   Run: node Research/SmartStart/Scripts/build-ultimate-default-catalog.mjs"
        exit 1
    fi
done
python3 - "$SMARTSTART_SOURCE_DIR/SmartStart_UltimateDefaultCatalog.base.json" "$RESOURCES_DIR/SmartStartUltimateDefaultCatalog.base.json" <<'PY'
import json
import sys
source, destination = sys.argv[1], sys.argv[2]
with open(source, "r", encoding="utf-8") as f:
    data = json.load(f)
with open(destination, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
PY
python3 - "$SMARTSTART_SOURCE_DIR/SmartStart_UltimateDefaultCatalog.manifest.json" "$RESOURCES_DIR/SmartStartUltimateDefaultCatalog.manifest.json" <<'PY'
import json
import sys
source, destination = sys.argv[1], sys.argv[2]
with open(source, "r", encoding="utf-8") as f:
    data = json.load(f)
with open(destination, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
PY
for notes_file in "$SMARTSTART_SOURCE_DIR"/SmartStart_UltimateDefaultCatalog.notes.*.json; do
    [ -e "$notes_file" ] || continue
    output_name="$(basename "$notes_file" | sed 's/SmartStart_UltimateDefaultCatalog/SmartStartUltimateDefaultCatalog/').deflate"
    python3 - "$notes_file" "$RESOURCES_DIR/$output_name" <<'PY'
import json
import sys
import zlib
source, destination = sys.argv[1], sys.argv[2]
with open(source, "r", encoding="utf-8") as f:
    data = json.load(f)
payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
compressor = zlib.compressobj(level=9, wbits=-15)
compressed = compressor.compress(payload) + compressor.flush()
with open(destination, "wb") as f:
    f.write(compressed)
PY
done

if find "$RESOURCES_DIR" -maxdepth 1 -type f \( \
    -name '*TranslationCache*' -o \
    -name '*invalid*' -o \
    -name 'SmartStartUltimateDefaultCatalog.json' -o \
    -name 'SmartStartUltimateDefaultCatalog.csv' -o \
    -name 'SmartStartUltimateDefaultCatalog.notes.*.json' \
    \) | grep -q .; then
    echo "❌ Forbidden Smart Start artifact copied into app bundle"
    find "$RESOURCES_DIR" -maxdepth 1 -type f \( \
        -name '*TranslationCache*' -o \
        -name '*invalid*' -o \
        -name 'SmartStartUltimateDefaultCatalog.json' -o \
        -name 'SmartStartUltimateDefaultCatalog.csv' -o \
        -name 'SmartStartUltimateDefaultCatalog.notes.*.json' \
        \) -print
    exit 1
fi

echo "==> Embedding PkgInfo..."
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> Setting permissions..."
chmod +x "$MACOS_DIR/$APP_NAME"

echo "==> Stripping debug symbols..."
strip -x "$MACOS_DIR/$APP_NAME"

echo "==> Clearing extended attributes..."
xattr -cr "$APP_BUNDLE" 2>/dev/null || true

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

echo "==> Verifying source Info.plist was not modified..."
SOURCE_INFO_PLIST_HASH_AFTER=$(shasum -a 256 "$INFO_PLIST" | awk '{print $1}')
if [ "$SOURCE_INFO_PLIST_HASH_BEFORE" != "$SOURCE_INFO_PLIST_HASH_AFTER" ]; then
    echo "❌ Build mutated tracked source file: $INFO_PLIST"
    exit 1
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
