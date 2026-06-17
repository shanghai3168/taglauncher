#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift"

python3 - "$CONTENT_VIEW_SWIFT" <<'PY'
import pathlib
import re
import sys

content = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def require(pattern: str, source: str, message: str) -> None:
    if not re.search(pattern, source, re.S):
        fail(message)


require(
    r"var\s+tagNavigationLastHoverScrollID\s*:\s*String\?\s*=\s*nil",
    content,
    "hover scroll must remember the last scrolled tag id",
)
require(
    r"var\s+tagNavigationLastHoverScrollAt\s*:\s*Date\?\s*=\s*nil",
    content,
    "hover scroll must remember the last scroll time",
)
require(
    r"private\s+let\s+tagNavigationHoverScrollDelay\s*:\s*TimeInterval\s*=\s*0\.14",
    content,
    "hover scroll must use the reviewed short hover-intent delay",
)
require(
    r"private\s+let\s+tagNavigationHoverScrollInterval\s*:\s*TimeInterval\s*=\s*0\.22",
    content,
    "hover scroll must keep throttling repeated scrolls for the same tag",
)
require(
    r"private\s+func\s+activateTagNavigation\(_\s+id:\s+String\)\s*\{(?P<body>.*?)scrollTo\(id\)(?P<body2>.*?)\n\s*\}",
    content,
    "clicking a tag must still scroll immediately",
)
require(
    r"private\s+func\s+handleTagNavigationHover\(_\s+id:\s+String,\s+active:\s+Bool\)\s*\{(?P<body>.*?)appGridInteraction\.appDragModeActive\s*\|\|\s*tagNavDragModeActive(?P<body2>.*?)scheduleTagNavigationHoverScroll\(id\)",
    content,
    "hovering a tag must schedule controlled scrolling and must be disabled during drag states",
)
require(
    r"private\s+func\s+scheduleTagNavigationHoverScroll\(_\s+id:\s+String\)\s*\{(?P<body>.*?)DispatchQueue\.main\.asyncAfter\(deadline:\s*\.now\(\)\s*\+\s*tagNavigationHoverScrollDelay\)(?P<body2>.*?)tagNavigationHoveredGroupName\s*==\s*id(?P<body3>.*?)!appGridInteraction\.appDragModeActive\s*&&\s*!tagNavDragModeActive(?P<body4>.*?)scrollToTagFromHover\(id\)",
    content,
    "scheduled hover scroll must only fire if the same tag is still hovered and no drag state is active",
)
require(
    r"private\s+func\s+scrollToTagFromHover\(_\s+id:\s+String\)\s*\{(?P<body>.*?)tagNavigationLastHoverScrollID\s*==\s*id(?P<body2>.*?)timeIntervalSince\(lastScrollAt\)\s*<\s*tagNavigationHoverScrollInterval(?P<body3>.*?)scrollTo\(id\)",
    content,
    "hover scrolling must be throttled and eventually call scrollTo(id)",
)

print("PASS: tag navigation hover scroll semantics are guarded")
PY
