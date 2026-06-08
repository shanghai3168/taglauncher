#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L10N_SWIFT="$ROOT_DIR/Apptag/L10n.swift"
DATA_LAYER_SWIFT="$ROOT_DIR/Apptag/DataLayer.swift"
BUILD_SCRIPT="$ROOT_DIR/build.sh"
APPLE_DIR="$ROOT_DIR/Research/AppleDefaultApps"
APPLE_BASE="$APPLE_DIR/AppleDefaultApps.base.json"
APPLE_TRANSLATIONS="$APPLE_DIR/AppleDefaultApps.translations.json"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$L10N_SWIFT" ]] || fail "missing L10n.swift at $L10N_SWIFT"
[[ -f "$DATA_LAYER_SWIFT" ]] || fail "missing DataLayer.swift at $DATA_LAYER_SWIFT"
[[ -f "$BUILD_SCRIPT" ]] || fail "missing build.sh at $BUILD_SCRIPT"
[[ -f "$APPLE_BASE" ]] || fail "missing Apple default app base at $APPLE_BASE"
[[ -f "$APPLE_TRANSLATIONS" ]] || fail "missing Apple translations at $APPLE_TRANSLATIONS"

python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import plistlib
import re
import sys

root = pathlib.Path(sys.argv[1])
l10n_swift = root / "Apptag" / "L10n.swift"
data_layer = root / "Apptag" / "DataLayer.swift"
apple_dir = root / "Research" / "AppleDefaultApps"
base_path = apple_dir / "AppleDefaultApps.base.json"
translations_path = apple_dir / "AppleDefaultApps.translations.json"

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
if len(l10n_codes) != 29:
    fail(f"L10n.supported has {len(l10n_codes)} languages, expected 29")

max_note_match = re.search(r"static\s+let\s+maxAppNoteLength\s*=\s*(\d+)", data_layer.read_text(encoding="utf-8"))
if not max_note_match:
    fail("could not find TagDatabase.maxAppNoteLength")
max_note_length = int(max_note_match.group(1))
soft_note_length = max_note_length - 2

base = load_json(base_path)
translations = load_json(translations_path)
if base.get("resourceFormatVersion") != 1:
    fail("Apple base resourceFormatVersion must be 1")
if translations.get("resourceFormatVersion") != 1:
    fail("Apple translations resourceFormatVersion must be 1")
if translations.get("translationsVersion", 0) < 2:
    fail("Apple translationsVersion must be at least 2")
if base.get("noteLimit") != max_note_length:
    fail(f"Apple base noteLimit {base.get('noteLimit')} does not match TagDatabase.maxAppNoteLength {max_note_length}")
if set(base.get("supportedLanguages", [])) != set(l10n_codes):
    fail("Apple base supportedLanguages does not match L10n.supported")
if set(translations.get("supportedLanguages", [])) != set(l10n_codes):
    fail("Apple translations supportedLanguages does not match L10n.supported")

entries = base.get("entries")
if not isinstance(entries, list) or not entries:
    fail("Apple base entries is empty or not a list")

bundle_ids = set()
normalized_names = set()
for entry in entries:
    bundle = entry.get("bundleIdentifier")
    normalized = entry.get("normalizedName")
    canonical = entry.get("canonicalName")
    tags = entry.get("defaultTag")
    if not isinstance(bundle, str) or not bundle.strip():
        fail("Apple base entry has empty bundleIdentifier")
    if not bundle.lower().startswith("com.apple."):
        fail(f"Apple base contains non-Apple bundleIdentifier: {bundle}")
    if bundle.lower() in bundle_ids:
        fail(f"Apple base duplicate bundleIdentifier: {bundle}")
    bundle_ids.add(bundle.lower())
    if not isinstance(normalized, str) or not normalized.strip():
        fail(f"Apple base entry {bundle} has empty normalizedName")
    if normalized.lower() in normalized_names:
        fail(f"Apple base duplicate normalizedName: {normalized}")
    normalized_names.add(normalized.lower())
    if not isinstance(canonical, str) or not canonical.strip():
        fail(f"Apple base entry {bundle} has empty canonicalName")
    if not isinstance(tags, list) or not tags or not all(isinstance(tag, str) and tag.strip() for tag in tags):
        fail(f"Apple base entry {bundle} has empty defaultTag")
    if not isinstance(entry.get("familiar"), bool):
        fail(f"Apple base entry {bundle} familiar must be boolean")

