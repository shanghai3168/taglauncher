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

## AI-Assisted App Categorization

### Product Goal

Help users create a useful TagLauncher category layout with very low effort. The user should be able to describe the desired tag names in natural language, then receive a proposed tag/category layout for the apps installed on their Mac.

### Version Plan

#### TagLauncher 6.0.0: Local Category Creator

Ship a local-only version first. This version does not use a server and does not perform intelligent app assignment.

Goal:

- let the user speak or type desired category/tag names
- parse the input into short tag chips
- create those tags locally
- append them to `tagOrder`
- leave app assignment to the existing manual/editing workflow

Why this belongs in 6.0.0:

- no backend dependency
- no LLM cost
- no upload/privacy review burden
- validates the entry point, wording, parsing, and user workflow before adding AI
- gives users immediate value even before intelligent classification exists

Suggested interaction:

1. User opens "Create Categories" from Preferences > Tags.
2. User types or dictates a messy list such as "工作 设计 写作 娱乐 系统工具".
3. The app parses it into chips.
4. The user can rename/delete/reorder chips.
5. The app creates missing tags locally and preserves existing tags.
6. The app shows a short success state and points the user back to edit mode for app assignment.

Implementation notes:

- Use macOS dictation into a regular text field; no custom audio handling in 6.0.0.
- Accept separators such as newline, comma, Chinese comma, semicolon, slash, bullet, and spaces for short CJK phrases.
- Trim whitespace and punctuation.
- Reject empty labels and duplicates.
- Warn when labels are too long.
- Do not delete or overwrite existing tags.
- Assign colors by cycling through `TagColor.allIndices`.
- Save through the existing `TagDatabase.save` path.

#### Later Version: AI Categorization Draft

After 6.0.0 proves the local category-creation flow, add the server-backed AI draft feature.

### Recommended AI Version

Do not make the first version fully automatic. Use a trust-building flow:

1. User opens an "AI Categorize" entry from Preferences > Tags or the overlay edit mode.
2. App shows a compact dialog with:
   - a text input for category names or natural-language intent
   - suggested starter chips such as Work, Design, Writing, Development, Study, Entertainment, Utilities
   - a clear privacy note explaining that app names, paths, bundle identifiers, and the user's requested category names will be uploaded only after confirmation
3. User confirms upload.
4. Server returns a draft JSON plan.
5. App displays a preview:
   - new tags
   - tag order
   - each app's proposed tag assignment
   - conflicts and uncertain apps
6. User can apply, edit, or cancel.
7. Applying the plan writes through `TagDatabase.save`, after creating a local backup snapshot so the change can be undone.

### Client Data To Send

Send only the minimum needed for classification:

- app display name
- bundle identifier
- install path category, for example `/Applications`, `/System/Applications`, `~/Applications`
- current tags, if any
- user-provided desired category names or intent
- current app language

Avoid uploading icons, full user paths beyond the app path already needed for local mapping, unrelated files, or usage history.

### Server Strategy

The backend does not need a heavy agent. It can be a small stateless API:

- `POST /v1/categorization-plans`
- validates input
- normalizes category names
- calls one lightweight LLM with a strict JSON schema
- validates the returned JSON
- returns a draft plan with confidence and reasons

Use a provider-adapter layer so the app is not locked to one model vendor. For the first version, the model should output only structured JSON; no tool use, no browsing, no remote code execution.

### Cost Strategy

This is a low-token, single-turn classification problem. A typical request can stay small by sending app names, bundle IDs, and 5-15 desired categories. The cost-effective path is:

- start with a cheap mini/flash/lite model
- use strict JSON schema output
- retry once with a stronger model only if validation fails or confidence is low
- cache common app classification hints server-side by bundle identifier
- optionally pre-classify well-known bundle IDs locally before calling the model

### Output Plan Shape

The server should return a draft, not a final overwrite:

```json
{
  "version": 1,
  "tags": [
    { "name": "Design", "color": 1 }
  ],
  "tagOrder": ["Design"],
  "assignments": [
    {
      "path": "/Applications/Figma.app",
      "appName": "Figma",
      "tags": ["Design"],
      "confidence": 0.95,
      "reason": "Design/prototyping tool"
    }
  ],
  "unassigned": [],
  "warnings": []
}
```

The local app converts this draft into the existing `TagDatabase.Store` format:

- `tags`: tag name to color
- `tagOrder`: ordered category list
- `appTags`: app path to tag-name array

### Interaction Notes

- Best entry point: Preferences > Tags, plus a small "AI Categorize" button in overlay edit mode.
- Keep the first dialog small and discoverable, not a big chatbot.
- Let users paste messy text; parse it into chips before upload.
- Limit category names to short labels and warn on overly long names.
- Never silently replace the user's existing layout. Show a before/after preview.
- Add a one-click undo after applying.

### Privacy And App Store Notes

- Explicit upload confirmation is required.
- The privacy copy should say exactly what is uploaded.
- Add a local-only fallback: if the user declines upload, the app can still create empty tags from the typed list.
- Update App Store privacy answers if the server feature ships.

### Future Enhancements

- Built-in local rules for common apps by bundle identifier.
- User style presets: by work type, by life area, by frequency, by project, by app category.
- Voice input using macOS dictation into the same text field, so the app does not need to handle audio processing in v1.
- A later on-device model experiment if privacy becomes a key selling point, but this should not block the server-based MVP.
