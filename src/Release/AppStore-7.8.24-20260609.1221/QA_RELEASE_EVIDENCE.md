# QA Release Evidence

## Version

- Product: TagLauncher
- Version: 7.8.24
- Build: 20260609.1221
- Commit: 45a86f77964416a30ba6e93cbea86ed126f35600

## Scope

- First-run Smart Start confirmation no longer closes the whole App Grid.
- App Grid tag hover no longer auto-scrolls.
- Apple default app catalog and SmartStart resources remain intact.

## Verification Commands

```bash
APP_BUILD=20260609.1221 bash build.sh
codesign --verify --deep --strict build/TagLauncher.app
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' -c 'Print :CFBundleVersion' -c 'Print :CFBundleIdentifier' -c 'Print :LSApplicationCategoryType' build/TagLauncher.app/Contents/Info.plist
bash Scripts/apple_default_apps_resource_qa.sh
bash Scripts/apple_default_note_policy_qa.sh
bash Scripts/smartstart_catalog_resource_qa.sh
bash Scripts/quick_search_app_name_qa.sh
bash Scripts/quick_search_system_app_qa.sh
hdiutil verify build/TagLauncher-7.8.24-build20260609.1221.dmg
pkgutil --check-signature build/AppStore/TagLauncher-7.8.24-build20260609.1221.pkg
pkgutil --expand-full build/AppStore/TagLauncher-7.8.24-build20260609.1221.pkg /private/tmp/taglauncher-7824-pkg
codesign -d --entitlements - /private/tmp/taglauncher-7824-pkg/com.taglauncher.app.pkg/Payload/TagLauncher.app
find /private/tmp/taglauncher-7824-pkg -xattrname com.apple.quarantine -print
```

## Results

- Build: PASS
- Version/build/category: PASS
- Code signing strict verification: PASS before App Store packaging
- Apple default app resources: PASS
- Apple default note policy: PASS
- SmartStart catalog resources: PASS
- Quick Search app-name QA: PASS
- Quick Search system app QA: PASS
- DMG verify: PASS
- App Store pkg generated and signed: PASS
- Expanded pkg entitlements/profile/category/quarantine preflight: PASS

## Known Gaps

- `Scripts/window_logic_qa.sh` was not used as final PASS evidence for this release because it has an existing unrelated early Dock/overlay window assertion issue observed before this Smart Start fix.
- Final first-run Smart Start visual confirmation should still be checked by the user on the candidate build before App Store submission if possible.
