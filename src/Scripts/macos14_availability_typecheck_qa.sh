#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/Apptag"
MACOS_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET:-14.0}"
TARGET_ARCHES_RAW="${TARGET_ARCHES:-arm64}"

if [[ ! "$MACOS_DEPLOYMENT_TARGET" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "FAIL: invalid MACOS_DEPLOYMENT_TARGET: $MACOS_DEPLOYMENT_TARGET" >&2
  exit 1
fi

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
MODULE_CACHE_DIR="${MODULE_CACHE_DIR:-${TMPDIR:-/tmp}/taglauncher-macos14-typecheck-cache}"
mkdir -p "$MODULE_CACHE_DIR"

SWIFT_FILES=()
while IFS= read -r file; do
  SWIFT_FILES+=("$file")
done < <(find "$SWIFT_DIR" -name '*.swift' -print | sort)

if [[ "${#SWIFT_FILES[@]}" -eq 0 ]]; then
  echo "FAIL: no Swift files found under $SWIFT_DIR" >&2
  exit 1
fi

TARGET_ARCHES=()
while IFS= read -r arch; do
  [[ -n "$arch" ]] && TARGET_ARCHES+=("$arch")
done < <(tr ',' '\n' <<<"$TARGET_ARCHES_RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

for arch in "${TARGET_ARCHES[@]}"; do
  case "$arch" in
    arm64|x86_64) ;;
    *)
      echo "FAIL: unsupported target arch: $arch" >&2
      exit 1
      ;;
  esac

  target="${arch}-apple-macosx${MACOS_DEPLOYMENT_TARGET}"
  echo "==> Typechecking for $target"
  swiftc -typecheck \
    -framework AppKit \
    -framework SwiftUI \
    -framework Carbon \
    -framework CoreServices \
    -lcompression \
    -sdk "$SDK_PATH" \
    -target "$target" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    "${SWIFT_FILES[@]}"
done

echo "PASS macOS $MACOS_DEPLOYMENT_TARGET availability typecheck: ${TARGET_ARCHES[*]}"
