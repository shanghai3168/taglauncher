#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/build/TagLauncher.app"
APP_PROCESS="TagLauncher"
LAUNCH_AGENT_LABEL="com.taglauncher.app"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"
SAVED_STATE_DIR="$HOME/Library/Saved Application State/$LAUNCH_AGENT_LABEL.savedState"
USER_GUI_DOMAIN="gui/$(id -u)"
RESTORE_LAUNCH_AGENT=false
LAUNCH_AGENT_PLIST_WAS_PRESENT=false
LAUNCH_AGENT_BACKUP="$(mktemp -t taglauncher-launchagent.XXXXXX.plist)"
DEFAULTS_DOMAIN="$LAUNCH_AGENT_LABEL"
SHOW_DOCK_ICON_WAS_SET=false
SHOW_DOCK_ICON_VALUE=""
APP_LANGUAGE_WAS_SET=false
APP_LANGUAGE_VALUE=""
FULLSCREEN_QA_PID=""
CLICK_TOOL="${CLICK_TOOL:-$(command -v cliclick || true)}"

if [[ -z "$CLICK_TOOL" ]]; then
  echo "FAIL: cliclick is required for window-position click checks." >&2
  exit 2
fi

log() {
  printf '%s\n' "$*"
}

backup_user_defaults() {
  local value
  if value="$(defaults read "$DEFAULTS_DOMAIN" showDockIcon 2>/dev/null)"; then
    SHOW_DOCK_ICON_WAS_SET=true
    SHOW_DOCK_ICON_VALUE="$value"
  fi
  if value="$(defaults read "$DEFAULTS_DOMAIN" appLanguage 2>/dev/null)"; then
    APP_LANGUAGE_WAS_SET=true
    APP_LANGUAGE_VALUE="$value"
  fi
}

