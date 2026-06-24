#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG_NAV_SWIFT="$ROOT_DIR/Apptag/TagNavigationView.swift"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_SWIFT="$ROOT_DIR/Apptag/ApptagApp.swift"
PREFERENCES_SWIFT="$ROOT_DIR/Apptag/PreferencesView.swift"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$TAG_NAV_SWIFT" ]] || fail "missing TagNavigationView.swift"
[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift"
[[ -f "$APP_SWIFT" ]] || fail "missing ApptagApp.swift"
[[ -f "$PREFERENCES_SWIFT" ]] || fail "missing PreferencesView.swift"

python3 - "$TAG_NAV_SWIFT" "$CONTENT_VIEW_SWIFT" "$APP_SWIFT" "$PREFERENCES_SWIFT" <<'PY'
import pathlib
import re
import sys

tag_nav = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
content = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
app = pathlib.Path(sys.argv[3]).read_text(encoding="utf-8")
prefs = pathlib.Path(sys.argv[4]).read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def require(pattern: str, source: str, message: str) -> None:
    if not re.search(pattern, source, re.S):
        fail(message)


require(r"let\s+onDoubleActivate:\s*\(String\)\s*->\s*Void", tag_nav, "TagNavigationView must expose a double-activation callback")
require(r"private\s+var\s+onDoubleActivate:\s*\(String\)\s*->\s*Void", tag_nav, "document view must store the double-activation callback")
require(r"var\s+onDoubleActivate:\s*\(String\)\s*->\s*Void", tag_nav, "tag button must store the double-activation callback")
require(r"button\.onDoubleActivate\s*=\s*\{\s*\[weak\s+self\]\s*tagID\s+in\s+self\?\.onDoubleActivate\(tagID\)\s*\}", tag_nav, "tag button callback must be wired through the document view")

mouse_match = re.search(r"override\s+func\s+mouseDown\(with\s+event:\s+NSEvent\)\s*\{(?P<body>.*?)@objc\s+private\s+func\s+performActivation", tag_nav, re.S)
if not mouse_match:
    fail("TagNavigationButton.mouseDown must exist")
mouse_body = mouse_match.group("body")
double_click_index = mouse_body.find("event.clickCount >= 2")
reorder_guard_index = mouse_body.find("guard canReorder(item.id)")
long_press_index = mouse_body.find("longPressDuration: TimeInterval = 0.35")
if double_click_index < 0:
    fail("mouseDown must check for double-click")
if reorder_guard_index < 0:
    fail("mouseDown must keep the reorder guard")
if long_press_index < 0:
    fail("mouseDown must preserve the 0.35s long-press reorder threshold")
if not (double_click_index < reorder_guard_index < long_press_index):
    fail("double-click must be handled before entering reorder/long-press logic")
require(r"onDoubleActivate\(item\.id\)", mouse_body, "double-click must call onDoubleActivate with the tag id")
require(r"onActivate\(item\.id\)", mouse_body, "single-click activation must remain in mouseDown")

require(r"tagLauncherPreferencesTabRequested", content, "shared notification for settings tab switching must exist")
require(r"enum\s+SettingsTabTarget(?P<body>.*?)userInfoKey\s*=\s*\"tab\"(?P<body2>.*?)tags\s*=\s*\"tags\"", content, "settings tab target constants must exist")
require(r"onDoubleActivate:\s*\{\s*_\s+in\s*openTagSettingsFromNavigation\(\)\s*\}", content, "AppKit tag navigation must open tag settings on double-click")
require(r"private\s+func\s+openTagSettingsFromNavigation\(\)\s*\{(?P<body>.*?)tagLauncherOpenPreferencesRequested(?P<body2>.*?)SettingsTabTarget\.tags", content, "double-click helper must request Preferences Tags tab")
require(r"onActivate:\s*\{\s*tagID\s+in\s*activateTagNavigation\(tagID\)\s*\}", content, "single-click tag activation must still scroll")
require(r"handleTagNavigationHover\(tagID,\s*active:\s*active\)", content, "tag hover behavior must remain wired")

require(r"preferencesTabTarget\(from:\s*notification\)", app, "AppDelegate observer must read the requested preferences tab")
require(r"openPreferences\(targetTab:\s*Self\.preferencesTabTarget\(from:\s*notification\)\)", app, "preferences request must pass the target tab into openPreferences")
require(r"private\s+func\s+openPreferences\(targetTab:\s*String\?\)", app, "AppDelegate must have a target-tab preferences opener")
require(r"PreferencesView\(initialTabRawValue:\s*targetTab\)", app, "new settings windows must open on the requested tab")
require(r"requestPreferencesTabSelection\(targetTab\)", app, "existing settings windows must switch to the requested tab")
require(r"tagLauncherPreferencesTabRequested", app, "existing settings window tab switch must use the shared notification")

require(r"init\(initialTabRawValue:\s*String\?\s*=\s*nil\)", prefs, "PreferencesView must accept an initial tab")
require(r"SettingsTab\.init\(rawValue:\s*\)", prefs, "PreferencesView initial tab must be validated through SettingsTab raw values")
require(r"private\s+func\s+selectTab\(rawValue:\s*String\?\)", prefs, "PreferencesView must expose an internal tab-selection helper")
require(r"publisher\(for:\s*\.tagLauncherPreferencesTabRequested\)", prefs, "PreferencesView must listen for tab switch requests")

print("PASS: double-click tag navigation opens Preferences Tags tab without removing single-click, hover, or long-press wiring")
PY