def is_nested_inside_app_bundle(path: pathlib.Path) -> bool:
    return any(part.lower().endswith(".app") for part in path.parts[:-1])

def system_scanned_apple_apps() -> list[tuple[pathlib.Path, str]]:
    search_roots = [
        pathlib.Path("/System/Applications"),
        pathlib.Path("/System/Library/CoreServices/Applications"),
        pathlib.Path("/System/Cryptexes/App/System/Applications"),
        pathlib.Path("/System/Volumes/Preboot/Cryptexes/App/System/Applications"),
    ]
    seen: set[str] = set()
    result: list[tuple[pathlib.Path, str]] = []
    for search_root in search_roots:
        if not search_root.is_dir():
            continue
        for app_path in search_root.rglob("*.app"):
            if is_nested_inside_app_bundle(app_path):
                continue
            resolved = str(app_path.resolve())
            if resolved in seen:
                continue
            seen.add(resolved)
            info_path = app_path / "Contents" / "Info.plist"
            if not info_path.is_file():
                continue
            try:
                info = plistlib.loads(info_path.read_bytes())
            except Exception:
                continue
            bundle = info.get("CFBundleIdentifier")
            if isinstance(bundle, str) and bundle.lower().startswith("com.apple."):
                result.append((app_path, bundle.lower()))
    return result

missing_scanned_apps = [
    f"{bundle} at {app_path}"
    for app_path, bundle in system_scanned_apple_apps()
    if bundle not in bundle_ids
]
if missing_scanned_apps:
    fail(
        "Apple catalog is missing system apps scanned by AppIndexer: "
        + "; ".join(missing_scanned_apps[:12])
    )

display_names_by_language = translations.get("displayNamesByLanguage")
notes_by_language = translations.get("notesByLanguage")
if not isinstance(display_names_by_language, dict):
    fail("Apple translations displayNamesByLanguage must be an object")
if not isinstance(notes_by_language, dict):
    fail("Apple translations notesByLanguage must be an object")

for code in l10n_codes:
    display_names = display_names_by_language.get(code)
    notes = notes_by_language.get(code)
    zh_hans_notes = notes_by_language.get("zh-Hans", {})
    if not isinstance(display_names, dict):
        fail(f"Apple translations missing displayNamesByLanguage.{code}")
    if not isinstance(notes, dict):
        fail(f"Apple translations missing notesByLanguage.{code}")
    for entry in entries:
        normalized = entry["normalizedName"]
        display = display_names.get(normalized)
        note = notes.get(normalized)
        if not isinstance(display, str) or not display.strip():
            fail(f"Apple translations has empty displayName for {code}/{normalized}")
        if not isinstance(note, str) or not note.strip():
            fail(f"Apple translations has empty note for {code}/{normalized}")
        note_len = len(note)
        if note_len > max_note_length:
            fail(f"Apple translations note for {code}/{normalized} is {note_len} chars, limit is {max_note_length}")
        if note_len >= soft_note_length:
            fail(
                f"Apple translations note for {code}/{normalized} is {note_len} chars, "
                f"too close to {max_note_length}; shorten it to avoid clipped notes"
            )
        if code not in {"zh-Hans", "zh-Hant"} and note == zh_hans_notes.get(normalized):
            fail(f"Apple translations note for {code}/{normalized} is identical to zh-Hans")
        if code not in {"zh-Hans", "zh-Hant", "ja"} and re.search(r"[\u4e00-\u9fff]", note):
            fail(f"Apple translations note for {code}/{normalized} contains Chinese characters")

bad_fragments = [
    "Apple 內建 App",
    "Apple app for",
    "Apple-App für",
    "app Apple pour",
    "app Apple per",
    "app de Apple",
    "app da Apple",
    "Apple純正アプリ",
    "приложение Apple",
    "програма Apple",
    "Apple апликација",
    "แอป Apple",
    "ứng dụng Apple",
    "تطبيق Apple",
    "Apple uygulaması",
    "aplikace Apple",
    "Apple-app",
    "app Apple untuk",
    "aplicație Apple",
    "aplikacja Apple",
    "FamilyMart",
    "fishing",
    "pêche",
    "pesca",
    "Angeln",
    "medicine",
    "médicament",
    "medicamento",
    "remédio",
    "obat penyesalan",
    "ubat",
    "rybaření",
    "fiskeri",
    "vissen",
    "łowienie",
    "pescuit",
    "ماكينات القمار",
    "corresponding system",
    "File Management",
    "Pictures & Photos",
    "System Maintenance",
    "undefined",
    "null",
]

