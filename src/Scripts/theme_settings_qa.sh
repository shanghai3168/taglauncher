#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/Apptag"

python3 - "$APP_DIR" <<'PY'
import json
import re
import sys
from pathlib import Path

app_dir = Path(sys.argv[1])
theme_file = app_dir / "AppGridTheme.swift"
preferences_file = app_dir / "PreferencesView.swift"
defaults_file = app_dir / "AppDefaults.swift"
content_file = app_dir / "ContentView.swift"
grid_file = app_dir / "AppGridCollectionView.swift"
localization_dir = app_dir / "Localization"

theme_source = theme_file.read_text(encoding="utf-8")
preferences_source = preferences_file.read_text(encoding="utf-8")
defaults_source = defaults_file.read_text(encoding="utf-8")
content_source = content_file.read_text(encoding="utf-8")
grid_source = grid_file.read_text(encoding="utf-8")
edit_views_source = (app_dir / "EditModeViews.swift").read_text(encoding="utf-8")

expected_cases = [
    "defaultLight",
    "deepBlue",
    "black",
    "pink",
    "purple",
    "green",
    "blue",
    "colorful",
]
for case in expected_cases:
    if not re.search(rf"case\s+{re.escape(case)}\b", theme_source):
        raise SystemExit(f"missing AppGridTheme case: {case}")

if "case theme" not in preferences_source:
    raise SystemExit("SettingsTab is missing the theme tab")
if "settings.darkAppGrid" in preferences_source:
    raise SystemExit("legacy dark grid copy is still referenced by PreferencesView")
if "Toggle(tr(\"settings.darkAppGrid\")" in preferences_source:
    raise SystemExit("legacy dark grid toggle is still visible")
if "useDarkAppGrid" in content_source or "useDarkAppGrid" in grid_source:
    raise SystemExit("legacy dark grid boolean still drives AppGrid rendering")
if "CAGradientLayer" in grid_source:
    raise SystemExit("AppGridCollectionView still owns a background gradient layer")
if "useDarkAppGrid" not in defaults_source or "AppGridTheme.deepBlue.rawValue" not in defaults_source:
    raise SystemExit("legacy dark preference migration is missing")
if "var usesVisualEffectBackdrop: Bool" not in theme_source:
    raise SystemExit("theme visual-effect backdrop policy is missing")
if "var isPureBlackBackground: Bool" not in theme_source or "self == .black" not in theme_source:
    raise SystemExit("pure black background policy is missing")
if "case .deepBlue, .black:" not in theme_source or "return true" not in theme_source:
    raise SystemExit("dark glass must be limited to deepBlue and black")
if "case .defaultLight, .pink, .purple, .green, .blue, .colorful:" not in theme_source or "return false" not in theme_source:
    raise SystemExit("bright themes must keep light glass")
if "backgroundDimmingOpacity" not in theme_source or "case .deepBlue:" not in theme_source:
    raise SystemExit("theme background dimming policy is missing")
if "theme.usesVisualEffectBackdrop" not in content_source or "theme.isPureBlackBackground" not in content_source:
    raise SystemExit("ContentView does not apply backdrop/pure-black theme policy")
required_edit_tokens = {
    "editPrimaryTextColor",
    "editSecondaryTextColor",
    "editTertiaryTextColor",
    "editDividerColor",
    "editToolbarSurfaceColor",
    "editControlSurfaceColor",
    "editControlStrokeColor",
    "editInactiveIndicatorColor",
    "editDisabledTextColor",
    "editDisabledSurfaceColor",
    "editButtonShadowColor",
    "editAccentColor",
    "editConfirmForegroundColor",
}
missing_tokens = [token for token in sorted(required_edit_tokens) if token not in theme_source]
if missing_tokens:
    raise SystemExit(f"AppGridTheme missing edit-mode contrast tokens: {missing_tokens}")
if "private var renderedAppGridTheme: AppGridTheme" not in content_source:
    raise SystemExit("ContentView is missing the runtime theme override")
if "editPhase == .none ? appGridTheme : .defaultLight" not in content_source:
    raise SystemExit("edit mode must temporarily render with the default light AppGrid theme")
if "let theme = renderedAppGridTheme" not in content_source:
    raise SystemExit("AppGrid background does not use the runtime rendered theme")
if "AppGridCollectionView(" in content_source and "appGridTheme: renderedAppGridTheme" not in content_source:
    raise SystemExit("AppGridCollectionView is not passed the runtime rendered theme")
if "EditAppsHeaderView(" in content_source and "theme: renderedAppGridTheme" not in content_source:
    raise SystemExit("edit apps header is not passed the runtime rendered theme")
if "theme: renderedAppGridTheme" not in content_source:
    raise SystemExit("edit mode selectable controls are not passed the runtime rendered theme")
for view_name in ["EditAppsHeaderView", "EditOperationPicker", "EditConfirmButton", "EditAppsSidebarIntroView", "EditSelectableTagItem", "EditableAppSelectionItem"]:
    if f"let theme: AppGridTheme" not in edit_views_source:
        raise SystemExit("edit mode views do not accept AppGridTheme")
    if view_name not in edit_views_source:
        raise SystemExit(f"missing edit mode view: {view_name}")
for token in ["theme.editPrimaryTextColor", "theme.editAccentColor", "theme.editControlSurfaceColor", "theme.editDisabledSurfaceColor"]:
    if token not in edit_views_source:
        raise SystemExit(f"edit mode views do not use contrast token: {token}")
if ".buttonStyle(.bordered)" in edit_views_source:
    raise SystemExit("edit mode views still rely on default bordered button styling")
if ".buttonStyle(.bordered)" in content_source and "editTagsView" in content_source:
    raise SystemExit("ContentView still relies on default bordered button styling in edit mode")

required_keys = {
    "settings.theme",
    "settings.themeDesc",
    "settings.themeScopeDesc",
    "theme.default",
    "theme.deepBlue",
    "theme.black",
    "theme.pink",
    "theme.purple",
    "theme.green",
    "theme.blue",
    "theme.colorful",
}
files = sorted(localization_dir.glob("*.json"))
if len(files) != 29:
    raise SystemExit(f"expected 29 localization files, found {len(files)}")
for path in files:
    data = json.loads(path.read_text(encoding="utf-8"))
    legacy = {"settings.darkAppGrid", "settings.darkAppGridDesc"} & set(data)
    if legacy:
        raise SystemExit(f"{path.name} still has legacy dark grid keys: {sorted(legacy)}")
    missing = required_keys - set(data)
    if missing:
        raise SystemExit(f"{path.name} missing keys: {sorted(missing)}")
    raw_values = [
        key for key in required_keys
        if str(data.get(key, "")).startswith("settings.") or str(data.get(key, "")).startswith("theme.")
    ]
    if raw_values:
        raise SystemExit(f"{path.name} has raw key values: {raw_values}")

print("PASS theme settings QA: 8 themes, Theme tab, migration, AppGrid-only rendering, glass policy, edit-mode default-theme override, and 29-language keys are present")
PY
