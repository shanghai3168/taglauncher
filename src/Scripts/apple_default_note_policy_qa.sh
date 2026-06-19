#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_LAYER_SWIFT="$ROOT_DIR/Apptag/DataLayer.swift"
SMARTSTART_SWIFT="$ROOT_DIR/Apptag/SmartCategorization/SmartStartService.swift"
APPLE_CATALOG_SWIFT="$ROOT_DIR/Apptag/AppleDefaultAppCatalog.swift"
CONTENT_VIEW_SWIFT="$ROOT_DIR/Apptag/ContentView.swift"
APP_DELEGATE_SWIFT="$ROOT_DIR/Apptag/ApptagApp.swift"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f "$DATA_LAYER_SWIFT" ]] || fail "missing DataLayer.swift"
[[ -f "$SMARTSTART_SWIFT" ]] || fail "missing SmartStartService.swift"
[[ -f "$APPLE_CATALOG_SWIFT" ]] || fail "missing AppleDefaultAppCatalog.swift"
[[ -f "$CONTENT_VIEW_SWIFT" ]] || fail "missing ContentView.swift"
[[ -f "$APP_DELEGATE_SWIFT" ]] || fail "missing ApptagApp.swift"

rg -Fq 'case appleDefault' "$DATA_LAYER_SWIFT" \
  || fail "AppNoteOrigin.appleDefault must be a first-class runtime origin"
rg -Fq 'apple: SmartDefaultNoteProvenance?' "$DATA_LAYER_SWIFT" \
  || fail "AppNoteMetadata must carry Apple default provenance separately"
rg -Fq 'origin: .manual' "$DATA_LAYER_SWIFT" \
  || fail "setAppNote must write manual metadata, including manual-empty"
rg -Fq 'noteFingerprint: TagDatabase.noteFingerprint("")' "$DATA_LAYER_SWIFT" \
  || fail "manual-empty notes must preserve an empty-note fingerprint"
rg -Fq 'seedDefaultAppleAppNotes' "$DATA_LAYER_SWIFT" \
  || fail "Apple default note seeding must have an Apple-specific path"
rg -Fq 'AppleDefaultAppCatalog.defaultNote(for: app)' "$DATA_LAYER_SWIFT" \
  || fail "Apple default note seeding must use AppleDefaultAppCatalog"
if rg -n 'SmartStartService\.defaultNote\(for: app\)' "$DATA_LAYER_SWIFT" >/dev/null; then
  rg -n 'SmartStartService\.defaultNote\(for: app\)' "$DATA_LAYER_SWIFT" >&2 || true
  fail "Apple default note seeding must not call SmartStartService.defaultNote(for:)"
fi

rg -Fq 'case .some(.appleDefault)' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must have an explicit appleDefault path"
rg -Fq 'expectedFingerprint == currentFingerprint' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must require fingerprint match before overwrite"
rg -Fq 'noteMatchesKnownDefault(' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must adopt legacy default notes by exact known-default fingerprint"
rg -Fq 'legacyDefaultNoteVariants' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must include historical default-note punctuation variants"
rg -Fq 'apple-default-note-migration' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must back up before adopting legacy no-metadata notes"
rg -Fq 'origin: .appleDefault' "$APPLE_CATALOG_SWIFT" \
  || fail "Apple relocalization must preserve appleDefault metadata"

rg -Fq 'let isManualOverride = existingMetadata?.origin == .manual' "$SMARTSTART_SWIFT" \
  || fail "SmartStart apply must detect manual note overrides"
rg -Fq '!isManualOverride' "$SMARTSTART_SWIFT" \
  || fail "SmartStart apply must not seed default notes over manual/manual-empty"
if rg -n 'static func defaultNote\(for app: AppInfo\)' "$SMARTSTART_SWIFT" >/dev/null; then
  rg -n 'static func defaultNote\(for app: AppInfo\)' "$SMARTSTART_SWIFT" >&2 || true
  fail "SmartStartService must not expose defaultNote(for:) as an Apple note source"
fi

rg -Fq 'AppleDefaultAppCatalog.relocalizeDefaultNotesForCurrentLanguage(apps: appsSnapshot)' "$CONTENT_VIEW_SWIFT" \
  || fail "language switching must relocalize Apple default notes"
rg -Fq 'SmartStartService.relocalizeDefaultNotesForCurrentLanguage(apps: appsSnapshot)' "$CONTENT_VIEW_SWIFT" \
  || fail "language switching must still relocalize SmartStart default notes"
rg -Fq 'relocalizeDefaultAppNotesForCurrentLanguageAsync()' "$APP_DELEGATE_SWIFT" \
  || fail "AppDelegate must relocalize default notes globally on startup and after language changes"
startup_relocalize_count=$(rg -F 'relocalizeDefaultAppNotesForCurrentLanguageAsync()' "$APP_DELEGATE_SWIFT" | wc -l | tr -d ' ')
if [ "$startup_relocalize_count" -lt 2 ]; then
  fail "AppDelegate must call default-note relocalization from both startup and language-change paths"
fi
rg -Fq 'AppleDefaultAppCatalog.relocalizeDefaultNotesForCurrentLanguage(apps: apps)' "$APP_DELEGATE_SWIFT" \
  || fail "global language-change path must relocalize Apple defaults even when App Grid is not open"
rg -Fq 'SmartStartService.relocalizeDefaultNotesForCurrentLanguage(apps: apps)' "$APP_DELEGATE_SWIFT" \
  || fail "global language-change path must relocalize SmartStart defaults even when App Grid is not open"

printf 'PASS Apple default note policy: Apple defaults, SmartStart defaults, and manual notes stay separated\n'