backup_launch_agent_plist() {
  if [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
    LAUNCH_AGENT_PLIST_WAS_PRESENT=true
    cp "$LAUNCH_AGENT_PLIST" "$LAUNCH_AGENT_BACKUP"
  fi
}

restore_user_defaults() {
  if [[ "$SHOW_DOCK_ICON_WAS_SET" == true ]]; then
    if [[ "$SHOW_DOCK_ICON_VALUE" == "1" || "$SHOW_DOCK_ICON_VALUE" == "true" || "$SHOW_DOCK_ICON_VALUE" == "TRUE" ]]; then
      defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool true
    else
      defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool false
    fi
  else
    defaults delete "$DEFAULTS_DOMAIN" showDockIcon >/dev/null 2>&1 || true
  fi

  if [[ "$APP_LANGUAGE_WAS_SET" == true ]]; then
    defaults write "$DEFAULTS_DOMAIN" appLanguage -string "$APP_LANGUAGE_VALUE"
  else
    defaults delete "$DEFAULTS_DOMAIN" appLanguage >/dev/null 2>&1 || true
  fi
}

restore_launch_agent_plist() {
  if [[ "$LAUNCH_AGENT_PLIST_WAS_PRESENT" == true ]]; then
    mkdir -p "$(dirname "$LAUNCH_AGENT_PLIST")"
    if [[ -f "$LAUNCH_AGENT_BACKUP" ]]; then
      cp "$LAUNCH_AGENT_BACKUP" "$LAUNCH_AGENT_PLIST" || true
    else
      log "WARN: launch agent backup missing during cleanup"
    fi
  else
    rm -f "$LAUNCH_AGENT_PLIST"
  fi
}

reset_dock_for_qa() {
  killall Dock >/dev/null 2>&1 || true
  sleep 1.5
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

send_quick_search_hotkey() {
  swift - <<'SWIFT' >/dev/null 2>&1
import CoreGraphics
import Foundation

let source = CGEventSource(stateID: .hidSystemState)
let down = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: true)!
down.flags = [.maskSecondaryFn]
down.post(tap: .cghidEventTap)
usleep(80_000)
let up = CGEvent(keyboardEventSource: source, virtualKey: 49, keyDown: false)!
up.flags = [.maskSecondaryFn]
up.post(tap: .cghidEventTap)
SWIFT
}

send_cmd_comma() {
  osascript -e 'tell application "System Events" to keystroke "," using {command down}'
}

send_cmd_w() {
  osascript -e 'tell application "System Events" to keystroke "w" using {command down}'
}

close_settings_window() {
  osascript <<'OSA' >/dev/null 2>&1 || true
tell application "System Events"
  tell process "TagLauncher"
    repeat 20 times
      repeat with windowRef in windows
        try
          if (name of windowRef as text) is not "" then
            click button 1 of windowRef
            return
          end if
        end try
      end repeat
      delay 0.1
    end repeat
  end tell
end tell
OSA
}

dismiss_reopen_dialog() {
  osascript <<'OSA' >/dev/null 2>&1 || true
tell application "System Events"
  tell process "TagLauncher"
    repeat 20 times
      repeat with windowRef in windows
        repeat with buttonRef in buttons of windowRef
          try
            set buttonName to name of buttonRef as text
            if buttonName contains "Don't" or buttonName contains "Don’t" or buttonName contains "不" then
              click buttonRef
              return
            end if
          end try
        end repeat
      end repeat
      delay 0.1
    end repeat
  end tell
end tell
OSA
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
  if [[ -n "${FULLSCREEN_QA_PID:-}" ]]; then
    kill "$FULLSCREEN_QA_PID" >/dev/null 2>&1 || true
    wait "$FULLSCREEN_QA_PID" >/dev/null 2>&1 || true
    FULLSCREEN_QA_PID=""
  fi
  kill_all_taglauncher_instances
  restore_user_defaults
  restore_launch_agent_plist
  if [[ "$RESTORE_LAUNCH_AGENT" == true && -f "$LAUNCH_AGENT_PLIST" ]]; then
    launchctl bootstrap "$USER_GUI_DOMAIN" "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
backup_user_defaults
backup_launch_agent_plist

kill_all_taglauncher_instances() {
  osascript -e 'tell application "TagLauncher" to quit' >/dev/null 2>&1 || true
  sleep 0.8
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

assert_single_qa_app_instance() {
  local lines count
  lines="$(pgrep -fl '/TagLauncher.app/Contents/MacOS/TagLauncher' || true)"
  [[ -n "$lines" ]] || { echo "FAIL: no TagLauncher process is running" >&2; return 1; }
  count="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
  if [[ "$count" != "1" || "$lines" != *"$APP_BUNDLE/Contents/MacOS/TagLauncher"* ]]; then
    echo "FAIL: expected exactly one QA build TagLauncher instance" >&2
    printf '%s\n' "$lines" >&2
    return 1
  fi
}

assert_single_dock_tile() {
  local output count names
  output="$(osascript <<'OSA'
tell application "System Events"
  tell process "Dock"
    set tagCount to 0
    set tagNames to {}
    repeat with itemRef in UI elements of list 1
      try
        set itemName to name of itemRef as text
        if itemName is "TagLauncher" then
          set tagCount to tagCount + 1
          set end of tagNames to itemName
        end if
      end try
    end repeat
    return (tagCount as text) & "|" & (tagNames as text)
  end tell
end tell
OSA
)"
  count="${output%%|*}"
  names="${output#*|}"
  if [[ "$count" != "1" ]]; then
    echo "FAIL: expected exactly one TagLauncher Dock tile, got $count ($names)" >&2
    return 1
  fi
  log "PASS Dock tile count: $names"
}

assert_no_dock_tile() {
  local output count names
  output="$(osascript <<'OSA'
tell application "System Events"
  tell process "Dock"
    set tagCount to 0
    set tagNames to {}
    repeat with itemRef in UI elements of list 1
      try
        set itemName to name of itemRef as text
        if itemName is "TagLauncher" then
          set tagCount to tagCount + 1
          set end of tagNames to itemName
        end if
      end try
    end repeat
    return (tagCount as text) & "|" & (tagNames as text)
  end tell
end tell
OSA
)"
  count="${output%%|*}"
  names="${output#*|}"
  if [[ "$count" != "0" ]]; then
    echo "FAIL: expected no TagLauncher Dock tile, got $count ($names)" >&2
    return 1
  fi
  log "PASS no TagLauncher Dock tile"
}

click_taglauncher_dock_tile() {
  local coords x y
  coords="$(osascript <<'OSA'
tell application "System Events"
  tell process "Dock"
    repeat with itemRef in UI elements of list 1
      try
        if (name of itemRef as text) is "TagLauncher" then
          set itemPosition to position of itemRef
          set itemSize to size of itemRef
          set centerX to (item 1 of itemPosition) + ((item 1 of itemSize) / 2)
          set centerY to (item 2 of itemPosition) + ((item 2 of itemSize) / 2)
          return (centerX as integer as text) & " " & (centerY as integer as text)
        end if
      end try
    end repeat
    error "TagLauncher Dock tile not found"
  end tell
end tell
OSA
)"
  read -r x y <<<"$coords"
  click_xy "$x" "$y"
}

open_overlay_from_dock_with_retry() {
  local output=""
  for _ in {1..3}; do
    click_taglauncher_dock_tile
    sleep 0.8
    if output="$(wait_swift_assert overlay 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
  done
  printf '%s\n' "$output" >&2
  return 1
}

assert_frontmost_taglauncher() {
  local frontmost
  frontmost="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
  if [[ "$frontmost" != "TagLauncher" ]]; then
    echo "FAIL: frontmost app is $frontmost, expected TagLauncher" >&2
    return 1
  fi
}

prepare_isolated_app_instance() {
  if launchctl print "$USER_GUI_DOMAIN/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
    RESTORE_LAUNCH_AGENT=true
    launchctl bootout "$USER_GUI_DOMAIN/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 || true
  fi

  kill_all_taglauncher_instances
  rm -rf "$SAVED_STATE_DIR"
  open -n "$APP_BUNDLE"
  sleep 1.0
  dismiss_reopen_dialog
  sleep 1.5

  if ! is_qa_app_only_running; then
    echo "FAIL: expected only QA build TagLauncher instance to be running" >&2
    pgrep -fl '/TagLauncher.app/Contents/MacOS/TagLauncher' >&2 || true
    exit 1
  fi
  assert_single_qa_app_instance
}

