#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_GRID_SWIFT="$ROOT_DIR/Apptag/AppGridCollectionView.swift"
PREFERENCES_VIEW_SWIFT="$ROOT_DIR/Apptag/PreferencesView.swift"
APP_DEFAULTS_SWIFT="$ROOT_DIR/Apptag/AppDefaults.swift"
LOCALIZATION_DIR="$ROOT_DIR/Apptag/Localization"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift"
[[ -f "$APP_GRID_SWIFT" ]] || fail "missing AppGridCollectionView.swift"
[[ -f "$PREFERENCES_VIEW_SWIFT" ]] || fail "missing PreferencesView.swift"
[[ -f "$APP_DEFAULTS_SWIFT" ]] || fail "missing AppDefaults.swift"
[[ -d "$LOCALIZATION_DIR" ]] || fail "missing Localization directory"

python3 - "$CONTENT_VIEW_SWIFT" "$APP_GRID_SWIFT" "$PREFERENCES_VIEW_SWIFT" "$APP_DEFAULTS_SWIFT" "$LOCALIZATION_DIR" <<'PY'
import json
import pathlib
import re
import sys

content_view = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
app_grid = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
preferences = pathlib.Path(sys.argv[3]).read_text(encoding="utf-8")
defaults = pathlib.Path(sys.argv[4]).read_text(encoding="utf-8")
localization_dir = pathlib.Path(sys.argv[5])

required_keys = [
    "settings.hideUsageTips",
    "settings.hideUsageTipsDesc",
    "usageTips.previous",
    "usageTips.next",
]
for index in range(1, 9):
    required_keys.append(f"usageTips.tip{index}.title")
    required_keys.append(f"usageTips.tip{index}.detail")


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def require(pattern: str, source: str, message: str) -> None:
    if not re.search(pattern, source, re.S):
        fail(message)


require(
    r"static\s+let\s+hideUsageTips\s*=\s*false",
    defaults,
    "usage tips must default to visible for existing and new users",
)
require(
    r'"hideUsageTips"\s*:\s*hideUsageTips',
    defaults,
    "AppDefaults.register must register hideUsageTips",
)
require(
    r'@AppStorage\("hideUsageTips"\)\s+private\s+var\s+hideUsageTips\s*=\s*AppDefaults\.hideUsageTips',
    content_view,
    "ContentView must observe hideUsageTips with AppStorage",
)
require(
    r'@AppStorage\("hideUsageTips"\)\s+private\s+var\s+hideUsageTips\s*=\s*AppDefaults\.hideUsageTips',
    preferences,
    "PreferencesView must persist hideUsageTips with AppStorage",
)
require(
    r'Toggle\s*\(\s*tr\("settings\.hideUsageTips"\)\s*,\s*isOn\s*:\s*\$hideUsageTips\s*\)',
    preferences,
    "General settings must expose a Hide usage tips toggle",
)
require(
    r"\bprivate\s+struct\s+AppGridUsageTipsBar\s*:\s*View\b",
    content_view,
    "ContentView must define the app grid usage tips overlay",
)
require(
    r"static\s+let\s+reservedHeight\s*:\s*CGFloat\s*=\s*64",
    content_view,
    "Usage tips overlay must reserve stable bottom space",
)
require(
    r"ScrollView\s*\(\s*\.horizontal\s*,\s*showsIndicators\s*:\s*textHovered\s*\)",
    content_view,
    "Long localized tip text must be horizontally scrollable on hover",
)
require(
    r"\.onHover\s*\{\s*textHovered\s*=\s*\$0\s*\}",
    content_view,
    "Usage tip text must react to hover so long text can be inspected",
)
require(
    r"bottomContentPadding\s*:\s*shouldShowUsageTips\s*\?\s*AppGridUsageTipsBar\.reservedHeight\s*:\s*0",
    content_view,
    "AppGrid must reserve bottom content space when tips are visible",
)
require(
    r"\.allowsHitTesting\s*\(\s*!dragModeActive\s*\)",
    content_view,
    "Usage tips overlay must stop intercepting drag/drop while app drag mode is active",
)
require(
    r"let\s+bottomContentPadding\s*:\s*CGFloat",
    app_grid,
    "AppGridCollectionView must accept bottom content padding",
)
if '"bottom=\\(Int(bottomContentPadding.rounded()))"' not in app_grid:
    fail("AppGrid layout signature must include bottom content padding")
require(
    r"\+\s*max\s*\(\s*0\s*,\s*bottomContentPadding\s*\)",
    app_grid,
    "AppGrid layout plans must add bottom content padding to content height",
)

tip_ids = [int(value) for value in re.findall(r"AppGridUsageTip\s*\(\s*id\s*:\s*(\d+)", content_view)]
if tip_ids != list(range(1, 9)):
    fail(f"usage tip IDs must be exactly 1 through 8, got {tip_ids}")
if "usageTips.tip0" in content_view:
    fail("usage tips must not expose a zero-based tip number")

for source_name, source in {
    "ContentView.swift": content_view,
    "AppGridCollectionView.swift": app_grid,
    "PreferencesView.swift": preferences,
}.items():
    if re.search(r"#available\s*\(\s*macOS\s+(?:15|26)", source):
        fail(f"{source_name} must not rely on macOS 15/26 availability for usage tips")
    if "scrollClipDisabled" in source:
        fail(f"{source_name} must avoid newer scrollClipDisabled behavior for macOS 14 compatibility")

json_files = sorted(localization_dir.glob("*.json"))
if len(json_files) != 29:
    fail(f"expected 29 localization files, found {len(json_files)}")

for path in json_files:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"{path.name} is not valid JSON: {exc}")
    missing = [key for key in required_keys if not data.get(key)]
    if missing:
        fail(f"{path.name} missing usage tip localization keys: {', '.join(missing)}")

print("PASS usage tips QA: overlay, hide setting, macOS 14-safe implementation, and 29-language localizations are present")
PY
