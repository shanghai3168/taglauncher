# Screenshot Shot List

Apple allows one to ten Mac screenshots. Use `.png`, `.jpg`, or `.jpeg` images. Use a 16:10 Mac size:

- `2880 x 1800` preferred
- `2560 x 1600`
- `1440 x 900`
- `1280 x 800`

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

## Capture Notes

- Hide unrelated desktop clutter and notifications.
- Use one language consistently unless intentionally localizing.
- Avoid showing sensitive installed apps, private folders, account names, messages, or internal documents.
- Do not add marketing text into screenshots unless you later create a designed promotional frame.
- If raw screenshots are larger than accepted App Store sizes, export or resize final files to `2880 x 1800`.

## Resize Command

After placing raw screenshots in `Screenshots/raw/`, run this from the repo root:

```bash
mkdir -p Release/AppStore-7.8.12-20260604.0105/Screenshots/AppStore
for file in Release/AppStore-7.8.12-20260604.0105/Screenshots/raw/*.png; do
  name="$(basename "$file")"
  sips -z 1800 2880 "$file" --out "Release/AppStore-7.8.12-20260604.0105/Screenshots/AppStore/$name"
done
```

Review each resized file before uploading. If a screenshot looks stretched or cropped poorly, recapture at a cleaner 16:10 screen size instead of forcing it.
