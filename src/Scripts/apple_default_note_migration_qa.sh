#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLE_DIR="$ROOT_DIR/Research/AppleDefaultApps"
APPLE_CATALOG_SWIFT="$ROOT_DIR/Apptag/AppleDefaultAppCatalog.swift"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$APPLE_DIR/AppleDefaultApps.base.json" ]] || fail "missing AppleDefaultApps.base.json"
[[ -f "$APPLE_DIR/AppleDefaultApps.translations.json" ]] || fail "missing AppleDefaultApps.translations.json"
[[ -f "$APPLE_CATALOG_SWIFT" ]] || fail "missing AppleDefaultAppCatalog.swift"

python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
apple_dir = root / "Research" / "AppleDefaultApps"

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)

def load_json(path: pathlib.Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        fail(f"{path.name} is not valid JSON: {error}")

def normalized_note(value, limit):
    if not isinstance(value, str):
        return None
    normalized = value.strip()[:limit]
    return normalized or None

def note_fingerprint(value: str, limit: int = 80) -> str:
    normalized = value.strip()[:limit]
    hash_value = 0xCBF29CE484222325
    for byte in normalized.encode("utf-8"):
        hash_value ^= byte
        hash_value = (hash_value * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"{hash_value:016x}"

def strip_sentence_punctuation(value: str) -> str:
    punctuation = ".。．!！?？"
    result = value.strip()
    while result and result[-1] in punctuation:
        result = result[:-1]
    return result

def legacy_variants(note: str, limit: int) -> list[str]:
    trimmed = note.strip()[:limit]
    if not trimmed:
        return []
    variants = [trimmed]
    stripped = strip_sentence_punctuation(trimmed)
    if stripped != trimmed:
        variants.append(stripped)
    for suffix in [".", "。"]:
        punctuated = (stripped + suffix)[:limit]
        if punctuated:
            variants.append(punctuated)
    seen = set()
    result = []
    for variant in variants:
        if variant not in seen:
            seen.add(variant)
            result.append(variant)
    return result

base = load_json(apple_dir / "AppleDefaultApps.base.json")
translations = load_json(apple_dir / "AppleDefaultApps.translations.json")
languages = base.get("supportedLanguages", [])
note_limit = int(base.get("noteLimit", 80))
entries = base.get("entries", [])
bundle_ids = {
    entry.get("bundleIdentifier").lower()
    for entry in entries
    if isinstance(entry.get("bundleIdentifier"), str)
}
normalized_names = {entry.get("normalizedName") for entry in entries}

for bundle in ["com.apple.colorsyncutility", "com.apple.campo", "com.apple.siri.launcher"]:
    if bundle not in bundle_ids:
        fail(f"Apple base is missing {bundle}")

if "siri-campo" not in normalized_names:
    fail("Apple base is missing normalizedName siri-campo")

for section_name in ["displayNamesByLanguage", "notesByLanguage"]:
    section = translations.get(section_name)
    if not isinstance(section, dict):
        fail(f"Apple translations missing {section_name}")
    for language in languages:
        values = section.get(language)
        if not isinstance(values, dict):
            fail(f"Apple translations missing {section_name}.{language}")
        if not values.get("siri-campo"):
            fail(f"Apple translations missing {section_name}.{language}.siri-campo")

localizations = {}
for language in languages:
    path = apple_dir / f"AppleDefaultApps.localizations.{language}.json"
    catalog = load_json(path)
    localizations[language] = {
        item["bundleIdentifier"].lower(): item
        for item in catalog.get("entries", [])
        if isinstance(item, dict) and isinstance(item.get("bundleIdentifier"), str)
    }
    for bundle in ["com.apple.campo", "com.apple.siri.launcher"]:
        if bundle not in localizations[language]:
            fail(f"{path.name} is missing {bundle}")

colorsync_bundle = "com.apple.colorsyncutility"
zh_colorsync = localizations["zh-Hans"].get(colorsync_bundle)
ar_colorsync = localizations["ar"].get(colorsync_bundle)
if not zh_colorsync or not ar_colorsync:
    fail("ColorSync localization fixture is incomplete")

zh_default_note = normalized_note(zh_colorsync.get("note"), note_limit)
ar_default_note = normalized_note(ar_colorsync.get("note"), note_limit)
if not zh_default_note or not ar_default_note:
    fail("ColorSync default note fixture is empty")
if zh_default_note == ar_default_note:
    fail("ColorSync Arabic note must not equal zh-Hans note")

known_fingerprints_by_bundle = {}
for bundle in bundle_ids:
    fingerprints = set()
    for language in languages:
        item = localizations[language].get(bundle)
        if not item:
            continue
        note = normalized_note(item.get("note"), note_limit)
        if not note:
            continue
        for variant in legacy_variants(note, note_limit):
            fingerprints.add(note_fingerprint(variant, note_limit))
    known_fingerprints_by_bundle[bundle] = fingerprints

historical_default_notes = {
    "com.apple.chess": "系统自带国际象棋，摸鱼时比刷网页更优雅。",
    "com.apple.freeform": "无限白板，适合头脑风暴、草图和乱七八糟的想法。",
    "com.apple.home": "控制 HomeKit 设备，让 Mac 也能管家里的灯和空调。",
    "com.apple.music": "本地音乐和 Apple Music 的播放器。",
    "com.apple.passwords": "系统密码管家，账号、验证码和通行密钥集中管。",
    "com.apple.mobilephone": "通过 iPhone 在 Mac 上接打电话。",
    "com.apple.tv": "Apple TV 和本地影视内容的入口。",
    "com.apple.backup.launcher": "系统备份工具，后悔药就靠它提前准备。",
    "com.apple.diskutility": "管磁盘、分区、格式化和急救，别乱点但很重要。",
    "com.apple.screencontinuity": "在 Mac 上直接操作 iPhone，少一次伸手拿手机。",
}
for bundle, note in historical_default_notes.items():
    if bundle not in known_fingerprints_by_bundle:
        fail(f"historical default bundle is not in Apple base: {bundle}")
    for variant in legacy_variants(note, note_limit):
        known_fingerprints_by_bundle[bundle].add(note_fingerprint(variant, note_limit))

legacy_zh_note_with_period = zh_default_note + "。"
if note_fingerprint(legacy_zh_note_with_period, note_limit) not in known_fingerprints_by_bundle[colorsync_bundle]:
    fail("legacy zh-Hans ColorSync note with historical period must match known Apple defaults")

for bundle, note in historical_default_notes.items():
    if note_fingerprint(note, note_limit) not in known_fingerprints_by_bundle[bundle]:
        fail(f"historical default note must match for {bundle}")
    for language in languages:
        localized_entry = localizations[language].get(bundle)
        if not localized_entry:
            fail(f"historical default note target is missing localization for {language}/{bundle}")
        localized_note = normalized_note(localized_entry.get("note"), note_limit)
        if not localized_note:
            fail(f"historical default note target is empty for {language}/{bundle}")
        if language not in {"zh-Hans", "zh-Hant"} and localized_note == note:
            fail(
                "historical default note migration would keep Chinese text "
                f"for {language}/{bundle}: {localized_note!r}"
            )

manual_chinese_note = zh_default_note + " 我自己加的备注"
if note_fingerprint(manual_chinese_note, note_limit) in known_fingerprints_by_bundle[colorsync_bundle]:
    fail("manual note extending the Apple default must not match Apple default fingerprints")

wrong_bundle = "com.apple.siri.launcher"
if note_fingerprint(legacy_zh_note_with_period, note_limit) in known_fingerprints_by_bundle[wrong_bundle]:
    fail("Apple default note matching must be scoped by bundle identifier")

print(
    "PASS Apple default note migration fixture: "
    "legacy no-metadata defaults can migrate, manual notes stay protected, Campo is complete"
)
PY

rg -Fq 'noteMatchesKnownDefault(' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must match legacy notes against known Apple defaults"
rg -Fq 'legacyDefaultNoteVariants' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must include historical punctuation variants"
rg -Fq 'legacyDefaultNoteFingerprintsByBundleIdentifier' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must include historical Apple default notes"
rg -Fq 'a3b754a4f06eee33' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must include pre-metadata Chess default note"
rg -Fq 'metadata?.origin == .manual' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must protect manual notes"
rg -Fq 'apple-default-note-migration' "$APPLE_CATALOG_SWIFT" \
  || fail "AppleDefaultAppCatalog must back up before adopting legacy default notes"

printf 'PASS Apple default note migration runtime guardrails\n'