assert_swift="$(mktemp -t taglauncher-window-assert.XXXXXX.swift)"
coords_swift="$(mktemp -t taglauncher-window-coords.XXXXXX.swift)"
settings_ax_swift="$(mktemp -t taglauncher-settings-ax.XXXXXX.swift)"
screens_swift="$(mktemp -t taglauncher-screens.XXXXXX.swift)"
fullscreen_swift="$(mktemp -t taglauncher-fullscreen-target.XXXXXX.swift)"
trap 'cleanup; rm -f "$assert_swift" "$coords_swift" "$settings_ax_swift" "$screens_swift" "$fullscreen_swift" "$LAUNCH_AGENT_BACKUP"' EXIT

cat >"$assert_swift" <<'SWIFT'
import AppKit
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

func dimension(_ bounds: NSDictionary, _ key: String) -> CGFloat {
    if let value = bounds[key] as? CGFloat {
        return value
    }
    if let value = bounds[key] as? NSNumber {
        return CGFloat(truncating: value)
    }
    return 0
}

func isTinyUntitledUtilityWindow(_ window: WindowInfo) -> Bool {
    window.name.isEmpty
        && dimension(window.bounds, "Width") < 160
        && dimension(window.bounds, "Height") < 160
}

func tagWindows(_ windows: [WindowInfo]) -> [WindowInfo] {
    windows.filter {
        $0.owner == "TagLauncher" && !isTinyUntitledUtilityWindow($0)
    }
}

func rect(_ window: WindowInfo) -> CGRect {
    CGRect(
        x: dimension(window.bounds, "X"),
        y: dimension(window.bounds, "Y"),
        width: dimension(window.bounds, "Width"),
        height: dimension(window.bounds, "Height")
    )
}

func isOverlayWindow(_ window: WindowInfo) -> Bool {
    guard window.name.isEmpty else { return false }
    let windowFrame = rect(window)
    return NSScreen.screens.contains { screen in
        let screenFrame = screen.frame
        return abs(windowFrame.width - screenFrame.width) <= 12
            && windowFrame.height >= screenFrame.height * 0.75
            && abs(windowFrame.midX - screenFrame.midX) <= 12
    }
}

func isQuickSearchWindow(_ window: WindowInfo) -> Bool {
    guard window.name.isEmpty, !isOverlayWindow(window) else { return false }
    let windowFrame = rect(window)
    return windowFrame.width >= 500
        && windowFrame.width <= 900
        && windowFrame.height >= 120
        && windowFrame.height <= 850
}

