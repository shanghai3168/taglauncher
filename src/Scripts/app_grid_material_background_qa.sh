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
    r"if\s+shouldRenderAppGridBehindQuickSearch\s*\{\s*"
    r"VisualEffectView\(material:\s*\.contentBackground,\s*blendingMode:\s*\.behindWindow\)"
    r"(?P<body>.*?)\.ignoresSafeArea\(\)"
    r"(?P<body2>.*?)\.allowsHitTesting\(false\)",
    content,
    "App Grid must use a non-interactive contentBackground material behind all content",
)

if re.search(
    r"if\s+shouldRenderAppGridBehindQuickSearch\s*\{\s*"
    r"VisualEffectView\(material:\s*\.hudWindow,\s*blendingMode:\s*\.behindWindow\)",
    content,
    re.S,
):
    fail("App Grid background must not regress to hudWindow material")

print("PASS: App Grid material background semantics are guarded")
PY
