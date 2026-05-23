# TagLauncher Mac App Store TODO

Baseline: `a416923` / `qa-passed-7.6.0-20260523`

## 0. Go/No-Go Gate

- [ ] Decide whether TagLauncher can ship through the Mac App Store or should remain direct-distribution only.
- [ ] Enable and test App Sandbox; Mac App Store distribution requires sandboxing.
- [ ] Audit whether these features survive sandboxing:
  - [ ] Global hotkeys.
  - [ ] Scanning installed apps.
  - [ ] Launching selected apps.
  - [ ] Import/export panels.
  - [ ] Login-at-launch behavior.
  - [ ] Window levels over fullscreen Spaces.
- [ ] Replace LaunchAgent writing with an App Store-safe login item approach if login launch remains required.
- [ ] Document any temporary sandbox exception entitlement and why review can verify it.

## 1. Apple Account And App Record

- [ ] Confirm Apple Developer Program membership is active.
- [ ] Accept current App Store Connect agreements.
- [ ] Complete tax and banking setup if the app will be paid.
- [ ] Create or confirm the App Store Connect app record:
  - [ ] Platform: macOS.
  - [ ] Name: `TagLauncher`.
  - [ ] Bundle ID: `com.taglauncher.app`.
  - [ ] SKU: choose a stable internal SKU, for example `taglauncher-macos`.
  - [ ] Primary language.
  - [ ] User access settings.
- [ ] Confirm the primary category matches the app bundle category.

## 2. Build, Signing, And Packaging

- [ ] Create an App Store signing path instead of the current ad-hoc local build.
- [ ] Add or generate an Xcode project/scheme if needed for App Store archive workflow.
- [ ] Add an entitlements file with App Sandbox enabled.
- [ ] Add only the minimum required sandbox entitlements.
- [ ] Verify `CFBundleShortVersionString` is `7.6.0`.
- [ ] Increment `CFBundleVersion` for every App Store upload attempt.
- [ ] Ensure the app icon includes App Store-ready sizes, including 1024x1024.
- [ ] Produce an App Store-signed build using Xcode or an equivalent supported workflow.
- [ ] Upload through Xcode, Transporter, altool, or App Store Connect API.
- [ ] Keep the direct-distribution DMG separate from the App Store upload artifact.

## 3. Privacy, Security, And Compliance

- [ ] Write and publish a privacy policy URL.
- [ ] Decide whether a privacy choices URL is needed.
- [ ] Complete App Store Connect app privacy answers.
- [ ] Audit local data:
  - [ ] Tags and preferences.
  - [ ] Installed app metadata.
  - [ ] Imported/exported files.
  - [ ] Crash or diagnostics data, if any.
  - [ ] Network calls, if any.
- [ ] Add `PrivacyInfo.xcprivacy` if required by the final build setup or SDK usage.
- [ ] Confirm no undeclared third-party SDKs are bundled.
- [ ] Confirm encryption export compliance answer.
- [ ] Prepare user-facing wording for any macOS permissions used by the app.
- [ ] Confirm no private APIs or review-risky window behavior are used.

## 4. Product Page Metadata

- [ ] App name.
- [ ] Subtitle.
- [ ] Short promotional text, if applicable.
- [ ] Full description.
- [ ] Keywords.
- [ ] What's New for `7.6.0`.
- [ ] Support URL.
- [ ] Marketing URL, if available.
- [ ] Privacy policy URL.
- [ ] Copyright.
- [ ] License agreement choice.
- [ ] Age rating questionnaire.
- [ ] Content rights declaration.
- [ ] Price and availability.
- [ ] App Review contact information.
- [ ] App Review notes explaining:
  - [ ] Global hotkey behavior.
  - [ ] Fullscreen/multi-display overlay behavior.
  - [ ] How to trigger appgrid and Quick Search.
  - [ ] Any sandbox exception entitlement.

## 5. Screenshots And Visual Assets

- [ ] Capture clean macOS screenshots from the locked build.
- [ ] Include appgrid view.
- [ ] Include Quick Search view.
- [ ] Include Settings view.
- [ ] Include import/export flow if useful.
- [ ] Prepare localized screenshots only after English/Chinese core metadata is approved.
- [ ] Verify screenshots meet current App Store Connect specs.
- [ ] Prepare optional app preview video only if it helps review/marketing.

## 6. QA For App Store Build

- [ ] Run `Scripts/window_logic_qa.sh` against the App Store-signed sandboxed build.
- [ ] Repeat manual two-real-screen smoke test.
- [ ] Test fresh install with no existing user defaults.
- [ ] Test upgrade from the current direct-distribution build.
- [ ] Test first launch permission prompts.
- [ ] Test login item behavior.
- [ ] Test import/export under sandbox.
- [ ] Test force-quit window remains above TagLauncher.
- [ ] Verify Dock/menu bar behavior while appgrid is visible.
- [ ] Verify App Store build has no debug logging or temp files.

## 7. Submission Flow

- [ ] Upload build.
- [ ] Wait for App Store Connect processing.
- [ ] Resolve upload warnings/errors.
- [ ] Add processed build to the app version.
- [ ] Fill every required metadata field.
- [ ] Attach screenshots.
- [ ] Complete privacy questionnaire.
- [ ] Complete sandbox exception usage information, if any.
- [ ] Add for Review.
- [ ] Submit for Review.
- [ ] Track review status and respond to reviewer questions quickly.

## 8. Release And Archive

- [ ] Choose manual or automatic release after approval.
- [ ] Create a final git tag for the submitted build.
- [ ] Archive the exact submitted artifact, entitlements, provisioning profile notes, and App Store Connect metadata.
- [ ] Record review feedback and required follow-up fixes.
- [ ] Keep the direct DMG release path separate from Mac App Store releases.
