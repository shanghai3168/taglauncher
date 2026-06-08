# Screenshot Shot List

Apple allows one to ten Mac screenshots. Use 16:10 PNG or JPG images. Recommended final size: `2880 x 1800`. Other accepted Mac sizes include `2560 x 1600`, `1440 x 900`, and `1280 x 800`.

Put original captures in `Screenshots/raw/`. Put final App Store-ready files in `Screenshots/AppStore/`.

## Recommended Final Set

Use five screenshots if possible.

1. `01-app-grid.png`
   - Show the main TagLauncher app grid.
   - Make sure several tag groups are visible.
   - Avoid private app names if needed.
   - This is the hero screenshot.

2. `02-quick-search.png`
   - Open AppGrid, press Space, and show Quick Search with a sample query.
   - Prefer a query that returns clean, recognizable results.
   - Keep AppGrid visible behind Quick Search.

3. `03-settings-appearance.png`
   - Show Settings with appearance/layout controls.
   - This demonstrates customization.

4. `04-hotkeys-or-search-settings.png`
   - Show the hotkey or Quick Search settings area.
   - This demonstrates the global launcher workflow.

5. `05-import-export-or-tag-editing.png`
   - Show import/export, tag editing, or a clean organized multi-tag grid.
   - This demonstrates data portability or organization depth.

## Optional Extra Shots

6. Split View / fullscreen Space behavior
   - Only include this if it looks visually clear.
   - AppGrid should appear above a fullscreen or Split View workspace.

7. Help/About page
   - Use only if you want to emphasize the built-in help link.

## Capture Notes

- Hide unrelated desktop clutter and notifications.
- Use the same language for all screenshots unless intentionally localizing.
- Avoid showing sensitive installed apps, private folders, account names, or messages.
- Do not add marketing text into the screenshots unless you later decide to create designed promotional frames.
- If taking full-screen captures on a Retina Mac, the raw image may be larger than accepted App Store sizes. Export or resize final files to `2880 x 1800`.

## Quick Resize Command

After placing raw screenshots in `Screenshots/raw/`, run this from the repo root to create `2880 x 1800` copies:

```bash
mkdir -p Release/AppStore-7.6.0-20260525.0016/Screenshots/AppStore
for file in Release/AppStore-7.6.0-20260525.0016/Screenshots/raw/*.png; do
  name="$(basename "$file")"
  sips -z 1800 2880 "$file" --out "Release/AppStore-7.6.0-20260525.0016/Screenshots/AppStore/$name"
done
```

Review each resized file before uploading. If a screenshot looks stretched or cropped poorly, recapture at a cleaner 16:10 screen size instead of forcing it.