script_requirements = {
    "zh-Hans": re.compile(r"[\u4e00-\u9fff]"),
    "zh-Hant": re.compile(r"[\u4e00-\u9fff]"),
    "ja": re.compile(r"[\u3040-\u30ff\u4e00-\u9fff]"),
    "ko": re.compile(r"[\uac00-\ud7af]"),
    "ar": re.compile(r"[\u0600-\u06ff]"),
    "ar-Najdi": re.compile(r"[\u0600-\u06ff]"),
    "ru": re.compile(r"[\u0400-\u04ff]"),
    "uk": re.compile(r"[\u0400-\u04ff]"),
    "sr-Cyrl": re.compile(r"[\u0400-\u04ff]"),
    "th": re.compile(r"[\u0e00-\u0e7f]"),
}

for code in l10n_codes:
    path = apple_dir / f"AppleDefaultApps.localizations.{code}.json"
    if not path.is_file():
        fail(f"missing Apple localization file: {path.name}")
    catalog = load_json(path)
    if catalog.get("resourceFormatVersion") != 1:
        fail(f"{path.name} resourceFormatVersion must be 1")
    if catalog.get("catalogContentVersion") != base.get("catalogContentVersion"):
        fail(f"{path.name} catalogContentVersion does not match base")
    if catalog.get("language") != code:
        fail(f"{path.name} language field is {catalog.get('language')!r}, expected {code!r}")
    entries_by_bundle = {}
    for item in catalog.get("entries", []):
        bundle = item.get("bundleIdentifier")
        display = item.get("displayName")
        note = item.get("note")
        if not isinstance(bundle, str) or bundle.lower() not in bundle_ids:
            fail(f"{path.name} contains unknown bundleIdentifier: {bundle!r}")
        if bundle.lower() in entries_by_bundle:
            fail(f"{path.name} duplicate bundleIdentifier: {bundle}")
        entries_by_bundle[bundle.lower()] = item
        if not isinstance(display, str) or not display.strip():
            fail(f"{path.name} has empty displayName for {bundle}")
        if not isinstance(note, str) or not note.strip():
            fail(f"{path.name} has empty note for {bundle}")
        note_len = len(note)
        if note_len > max_note_length:
            fail(f"{path.name} note for {bundle} is {note_len} chars, limit is {max_note_length}")
        if note_len >= soft_note_length:
            fail(
                f"{path.name} note for {bundle} is {note_len} chars, "
                f"too close to {max_note_length}; shorten it to avoid clipped notes"
            )
        for fragment in bad_fragments:
            if fragment in note:
                fail(f"{path.name} note for {bundle} contains blocked fragment: {fragment!r}")
        if code in script_requirements and not script_requirements[code].search(note):
            fail(f"{path.name} note for {bundle} does not contain expected script for {code}")
    missing = bundle_ids - set(entries_by_bundle)
    if missing:
        fail(f"{path.name} is missing {len(missing)} Apple entries; first missing: {sorted(missing)[:5]}")

print(
    "PASS Apple default app resources: "
    f"{len(entries)} apps, {len(l10n_codes)} languages, notes <= {max_note_length}"
)
PY

rg -Fq 'AppleDefaultApps.base.json' "$BUILD_SCRIPT" \
  || fail "build.sh must copy AppleDefaultApps.base.json"
rg -Fq 'AppleDefaultApps.localizations.*.json' "$BUILD_SCRIPT" \
  || fail "build.sh must copy AppleDefaultApps.localizations.<lang>.json"
rg -Fq 'AppleDefaultApps.localizations.\(languageCode)' "$ROOT_DIR/Apptag/AppleDefaultAppCatalog.swift" \
  || fail "AppleDefaultAppCatalog must load AppleDefaultApps.localizations.<language>"
rg -Fq 'withExtension: "json.deflate"' "$ROOT_DIR/Apptag/AppleDefaultAppCatalog.swift" \
  || fail "AppleDefaultAppCatalog must prefer deflated localization resources"

printf 'PASS Apple default app runtime resource boundary\n'
