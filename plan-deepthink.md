> 2026.0511.18:02已创建：plan-deepthink.md
>
> 加入了一个小章节：
>
> macOS Backward Compatibility
>
> 内容包括：
>
> - 是否可能兼容 macOS 10.15 的结论
> - 当前主要阻碍
> - 编译探测结果
> - 推荐路线
> - 未来迁移任务清单
>
> 后续关于未来版本、长期功能、架构想法、兼容性计划，都可以继续追加到这个文件里。当前这个文件还未提交进 git。

# Apptag Future Development Notes

This document is the shared parking lot for future-facing ideas, deeper product thoughts, and technical plans that should not interrupt the current release flow.

When a new future idea comes up, add it here first so it can be revisited, compared, and prioritized later.

## macOS Backward Compatibility

### Question

Can Apptag eventually support older macOS versions, especially macOS 10.15 Catalina?

### Current Conclusion

Supporting macOS 10.15 is theoretically possible, but it is not a simple deployment-target change. The current codebase is built around newer SwiftUI and AppKit APIs, so macOS 10.15 support would require a dedicated compatibility pass and likely a separate branch.

For the near-term App Store release, keeping the current macOS 15.0 minimum is safer.

### Main Compatibility Blockers

- The build currently targets only Apple Silicon:
  - `arm64-apple-macosx15.0`
  - macOS 10.15 only runs on Intel Macs, so a 10.15-compatible release would need an `x86_64-apple-macosx10.15` build, ideally packaged as a universal app when also supporting Apple Silicon.
- The app currently uses the SwiftUI app lifecycle:
  - `@main struct TagLauncherApp: App`
  - `Settings { PreferencesView() }`
  - This lifecycle is macOS 11+, so macOS 10.15 would require returning to an AppKit lifecycle with `NSApplicationDelegate`, manually managed preferences windows, and `NSHostingView`.
- The UI uses many SwiftUI APIs that are not available on macOS 10.15, including:
  - `LazyVGrid`
  - `LazyVStack`
  - `@AppStorage`
  - `Label`
  - `ProgressView`
  - Newer `.onChange` signatures
  - `.foregroundStyle`
  - `.ultraThinMaterial` / `.ultraThickMaterial`
  - `.controlSize`
  - `symbolRenderingMode`
- Several system APIs would need fallbacks:
  - `NSImage(systemSymbolName:)` is macOS 11+.
  - `UniformTypeIdentifiers` / `UTType.plainText` should be replaced or wrapped for older systems.
  - `NSOpenPanel.allowedContentTypes = [.json]` should fall back to `allowedFileTypes = ["json"]`.
  - `NSScreen.safeAreaInsets` should be guarded or removed for 10.15, where notch handling is not relevant.

### Compile Probe Result

A direct compile probe with:

```bash
swiftc -o /private/tmp/TagLauncher-compat-check \
  -framework AppKit \
  -framework SwiftUI \
  -framework Carbon \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -target arm64-apple-macosx10.15 \
  Apptag/*.swift
```

failed immediately on macOS 14+ API usage:

```text
'onChange(of:initial:_:)' is only available in macOS 14.0 or newer
```

That is only the first visible blocker; more availability issues would appear after fixing it.

### Recommended Path

- Do not block the 5.5.0 App Store release on macOS 10.15 compatibility.
- If broader compatibility becomes a product goal, create a dedicated branch such as `compat/macos-10.15`.
- Consider an intermediate target first:
  - macOS 13 or 14: likely lower effort.
  - macOS 10.15: larger migration, because it requires lifecycle, layout, storage-binding, symbol, drag/drop, and file-panel compatibility work.

### Possible Migration Tasks

- Add universal build support:
  - `x86_64-apple-macosx10.15`
  - `arm64-apple-macosx11.0+`
  - merge with `lipo` or migrate to an Xcode project / Swift Package build flow.
- Replace SwiftUI app lifecycle with an AppKit-compatible entrypoint.
- Wrap or replace newer SwiftUI APIs with compatibility components.
- Replace SF Symbol dependencies with bundled vector or PNG assets for older systems.
- Add availability guards for file panels, screen safe areas, app launching, and drag/drop type identifiers.
- Maintain a compatibility test checklist on an actual macOS 10.15 Intel machine or VM.

