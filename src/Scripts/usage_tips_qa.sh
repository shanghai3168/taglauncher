#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_GRID_SWIFT="$ROOT_DIR/Apptag/AppGridCollectionView.swift"
APPTAG_APP_SWIFT="$ROOT_DIR/Apptag/ApptagApp.swift"
PREFERENCES_VIEW_SWIFT="$ROOT_DIR/Apptag/PreferencesView.swift"
APP_DEFAULTS_SWIFT="$ROOT_DIR/Apptag/AppDefaults.swift"
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
[[ -d "$LOCALIZATION_DIR" ]] || fail "missing Localization directory"

python3 - "$CONTENT_VIEW_SWIFT" "$APP_GRID_SWIFT" "$APPTAG_APP_SWIFT" "$PREFERENCES_VIEW_SWIFT" "$APP_DEFAULTS_SWIFT" "$LOCALIZATION_DIR" <<'PY'
import json
import pathlib
import re
import sys

content_view = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
app_grid = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
apptag_app = pathlib.Path(sys.argv[3]).read_text(encoding="utf-8")
preferences = pathlib.Path(sys.argv[4]).read_text(encoding="utf-8")
defaults = pathlib.Path(sys.argv[5]).read_text(encoding="utf-8")
localization_dir = pathlib.Path(sys.argv[6])

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
    r"enum\s+AppGridUsageTipsMetrics\s*\{(?P<body>.*?)static\s+let\s+barHeight\s*:\s*CGFloat\s*=\s*136(?P<body2>.*?)static\s+let\s+reservedHeight\s*:\s*CGFloat\s*=\s*176",
    app_grid,
    "Usage tips overlay must reserve a design-reviewed multi-line bottom space for the native HUD bar",
)
require(
    r"NSVisualEffectView\s*\(",
    app_grid,
    "Usage tips must use a native macOS visual effect surface instead of split black/white blocks",
)
require(
    r'systemSymbolName\s*:\s*"lightbulb\.fill"',
    app_grid,
    "Usage tips HUD must include a compact native guidance icon",
)
require(
    r"preferredWidth\s*\(\s*maxAvailableWidth\s*:\s*CGFloat\s*\)",
    app_grid,
    "Usage tips HUD must be content-adaptive instead of stretched across the full AppGrid",
)
if re.search(r"static\s+let\s+maxWidth\s*:\s*CGFloat", app_grid):
    fail("Usage tips HUD must not use a hard maximum width that truncates localized titles")
require(
    r"fullTitleWidth\s*=\s*ceil\s*\(\s*titleLabel\.attributedStringValue\.size\(\)\.width\s*\)",
    app_grid,
    "Usage tips layout must measure the localized title width instead of using a fixed title column",
)
require(
    r"configureLabel\s*\(\s*titleLabel\s*,\s*font\s*:\s*titleFont\s*,\s*lineBreakMode\s*:\s*\.byClipping\s*\)",
    app_grid,
    "Usage tip titles must not use tail truncation ellipses",
)
if re.search(r"configureLabel\s*\(\s*titleLabel\s*,\s*font\s*:\s*titleFont\s*,\s*lineBreakMode\s*:\s*\.byTruncatingTail\s*\)", app_grid):
    fail("Usage tip titles must not be configured with byTruncatingTail")
