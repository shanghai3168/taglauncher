#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_GRID_SWIFT="$ROOT_DIR/Apptag/AppGridCollectionView.swift"
APPTAG_APP_SWIFT="$ROOT_DIR/Apptag/ApptagApp.swift"
PREFERENCES_VIEW_SWIFT="$ROOT_DIR/Apptag/PreferencesView.swift"
APP_DEFAULTS_SWIFT="$ROOT_DIR/Apptag/AppDefaults.swift"
APP_GRID_THEME_SWIFT="$ROOT_DIR/Apptag/AppGridTheme.swift"
LOCALIZATION_DIR="$ROOT_DIR/Apptag/Localization"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift"
[[ -f "$APP_GRID_SWIFT" ]] || fail "missing AppGridCollectionView.swift"
[[ -f "$APPTAG_APP_SWIFT" ]] || fail "missing ApptagApp.swift"
[[ -f "$PREFERENCES_VIEW_SWIFT" ]] || fail "missing PreferencesView.swift"
[[ -f "$APP_DEFAULTS_SWIFT" ]] || fail "missing AppDefaults.swift"
[[ -f "$APP_GRID_THEME_SWIFT" ]] || fail "missing AppGridTheme.swift"
[[ -d "$LOCALIZATION_DIR" ]] || fail "missing Localization directory"

python3 - "$CONTENT_VIEW_SWIFT" "$APP_GRID_SWIFT" "$APPTAG_APP_SWIFT" "$PREFERENCES_VIEW_SWIFT" "$APP_DEFAULTS_SWIFT" "$APP_GRID_THEME_SWIFT" "$LOCALIZATION_DIR" <<'PY'
import json
import pathlib
import re
import sys

content_view = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
app_grid = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
apptag_app = pathlib.Path(sys.argv[3]).read_text(encoding="utf-8")
preferences = pathlib.Path(sys.argv[4]).read_text(encoding="utf-8")
defaults = pathlib.Path(sys.argv[5]).read_text(encoding="utf-8")
theme = pathlib.Path(sys.argv[6]).read_text(encoding="utf-8")
localization_dir = pathlib.Path(sys.argv[7])


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def require(pattern: str, source: str, message: str) -> None:
    if not re.search(pattern, source, re.S):
        fail(message)