func isSettingsLikeWindow(_ window: WindowInfo) -> Bool {
    !window.name.isEmpty
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
    guard isOverlayWindow(tag[0]) else { fail("overlay window was not full-screen sized: \(tag[0].bounds)") }
    let menubarLayer = windows.first { $0.owner == "Window Server" && $0.name == "Menubar" }?.layer
    guard menubarLayer == 24 else { fail("menubar layer expected 24, got \(String(describing: menubarLayer))") }
    let dockWindows = windows.filter { $0.owner == "Dock" }
    guard dockWindows.isEmpty else { fail("Dock should be hidden while overlay is visible; found \(dockWindows.count) Dock windows") }
    print("PASS overlay: tagLayer=\(tag[0].layer) menubarLayer=24 dockWindows=0")

case "quick-search":
    guard tag.count == 2 else { fail("quick search expected overlay plus panel, got \(tag.count)") }
    assertTagLayer(tag)
    let overlays = tag.filter(isOverlayWindow)
    let quickSearch = tag.filter(isQuickSearchWindow)
    guard overlays.count == 1, quickSearch.count == 1 else {
        fail("quick search stack wrong: names=\(tag.map(\.name)) bounds=\(tag.map(\.bounds))")
    }
    print("PASS quick search stack: tagLayers=\(tag.map(\.layer))")

case "settings":
    guard tag.count == 2 else { fail("settings expected 2 TagLauncher windows, got \(tag.count)") }
    assertTagLayer(tag)
    let overlays = tag.filter(isOverlayWindow)
    let settings = tag.filter(isSettingsLikeWindow)
    guard overlays.count == 1, settings.count == 1 else {
        fail("settings stack wrong: names=\(tag.map(\.name)) bounds=\(tag.map(\.bounds))")
    }
    guard !tag[0].name.isEmpty else {
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

case "fullscreen-target":
    guard let target = windows.first(where: { $0.name == "TagLauncherFullscreenQATargetFullscreen" }) else {
        fail("fullscreen QA target window not found")
    }
    guard let targetWidth = target.bounds["Width"] as? CGFloat,
          let targetHeight = target.bounds["Height"] as? CGFloat else {
        fail("fullscreen QA target has invalid bounds")
    }
    let frames = NSScreen.screens.map(\.frame)
    let matchesScreen = frames.contains { frame in
        abs(targetWidth - frame.width) <= 8 && targetHeight >= frame.height * 0.90
    }
    guard matchesScreen else {
        fail("fullscreen QA target is visible but not fullscreen: \(target.bounds)")
    }
    print("PASS fullscreen target: layer=\(target.layer) bounds=\(target.bounds)")

case "fullscreen-overlay":
    guard tag.count == 1 || tag.count == 2 else { fail("fullscreen overlay expected 1 or 2 TagLauncher windows, got \(tag.count)") }
    assertTagLayer(tag)
    guard let target = windows.first(where: { $0.name == "TagLauncherFullscreenQATargetFullscreen" }) else {
        fail("fullscreen target disappeared; TagLauncher likely switched to another Space")
    }
    guard let overlay = tag.first(where: isOverlayWindow) else {
        fail("fullscreen overlay TagLauncher window not found: \(tag.map(\.bounds))")
    }
    let quickSearch = tag.filter(isQuickSearchWindow)
    guard quickSearch.count == tag.count - 1 else {
        fail("fullscreen overlay stack has unexpected windows: \(tag.map(\.bounds))")
    }
    let overlayWidth = dimension(overlay.bounds, "Width")
    let overlayHeight = dimension(overlay.bounds, "Height")
    let overlayMidX = dimension(overlay.bounds, "X") + overlayWidth / 2
    let targetWidth = dimension(target.bounds, "Width")
    let targetHeight = dimension(target.bounds, "Height")
    let targetMidX = dimension(target.bounds, "X") + targetWidth / 2
    guard abs(overlayWidth - targetWidth) <= 12,
          overlayHeight >= targetHeight * 0.88,
          abs(overlayMidX - targetMidX) <= 12 else {
        fail("fullscreen overlay is not on the target fullscreen display: overlay=\(overlay.bounds) target=\(target.bounds)")
    }
    guard tag.allSatisfy({ $0.layer > target.layer }) else {
        fail("TagLauncher stack is not above fullscreen target")
    }
    print("PASS fullscreen overlay above target: tagLayers=\(tag.map(\.layer)) targetLayer=\(target.layer)")

case "fullscreen-settings":
    guard tag.count == 2 else { fail("fullscreen settings expected 2 TagLauncher windows, got \(tag.count)") }
    assertTagLayer(tag)
    guard let target = windows.first(where: { $0.name == "TagLauncherFullscreenQATargetFullscreen" }) else {
        fail("fullscreen target disappeared after opening settings; TagLauncher likely switched to another Space")
    }
    let overlays = tag.filter(isOverlayWindow)
    let settings = tag.filter(isSettingsLikeWindow)
    guard overlays.count == 1, settings.count == 1 else {
        fail("fullscreen settings stack wrong: names=\(tag.map(\.name)) bounds=\(tag.map(\.bounds))")
    }
    guard !tag[0].name.isEmpty else {
        fail("fullscreen settings order wrong: \(tag.map(\.name))")
    }
    guard tag.allSatisfy({ $0.layer > target.layer }) else {
        fail("TagLauncher settings stack is not above fullscreen target")
    }
    print("PASS fullscreen settings above target: tagLayers=\(tag.map(\.layer)) targetLayer=\(target.layer)")

case "split-geometry":
    func isSingleFullscreenWindow(_ windowFrame: CGRect, on screenFrame: CGRect) -> Bool {
        let widthMatches = abs(windowFrame.width - screenFrame.width) <= 12
        let heightMatches = windowFrame.height >= screenFrame.height * 0.88
        let horizontallyAligned = abs(windowFrame.midX - screenFrame.midX) <= 12
        let verticallyAligned = abs(windowFrame.maxY - screenFrame.maxY) <= 32
        return widthMatches && heightMatches && horizontallyAligned && verticallyAligned
    }

    func hasSplitViewFullscreenWindows(_ windows: [CGRect], on screenFrame: CGRect) -> Bool {
        let clippedWindows = windows.map { $0.intersection(screenFrame) }
        let tallWindows = clippedWindows
            .filter { frame in
                frame.height >= screenFrame.height * 0.86
                    && frame.width >= screenFrame.width * 0.20
                    && frame.width <= screenFrame.width * 0.86
                    && abs(frame.maxY - screenFrame.maxY) <= 32
            }
            .sorted { $0.minX < $1.minX }

        guard tallWindows.count >= 2 else { return false }

        for startIndex in tallWindows.indices {
            var union = tallWindows[startIndex]
            var lastMaxX = union.maxX

            for window in tallWindows.dropFirst(startIndex + 1) {
                let gap = window.minX - lastMaxX
                if gap < -32 || gap > 48 {
                    break
                }
                union = union.union(window)
                lastMaxX = max(lastMaxX, window.maxX)

                let touchesLeft = abs(union.minX - screenFrame.minX) <= 32
                let touchesRight = abs(union.maxX - screenFrame.maxX) <= 32
                let coversWidth = union.width >= screenFrame.width * 0.92
                let coversHeight = union.height >= screenFrame.height * 0.86
                if touchesLeft && touchesRight && coversWidth && coversHeight {
                    return true
                }
            }
        }

        return false
    }

    let screen = CGRect(x: 0, y: 0, width: 1710, height: 1112)
    let single = CGRect(x: 0, y: 39, width: 1710, height: 1073)
    let splitHalf = [
        CGRect(x: 0, y: 39, width: 853, height: 1073),
        CGRect(x: 857, y: 39, width: 853, height: 1073)
    ]
    let splitThird = [
        CGRect(x: 0, y: 39, width: 568, height: 1073),
        CGRect(x: 572, y: 39, width: 1138, height: 1073)
    ]
    let desktopTiledWithLargeGap = [
        CGRect(x: 0, y: 90, width: 700, height: 900),
        CGRect(x: 900, y: 90, width: 700, height: 900)
    ]
    let desktopSideBySideBelowDock = [
        CGRect(x: 0, y: 39, width: 856, height: 983),
        CGRect(x: 854, y: 39, width: 856, height: 983)
    ]
    let halfOnly = [CGRect(x: 0, y: 39, width: 853, height: 1073)]

    guard isSingleFullscreenWindow(single, on: screen) else {
        fail("split geometry expected single fullscreen window to match")
    }
    guard hasSplitViewFullscreenWindows(splitHalf, on: screen) else {
        fail("split geometry expected 50/50 Split View to match")
    }
    guard hasSplitViewFullscreenWindows(splitThird, on: screen) else {
        fail("split geometry expected 33/67 Split View to match")
    }
    guard !hasSplitViewFullscreenWindows(desktopTiledWithLargeGap, on: screen) else {
        fail("split geometry should not match ordinary tiled desktop windows")
    }
    guard !hasSplitViewFullscreenWindows(desktopSideBySideBelowDock, on: screen) else {
        fail("split geometry should not match side-by-side desktop windows below the Dock")
    }
    guard !hasSplitViewFullscreenWindows(halfOnly, on: screen) else {
        fail("split geometry should not match a single half-width window")
    }
    print("PASS split fullscreen geometry detection")

case "screen-count":
    print("INFO screens=\(NSScreen.screens.count) frames=\(NSScreen.screens.map { NSStringFromRect($0.frame) })")

default:
    fail("unknown assert mode: \(mode)")
}
SWIFT

cat >"$coords_swift" <<'SWIFT'
import AppKit
import CoreGraphics
import Foundation

let raw = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let tag = raw.filter { ($0[kCGWindowOwnerName as String] as? String) == "TagLauncher" }
let mode = CommandLine.arguments.dropFirst().first ?? ""

func dimension(_ bounds: NSDictionary, _ key: String) -> CGFloat {
    if let value = bounds[key] as? CGFloat {
        return value
    }
    if let value = bounds[key] as? NSNumber {
        return CGFloat(truncating: value)
    }
    return 0
}

switch mode {
case "data-tab":
    guard let settings = tag.first(where: { (($0[kCGWindowName as String] as? String) ?? "").isEmpty == false }),
          let bounds = settings[kCGWindowBounds as String] as? NSDictionary,
          let x = bounds["X"] as? CGFloat,
          let y = bounds["Y"] as? CGFloat else {
        fputs("FAIL: could not find settings window bounds\n", stderr)
        exit(1)
    }
    print("\(Int(round(x + 625))) \(Int(round(y + 50)))")
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
    guard let overlay = tag.max(by: { lhs, rhs in
        let lhsBounds = lhs[kCGWindowBounds as String] as? NSDictionary ?? [:]
        let rhsBounds = rhs[kCGWindowBounds as String] as? NSDictionary ?? [:]
        let lhsArea = dimension(lhsBounds, "Width") * dimension(lhsBounds, "Height")
        let rhsArea = dimension(rhsBounds, "Width") * dimension(rhsBounds, "Height")
        return lhsArea < rhsArea
    }), let overlayBounds = overlay[kCGWindowBounds as String] as? NSDictionary else {
        let screen = NSScreen.screens.first?.frame ?? CGRect(x: 0, y: 0, width: 1200, height: 800)
        print("\(Int(round(screen.minX + 120))) \(160)")
        exit(0)
    }
    let overlayX = dimension(overlayBounds, "X")
    let overlayY = dimension(overlayBounds, "Y")
    print("\(Int(round(overlayX + 120))) \(Int(round(overlayY + 160)))")
case "overlay-center":
    guard let overlay = tag.max(by: { lhs, rhs in
        let lhsBounds = lhs[kCGWindowBounds as String] as? NSDictionary ?? [:]
        let rhsBounds = rhs[kCGWindowBounds as String] as? NSDictionary ?? [:]
        let lhsArea = dimension(lhsBounds, "Width") * dimension(lhsBounds, "Height")
        let rhsArea = dimension(rhsBounds, "Width") * dimension(rhsBounds, "Height")
        return lhsArea < rhsArea
    }), let overlayBounds = overlay[kCGWindowBounds as String] as? NSDictionary else {
        let screen = NSScreen.screens.first?.frame ?? CGRect(x: 0, y: 0, width: 1200, height: 800)
        print("\(Int(round(screen.midX))) \(Int(round(screen.midY)))")
        exit(0)
    }
    let overlayX = dimension(overlayBounds, "X")
    let overlayY = dimension(overlayBounds, "Y")
    let overlayWidth = dimension(overlayBounds, "Width")
    let overlayHeight = dimension(overlayBounds, "Height")
    print("\(Int(round(overlayX + overlayWidth / 2))) \(Int(round(overlayY + overlayHeight / 2)))")
case "quick-search-result":
    guard let quickSearch = tag.first(where: { window in
        let name = (window[kCGWindowName as String] as? String) ?? ""
        let bounds = window[kCGWindowBounds as String] as? NSDictionary ?? [:]
        let width = dimension(bounds, "Width")
        let height = dimension(bounds, "Height")
        return name.isEmpty
            && width >= 500
            && width <= 900
            && height >= 120
            && height <= 850
    }), let bounds = quickSearch[kCGWindowBounds as String] as? NSDictionary else {
        fputs("FAIL: could not find quick search result-list bounds\n", stderr)
        exit(1)
    }
    let x = dimension(bounds, "X")
    let y = dimension(bounds, "Y")
    let width = dimension(bounds, "Width")
    print("\(Int(round(x + width * 0.35))) \(Int(round(y + 190)))")
case "fullscreen-target-center":
    guard let target = raw.first(where: { ($0[kCGWindowName as String] as? String) == "TagLauncherFullscreenQATargetFullscreen" }),
          let bounds = target[kCGWindowBounds as String] as? NSDictionary else {
        fputs("FAIL: could not find fullscreen target bounds\n", stderr)
        exit(1)
    }
    let x = dimension(bounds, "X")
    let y = dimension(bounds, "Y")
    let width = dimension(bounds, "Width")
    let height = dimension(bounds, "Height")
    print("\(Int(round(x + width / 2))) \(Int(round(y + height / 2)))")
default:
    fputs("FAIL: unknown coords mode \(mode)\n", stderr)
    exit(1)
}
SWIFT

cat >"$settings_ax_swift" <<'SWIFT'
import AppKit
import ApplicationServices
import Foundation

let mode = CommandLine.arguments.dropFirst().first ?? ""
let bundleID = "com.taglauncher.app"

guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
    fputs("FAIL: TagLauncher is not running\n", stderr)
    exit(1)
}

