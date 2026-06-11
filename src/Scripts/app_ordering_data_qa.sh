#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_LAYER_SWIFT="$ROOT_DIR/Apptag/DataLayer.swift"
SMART_START_SWIFT="$ROOT_DIR/Apptag/SmartCategorization/SmartStartService.swift"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_GRID_SWIFT="$ROOT_DIR/Apptag/AppGridCollectionView.swift"
APP_DRAG_SWIFT="$ROOT_DIR/Apptag/AppDragCoordinator.swift"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$DATA_LAYER_SWIFT" ]] || fail "missing DataLayer.swift at $DATA_LAYER_SWIFT"
[[ -f "$SMART_START_SWIFT" ]] || fail "missing SmartStartService.swift at $SMART_START_SWIFT"
[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift at $CONTENT_VIEW_SWIFT"
[[ -f "$APP_GRID_SWIFT" ]] || fail "missing AppGridCollectionView.swift at $APP_GRID_SWIFT"
[[ -f "$APP_DRAG_SWIFT" ]] || fail "missing AppDragCoordinator.swift at $APP_DRAG_SWIFT"

python3 - "$DATA_LAYER_SWIFT" "$SMART_START_SWIFT" "$CONTENT_VIEW_SWIFT" "$APP_GRID_SWIFT" "$APP_DRAG_SWIFT" <<'PY'
import json
import pathlib
import re
import sys

data_layer = pathlib.Path(sys.argv[1])
smart_start = pathlib.Path(sys.argv[2])
content_view = pathlib.Path(sys.argv[3])
app_grid = pathlib.Path(sys.argv[4])
app_drag = pathlib.Path(sys.argv[5])
text = data_layer.read_text(encoding="utf-8")
smart_start_text = smart_start.read_text(encoding="utf-8")
content_text = content_view.read_text(encoding="utf-8")
app_grid_text = app_grid.read_text(encoding="utf-8")
app_drag_text = app_drag.read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def require(pattern: str, message: str, source: str = text) -> None:
    if not re.search(pattern, source, re.S):
        fail(message)


def extract_braced_block(marker_pattern: str, label: str, source: str = text) -> str:
    match = re.search(marker_pattern, source)
    if not match:
        fail(f"missing {label}")

    start = source.find("{", match.end())
    if start == -1:
        fail(f"missing opening brace for {label}")

    depth = 0
    for index in range(start, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start + 1:index]

    fail(f"missing closing brace for {label}")


store_block = extract_braced_block(r"\bstruct\s+Store\s*:\s*Codable\b", "TagDatabase.Store")
coding_keys_block = extract_braced_block(
    r"\benum\s+CodingKeys\s*:\s*String\s*,\s*CodingKey\b",
    "Store.CodingKeys",
    store_block,
)
fingerprint_block = extract_braced_block(
    r"\bprivate\s+struct\s+CategorySchemeFingerprint\s*:\s*Equatable\b",
    "CategorySchemeFingerprint",
)
fingerprint_func = extract_braced_block(
    r"\bprivate\s+static\s+func\s+categorySchemeFingerprint\s*\(\s*for\s+store\s*:\s*Store\s*\)\s*->\s*CategorySchemeFingerprint\b",
    "categorySchemeFingerprint(for:)",
)
reorder_apps_func = extract_braced_block(
    r"\bstatic\s+func\s+reorderApps\s*\(\s*inContainer\s+containerID\s*:\s*String\s*,\s*orderedPaths\s*:\s*\[String\]\s*\)",
    "TagEditor.reorderApps(inContainer:orderedPaths:)",
)
reset_uncategorized_func = extract_braced_block(
    r"\bstatic\s+func\s+resetAppTagAssignmentsToUncategorized\s*\(\s*\)\s*->\s*Store\b",
    "resetAppTagAssignmentsToUncategorized()",
)
content_drop_app_func = extract_braced_block(
    r"\bprivate\s+func\s+dropApp\s*\(\s*path\s*:\s*String\s*,\s*sourceTag\s*:\s*String\s*,\s*targetTag\s*:\s*String\s*,\s*copy\s*:\s*Bool\s*\)",
    "ContentView.dropApp(path:sourceTag:targetTag:copy:)",
    content_text,
)
app_grid_perform_drop_func = extract_braced_block(
    r"\bfunc\s+performDrop\s*\(\s*path\s*:\s*String\s*,\s*source\s*:\s*String\s*,\s*sourceContainerID\s*:\s*String\s*,\s*copy\s*:\s*Bool\s*\)",
    "AppGridGroupCardView.performDrop(path:source:sourceContainerID:copy:)",
    app_grid_text,
)

require(
    r"\bvar\s+containerAppOrder\s*:\s*\[String\s*:\s*\[String\]\]\s*=\s*\[:\]",
    "Store must persist containerAppOrder as [String: [String]] with an empty default",
    store_block,
)
require(
    r"\bcase\s+containerAppOrder\b",
    "Store.CodingKeys must include containerAppOrder for JSON roundtrip",
    coding_keys_block,
)
require(
    r"containerAppOrder\s*=\s*try\s+container\.decodeIfPresent\(\s*\[String\s*:\s*\[String\]\]\.self\s*,\s*forKey\s*:\s*\.containerAppOrder\s*\)\s*\?\?\s*\[:\]",
    "Store.init(from:) must decode missing containerAppOrder as an empty dictionary",
    store_block,
)

if re.search(r"\bfunc\s+encode\s*\(\s*to\s+encoder\s*:\s*Encoder\s*\)", store_block):
    require(
        r"\.encode\(\s*containerAppOrder\s*,\s*forKey\s*:\s*\.containerAppOrder\s*\)",
        "custom Store.encode(to:) must encode containerAppOrder",
        store_block,
    )

require(
    r"\blet\s+containerAppOrder\s*:\s*\[String\s*:\s*\[String\]\]",
    "CategorySchemeFingerprint must include containerAppOrder",
    fingerprint_block,
)
require(
    r"containerAppOrder\s*:",
    "categorySchemeFingerprint(for:) must populate containerAppOrder",
    fingerprint_func,
)
require(
    r"store\.containerAppOrder\b",
    "categorySchemeFingerprint(for:) must derive containerAppOrder from Store.containerAppOrder",
    fingerprint_func,
)
require(
    r"\bstatic\s+func\s+normalizedContainerID\s*\(",
    "TagDatabase must expose normalizedContainerID(_:) so UI never keys order by display name",
)
require(
    r"\bstatic\s+func\s+normalizedContainerAppOrder\s*\(",
    "TagDatabase must normalize containerAppOrder keys and path arrays",
)
require(
    r"let\s+effectiveTagDefinitions\s*=\s*tagDefinitions\s*\?\?\s*loadedStore\?\.tags\s*\?\?\s*\[:\](?:(?!\n\s*var\s+dict).)*normalizedContainerAppOrder\s*\([^)]*tags\s*:\s*effectiveTagDefinitions",
    "AppIndexer.group must normalize order with effective tag definitions so tag/system container order survives reload",
)
require(
    r"normalizedContainerAppOrder\s*\([^)]*appTags\s*:\s*appTagsByPath\s*,\s*validAppPaths\s*:\s*validAppPaths",
    "AppIndexer.group must normalize display order against current visible app paths and memberships",
)
require(
    r"\bstatic\s+func\s+normalizeContainerAppOrder\s*\(",
    "TagDatabase must normalize/prune containerAppOrder during lifecycle writes",
)
require(
    r"saveUserCategorySchemeMutation\s*\([^)]*reason\s*:\s*\"reorder-apps\"",
    "TagEditor.reorderApps must save through category scheme mutation with reason reorder-apps",
    reorder_apps_func,
)
require(
    r"store\.containerAppOrder\s*=\s*\[:\]",
    "reset to uncategorized must clear old containerAppOrder",
    reset_uncategorized_func,
)

require(
    r"\bstatic\s+func\s+exportTo\s*\([^)]*\)\s+throws\s*\{(?:(?!\n\s*static\s+func).)*JSONEncoder\(\)\.encode\(\s*store\s*\)",
    "exportTo(_:) must encode the full Store so containerAppOrder is exported",
)
require(
    r"\bstatic\s+func\s+importFrom\s*\([^)]*\)\s+throws\s*->\s*Store\s*\{(?:(?!\n\s*static\s+func).)*JSONDecoder\(\)\.decode\(\s*Store\.self\s*,\s*from\s*:\s*data\s*\)",
    "importFrom(_:) must decode the full Store so containerAppOrder is imported",
)
require(
    r"\bstatic\s+func\s+backup\s*\([^)]*\)\s*->\s*URL\?\s*\{(?:(?!\n\s*static\s+func).)*encoder\.encode\(\s*store\s*\)",
    "backup(_:reason:in:) must encode the full Store so ordering is included in snapshots",
)
require(
    r"\bstatic\s+func\s+restore\s*\(\s*fromBackupAt\s+path\s*:\s*String\s*\)\s*->\s*Bool\s*\{(?:(?!\n\s*(?:static|private)\s+func).)*JSONDecoder\(\)\.decode\(\s*Store\.self\s*,\s*from\s*:\s*data\s*\)",
    "restore(fromBackupAt:) must decode the full Store so ordering can be restored",
)
require(
    r"replaceExistingScheme\s*\{(?:(?!\n\s*\}).)*store\.containerAppOrder\s*=\s*\[:\]",
    "SmartStart replaceExistingScheme must clear stale containerAppOrder",
    smart_start_text,
)
require(
    r"let\s+containerAppOrder\s*:\s*\[String\s*:\s*\[String\]\]",
    "AppLibrarySnapshot must carry containerAppOrder from the same Store snapshot",
    pathlib.Path(sys.argv[1]).with_name("AppLibraryController.swift").read_text(encoding="utf-8"),
)
require(
    r"onReorderApps\s*:\s*\{\s*containerID\s*,\s*orderedPaths\s+in(?:(?!\n\s*\}).)*reorderApps\s*\(\s*inContainer\s*:\s*containerID\s*,\s*orderedPaths\s*:\s*orderedPaths\s*\)",
    "ContentView must wire AppGrid onReorderApps into the reorder write path",
    content_text,
)
require(
    r"TagEditor\.reorderApps\s*\(\s*inContainer\s*:\s*key\s*,\s*orderedPaths\s*:\s*paths\s*\)",
    "ContentView.reorderApps must persist the normalized container order",
    content_text,
)
require(
    r"sourceContainerID",
    "AppGrid drag payload must include sourceContainerID for language-stable same-container checks",
    app_grid_text,
)
require(
    r"activeReorderPath\s*\(\s*in\s+containerID\s*:\s*String\s*,\s*copy\s*:\s*Bool\s*\)",
    "AppGrid coordinator must expose a same-container reorder guard",
    app_grid_text,
)
require(
    r"shouldCancelEmptyDropForActiveReorder\s*\([^)]*path\s*:\s*String[^)]*screenPoint\s*:\s*NSPoint[^)]*copy\s*:\s*Bool",
    "AppGrid must cancel near-edge same-container reorder drops instead of routing them to remove-tag empty drop",
    app_grid_text,
)
require(
    r"if\s+sourceContainerID\s*==\s*group\.containerID\s*\{",
    "AppGrid same-container drops, including no-op and Option drops, must be swallowed before cross-container move/copy logic",
    app_grid_perform_drop_func,
)
same_container_index = app_grid_perform_drop_func.find("sourceContainerID == group.containerID")
same_return_index = app_grid_perform_drop_func.find("return", same_container_index)
cross_drop_index = app_grid_perform_drop_func.find("coordinator?.onDropApp")
if not (0 <= same_container_index < same_return_index < cross_drop_index):
    fail("AppGrid same-container drop must return before coordinator.onDropApp")
if "coordinator?.endAppIconDrag()" not in app_grid_perform_drop_func[same_container_index:same_return_index]:
    fail("AppGrid same-container drop must end drag state before returning")
if "clearReorderInsertion()" not in app_grid_perform_drop_func[same_container_index:same_return_index]:
    fail("AppGrid same-container drop must clear insertion state before returning")
source_guard_index = content_drop_app_func.find("guard sourceTag != targetTag else { return }")
apple_guard_index = content_drop_app_func.find("isAppleBuiltInDropTarget")
if not (0 <= source_guard_index < apple_guard_index):
    fail("ContentView.dropApp must no-op same source/target before Apple built-in warning")
require(
    r"parts\.dropFirst\(2\)\.first\s*\?\?\s*\"\"",
    "AppDragCoordinator must parse sourceContainerID from the drag payload",
    app_drag_text,
)

old_fixture = json.loads(
    """
    {
      "version": 1,
      "tags": {"Work": {"color": 1}},
      "appTags": {"/Applications/A.app": ["Work"]},
      "tagOrder": ["Work"]
    }
    """
)
new_fixture = json.loads(
    """
    {
      "version": 1,
      "tags": {"Work": {"color": 1}},
      "appTags": {"/Applications/A.app": ["Work"], "/Applications/B.app": ["Work"]},
      "tagOrder": ["Work"],
      "containerAppOrder": {"tag:Work": ["/Applications/B.app", "/Applications/A.app"]}
    }
    """
)

if "containerAppOrder" in old_fixture:
    fail("old fixture unexpectedly contains containerAppOrder")
if new_fixture.get("containerAppOrder", {}).get("tag:Work") != [
    "/Applications/B.app",
    "/Applications/A.app",
]:
    fail("new fixture does not preserve ordered app paths")

print(
    "PASS app ordering QA: Store decode/default, JSON roundtrip, "
    "fingerprint, import/export, backup/restore, SmartStart reset, "
    "ContentView wiring, and AppGrid stable payload gates are present"
)
PY
