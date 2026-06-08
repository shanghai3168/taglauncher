#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L10N_SWIFT="$ROOT_DIR/Apptag/L10n.swift"
SMARTSTART_SWIFT="$ROOT_DIR/Apptag/SmartCategorization/SmartStartService.swift"
CATALOG_DIR="$ROOT_DIR/Research/SmartStart/UltimateDefaultCatalog"
BASE_CATALOG="$CATALOG_DIR/SmartStart_UltimateDefaultCatalog.base.json"
APPLE_BASE="$ROOT_DIR/Research/AppleDefaultApps/AppleDefaultApps.base.json"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$L10N_SWIFT" ]] || fail "missing L10n.swift at $L10N_SWIFT"
[[ -f "$SMARTSTART_SWIFT" ]] || fail "missing SmartStartService.swift at $SMARTSTART_SWIFT"
[[ -f "$BASE_CATALOG" ]] || fail "missing SmartStart base catalog at $BASE_CATALOG"
[[ -f "$APPLE_BASE" ]] || fail "missing Apple default app base catalog at $APPLE_BASE"

python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
l10n_swift = root / "Apptag" / "L10n.swift"
localization_dir = root / "Apptag" / "Localization"
catalog_dir = root / "Research" / "SmartStart" / "UltimateDefaultCatalog"
base_path = catalog_dir / "SmartStart_UltimateDefaultCatalog.base.json"
apple_base_path = root / "Research" / "AppleDefaultApps" / "AppleDefaultApps.base.json"

EXPECTED_LANGUAGE_COUNT = 29

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)

