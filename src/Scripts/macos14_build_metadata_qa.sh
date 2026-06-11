#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/build/TagLauncher.app}"
EXPECTED_MINIMUM_SYSTEM="${MACOS_DEPLOYMENT_TARGET:-14.0}"
EXPECTED_ARCHES_RAW="${EXPECTED_ARCHES:-arm64}"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/TagLauncher"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -d "$APP_BUNDLE" ]] || fail "app bundle not found: $APP_BUNDLE"
[[ -f "$INFO_PLIST" ]] || fail "Info.plist not found: $INFO_PLIST"
[[ -x "$EXECUTABLE" ]] || fail "executable not found or not executable: $EXECUTABLE"

actual_minimum_system="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO_PLIST")"
if [[ "$actual_minimum_system" != "$EXPECTED_MINIMUM_SYSTEM" ]]; then
  fail "LSMinimumSystemVersion expected $EXPECTED_MINIMUM_SYSTEM, got $actual_minimum_system"
fi

EXPECTED_ARCHES=()
while IFS= read -r arch; do
  [[ -n "$arch" ]] && EXPECTED_ARCHES+=("$arch")
done < <(tr ',' '\n' <<<"$EXPECTED_ARCHES_RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

[[ "${#EXPECTED_ARCHES[@]}" -gt 0 ]] || fail "no EXPECTED_ARCHES configured"

actual_arches="$(lipo -archs "$EXECUTABLE")"
for expected_arch in "${EXPECTED_ARCHES[@]}"; do
  case "$expected_arch" in
    arm64|x86_64) ;;
    *) fail "unsupported expected arch: $expected_arch" ;;
  esac
  if ! grep -Eq "(^|[[:space:]])${expected_arch}($|[[:space:]])" <<<"$actual_arches"; then
    fail "missing architecture $expected_arch; actual arches: $actual_arches"
  fi
done

for actual_arch in $actual_arches; do
  matched=false
  for expected_arch in "${EXPECTED_ARCHES[@]}"; do
    if [[ "$actual_arch" == "$expected_arch" ]]; then
      matched=true
      break
    fi
  done
  [[ "$matched" == true ]] || fail "unexpected architecture $actual_arch; expected: ${EXPECTED_ARCHES[*]}"
done

for arch in "${EXPECTED_ARCHES[@]}"; do
  build_info="$(vtool -arch "$arch" -show-build "$EXECUTABLE")"
  minos="$(awk '/minos/{print $2; exit}' <<<"$build_info")"
  [[ "$minos" == "$EXPECTED_MINIMUM_SYSTEM" ]] || fail "$arch LC_BUILD_VERSION minos expected $EXPECTED_MINIMUM_SYSTEM, got $minos"
done

codesign --verify --deep --strict "$APP_BUNDLE"

echo "PASS build metadata: LSMinimumSystemVersion=$actual_minimum_system minos=$EXPECTED_MINIMUM_SYSTEM arches=$actual_arches"
