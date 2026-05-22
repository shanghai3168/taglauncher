#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/build/TagLauncher.app"
APP_PROCESS="TagLauncher"
LAUNCH_AGENT_LABEL="com.taglauncher.app"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"
USER_GUI_DOMAIN="gui/$(id -u)"
RESTORE_LAUNCH_AGENT=false
CLICK_TOOL="${CLICK_TOOL:-$(command -v cliclick || true)}"

if [[ -z "$CLICK_TOOL" ]]; then
  echo "FAIL: cliclick is required for window-position click checks." >&2
  exit 2
fi

log() {
  printf '%s\n' "$*"
}

send_keycode() {
  local keycode="$1"
  local modifiers="${2:-}"
  if [[ -n "$modifiers" ]]; then
    osascript -e "tell application \"System Events\" to key code $keycode using {$modifiers}"
  else
    osascript -e "tell application \"System Events\" to key code $keycode"
  fi
}

send_main_hotkey() {
  osascript -e 'tell application "System Events" to keystroke space using {option down, shift down}'
}

send_cmd_comma() {
  osascript -e 'tell application "System Events" to keystroke "," using {command down}'
}

send_cmd_w() {
  osascript -e 'tell application "System Events" to keystroke "w" using {command down}'
}

show_overlay_from_app_menu() {
  osascript <<'OSA'
tell application "System Events"
  tell process "TagLauncher"
    repeat 50 times
      set frontmost to true
      delay 0.2
      repeat with itemRef in menu items of menu 1 of menu bar item "TagLauncher" of menu bar 1
        try
          set itemName to name of itemRef as text
          if itemName contains "显示应用列表" or itemName contains "Show" then
            click itemRef
            return
          end if
        end try
      end repeat
    end repeat
    error "TagLauncher Show App List menu item did not become available"
  end tell
end tell
OSA
}

cliclick_coord() {
  local value="$1"
  if [[ "$value" == -* ]]; then
    printf '=%s' "$value"
  else
    printf '%s' "$value"
  fi
}

click_xy() {
  local x="$1"
  local y="$2"
  "$CLICK_TOOL" c:"$(cliclick_coord "$x")","$(cliclick_coord "$y")"
}

move_xy() {
  local x="$1"
  local y="$2"
  "$CLICK_TOOL" m:"$(cliclick_coord "$x")","$(cliclick_coord "$y")"
}