def load_json(path: pathlib.Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        fail(f"{path} is not valid JSON: {error}")

text = l10n_swift.read_text(encoding="utf-8")
supported_block_match = re.search(
    r"static\s+let\s+supported\s*:\s*\[\(code:\s*String,\s*name:\s*String\)\]\s*=\s*\[(.*?)\n\s*\]",
    text,
    re.S,
)
if not supported_block_match:
    fail("could not find L10n.supported language list")

l10n_codes = re.findall(r'\("([^"]+)",\s*"[^"]+"\)', supported_block_match.group(1))
if len(l10n_codes) != EXPECTED_LANGUAGE_COUNT:
    fail(f"L10n.supported has {len(l10n_codes)} languages, expected {EXPECTED_LANGUAGE_COUNT}")
if len(set(l10n_codes)) != len(l10n_codes):
    fail("L10n.supported contains duplicate language codes")

missing_l10n_files = [
    code for code in l10n_codes
    if not (localization_dir / f"{code}.json").is_file()
]
if missing_l10n_files:
    fail(f"missing Apptag/Localization JSON files: {', '.join(missing_l10n_files)}")

base = load_json(base_path)
apple_base = load_json(apple_base_path)
apple_entries = apple_base.get("entries")
if not isinstance(apple_entries, list) or not apple_entries:
    fail("Apple default app base catalog has no entries")
apple_bundles = {
    entry.get("bundleIdentifier", "").lower()
    for entry in apple_entries
    if isinstance(entry.get("bundleIdentifier"), str)
}
apple_names = {
    entry.get("normalizedName", "").lower()
    for entry in apple_entries
    if isinstance(entry.get("normalizedName"), str)
}

base_languages = base.get("supportedLanguages")
if not isinstance(base_languages, list):
    fail("SmartStart base catalog supportedLanguages is not a list")
if len(base_languages) != EXPECTED_LANGUAGE_COUNT:
    fail(f"SmartStart base catalog has {len(base_languages)} supported languages, expected {EXPECTED_LANGUAGE_COUNT}")
if set(base_languages) != set(l10n_codes):
    fail(
        "SmartStart supportedLanguages does not match L10n.supported: "
        f"missing={sorted(set(l10n_codes) - set(base_languages))}, "
        f"extra={sorted(set(base_languages) - set(l10n_codes))}"
    )

entries = base.get("entries")
if not isinstance(entries, list):
    fail("SmartStart base catalog entries is not a list")

entry_ids = set()
for entry in entries:
    entry_id = entry.get("entryID")
    if not isinstance(entry_id, str) or not entry_id.strip():
        fail("SmartStart base catalog contains an entry without a non-empty entryID")
    if entry_id in entry_ids:
        fail(f"SmartStart base catalog contains duplicate entryID: {entry_id}")
    entry_ids.add(entry_id)

    bundle = entry.get("bundleIdentifier")
    if isinstance(bundle, str) and bundle.lower().startswith("com.apple."):
        fail(f"SmartStart base catalog still contains Apple bundle ID: {bundle}")
    if isinstance(bundle, str) and bundle.lower() in apple_bundles:
        fail(f"SmartStart base catalog bundle conflicts with Apple default catalog: {bundle}")
    normalized_name = entry.get("normalizedName")
    if isinstance(normalized_name, str) and normalized_name.lower() in apple_names:
        fail(f"SmartStart base catalog normalizedName conflicts with Apple default catalog: {normalized_name}")

note_files = sorted(catalog_dir.glob("SmartStart_UltimateDefaultCatalog.notes.*.json"))
note_languages = [
    path.name.split(".notes.", 1)[1].removesuffix(".json")
    for path in note_files
]
if len(note_files) != EXPECTED_LANGUAGE_COUNT:
    fail(f"found {len(note_files)} SmartStart notes language files, expected {EXPECTED_LANGUAGE_COUNT}")
if set(note_languages) != set(l10n_codes):
    fail(
        "SmartStart notes language files do not match L10n.supported: "
        f"missing={sorted(set(l10n_codes) - set(note_languages))}, "
        f"extra={sorted(set(note_languages) - set(l10n_codes))}"
    )

for notes_path in note_files:
    language = notes_path.name.split(".notes.", 1)[1].removesuffix(".json")
    notes = load_json(notes_path)
    if notes.get("language") != language:
        fail(f"{notes_path.name} language field is {notes.get('language')!r}, expected {language!r}")
    if notes.get("catalogContentVersion") != base.get("catalogContentVersion"):
        fail(f"{notes_path.name} catalogContentVersion does not match SmartStart base catalog")
    note_entries = notes.get("entries")
    if not isinstance(note_entries, list):
        fail(f"{notes_path.name} entries is not a list")

    seen_note_ids = set()
    for entry in note_entries:
        entry_id = entry.get("entryID")
        note = entry.get("note")
        if not isinstance(entry_id, str) or not entry_id.strip():
            fail(f"{notes_path.name} contains an entry without a non-empty entryID")
        if entry_id in seen_note_ids:
            fail(f"{notes_path.name} contains duplicate entryID: {entry_id}")
        if entry_id not in entry_ids:
            fail(f"{notes_path.name} contains note for entryID not present in SmartStart base: {entry_id}")
        if not isinstance(note, str) or not note.strip():
            fail(f"{notes_path.name} has an empty note for entryID {entry_id}")
        seen_note_ids.add(entry_id)

print(
    "PASS SmartStart catalog resources: "
    f"{len(l10n_codes)} languages, {len(entries)} non-Apple entries, "
    f"{len(note_files)} notes catalogs with no Apple default conflicts"
)
PY

rg -Fq 'SmartStartUltimateDefaultCatalog.notes.\(languageCode)' "$SMARTSTART_SWIFT" \
  || fail "SmartStartService must load runtime notes from SmartStartUltimateDefaultCatalog.notes.<language>.json(.deflate)"
rg -Fq 'withExtension: "json.deflate"' "$SMARTSTART_SWIFT" \
  || fail "SmartStartService must prefer deflated runtime notes resources"
if rg -n 'AppleDefaultAppNotes' "$ROOT_DIR/Apptag" "$ROOT_DIR/Research/SmartStart" --glob '*.swift' --glob '*.mjs' >/dev/null; then
  rg -n 'AppleDefaultAppNotes' "$ROOT_DIR/Apptag" "$ROOT_DIR/Research/SmartStart" --glob '*.swift' --glob '*.mjs' >&2 || true
  fail "AppleDefaultAppNotes legacy source must not remain in runtime or SmartStart generation paths"
fi

printf 'PASS SmartStart runtime boundary: no Apple default notes or legacy Apple source\n'