let root = AXUIElementCreateApplication(app.processIdentifier)

func copyAttribute(_ element: AXUIElement, _ attribute: CFString) -> CFTypeRef? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute, &value)
    guard result == .success else { return nil }
    return value
}

func stringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
    copyAttribute(element, attribute) as? String
}

func titleCandidates(for element: AXUIElement) -> [String] {
    [
        stringAttribute(element, kAXTitleAttribute as CFString),
        stringAttribute(element, kAXDescriptionAttribute as CFString),
        stringAttribute(element, kAXValueAttribute as CFString),
        stringAttribute(element, kAXHelpAttribute as CFString)
    ].compactMap { $0 }.filter { !$0.isEmpty }
}

func children(of element: AXUIElement) -> [AXUIElement] {
    if let values = copyAttribute(element, kAXChildrenAttribute as CFString) as? [AXUIElement] {
        return values
    }
    return []
}

func matches(_ element: AXUIElement, candidates: [String]) -> Bool {
    let role = stringAttribute(element, kAXRoleAttribute as CFString) ?? ""
    let titles = titleCandidates(for: element)
    guard !titles.isEmpty else { return false }
    let interactiveRole = role == kAXButtonRole as String
        || role == kAXRadioButtonRole as String
        || role == kAXTabGroupRole as String
        || role == kAXMenuItemRole as String
    guard interactiveRole else { return false }
    return titles.contains { title in
        candidates.contains { candidate in
            title == candidate || title.localizedCaseInsensitiveContains(candidate)
        }
    }
}

