#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/Apptag"
MACOS_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET:-14.0}"
TARGET_ARCHES_RAW="${TARGET_ARCHES:-arm64}"
SWIFTC="${SWIFTC:-swiftc}"

if [[ ! "$MACOS_DEPLOYMENT_TARGET" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "FAIL: invalid MACOS_DEPLOYMENT_TARGET: $MACOS_DEPLOYMENT_TARGET" >&2
  exit 1
fi

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
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

select_macos_sdk() {
  local target="$1"
  local explicit_sdk="${SDK_PATH_OVERRIDE:-${SDKROOT:-}}"
  if [[ -n "$explicit_sdk" ]]; then
    if [[ ! -d "$explicit_sdk" ]]; then
      echo "FAIL: explicit SDK path does not exist: $explicit_sdk" >&2
      return 1
    fi
    echo "$explicit_sdk"
    return 0
  fi

  local default_sdk="$SDK_PATH"
  local sdk_candidates
  sdk_candidates="$(python3 - "$default_sdk" <<'PY'
import glob
import os
import re
import sys

seen = set()
candidates = []

def add(path):
    if not path:
        return
    real = os.path.realpath(path)
    if os.path.isdir(path) and real not in seen:
        seen.add(real)
        candidates.append(path)

if len(sys.argv) > 1:
    add(sys.argv[1])

for path in glob.glob("/Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk"):
    add(path)

for path in glob.glob("/Applications/Xcode*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.sdk"):
    add(path)

def version_key(path):
    name = os.path.basename(path)
    match = re.search(r"MacOSX(\d+(?:\.\d+)*)\.sdk$", name)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("."))

default_real = os.path.realpath(sys.argv[1]) if len(sys.argv) > 1 else ""
rest = [p for p in candidates if os.path.realpath(p) != default_real]
rest.sort(key=version_key, reverse=True)
ordered = [p for p in candidates if os.path.realpath(p) == default_real] + rest
for path in ordered:
    print(path)
PY
)"

  while IFS= read -r sdk; do
    [[ -n "$sdk" ]] || continue
    if printf 'import Swift\n' | "$SWIFTC" -typecheck -sdk "$sdk" -target "$target" - >/dev/null 2>&1; then
      echo "$sdk"
      return 0
    fi
  done <<< "$sdk_candidates"

  echo "FAIL: no installed macOS SDK is compatible with current swiftc for target $target" >&2
  echo "swiftc: $("$SWIFTC" --version | head -n 1)" >&2
  echo "default SDK: $default_sdk" >&2
  return 1
}

for arch in "${TARGET_ARCHES[@]}"; do
  case "$arch" in
    arm64|x86_64) ;;
    *)
      echo "FAIL: unsupported target arch: $arch" >&2
      exit 1
      ;;
  esac

  target="${arch}-apple-macosx${MACOS_DEPLOYMENT_TARGET}"
  SDK_PATH="$(select_macos_sdk "$target")"
  echo "==> Typechecking for $target"
  echo "==> Using SDK: $SDK_PATH"
  echo "==> Using Swift compiler: $SWIFTC"
  "$SWIFTC" -typecheck \
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