require(
    r"relayoutUsageTipsAfterContentChange\s*\(\s*\)",
    app_grid,
    "Usage tips must ask the host to recompute width after localized text changes",
)
require(
    r"controlZoneWidth\s*:\s*CGFloat\s*=\s*176",
    app_grid,
    "Usage tips layout must reserve a fixed right-side control zone",
)
require(
    r"availableTextWidth\s*=\s*max\s*\(\s*1\s*,\s*textRight\s*-\s*titleX\s*\)",
    app_grid,
    "Usage tips layout must allocate text from actual available AppGrid width",
)
require(
    r"dotsView\.frame\s*=\s*NSRect\s*\((?P<body>.*?)x\s*:\s*buttonsGroupMinX\s*\+\s*\(buttonsWidth\s*-\s*dotsWidth\)\s*/\s*2(?P<body2>.*?)y\s*:\s*previousButton\.frame\.maxY\s*\+\s*buttonDotsGap",
    app_grid,
    "Usage tips page dots must sit centered below the previous/next arrow buttons",
)
require(
    r"detailRight\s*=\s*textRight",
    app_grid,
    "Usage tips detail text must stop before the fixed right-side arrow control zone",
)
require(
    r"configureDetailLabel\s*\(\s*\)(?P<body>.*?)detailLabel\.lineBreakMode\s*=\s*\.byWordWrapping",
    app_grid,
    "Usage tip detail text must wrap naturally inside the reserved text column",
)
require(
    r"detailLabel\.maximumNumberOfLines\s*=\s*2",
    app_grid,
    "Usage tip detail text must use the design-reviewed two-line body layout",
)
require(
    r"return\s+min\s*\(\s*maxAvailableWidth\s*,\s*preferredWidth\s*\)",
    app_grid,
    "Usage tips preferred width must expand up to available AppGrid width for long localizations",
)
require(
    r"detailScrollView\.hasHorizontalScroller\s*=\s*true",
    app_grid,
    "Long localized tip text must be horizontally scrollable in the native AppKit bar",
)
if len(re.findall(r"NSFont\.systemFont\s*\(\s*ofSize\s*:\s*24\s*,\s*weight\s*:\s*\.(?:semibold|regular)\s*\)", app_grid)) < 2:
    fail("Usage tip title/detail fonts must use readable 24pt native HUD typography")
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
    r"override\s+func\s+hitTest\s*\(\s*_\s+point\s*:\s*NSPoint\s*\)\s*->\s*NSView\?\s*\{(?P<body>.*?)usageTipsView\.frame\.contains\s*\(\s*point\s*\)",
    app_grid,
    "AppGrid host must prioritize the native usage tips hit-test region above the collection view",
)
require(
    r"usageTipsEventRegion\s*\(\s*\)\s*->\s*NSRect",
    app_grid,
    "AppGrid host must reserve a full bottom event region for tips so clicks cannot pass through",
)
require(
    r"private\s+final\s+class\s+AppGridUsageTipsShieldView\s*:\s*NSView\b",
    app_grid,
    "AppGrid must use a native transparent shield view for the full bottom tips event region",
)
require(
    r"usageTipsShieldView\.frame\s*=\s*usageTipsEventRegion\s*\(\s*\)",
    app_grid,
    "Usage tips shield must cover the full bottom event region, not just the visible HUD",
)
require(
    r"usageTipsView\.frame\s*=\s*usageTipsEventRegion\s*\(\s*\)",
    app_grid,
    "Usage tips HUD hit-test view itself must cover the full bottom event region",
)
require(
    r"configureVisualLayout\s*\(\s*width\s*:\s*CGFloat\s*,\s*height\s*:\s*CGFloat\s*,\s*bottomMargin\s*:\s*CGFloat\s*\)",
    app_grid,
    "Usage tips must separate full hit-test coverage from the centered visual HUD frame",
)
require(
    r"currentVisualFrame\s*\(\s*\)\s*->\s*NSRect",
    app_grid,
    "Usage tips must compute a centered visual frame inside the full bottom hit-test region",
)
require(
    r"addSubview\s*\(\s*usageTipsShieldView\s*,\s*positioned\s*:\s*\.above\s*,\s*relativeTo\s*:\s*scrollView\s*\)",
    app_grid,
    "Usage tips shield must sit above the AppGrid collection scroll view",
)
require(
    r"addSubview\s*\(\s*usageTipsView\s*,\s*positioned\s*:\s*\.above\s*,\s*relativeTo\s*:\s*usageTipsShieldView\s*\)",
    app_grid,
    "Visible usage tips HUD must sit above the transparent event shield",
)
require(
    r"claimUsageTipsEventRegion\s*\(\s*\)",
    app_grid,
    "AppGrid host must claim bottom tips events and suppress lower bubbles",
)
require(
    r"handleUsageTipsMouseDown\s*\(\s*_\s+event\s*:\s*NSEvent\s*\)\s*->\s*Bool",
    app_grid,
    "AppGrid host must expose a native AppKit event router for usage tips clicks",
)
require(
    r"addLocalMonitorForEvents\s*\(\s*matching\s*:\s*\[(?P<body>.*?)\.leftMouseDown(?P<body2>.*?)\.leftMouseUp(?P<body3>.*?)\.rightMouseDown(?P<body4>.*?)\.otherMouseUp",
    app_grid,
    "AppGrid host must intercept usage tips mouseDown/mouseUp events before NSCollectionView app items receive them",
)
require(
    r"\.leftMouseUp(?P<body>.*?)\.rightMouseUp(?P<body2>.*?)\.otherMouseUp",
    app_grid,
    "AppGrid host must also swallow mouseUp events in the usage tips region so app icons below cannot open on release",
)
require(
    r"triggerButtons\s*:\s*event\.type\s*==\s*\.leftMouseDown",
    app_grid,
    "Usage tips monitor must only trigger paging on left mouseDown, not on mouseUp or right/other clicks",
)
require(
    r"usageTipsHostPoint\s*\(\s*for\s+event\s*:\s*NSEvent\s*\)\s*->\s*NSPoint",
    app_grid,
    "Usage tips mouse monitor must resolve the event position through the AppGrid host",
)
require(
    r"window\.convertPoint\s*\(\s*fromScreen\s*:\s*NSEvent\.mouseLocation\s*\)",
    app_grid,
    "Usage tips hit testing must fall back to current screen mouse location when event.window is unreliable",
)
require(
    r"self\.handleUsageTipsMouseEvent\s*\(\s*event\s*,(?P<body>.*?)triggerButtons\s*:\s*event\.type\s*==\s*\.leftMouseDown(?P<body2>.*?)return\s+nil",
    app_grid,
    "Usage tips mouse monitor must swallow handled bottom-tip events so app icons below cannot open",
)
require(
    r"removeUsageTipsMouseMonitor\s*\(\s*\)",
    app_grid,
    "Usage tips mouse monitor must be removed when the AppGrid host leaves its window",
)
require(
    r"func\s+handleMouseEventFromHost\s*\(\s*_\s+event\s*:\s*NSEvent\s*,\s*triggerButtons\s*:\s*Bool\s*\)\s*->\s*Bool\s*\{(?P<body>.*?)if\s+triggerButtons\s*,\s*routeButtonClickIfNeeded\s*\(\s*event\s*\)(?P<body2>.*?)claimInteractionFocus\s*\(\s*\)(?P<body3>.*?)return\s+true",
    app_grid,
    "Usage tips host-routed clicks must only trigger page changes on arrow hit regions and otherwise only consume the event",
)
if re.search(r"handleMouseEventFromHost\s*\(\s*_\s+event\s*:\s*NSEvent\s*,\s*triggerButtons\s*:\s*Bool\s*\)\s*->\s*Bool\s*\{(?P<body>.*?)target\.mouseDown", app_grid, re.S):
    fail("Usage tips host-routed clicks must not redispatch arbitrary mouseDown events that can pierce to app icons")
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
    r"private\s+final\s+class\s+AppGridDecorativeImageView\s*:\s*NSImageView\b(?P<body>.*?)override\s+func\s+hitTest\s*\(\s*_\s+point\s*:\s*NSPoint\s*\)\s*->\s*NSView\?\s*\{\s*nil\s*\}",
    app_grid,
    "Usage tip icon images must not steal hit testing from their parent AppKit controls",
)
require(
    r"private\s+final\s+class\s+AppGridUsageTipIconButton\s*:\s*NSView\b(?P<body>.*?)acceptsFirstMouse\s*\(\s*for\s+event\s*:\s*NSEvent\?\s*\)\s*->\s*Bool\s*\{\s*true\s*\}",
    app_grid,
    "Usage tip navigation controls must accept first mouse clicks in the floating overlay",
)
require(
    r"override\s+func\s+isAccessibilityElement\s*\(\s*\)\s*->\s*Bool\s*\{\s*true\s*\}",
    app_grid,
    "Usage tip navigation controls must be exposed as accessibility elements",
)
require(
    r"override\s+func\s+accessibilityRole\s*\(\s*\)\s*->\s*NSAccessibility\.Role\?\s*\{\s*\.button\s*\}",
    app_grid,
    "Usage tip navigation controls must expose the AX button role",
)
require(
    r"override\s+func\s+accessibilityPerformPress\s*\(\s*\)\s*->\s*Bool\s*\{(?P<body>.*?)action\?\(\)(?P<body2>.*?)return\s+true",
    app_grid,
    "Usage tip navigation controls must support AX press actions",
)
require(
    r"override\s+var\s+mouseDownCanMoveWindow\s*:\s*Bool\s*\{\s*false\s*\}",
    app_grid,
    "Usage tips hit-test views must not let mouseDown move or dismiss the overlay window",
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
    r"override\s+func\s+mouseDown\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)\s*\{(?P<body>.*?)action\?\(\)",
    app_grid,
    "Native usage tip icon buttons must invoke their action directly on mouseDown",
)
require(
    r"onUsageTipIndexChange\s*\(\s*nextIndex\s*\)",
    app_grid,
    "Native usage tip selection must publish the new index back to SwiftUI state",
)
require(
    r"override\s+func\s+keyDown\s*\(\s*with\s+event\s*:\s*NSEvent\s*\)\s*\{(?P<body>.*?)kVK_LeftArrow(?P<body2>.*?)kVK_RightArrow",
    app_grid,
    "Focused native usage tips HUD must support left/right arrow key switching",
)
require(
    r"formattedTipDetail\s*\(_\s+text\s*:\s*String\s*\)",
    app_grid,
    "Usage tips detail text must normalize separators for display",
)
require(
    r"replacingOccurrences\s*\(\s*of\s*:\s*\"\\\\s\*\(\?:-->\|->\|>\|→\|＞\)\\\\s\*\"\s*,\s*with\s*:\s*\"\\n\"",
    app_grid,
    "Usage tips detail text must convert -->, ->, and > separators into hard line breaks",
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
    r"shouldSwallowUsageTipsBackdropClick\s*\(\s*at\s+location\s*:\s*NSPoint\s*\)\s*->\s*Bool",
    apptag_app,
    "DismissibleHostingView must not treat bottom usage tips clicks as backdrop taps",
)
require(
    r"routeUsageTipsMouseDownIfNeeded\s*\(\s*event\s*\)",
    apptag_app,
    "DismissibleHostingView must forward bottom usage tips clicks to native AppKit controls before swallowing",
)
require(
    r"findAppGridCollectionHost\s*\(\s*in\s+view\s*:\s*NSView\s*\)\s*->\s*AppGridCollectionHostView\?",
    apptag_app,
    "DismissibleHostingView must locate the native AppGrid host for usage tips event forwarding",
)
require(
    r"AppGridUsageTipsMetrics\.reservedHeight",
    apptag_app,
    "Backdrop usage tips guard must match the native AppGrid reserved height",
)
require(
    r'UserDefaults\.standard\.bool\s*\(\s*forKey\s*:\s*"hideUsageTips"\s*\)',
    apptag_app,
    "Backdrop usage tips guard must respect the hide usage tips setting",
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