## Smart App Categorization For 7.0

### Product Goal

The biggest first-run pain is not launching apps; it is creating tags and assigning apps from scratch.

Apptag 7.0 should make the first experience feel intelligent: after the first scan, most common apps should already be placed into useful categories, with a clear way to review, undo, and improve the result.

Target user-facing promise:

> Open Apptag, wait briefly while it scans, then see most of your everyday apps already organized.

### Updated 7.0 Decision

The previous plan treated local category creation as a possible 6.0 feature and server-backed AI as a later feature. For 7.0, replace that with a hybrid `Smart Start` system:

1. Local bundled categorization handles common apps immediately.
2. Local heuristic rules handle obvious apps not in the bundled table.
3. Optional cloud AI improves the draft only after explicit user consent.

This gives the best balance of product experience, privacy, cost, and implementation risk.

### Why Not Pure Local Or Pure Cloud

#### Pure Local Table

Pros:

- instant first-run value
- no backend
- no model cost
- no network dependency
- minimal privacy/App Store complexity
- works offline

Cons:

- requires an app-category catalog
- misses long-tail apps
- categories may not match every user's mental model

Conclusion:

Use this as the first and default layer. It is the highest-ROI foundation.

#### Pure Cloud AI

Pros:

- better long-tail coverage
- can adapt to user intent, language, and preferred tag style
- can produce a complete categorization draft for unusual app libraries

Cons:

- requires backend/API operations
- adds privacy copy and App Store privacy work
- can fail when offline or rate-limited
- has recurring cost and abuse risk
- should not silently overwrite local user data

Conclusion:

Use this only as an opt-in enhancement, not as the default first-run path.

### Recommended 7.0 Product Flow: Smart Start

First-run flow for a new user:

1. App scans installed applications.
2. A progress screen says it is organizing apps locally.
3. The local catalog matches known apps by `bundleIdentifier`.
4. Local heuristics match obvious cases by app name, path, and metadata.
5. Apptag generates a local categorization draft.
6. If the user has no existing tag setup, apply high-confidence results automatically.
7. Show a result summary:
   - apps organized
   - tags created
   - apps left uncategorized
   - option to undo
   - option to edit manually
   - option to use AI Improve

For existing users:

1. Never overwrite their layout silently.
2. Show Smart Start as a preview/draft.
3. Let the user apply only missing assignments, replace selected categories, or cancel.
4. Always create a backup snapshot before applying.

### Local Catalog Strategy

Add a bundled catalog file:

```text
Apptag/SmartCategorization/SmartCategoryCatalog.json
```

Primary key:

- `bundleIdentifier`

Fallback keys:

- normalized app name
- executable/app bundle name
- install path category such as `/Applications`, `/System/Applications`, `~/Applications`

Suggested catalog entry shape:

```json
{
  "bundleIdentifier": "com.figma.Desktop",
  "names": ["Figma"],
  "category": "Design",
  "confidence": 0.98,
  "source": "bundled"
}
```

Initial categories should be broad, short, and understandable:

- Browser
- Communication
- Productivity
- Development
- Design
- Writing
- Media
- Utilities
- System
- Entertainment
- Finance
- Education
- AI Tools
- Security
- Other

For Chinese UI, display localized names, but keep internal category IDs stable.

### How To Build The Initial Catalog

Do not wait for a perfect dataset.

Recommended first version:

1. Start with 300-800 common Mac apps.
2. Generate a draft list semi-automatically from known popular Mac apps.
3. Review it manually for category quality.
4. Store stable identifiers and category IDs, not only display names.
5. Expand the table in later releases.

Good sources of first-pass coverage:

- Apple system apps
- browsers
- office/productivity apps
- design apps
- development tools
- communication apps
- media apps
- utilities
- common Chinese-market apps
- common global apps
- designer icon packs and macOS icon libraries, because apps that designers repeatedly draw replacement icons for are often high-visibility apps in real Mac workflows

Optional later enhancement:

- remotely update a signed JSON ruleset, so the app can improve common-app coverage without a full app release.

### Local Heuristic Rules

After exact catalog matches, use simple local rules for obvious cases:

- apps under `/System/Applications` -> System
- app names containing Terminal, Console, Activity Monitor -> Utilities/System
- app names containing Code, Xcode, Studio, Git -> Development
- app names containing Player, Music, Video -> Media
- app names containing Browser, Chrome, Firefox, Safari, Edge -> Browser

Rules should produce lower confidence than exact bundle matches.

Never use low-confidence local rules to overwrite existing user choices.

### AI Improve: Optional Cloud Enhancement

Add `AI Improve` only after the local Smart Start foundation works.

The cloud feature should produce a draft, not a final overwrite:

1. User clicks `AI Improve`.
2. App explains exactly what will be uploaded.
3. User confirms.
4. Client sends a minimal app list.
5. Server returns a structured categorization draft.
6. App shows preview.
7. User applies, edits, or cancels.
8. Applying creates a backup first and supports undo.

### Client Data To Send For AI Improve

Send only the minimum needed:

- app display name
- bundle identifier
- install path category, not full unnecessary user data
- current tags, if any
- user's desired categories or natural-language intent, if provided
- current app language

Do not upload:

- icons
- usage history
- unrelated file paths
- local notes
- private documents

### Server Strategy For AI Improve

The backend can be a small stateless API:

- `POST /v1/categorization-plans`
- validate request size and schema
- normalize category names
- apply server-side known-app cache by bundle identifier
- call a lightweight model for the remaining uncertain apps
- require structured JSON output
- validate the returned plan
- return confidence, warnings, and unassigned apps

Do not use a heavy multi-agent system for this. It is a single-turn classification task.

Use a provider-adapter layer so the app is not locked to one model vendor.

### Cost Strategy

This is a low-token classification task.

Recommended approach:

- classify known bundle IDs locally or from cache first
- send only unknown/uncertain apps to the model
- use a cheap mini/nano/flash/lite model first
- require structured JSON schema output
- retry once with a stronger model only if validation fails or confidence is low
- cache common model results server-side by bundle identifier

### Output Plan Shape

Both local Smart Start and cloud AI Improve should produce the same draft shape:

```json
{
  "version": 1,
  "source": "local-smart-start",
  "tags": [
    { "id": "design", "name": "Design", "color": 1 }
  ],
  "tagOrder": ["design"],
  "assignments": [
    {
      "path": "/Applications/Figma.app",
      "bundleIdentifier": "com.figma.Desktop",
      "appName": "Figma",
      "tagIDs": ["design"],
      "confidence": 0.98,
      "reason": "Known design/prototyping app"
    }
  ],
  "unassigned": [],
  "warnings": []
}
```

The app then converts this draft into the current `TagDatabase.Store` format until the store schema is upgraded.

### Data Safety Requirements

Before applying any generated categorization:

- preserve existing user tags
- do not delete tags silently
- do not overwrite existing assignments unless user explicitly chooses replace
- create a backup snapshot
- show a one-click undo
- keep a list of unassigned/uncertain apps

### Architecture Tasks

Recommended implementation modules:

```text
SmartCategoryCatalog.json
SmartCategoryCatalog.swift
SmartCategorizationDraft.swift
SmartCategorizer.swift
SmartStartView.swift
AICategorizationClient.swift
CategorizationPlanPreviewView.swift
TagBackupService.swift
```

### 7.0 Implementation Phases

#### Phase 1: Local Smart Start Foundation

- define stable category IDs
- add bundled catalog format
- implement exact bundle ID matching
- implement basic heuristic rules
- generate a draft plan
- apply only high-confidence results for new users

#### Phase 2: Preview, Undo, And Backup

- add categorization preview UI
- add backup before apply
- add one-click undo
- support existing-user merge behavior

#### Phase 3: Catalog Expansion

- build the first 300-800 app catalog
- add common Chinese and global apps
- localize category display names
- add catalog QA checklist

#### Phase 4: Optional AI Improve

- add opt-in upload confirmation
- build stateless categorization API
- return structured JSON draft
- validate, preview, backup, and apply locally

### Non-Goals For First 7.0 Iteration

- no automatic cloud upload on first launch
- no silent replacement of existing user layouts
- no chatbot-style categorization interface
- no model call for apps already covered locally
- no use of app icons, usage history, or user notes for cloud classification