required_keys = [
    "settings.hideUsageTips",
    "settings.hideUsageTipsDesc",
    "usageTips.previous",
    "usageTips.next",
    "usageTips.close",
]
for index in range(1, 9):
    required_keys.append(f"usageTips.tip{index}.title")
    required_keys.append(f"usageTips.tip{index}.detail")

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
for source_name, source in {
    "ContentView.swift": content_view,
    "PreferencesView.swift": preferences,
}.items():
    require(
        r'@AppStorage\("hideUsageTips"\)\s+private\s+var\s+hideUsageTips\s*=\s*AppDefaults\.hideUsageTips',
        source,
        f"{source_name} must persist hideUsageTips with AppStorage",
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
if re.search(r"AppGridUsageTipsBar\s*:\s*View|usageTipNavigationButton|Text\s*\(\s*tr\s*\(\s*tip\.", content_view):
    fail("usage tips must not be rendered by SwiftUI in ContentView")

require(
    r"enum\s+AppGridUsageTipsMetrics\s*\{(?P<body>.*?)static\s+let\s+barHeight\s*:\s*CGFloat\s*=\s*154(?P<body2>.*?)static\s+let\s+reservedHeight\s*:\s*CGFloat\s*=\s*194",
    app_grid,
    "usage tips must reserve the new design-reviewed full-width teaching banner height",
)
require(
    r"bottomContentPadding\s*:\s*shouldShowUsageTips\s*\?\s*AppGridUsageTipsMetrics\.reservedHeight\s*:\s*0",
    content_view,
    "AppGrid must reserve bottom content space when tips are visible",
)
require(
    r"usageTipsVisible\s*:\s*shouldShowUsageTips",
    content_view,
    "ContentView must pass usage tip visibility into AppGrid",
)
require(
    r"selectedUsageTipIndex\s*:\s*\$selectedUsageTipIndex",
    content_view,
    "ContentView must bind usage tip selection to AppGrid",
)
require(
    r"onHideUsageTips\s*:\s*\{\s*hideUsageTips\s*=\s*true\s*\}",
    content_view,
    "closing the native usage tips banner must persist hideUsageTips",
)
require(
    r"let\s+onHideUsageTips\s*:\s*\(\)\s*->\s*Void",
    app_grid,
    "AppGridCollectionView must accept an onHideUsageTips callback",
)
require(
    r"closeButton\.action\s*=\s*\{\s*\[weak\s+self\]\s+in\s+self\?\.hideUsageTips\(\)\s*\}",
    app_grid,
    "close button must call the native hideUsageTips handler",
)
require(
    r"coordinator\?\.onHideUsageTips\(\)",
    app_grid,
    "native hideUsageTips must call back to persisted SwiftUI state",
)

require(
    r"private\s+let\s+titlePanelView\s*=\s*NSView\(\)",
    app_grid,
    "usage tips must use a separated title panel",
)
require(
    r"private\s+let\s+titleFont\s*=\s*NSFont\.systemFont\s*\(\s*ofSize\s*:\s*25\s*,\s*weight\s*:\s*\.bold\s*\)",
    app_grid,
    "usage tips title must use the design-reviewed larger bold title font",
)
require(
    r"titlePanelWidth\s*=\s*min\s*\((?P<body>.*?)max\s*\(\s*350\s*,\s*visualFrame\.width\s*\*\s*0\.24\s*\)(?P<body2>.*?)min\s*\(\s*460\s*,\s*visualFrame\.width\s*\*\s*0\.36\s*\)",
    app_grid,
    "usage tips title panel must be wide enough for 29-language titles",
)
require(
    r"private\s+let\s+closeButton\s*=\s*AppGridUsageTipIconButton\s*\(\s*systemImage\s*:\s*\"xmark\"\s*\)",
    app_grid,
    "usage tips must provide a low-emphasis native close button",
)
require(
    r"controlZoneWidth\s*:\s*CGFloat\s*=\s*min\s*\(\s*148\s*,\s*max\s*\(\s*128\s*,\s*visualFrame\.width\s*\*\s*0\.08\s*\)\s*\)",
    app_grid,
    "usage tips must reserve a stable 128-148pt right-side control zone",
)
require(
    r"func\s+preferredWidth\s*\(\s*maxAvailableWidth\s*:\s*CGFloat\s*\)\s*->\s*CGFloat\s*\{\s*max\s*\(\s*1\s*,\s*maxAvailableWidth\s*\)\s*\}",
    app_grid,
    "usage tips visual banner must occupy the available bottom width",
)
require(
    r"dotsView\.frame\s*=\s*NSRect\s*\((?P<body>.*?)x\s*:\s*buttonsGroupMinX\s*\+\s*\(buttonsWidth\s*-\s*dotsWidth\)\s*/\s*2(?P<body2>.*?)y\s*:\s*previousButton\.frame\.maxY\s*\+\s*buttonDotsGap",
    app_grid,
    "page dots must be centered below the previous/next arrows",
)
require(
    r"detailScrollView\.frame\s*=\s*NSRect\s*\((?P<body>.*?)x\s*:\s*detailX(?P<body2>.*?)width\s*:\s*max\s*\(\s*1\s*,\s*textRight\s*-\s*detailX\s*\)",
    app_grid,
    "detail text must live in the middle reading area and stop before controls",
)
require(
    r"detailLabel\.lineBreakMode\s*=\s*\.byWordWrapping",
    app_grid,
    "detail text must wrap inside the two-line teaching banner",
)
require(
    r"detailLabel\.maximumNumberOfLines\s*=\s*2",
    app_grid,
    "detail text must keep the design-reviewed two-line layout",
)
require(
    r"detailLabel\.cell\s*=\s*AppGridCenteredMultilineTextFieldCell\s*\(\s*textCell\s*:\s*\"\"\s*\)",
    app_grid,
    "detail text must use a vertically centered multiline cell",
)
require(
    r"paragraphStyle\.minimumLineHeight\s*=\s*31(?P<body>.*?)paragraphStyle\.maximumLineHeight\s*=\s*34(?P<body2>.*?)paragraphStyle\.lineSpacing\s*=\s*6",
    app_grid,
    "detail text must use the design-reviewed line height and spacing",
)
require(
    r"detailScrollView\.hasHorizontalScroller\s*=\s*true",
    app_grid,
    "long localized tip text must remain horizontally scrollable",
)
require(
    r"formattedTipDetail\s*\(_\s+text\s*:\s*String\s*\)",
    app_grid,
    "usage tips detail text must normalize separators for display",
)
require(
    r"orderedTipDetail\s*\(_\s+text\s*:\s*String\s*\)(?P<body>.*?)map\s*\{\s*\"\\\(\$0\.offset\s*\+\s*1\)\.\s*\\\(\$0\.element\)\"\s*\}",
    app_grid,
    "multi-line usage tips detail must be rendered as an ordered list",
)
require(
    r"replacingOccurrences\s*\(\s*of\s*:\s*\"\\\\s\*\(\?:-->\|->\|>\|→\|＞\|,\)\\\\s\*\"\s*,\s*with\s*:\s*\"\\n\"",
    app_grid,
    "usage tips detail text must turn separators into hard line breaks",
)
require(
    r"updateTipIcon\s*\(\s*id\s*:\s*tip\.id\s*\)",
    app_grid,
    "usage tips must update the leading icon for each tip",
)
require(
    r"private\s+func\s+updateTipIcon\s*\(\s*id\s*:\s*Int\s*\)(?P<body>.*?)case\s+1:(?P<body2>.*?)tag\.fill(?P<body3>.*?)case\s+8:(?P<body4>.*?)note\.text",
    app_grid,
    "usage tips must vary the leading icon by tip type",
)

require(
    r"private\s+func\s+updateColors\(\)(?P<body>.*?)coordinator\?\.appGridTheme\.usesDarkGlass\s*==\s*true",
    app_grid,
    "usage tips colors must be driven by the current AppGrid theme",
)
for token in [
    r"backgroundView\.material\s*=\s*usesDarkGlass\s*\?\s*\.underWindowBackground\s*:\s*\.popover",
    r"backgroundView\.appearance\s*=\s*usesDarkGlass\s*\?\s*NSAppearance\s*\(\s*named\s*:\s*\.darkAqua\s*\)\s*:\s*nil",
    r"titlePanelView\.layer\?\.backgroundColor",
    r"usageTipAccentColor\s*\(\s*for\s*:\s*theme\s*\)",
    r"titleLabel\.textColor\s*=\s*usesDarkGlass",
    r"detailLabel\.textColor\s*=\s*usesDarkGlass",
    r"closeButton\.hoveredTintColor\s*=\s*usesDarkGlass",
    r"dotsView\.selectedColor\s*=\s*usesDarkGlass",
]:
    require(token, app_grid, f"usage tips theme token missing: {token}")
require(
    r"private\s+func\s+usageTipAccentColor\s*\(\s*for\s+theme\s*:\s*AppGridTheme\s*\)\s*->\s*NSColor(?P<body>.*?)case\s+\.pink:(?P<body2>.*?)case\s+\.colorful:",
    app_grid,
    "usage tips title color must provide per-theme readable accent colors",
)

require(
    r"var\s+usesDarkGlass\s*:\s*Bool\s*\{(?P<body>.*?)case\s+\.deepBlue,\s*\.black:(?P<body2>.*?)return\s+true",
    theme,
    "only dark/deep-black themes should use the dark glass palette",
)

for token in [
    r"usageTipsEventRegion\s*\(\s*\)\s*->\s*NSRect",
    r"usageTipsShieldView\.frame\s*=\s*usageTipsEventRegion\s*\(\s*\)",
    r"usageTipsView\.frame\s*=\s*usageTipsEventRegion\s*\(\s*\)",
    r"addSubview\s*\(\s*usageTipsShieldView\s*,\s*positioned\s*:\s*\.above\s*,\s*relativeTo\s*:\s*scrollView\s*\)",
    r"addSubview\s*\(\s*usageTipsView\s*,\s*positioned\s*:\s*\.above\s*,\s*relativeTo\s*:\s*usageTipsShieldView\s*\)",
    r"claimUsageTipsEventRegion\s*\(\s*\)",
    r"handleUsageTipsMouseDown\s*\(\s*_\s+event\s*:\s*NSEvent\s*\)\s*->\s*Bool",
]:
    require(token, app_grid, f"usage tips click-through protection missing: {token}")
require(
    r"addLocalMonitorForEvents\s*\(\s*matching\s*:\s*\[(?P<body>.*?)\.leftMouseDown(?P<body2>.*?)\.leftMouseUp(?P<body3>.*?)\.rightMouseDown(?P<body4>.*?)\.otherMouseUp",
    app_grid,
    "AppGrid host must intercept usage tips mouseDown/mouseUp events before NSCollectionView app items receive them",
)
require(
    r"triggerButtons\s*:\s*event\.type\s*==\s*\.leftMouseDown",
    app_grid,
    "usage tips monitor must only trigger page changes on left mouseDown",
)
require(
    r"func\s+handleMouseEventFromHost\s*\(\s*_\s+event\s*:\s*NSEvent\s*,\s*triggerButtons\s*:\s*Bool\s*\)\s*->\s*Bool\s*\{(?P<body>.*?)if\s+triggerButtons,\s*routeButtonClickIfNeeded\s*\(\s*event\s*\)(?P<body2>.*?)claimInteractionFocus\(\)(?P<body3>.*?)return\s+true",
    app_grid,
    "host-routed tips clicks must consume the event and only trigger buttons on hit regions",
)
if re.search(r"handleMouseEventFromHost\s*\(\s*_\s+event\s*:\s*NSEvent,\s*triggerButtons\s*:\s*Bool\s*\).*?target\.mouseDown", app_grid, re.S):
    fail("usage tips host-routed clicks must not redispatch arbitrary mouseDown events")

for token in [
    r"private\s+final\s+class\s+AppGridUsageTipIconButton\s*:\s*NSView\b",
    r"override\s+func\s+acceptsFirstMouse\s*\(\s*for\s+event\s*:\s*NSEvent\?\s*\)\s*->\s*Bool\s*\{\s*true\s*\}",
    r"override\s+func\s+isAccessibilityElement\s*\(\s*\)\s*->\s*Bool\s*\{\s*true\s*\}",
    r"override\s+func\s+accessibilityRole\s*\(\s*\)\s*->\s*NSAccessibility\.Role\?\s*\{\s*\.button\s*\}",
    r"override\s+func\s+accessibilityPerformPress\s*\(\s*\)\s*->\s*Bool\s*\{(?P<body>.*?)action\?\(\)(?P<body2>.*?)return\s+true",
    r"var\s+hoveredTintColor\s*:\s*NSColor\?",
    r"var\s+pressedTintColor\s*:\s*NSColor\?",
    r"func\s+performPressFeedback\(\)",
    r"private\s+func\s+updateIconTint\(\)",
]:
    require(token, app_grid, f"native usage tip control behavior missing: {token}")
require(
    r"previousButton\.action\s*=\s*\{\s*\[weak\s+self\]\s+in\s+self\?\.selectUsageTip\s*\(\s*offset\s*:\s*-1\s*\)\s*\}",
    app_grid,
    "previous usage tip control must page backward",
)
require(
    r"nextButton\.action\s*=\s*\{\s*\[weak\s+self\]\s+in\s+self\?\.selectUsageTip\s*\(\s*offset\s*:\s*1\s*\)\s*\}",
    app_grid,
    "next usage tip control must page forward",
)
require(
    r"routeButtonClickIfNeeded\s*\(_\s+event\s*:\s*NSEvent\s*\)(?P<body>.*?)nextButton\.frame\.insetBy(?P<body2>.*?)previousButton\.frame\.insetBy",
    app_grid,
    "usage tip arrows must only respond inside their hit regions",
)
require(
    r"override\s+func\s+keyDown\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)(?P<body>.*?)kVK_LeftArrow(?P<body2>.*?)kVK_RightArrow",
    app_grid,
    "focused native usage tips HUD must support left/right arrow keys",
)

for token in [
    r"shouldSwallowUsageTipsBackdropClick\s*\(\s*at\s+location\s*:\s*NSPoint\s*\)\s*->\s*Bool",
    r"routeUsageTipsMouseDownIfNeeded\s*\(\s*event\s*\)",
    r"findAppGridCollectionHost\s*\(\s*in\s+view\s*:\s*NSView\s*\)\s*->\s*AppGridCollectionHostView\?",
    r"AppGridUsageTipsMetrics\.reservedHeight",
    r'UserDefaults\.standard\.bool\s*\(\s*forKey\s*:\s*"hideUsageTips"\s*\)',
]:
    require(token, apptag_app, f"App window backdrop usage-tips protection missing: {token}")

for source_name, source in {
    "ContentView.swift": content_view,
    "AppGridCollectionView.swift": app_grid,
    "PreferencesView.swift": preferences,
}.items():
    if re.search(r"#available\s*\(\s*macOS\s+(?:15|26)", source):
        fail(f"{source_name} must not rely on macOS 15/26 availability for usage tips")
    if "scrollClipDisabled" in source:
        fail(f"{source_name} must avoid newer scrollClipDisabled behavior for macOS 14 compatibility")

tip_ids = [int(value) for value in re.findall(r"AppGridUsageTip\s*\(\s*id\s*:\s*(\d+)", content_view)]
if tip_ids != list(range(1, 9)):
    fail(f"usage tip IDs must be exactly 1 through 8, got {tip_ids}")
if "usageTips.tip0" in content_view:
    fail("usage tips must not expose a zero-based tip number")

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
    for tip_index in range(1, 9):
        title = data[f"usageTips.tip{tip_index}.title"]
        if re.search(r"\s*[:：]\s*$", title):
            fail(f"{path.name} usageTips.tip{tip_index}.title must not end with a colon")
    tip1_title = data["usageTips.tip1.title"]
    tip1_detail = data["usageTips.tip1.detail"]
    if path.stem == "en":
        if tip1_title != "Tip 1 - Edit tags":
            fail("en.json usageTips.tip1.title must describe editing tags")
        if "Double-click" not in tip1_detail or "tag list" not in tip1_detail:
            fail("en.json usageTips.tip1.detail must mention double-clicking a tag in the tag list")
    if path.stem == "zh-Hans":
        if tip1_title != "技巧1-编辑标签":
            fail("zh-Hans.json usageTips.tip1.title must be 编辑标签")
        if "双击标签" not in tip1_detail or "标签列表" not in tip1_detail:
            fail("zh-Hans.json usageTips.tip1.detail must mention double-clicking in the tag list")
    if path.stem == "zh-Hant":
        if tip1_title != "技巧1-編輯標籤":
            fail("zh-Hant.json usageTips.tip1.title must be 編輯標籤")
        if "雙擊標籤" not in tip1_detail or "標籤列表" not in tip1_detail:
            fail("zh-Hant.json usageTips.tip1.detail must mention double-clicking in the tag list")
    if path.stem not in {"zh-Hans", "zh-Hant"}:
        for tip_index in range(1, 9):
            detail = data[f"usageTips.tip{tip_index}.detail"]
            if any(marker in detail for marker in [">", "→", "＞"]):
                fail(f"{path.name} usageTips.tip{tip_index}.detail must use a comma line break instead of navigation markers")
            if detail.count(",") != 1:
                fail(f"{path.name} usageTips.tip{tip_index}.detail must contain exactly one comma line break")
            first, second = [part.strip() for part in detail.split(",", 1)]
            if not first or not second:
                fail(f"{path.name} usageTips.tip{tip_index}.detail must have text on both sides of the comma line break")

print("PASS usage tips QA: native split teaching banner, theme-aware glass, click protection, close action, and 29-language localizations are present")
PY