cleanup() {
  osascript -e 'tell application "System Events" to key code 53' >/dev/null 2>&1 || true
  sleep 0.2
  osascript -e 'tell application "System Events" to key code 53' >/dev/null 2>&1 || true
  kill_all_taglauncher_instances
  if [[ "$RESTORE_LAUNCH_AGENT" == true && -f "$LAUNCH_AGENT_PLIST" ]]; then
    launchctl bootstrap "$USER_GUI_DOMAIN" "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

kill_all_taglauncher_instances() {
  local pids
  pids="$(pgrep -f '/TagLauncher.app/Contents/MacOS/TagLauncher' || true)"
  if [[ -n "$pids" ]]; then
    kill $pids >/dev/null 2>&1 || true
    sleep 0.4
  fi
  pids="$(pgrep -f '/TagLauncher.app/Contents/MacOS/TagLauncher' || true)"
  if [[ -n "$pids" ]]; then
    kill -9 $pids >/dev/null 2>&1 || true
  fi
}

is_qa_app_only_running() {
  local lines
  lines="$(pgrep -fl '/TagLauncher.app/Contents/MacOS/TagLauncher' || true)"
  [[ -n "$lines" ]] || return 1
  while IFS= read -r line; do
    [[ "$line" == *"$APP_BUNDLE/Contents/MacOS/TagLauncher"* ]] || return 1
  done <<<"$lines"
}

prepare_isolated_app_instance() {
  if launchctl print "$USER_GUI_DOMAIN/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
    RESTORE_LAUNCH_AGENT=true
    launchctl bootout "$USER_GUI_DOMAIN/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
  fi

  kill_all_taglauncher_instances
  open -n "$APP_BUNDLE"
  sleep 2.5

  if ! is_qa_app_only_running; then
    echo "FAIL: expected only QA build TagLauncher instance to be running" >&2
    pgrep -fl '/TagLauncher.app/Contents/MacOS/TagLauncher' >&2 || true
    exit 1
  fi
}

assert_swift="$(mktemp -t taglauncher-window-assert.XXXXXX.swift)"
coords_swift="$(mktemp -t taglauncher-window-coords.XXXXXX.swift)"
screens_swift="$(mktemp -t taglauncher-screens.XXXXXX.swift)"
trap 'rm -f "$assert_swift" "$coords_swift" "$screens_swift"; cleanup' EXIT

cat >"$assert_swift" <<'SWIFT'
import AppKit
import CoreGraphics
import Foundation

struct WindowInfo {
    let owner: String
    let name: String
    let layer: Int
    let bounds: NSDictionary
}

func allWindows() -> [WindowInfo] {
    let raw = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    return raw.map {
        WindowInfo(
            owner: $0[kCGWindowOwnerName as String] as? String ?? "",
            name: $0[kCGWindowName as String] as? String ?? "",
            layer: $0[kCGWindowLayer as String] as? Int ?? -999,
            bounds: $0[kCGWindowBounds as String] as? NSDictionary ?? [:]
        )
    }
}

func dumpRelevantWindows() {
    fputs("---- relevant on-screen windows ----\n", stderr)
    for (index, window) in allWindows().enumerated() {
        let isRelevant = window.owner == "TagLauncher"
            || window.owner == "Window Server"
            || window.owner == "Dock"
            || window.owner == "loginwindow"
        guard isRelevant else { continue }
        fputs("#\(index) owner=\(window.owner) name=\(window.name) layer=\(window.layer) bounds=\(window.bounds)\n", stderr)
    }
    fputs("------------------------------------\n", stderr)
}

func fail(_ message: String) -> Never {
    fputs("FAIL: \(message)\n", stderr)
    dumpRelevantWindows()
    exit(1)
}

func tagWindows(_ windows: [WindowInfo]) -> [WindowInfo] {
    windows.filter { $0.owner == "TagLauncher" }
}

func assertTagLayer(_ tag: [WindowInfo]) {
    for window in tag where window.layer != 23 {
        fail("TagLauncher window has unexpected layer \(window.layer); expected 23")
    }
}

let mode = CommandLine.arguments.dropFirst().first ?? ""
let windows = allWindows()
let tag = tagWindows(windows)

switch mode {
case "overlay":
    guard tag.count == 1 else { fail("overlay expected 1 TagLauncher window, got \(tag.count)") }
    assertTagLayer(tag)
    let menubarLayer = windows.first { $0.owner == "Window Server" && $0.name == "Menubar" }?.layer
    guard menubarLayer == 24 else { fail("menubar layer expected 24, got \(String(describing: menubarLayer))") }
    let dockWindows = windows.filter { $0.owner == "Dock" }
    guard dockWindows.isEmpty else { fail("Dock should be hidden while overlay is visible; found \(dockWindows.count) Dock windows") }
    print("PASS overlay: tagLayer=\(tag[0].layer) menubarLayer=24 dockWindows=0")

case "settings":
    guard tag.count == 2 else { fail("settings expected 2 TagLauncher windows, got \(tag.count)") }
    assertTagLayer(tag)
    guard !tag[0].name.isEmpty, tag[1].name.isEmpty else {
        fail("settings order wrong: \(tag.map(\.name))")
    }
    print("PASS settings over overlay: order=\(tag.map(\.name))")

case "file-panel":
    guard tag.count == 3 else { fail("file panel expected 3 TagLauncher windows, got \(tag.count)") }
    assertTagLayer(tag)
    guard !tag[0].name.isEmpty, !tag[1].name.isEmpty, tag[2].name.isEmpty else {
        fail("file panel order wrong: \(tag.map(\.name))")
    }
    print("PASS file panel over settings: order=\(tag.map(\.name))")

case "no-overlay":
    guard tag.isEmpty else { fail("expected no TagLauncher windows, got \(tag.count)") }
    print("PASS overlay hidden")

case "force-quit":
    guard let overlay = tag.first else { fail("force quit check expected overlay window") }
    guard let forceQuit = windows.first(where: {
        $0.owner == "loginwindow" && ($0.name.localizedCaseInsensitiveContains("force") || $0.name.contains("强制"))
    }) else {
        fail("force quit window not found")
    }
    guard forceQuit.layer > overlay.layer else {
        fail("force quit layer \(forceQuit.layer) is not above overlay layer \(overlay.layer)")
    }
    print("PASS force quit above overlay: forceQuitLayer=\(forceQuit.layer) overlayLayer=\(overlay.layer)")

case "screen-count":
    print("INFO screens=\(NSScreen.screens.count) frames=\(NSScreen.screens.map { NSStringFromRect($0.frame) })")

default:
    fail("unknown assert mode: \(mode)")
}
SWIFT

cat >"$coords_swift" <<'SWIFT'
import CoreGraphics
import Foundation

let raw = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let tag = raw.filter { ($0[kCGWindowOwnerName as String] as? String) == "TagLauncher" }
let mode = CommandLine.arguments.dropFirst().first ?? ""
switch mode {
case "data-tab":
    guard let settings = tag.first(where: { (($0[kCGWindowName as String] as? String) ?? "").isEmpty == false }),
          let bounds = settings[kCGWindowBounds as String] as? NSDictionary,
          let x = bounds["X"] as? CGFloat,
          let y = bounds["Y"] as? CGFloat else {
        fputs("FAIL: could not find settings window bounds\n", stderr)
        exit(1)
    }
    print("\(Int(round(x + 523))) \(Int(round(y + 50)))")
case "export":
    guard let settings = tag.first(where: { (($0[kCGWindowName as String] as? String) ?? "").isEmpty == false }),
          let bounds = settings[kCGWindowBounds as String] as? NSDictionary,
          let x = bounds["X"] as? CGFloat,
          let y = bounds["Y"] as? CGFloat else {
        fputs("FAIL: could not find settings window bounds\n", stderr)
        exit(1)
    }
    print("\(Int(round(x + 375))) \(Int(round(y + 331)))")
case "overlay-outside":
    guard let overlay = tag.first(where: { (($0[kCGWindowName as String] as? String) ?? "").isEmpty }),
          let overlayBounds = overlay[kCGWindowBounds as String] as? NSDictionary,
          let overlayX = overlayBounds["X"] as? CGFloat,
          let overlayY = overlayBounds["Y"] as? CGFloat else {
        fputs("FAIL: could not find overlay window bounds\n", stderr)
        exit(1)
    }
    print("\(Int(round(overlayX + 120))) \(Int(round(overlayY + 160)))")
default:
    fputs("FAIL: unknown coords mode \(mode)\n", stderr)
    exit(1)
}
SWIFT

cat >"$screens_swift" <<'SWIFT'
import AppKit
import Foundation

for (index, screen) in NSScreen.screens.enumerated() {
    let frame = screen.frame
    let cgTop = NSScreen.screens.map { $0.frame.maxY }.max() ?? frame.maxY
    let cgY = cgTop - frame.maxY
    let clickY = cgY + frame.height / 2
    print("\(index)|\(Int(round(frame.midX)))|\(Int(round(clickY)))|\(Int(round(frame.origin.x)))|\(Int(round(cgY)))|\(Int(round(frame.width)))|\(Int(round(frame.height)))")
}
SWIFT

swift_assert() {
  swift "$assert_swift" "$1"
}

wait_swift_assert() {
  local mode="$1"
  local output=""
  for _ in {1..12}; do
    if output="$(swift "$assert_swift" "$mode" 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
    sleep 0.2
  done
  printf '%s\n' "$output" >&2
  return 1
}

show_overlay() {
  send_main_hotkey
  if wait_swift_assert overlay >/dev/null 2>&1; then
    swift_assert overlay
    return 0
  fi

  show_overlay_from_app_menu
  wait_swift_assert overlay
}

click_relative_to_settings() {
  local mode="$1"
  local coords
  coords="$(swift "$coords_swift" "$mode")"
  read -r x y <<<"$coords"
  click_xy "$x" "$y"
}

click_overlay_outside_quick_search() {
  local coords
  coords="$(swift "$coords_swift" overlay-outside)"
  read -r x y <<<"$coords"
  click_xy "$x" "$y"
}

log "==> Building app"
bash "$ROOT_DIR/build.sh" >/dev/null

log "==> Starting clean app instance"
prepare_isolated_app_instance

log "==> QA 1/7: overlay claims foreground, hides Dock, keeps menu bar visible"
show_overlay
frontmost="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
[[ "$frontmost" == "TagLauncher" ]] || { echo "FAIL: frontmost app is $frontmost, expected TagLauncher" >&2; exit 1; }
swift_assert overlay

log "==> QA 1/7 and 4/7: settings floats above appgrid and quick search"
send_keycode 49
sleep 0.4
send_cmd_comma
sleep 0.7
swift_assert settings

log "==> QA 2/7: import/export file panel floats above settings"
click_relative_to_settings data-tab
sleep 0.3
click_relative_to_settings export
sleep 0.7
swift_assert file-panel
send_keycode 53
sleep 0.3
send_cmd_w
sleep 0.5
swift_assert overlay

log "==> QA 4/7 and 5/7: appgrid-space quick search and double-Esc behavior"
send_keycode 49
sleep 0.4
send_keycode 53
sleep 0.4
swift_assert overlay
send_keycode 53
sleep 0.4
swift_assert no-overlay

log "==> QA 5/7: clicking outside quick search closes search, not appgrid"
show_overlay
send_keycode 49
sleep 0.4
click_overlay_outside_quick_search
sleep 0.4
swift_assert overlay

log "==> QA 3/7: system force-quit window stays above TagLauncher"
send_keycode 53 "option down, command down"
sleep 0.7
swift_assert force-quit
send_keycode 53
sleep 0.3

log "==> QA 6/7: screen-following logic"
swift_assert screen-count
screen_count="$(swift "$screens_swift" | wc -l | tr -d ' ')"
if [[ "$screen_count" -gt 1 ]]; then
  while IFS='|' read -r index cx cy sx sy sw sh; do
    kill_all_taglauncher_instances
    open -n "$APP_BUNDLE"
    sleep 2.5
    if ! is_qa_app_only_running; then
      echo "FAIL: expected only QA build TagLauncher instance during screen-following check" >&2
      pgrep -fl '/TagLauncher.app/Contents/MacOS/TagLauncher' >&2 || true
      exit 1
    fi
    move_xy "$cx" "$cy"
    sleep 0.2
    show_overlay
    wait_swift_assert overlay
    swift - "$sx" "$sy" "$sw" "$sh" <<'SWIFT'
import CoreGraphics
import Foundation
let expected = CommandLine.arguments.dropFirst().map { Int($0)! }
let raw = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let tag = raw.filter { ($0[kCGWindowOwnerName as String] as? String) == "TagLauncher" }
guard tag.count == 1, let bounds = tag[0][kCGWindowBounds as String] as? NSDictionary else {
    fputs("FAIL: expected one overlay for screen-following check\n", stderr)
    exit(1)
}
let actual = ["X", "Y", "Width", "Height"].map { Int(round((bounds[$0] as? Double) ?? 0)) }
guard actual == expected else {
    fputs("FAIL: overlay bounds \(actual) did not match screen frame \(expected)\n", stderr)
    exit(1)
}
print("PASS screen frame: \(actual)")
SWIFT
  done < <(swift "$screens_swift")
else
  rg -Fq 'screenContainingCurrentPointer() ??' "$ROOT_DIR/Apptag/ApptagApp.swift"
  rg -Fq 'NSMouseInRect(mousePoint, $0.frame, false)' "$ROOT_DIR/Apptag/ApptagApp.swift"
  log "PASS screen-following static path: single physical display here; code selects NSScreen under current pointer"
fi

log "==> QA 7/7: final chrome state still valid"
swift_assert overlay
send_keycode 53
sleep 0.4
swift_assert no-overlay

log "ALL WINDOW LOGIC QA PASSED"
