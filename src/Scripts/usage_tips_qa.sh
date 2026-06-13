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
    r"\bprivate\s+final\s+class\s+AppGridUsageTipsNSView\s*:\s*NSView\b",
    app_grid,
    "Usage tips must be implemented as a native AppKit NSView",
)
require(
    r"enum\s+AppGridUsageTipsMetrics\s*\{(?P<body>.*?)static\s+let\s+reservedHeight\s*:\s*CGFloat\s*=\s*104",
    app_grid,
    "Usage tips overlay must reserve stable bottom space for the larger native bar",
)
require(
    r"detailScrollView\.hasHorizontalScroller\s*=\s*true",
    app_grid,
    "Long localized tip text must be horizontally scrollable in the native AppKit bar",
)
if len(re.findall(r"NSFont\.systemFont\s*\(\s*ofSize\s*:\s*24\s*,\s*weight\s*:\s*\.bold\s*\)", app_grid)) < 2:
    fail("Usage tip title/detail fonts must use the larger 24pt native AppKit style")
require(
    r"override\s+func\s+scrollWheel\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)\s*\{\s*detailScrollView\.scrollWheel\s*\(\s*with\s*:\s*event\s*\)",
    app_grid,
    "Usage tips must route wheel events to the native horizontal text scroller",
)
require(
    r"bottomContentPadding\s*:\s*shouldShowUsageTips\s*\?\s*AppGridUsageTipsMetrics\.reservedHeight\s*:\s*0",
    content_view,
    "AppGrid must reserve bottom content space when tips are visible",
)
require(
    r"usageTipsVisible\s*:\s*shouldShowUsageTips",
    content_view,
    "ContentView must pass visibility into the native AppKit usage tips bar",
)
require(
    r"selectedUsageTipIndex\s*:\s*\$selectedUsageTipIndex",
    content_view,
    "ContentView must bind usage tip selection to the native AppKit bar",
)
require(
    r"override\s+func\s+hitTest\s*\(\s*_\s+point\s*:\s*NSPoint\s*\)\s*->\s*NSView\?\s*\{(?P<body>.*?)bounds\.contains\s*\(\s*point\s*\)",
    app_grid,
    "Native usage tips bar must own hit testing so clicks do not fall through to AppGrid",
)
require(
    r"override\s+func\s+mouseDown\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)",
    app_grid,
    "Native usage tips bar must swallow mouseDown events instead of letting clicks close the grid",
)
require(
    r"private\s+final\s+class\s+AppGridUsageTipIconButton\s*:\s*NSView\b",
    app_grid,
    "Usage tip navigation controls must be native AppKit hit-testable views",
)
require(
    r"func\s+selectUsageTip\s*\(\s*offset\s*:\s*Int\s*\)",
    app_grid,
    "Usage tip navigation must update the selected tip index from AppKit",
)
require(
    r"previousButton\.action\s*=\s*\{\s*\[weak\s+self\]\s+in\s+self\?\.selectUsageTip\s*\(\s*offset\s*:\s*-1\s*\)\s*\}",
    app_grid,
    "Previous usage tip control must call the native selection handler",
)
require(
    r"nextButton\.action\s*=\s*\{\s*\[weak\s+self\]\s+in\s+self\?\.selectUsageTip\s*\(\s*offset\s*:\s*1\s*\)\s*\}",
    app_grid,
    "Next usage tip control must call the native selection handler",
)
require(
    r"override\s+func\s+mouseDown\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)\s*\{\s*action\?\(\)\s*\}",
    app_grid,
    "Native usage tip icon buttons must invoke their action directly on mouseDown",
)
require(
    r"onUsageTipIndexChange\s*\(\s*nextIndex\s*\)",
    app_grid,
    "Native usage tip selection must publish the new index back to SwiftUI state",
)
require(
    r"setUsageTipsBubbleDisabled\s*\(\s*inside\s*\)",
    app_grid,
    "Hovering usage tips must suppress lower AppGrid bubbles",
)
require(
    r"onUsageTipsHoverChange\s*\(\s*inside\s*\)",
    app_grid,
    "Hovering usage tips must notify ContentView to clear already visible SwiftUI bubbles",
)
require(
    r"private\s+func\s+handleUsageTipsHoverChange\s*\(\s*_\s+hovering\s*:\s*Bool\s*\)",
    content_view,
    "ContentView must clear existing app bubbles while the native usage tips bar is hovered",
)
if re.search(r"AppGridUsageTipsBar\s*:\s*View|usageTipNavigationButton|ScrollView\s*\(\s*\.horizontal\s*,\s*showsIndicators\s*:\s*textHovered", content_view):
    fail("usage tips must not be implemented with SwiftUI views in ContentView")
if re.search(r"Text\s*\(\s*tr\s*\(\s*tip\.(?:titleKey|detailKey)", content_view):
    fail("usage tip title/detail rendering must not use SwiftUI Text")
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
