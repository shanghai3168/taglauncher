#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/Apptag"

python3 - "$APP_DIR" <<'PY'
import sys
from pathlib import Path

app_dir = Path(sys.argv[1])
content = (app_dir / "ContentView.swift").read_text(encoding="utf-8")
library = (app_dir / "AppLibraryController.swift").read_text(encoding="utf-8")

required_library_tokens = [
    "private static var cachedSnapshot: AppLibrarySnapshot?",
    "static func lastSnapshot() -> AppLibrarySnapshot?",
    "private static func updateLastSnapshot(_ snapshot: AppLibrarySnapshot)",
    "updateLastSnapshot(snapshot)",
]
for token in required_library_tokens:
    if token not in library:
        raise SystemExit(f"AppLibraryController missing startup snapshot token: {token}")

required_content_tokens = [
    "@State private var loadingSpinnerVisible = false",
    "@State private var loadingSpinnerToken = 0",
    "private let loadingSpinnerDelay: TimeInterval = 0.25",
    "hydrateFromLastAppLibrarySnapshotIfNeeded()",
    "AppLibraryController.lastSnapshot()",
    "scheduleLoadingSpinnerIfNeeded()",
    "hideLoadingSpinner()",
    "if loadingSpinnerVisible",
]
for token in required_content_tokens:
    if token not in content:
        raise SystemExit(f"ContentView missing startup loading token: {token}")

if "if allApps.isEmpty {\n                Spacer()\n                ProgressView().scaleEffect(0.8)" in content:
    raise SystemExit("AppGrid empty state still shows ProgressView immediately")

if "if allApps.isEmpty {\n                    Spacer(); ProgressView().scaleEffect(0.8); Spacer()" in content:
    raise SystemExit("edit AppGrid empty state still shows ProgressView immediately")

print("PASS AppGrid startup loading QA: last snapshot reuse and delayed spinner are present")
PY