func findMatchingElement(
    _ element: AXUIElement,
    candidates: [String],
    depth: Int,
    visited: inout Set<CFHashCode>
) -> AXUIElement? {
    guard depth >= 0 else { return nil }
    let hash = CFHash(element)
    guard !visited.contains(hash) else { return nil }
    visited.insert(hash)

    if matches(element, candidates: candidates) {
        return element
    }

    for child in children(of: element) {
        if let match = findMatchingElement(child, candidates: candidates, depth: depth - 1, visited: &visited) {
            return match
        }
    }
    return nil
}

let candidates: [String]
switch mode {
case "data-tab":
    candidates = ["Data"]
case "export":
    candidates = ["Export"]
default:
    fputs("FAIL: unknown settings action \(mode)\n", stderr)
    exit(1)
}

var visited = Set<CFHashCode>()
guard let element = findMatchingElement(root, candidates: candidates, depth: 12, visited: &visited) else {
    fputs("FAIL: could not find settings control for \(mode)\n", stderr)
    exit(1)
}

let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
guard result == .success else {
    fputs("FAIL: could not press settings control for \(mode): \(result.rawValue)\n", stderr)
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

cat >"$fullscreen_swift" <<'SWIFT'
import AppKit
import Foundation

final class FullscreenQATargetDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 900, height: 600)
        let initialFrame = NSRect(
            x: frame.midX - 450,
            y: frame.midY - 300,
            width: 900,
            height: 600
        )
        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TagLauncherFullscreenQATarget"
        window.collectionBehavior = [.managed, .fullScreenPrimary]
        let view = NSView(frame: initialFrame)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.16, alpha: 1).cgColor
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: window,
            queue: .main
        ) { _ in
            window.title = "TagLauncherFullscreenQATargetFullscreen"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !window.styleMask.contains(.fullScreen) {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.toggleFullScreen(nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = FullscreenQATargetDelegate()
app.delegate = delegate
app.run()
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

open_quick_search_with_retry() {
  local output=""
  for _ in {1..3}; do
    send_quick_search_hotkey
    sleep 0.8
    if output="$(wait_swift_assert quick-search 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
  done
  printf '%s\n' "$output" >&2
  return 1
}

open_appgrid_quick_search_with_retry() {
  local output=""
  for _ in {1..3}; do
    send_keycode 49
    sleep 0.4
    if output="$(wait_swift_assert quick-search 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
  done
  printf '%s\n' "$output" >&2
  return 1
}

assert_fullscreen_overlay_stable() {
  local output=""
  local consecutive_successes=0
  for _ in {1..20}; do
    if output="$(swift "$assert_swift" fullscreen-overlay 2>&1)"; then
      consecutive_successes=$((consecutive_successes + 1))
      if [[ "$consecutive_successes" -ge 6 ]]; then
        printf '%s\n' "$output"
        return 0
      fi
    else
      consecutive_successes=0
    fi
    sleep 0.1
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

click_settings_control() {
  local mode="$1"
  if swift "$settings_ax_swift" "$mode" >/dev/null 2>&1; then
    return 0
  fi
  click_relative_to_settings "$mode"
}

click_overlay_outside_quick_search() {
  local coords
  coords="$(swift "$coords_swift" overlay-outside)"
  read -r x y <<<"$coords"
  click_xy "$x" "$y"
}

hover_quick_search_results() {
  local coords x y
  coords="$(quick_search_result_coords_with_retry)"
  read -r x y <<<"$coords"
  for offset in 0 8 16 8 0; do
    move_xy "$x" "$((y + offset))"
    sleep 0.08
  done
}

click_quick_search_result() {
  local coords x y
  coords="$(quick_search_result_coords_with_retry)"
  read -r x y <<<"$coords"
  click_xy "$x" "$y"
}

quick_search_result_coords_with_retry() {
  local output
  for _ in {1..8}; do
    if output="$(swift "$coords_swift" quick-search-result 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi
    sleep 0.15
  done
  printf '%s\n' "$output" >&2
  return 1
}

page_scroll_appgrid() {
  local coords
  coords="$(swift "$coords_swift" overlay-center)"
  read -r x y <<<"$coords"
  move_xy "$x" "$y"
  sleep 0.15
  swift - <<'SWIFT'
import CoreGraphics
if let event = CGEvent(
    scrollWheelEvent2Source: nil,
    units: .pixel,
    wheelCount: 1,
    wheel1: -900,
    wheel2: 0,
    wheel3: 0
) {
    event.post(tap: .cghidEventTap)
}
SWIFT
  sleep 0.25
}

kill_fullscreen_qa_target() {
  if [[ -n "${FULLSCREEN_QA_PID:-}" ]]; then
    kill "$FULLSCREEN_QA_PID" >/dev/null 2>&1 || true
    wait "$FULLSCREEN_QA_PID" >/dev/null 2>&1 || true
    FULLSCREEN_QA_PID=""
    sleep 1.0
  fi
}

start_fullscreen_qa_target() {
  kill_fullscreen_qa_target
  local log_file
  log_file="$(mktemp -t taglauncher-fullscreen-target.XXXXXX.log)"
  swift "$fullscreen_swift" >"$log_file" 2>&1 &
  FULLSCREEN_QA_PID=$!
  local output=""
  for _ in {1..36}; do
    if output="$(swift "$assert_swift" fullscreen-target 2>&1)"; then
      printf '%s\n' "$output"
      rm -f "$log_file"
      return 0
    fi
    sleep 0.5
  done
  printf '%s\n' "$output" >&2
  cat "$log_file" >&2 || true
  rm -f "$log_file"
  return 1
}

move_pointer_to_fullscreen_target() {
  local coords
  coords="$(swift "$coords_swift" fullscreen-target-center)"
  read -r x y <<<"$coords"
  move_xy "$x" "$y"
  sleep 0.2
}

log "==> Building app"
bash "$ROOT_DIR/build.sh" >/dev/null

log "==> Preparing QA defaults"
defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool true
defaults write "$DEFAULTS_DOMAIN" appLanguage -string en
reset_dock_for_qa

log "==> Starting clean app instance"
prepare_isolated_app_instance

log "==> QA duplicate guard: showDockIcon=true and repeated self-launch keep one Dock app instance"
plist_multiple="$(/usr/libexec/PlistBuddy -c 'Print :LSMultipleInstancesProhibited' "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true)"
[[ "$plist_multiple" == "true" ]] || { echo "FAIL: LSMultipleInstancesProhibited is not true in built Info.plist" >&2; exit 1; }
rg -Fq 'isTagLauncherBundle' "$ROOT_DIR/Apptag/DataLayer.swift"
rg -Fq 'guard !isTagLauncherBundle(bundleId)' "$ROOT_DIR/Apptag/DataLayer.swift"
for _ in {1..5}; do
  open -n "$APP_BUNDLE"
  sleep 0.35
done
sleep 1.5
assert_single_qa_app_instance
assert_single_dock_tile
swift_assert no-overlay
for _ in {1..3}; do
  "$APP_BUNDLE/Contents/MacOS/TagLauncher" >/dev/null 2>&1 &
  sleep 0.25
done
sleep 2.0
assert_single_qa_app_instance
assert_single_dock_tile
swift_assert no-overlay
for _ in {1..3}; do
  "$APP_BUNDLE/Contents/MacOS/TagLauncher" --hide >/dev/null 2>&1 &
  sleep 0.25
done
sleep 2.0
assert_single_qa_app_instance
assert_single_dock_tile
swift_assert no-overlay
log "==> QA Dock reopen: showDockIcon=true opens App Grid from explicit app reopen"
open_overlay_from_dock_with_retry
send_keycode 53
sleep 0.4
wait_swift_assert no-overlay
log "==> QA hidden Dock: main hotkey opens App Grid without showing Dock tile"
defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool false
prepare_isolated_app_instance
assert_no_dock_tile
send_main_hotkey
sleep 0.8
wait_swift_assert overlay
assert_no_dock_tile
send_keycode 53
sleep 0.4
wait_swift_assert no-overlay
kill_all_taglauncher_instances
sleep 0.4
swift_assert no-overlay
prepare_isolated_app_instance
assert_no_dock_tile
log "==> QA hidden Dock: Fn+Space Quick Search hover does not resurrect App Grid"
open_quick_search_with_retry
hover_quick_search_results
sleep 0.8
wait_swift_assert quick-search
assert_no_dock_tile
send_quick_search_hotkey
sleep 0.8
wait_swift_assert no-overlay
assert_no_dock_tile
kill_all_taglauncher_instances
sleep 0.4
swift_assert no-overlay
prepare_isolated_app_instance
assert_no_dock_tile
log "==> QA hidden Dock: clicking Quick Search result closes without showing App Grid"
open_quick_search_with_retry
click_quick_search_result
sleep 1.4
wait_swift_assert no-overlay
assert_no_dock_tile
kill_all_taglauncher_instances
sleep 0.4
swift_assert no-overlay

log "==> QA split-view fullscreen geometry detection"
swift_assert split-geometry

run_fullscreen_space_case() {
  local dock_value="$1"
  log "==> QA fullscreen Space: overlay stays above the current fullscreen app (showDockIcon=$dock_value)"
  defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool "$dock_value"
  prepare_isolated_app_instance
  start_fullscreen_qa_target
  move_pointer_to_fullscreen_target
  send_main_hotkey
  wait_swift_assert fullscreen-overlay
  assert_fullscreen_overlay_stable
  log "==> QA fullscreen Space: quick search from appgrid does not switch Space"
  open_appgrid_quick_search_with_retry
  assert_fullscreen_overlay_stable
  send_keycode 53
  sleep 0.3
  wait_swift_assert fullscreen-overlay
  log "==> QA fullscreen Space: settings from appgrid does not switch Space"
  send_cmd_comma
  sleep 0.7
  wait_swift_assert fullscreen-settings
  close_settings_window
  sleep 0.5
  wait_swift_assert fullscreen-overlay
  send_keycode 53
  sleep 0.4
  wait_swift_assert no-overlay
  kill_fullscreen_qa_target
}

run_fullscreen_space_case true
run_fullscreen_space_case false

log "==> Restoring dock-visible QA app instance for remaining checks"
defaults write "$DEFAULTS_DOMAIN" showDockIcon -bool true
prepare_isolated_app_instance

log "==> QA 1/7: overlay claims foreground, hides Dock, keeps menu bar visible"
show_overlay
frontmost="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
[[ "$frontmost" == "TagLauncher" ]] || { echo "FAIL: frontmost app is $frontmost, expected TagLauncher" >&2; exit 1; }
swift_assert overlay

log "==> QA 1/7 and 4/7: settings floats above appgrid and quick search"
open_appgrid_quick_search_with_retry
send_cmd_comma
sleep 0.7
swift_assert settings

log "==> QA 2/7: import/export file panel floats above settings"
click_settings_control data-tab
sleep 0.3
click_settings_control export
sleep 0.7
swift_assert file-panel
send_keycode 53
sleep 0.3
close_settings_window
sleep 0.9
swift_assert overlay
assert_frontmost_taglauncher

log "==> QA 4/7 and 5/7: appgrid-space quick search and double-Esc behavior"
open_appgrid_quick_search_with_retry
send_keycode 53
sleep 0.4
swift_assert overlay
send_keycode 53
sleep 0.4
swift_assert no-overlay

log "==> QA 4/7: appgrid scroll keeps Space and Esc keyboard routing"
show_overlay
for _ in {1..5}; do
  page_scroll_appgrid
  open_appgrid_quick_search_with_retry
  send_keycode 53
  sleep 0.25
  swift_assert overlay
done
page_scroll_appgrid
send_keycode 53
sleep 0.35
swift_assert no-overlay

log "==> QA 5/7: clicking outside quick search closes search, not appgrid"
show_overlay
open_appgrid_quick_search_with_retry
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
  rg -Fq 'statusMenuScreenForNextOverlay = overlayController.screenContainingCurrentPointer()' "$ROOT_DIR/Apptag/ApptagApp.swift"
  rg -Fq 'screenContainingCurrentPointer() ??' "$ROOT_DIR/Apptag/OverlayWindowController.swift"
  rg -Fq 'NSMouseInRect(mousePoint, $0.frame, false)' "$ROOT_DIR/Apptag/OverlayWindowController.swift"
  log "PASS screen-following static path: single physical display here; code selects NSScreen under current pointer"
fi

log "==> QA 7/7: final chrome state still valid"
swift_assert overlay
send_keycode 53
sleep 0.4
swift_assert no-overlay

log "ALL WINDOW LOGIC QA PASSED"
