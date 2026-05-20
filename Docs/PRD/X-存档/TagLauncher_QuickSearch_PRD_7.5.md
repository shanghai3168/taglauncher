# TagLauncher 7.5 PRD: Quick Search

Status: Draft for product and architecture review  
Owner: Product Manager / Architect  
Feature: Quick Search, search overlay, custom global shortcuts  
Version: 7.5  

## Product Goal

TagLauncher 7.5 should add a fast, keyboard-first Quick Search experience that lets users launch apps through muscle memory.

The main TagLauncher interface remains the place for browsing, organizing, tagging, and managing apps. Quick Search is a second launch entry: it is optimized for users who already have an intent and want to type a few characters, select the right app, and press Enter.

The feature must feel close to macOS Spotlight and Raycast in speed and clarity, while preserving TagLauncher's identity around app tags and app notes.

## Product Positioning

TagLauncher has two complementary entry modes:

| Mode | User intent | Primary behavior |
|---|---|---|
| Main interface | Browse, organize, manage, understand app groups | Show tags, app list, notes, and management affordances |
| Quick Search | Quickly locate and launch an app | Search across all apps by app name, tag name, and app note |

Quick Search must not be implemented as a simple filter inside the current app list. It must search across all available apps, regardless of which tag or view the main interface is currently showing.

Example:

- If the main interface is currently showing only the `Design` tag, searching `chrome` in Quick Search should still find Google Chrome.
- If the user searches a tag name such as `AI`, Quick Search should return apps associated with that tag.
- If the user searches a word that appears only in an app note, Quick Search should still be able to surface that app.

## Background

The current main interface shortcut is:

```text
Shift + Option + Space
⇧ ⌥ Space
```

This shortcut is reasonable for opening the full TagLauncher interface because it avoids the most common macOS system conflicts and avoids the increasingly crowded `Option + Space` shortcut used by AI tools and launchers.

However, fast app launching benefits from an even lighter interaction once TagLauncher is visible. The proposed 7.5 interaction is:

```text
⇧ ⌥ Space
Open TagLauncher

Space
Open Quick Search overlay

Type
Search and rank apps in real time

Enter
Open selected app
```

Users who want TagLauncher to become their first launcher should be able to configure a direct global Quick Search shortcut in Settings, including `⌥ Space` or `⌘ Space`, with clear conflict detection and resolution guidance.

## Shortcut Strategy

The product principle is:

```text
Default: avoid conflict.
Settings: let advanced users choose a stronger shortcut.
```

Default behavior:

| Shortcut | Behavior | Default status |
|---|---|---|
| `⇧ ⌥ Space` | Open main TagLauncher interface | Enabled |
| `Space` while TagLauncher is visible | Open Quick Search overlay | Enabled |
| Direct global Quick Search shortcut | Open Quick Search directly | Not enabled by default |

Recommended optional shortcuts shown in Settings:

| Shortcut | Meaning | Product guidance |
|---|---|---|
| `⌥ Space` | Launcher-style quick entry | Fast and familiar, but may conflict with ChatGPT, Raycast, Alfred, or other tools |
| `⌘ Space` | Replace Spotlight | Powerful for advanced users, but conflicts with macOS Spotlight unless the system shortcut is changed |
| Custom shortcut | User-defined | Recommended when the user already has many AI or launcher tools installed |

## Core User Stories

1. As a user, I can open TagLauncher with `⇧ ⌥ Space`, press `Space`, type a few letters, and launch the selected app with `Enter`.
2. As a user, I can search by app name, tag name, or app note.
3. As a user, I can type partial or non-contiguous letters and still get useful results.
4. As a user, I can use arrow keys to select a result and press `Enter` to open it.
5. As a user, I can click a search result to open it.
6. As a user, I can press `Esc` to close Quick Search without closing the main interface.
7. As an advanced user, I can assign a direct global shortcut to Quick Search.
8. As a user, if my chosen shortcut conflicts with macOS or another app, I get a clear explanation and a practical next step.

## Interaction Requirements

### Opening Quick Search

When TagLauncher is visible and no text input field is focused:

- Pressing `Space` opens Quick Search.
- The Quick Search input is focused immediately.
- The cursor is visible in the input field.
- The app list behind the overlay must not be reflowed or resized.

If the main interface is hidden:

- Pressing `⇧ ⌥ Space` opens the main interface.
- If the user has configured and successfully enabled a direct Quick Search global shortcut, pressing that shortcut opens Quick Search directly.

### Search Overlay

Quick Search should appear as a floating overlay above the existing app list.

Visual direction:

- Spotlight-like search field.
- Pure black or near-black background.
- White input text.
- Minimal border or shadow for separation.
- Large, clear input typography.
- Positioned near the top center of the TagLauncher window.
- High z-index above the app list.
- Does not push, resize, or rearrange the main app list.

Recommended layout:

```text
┌──────────────────────────────────────────────┐
│ Search apps, tags, notes...                  │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ App icon   App name                 Tags     │
│            matched note snippet              │
├──────────────────────────────────────────────┤
│ App icon   App name                 Tags     │
│            matched note snippet              │
└──────────────────────────────────────────────┘
```

The result list can appear directly below the search field in the same overlay layer.

### Empty Query State

When Quick Search opens with an empty query:

- Show a small list of recent or frequently opened apps.
- Select the first item by default if results exist.
- Do not show the full app catalog as a giant list.

This makes the overlay immediately useful even before typing.

### Typing and Matching

While the user types:

- Results update in real time.
- Matching should feel instant.
- The current selection should default to the top-ranked result.
- If the current selected app remains in the result list after typing, preserve the selection when reasonable.
- If the selected app disappears, select the top result.

### Keyboard Navigation

Required keys:

| Key | Behavior |
|---|---|
| `↑` | Move selection to previous result |
| `↓` | Move selection to next result |
| `Enter` | Open selected result |
| `Esc` | Close Quick Search |
| `Space` inside the input | Insert a space character |

Escape behavior:

- If Quick Search is open, `Esc` closes Quick Search and returns to the main interface.
- If Quick Search is closed and the main interface is visible, existing main interface close behavior may continue to apply.

### Mouse Interaction

Required behavior:

- Hovering a result highlights it.
- Clicking a result opens the app.
- Clicking outside the overlay closes Quick Search only if this matches the existing main interface behavior. If the existing product does not use outside-click dismissal, keep behavior consistent.

## Search Scope

Quick Search searches all launchable apps known to TagLauncher.

Required searchable fields:

| Field | Requirement | Weight |
|---|---|---|
| App display name | Required | Highest |
| App localized name, if available | Required when available | Highest |
| Tag names | Required | Medium-high |
| App note / remark | Required | Medium |
| Bundle identifier | Optional, lower priority | Low |

Future searchable fields:

- User-defined aliases.
- Pinyin or initials for Chinese app names and notes.
- Recent command history.
- TagLauncher actions such as settings or tag management commands.

These future fields must not block the 7.5 release.

## Fuzzy Search Requirements

The word "fuzzy" has two meanings in this PRD.

First, search must cover multiple fields:

- App names.
- Tag names.
- App notes.

Second, character matching does not require a strict full prefix match.

Required match types:

| Match type | Example |
|---|---|
| Exact match | `Figma` finds `Figma` |
| Prefix match | `fig` finds `Figma` |
| Substring match | `shop` finds `Photoshop` |
| Acronym match | `gc` finds `Google Chrome` |
| Subsequence match | `ps` finds `Photoshop` |
| Case-insensitive match | `chrome`, `Chrome`, and `CHROME` can all find `Google Chrome` |

For Chinese text:

- Direct Chinese character matching is required.
- Mixed Chinese and Latin text should be searchable when present in app names, tags, or notes.
- Pinyin matching is not required for 7.5, but the search index should not make it hard to add later.

## Ranking Requirements

Search ranking should optimize for launching the intended app with as few keystrokes as possible.

Recommended scoring model:

```text
finalScore =
  textMatchScore
  + fieldWeight
  + recentOpenBoost
  + frequencyBoost
```

Field weights:

| Field | Ranking rule |
|---|---|
| App name | Strongest signal |
| App localized name | Strongest signal |
| Tag name | Strong signal |
| App note | Useful supporting signal |
| Bundle identifier | Weak supporting signal |

Text match priority:

```text
exact match
prefix match
substring match
acronym match
subsequence match
```

Behavioral boosts:

- Apps opened recently should receive a small boost.
- Apps opened frequently should receive a small boost.
- Behavioral boosts must not completely overpower strong text matches.

Example:

- Searching `fi` should rank `Figma` above an app whose note merely contains `file`.
- Searching `ai` may rank a frequently used AI app above a rarely used app with a weak note match.

## Result Row Requirements

Each result row should include:

- App icon.
- App display name.
- Matched tags, if relevant.
- Note snippet, if the note contributed to the match.
- Visual selected state.

Optional but recommended:

- Highlight the matched part of app names, tags, or notes.
- Show a small secondary label such as bundle name only when useful.

The row must remain compact and scannable. Quick Search is not a detail view.

## Launch Behavior

When the user presses `Enter` or clicks a result:

1. Launch the selected app.
2. Close Quick Search.
3. Close or hide the main interface according to existing TagLauncher launch behavior.
4. Update recent-open and open-count data if TagLauncher already tracks this, or add the minimum local tracking needed for ranking.

If app launch fails:

- Keep Quick Search open or return to the main interface.
- Show a short, clear error message.
- Do not lose the user's query immediately.

## Custom Shortcut Settings

Settings must expose shortcut configuration for:

| Setting | Default |
|---|---|
| Main interface shortcut | `⇧ ⌥ Space` |
| Direct Quick Search shortcut | Disabled / unset |

The shortcut recording UI must:

- Let users record a new shortcut.
- Let users clear a shortcut.
- Let users restore the default main interface shortcut.
- Show whether the shortcut is active.
- Detect conflicts before presenting a shortcut as successfully enabled.

Recommended UI states:

| State | Meaning |
|---|---|
| Active | Shortcut was registered successfully |
| Conflict | Shortcut is already used by macOS or another app |
| Pending | User chose the shortcut, but it cannot currently be activated |
| Disabled | No shortcut is assigned |

## Shortcut Conflict Detection

When a user records or saves a shortcut, TagLauncher must attempt to register it immediately.

If registration succeeds:

- Save the shortcut.
- Show it as active.
- The shortcut should work immediately without restarting the app.

If registration fails:

- Do not silently accept the shortcut as active.
- Show a clear conflict state.
- Explain the likely reason.
- Offer a practical resolution path.

Known macOS conflicts that should receive special copy:

| Shortcut | Default macOS use |
|---|---|
| `⌘ Space` | Spotlight |
| `⌥ ⌘ Space` | Finder search window |
| `⌃ Space` | Previous input source |
| `⌃ ⌥ Space` | Next input source |
| `⌃ ⌘ Space` | Emoji and symbols |

For unknown conflicts:

```text
This shortcut is already used by macOS or another app.
Choose another shortcut, or change the shortcut in the other app and try again.
```

For `⌘ Space`:

```text
⌘ Space is currently used by macOS Spotlight. TagLauncher cannot use it at the same time.

To use ⌘ Space for TagLauncher:
1. Open System Settings > Keyboard > Keyboard Shortcuts > Spotlight.
2. Turn off or change "Show Spotlight search".
3. Return to TagLauncher and click Retry.
```

Required actions:

- Choose another shortcut.
- Retry.
- Open system shortcut settings when possible.

Important implementation rule:

- TagLauncher should not use low-level keyboard interception to forcibly steal system shortcuts.
- The product should prefer transparent registration, clear status, and user-controlled resolution.

## Data and Architecture Requirements

Quick Search should be implemented as a separate search capability, not as logic embedded inside the app list UI.

Recommended module boundaries:

```text
App data / Tag data / Note data
        ↓
SearchIndexService
        ↓
SearchController
        ↓
QuickSearchOverlay UI
        ↓
Launch action
```

Responsibilities:

| Module | Responsibility |
|---|---|
| SearchIndexService | Build and refresh searchable documents |
| SearchController | Manage query, result ranking, selected index, keyboard navigation |
| QuickSearchOverlay UI | Render input, results, selected state, empty state |
| ShortcutSettings | Record shortcuts, persist settings, show status |
| ShortcutRegistration | Register global shortcuts and return success or conflict state |

Searchable document shape:

```text
appId
bundleIdentifier
displayName
localizedNames
tagNames
note
aliases
lastOpenedAt
openCount
```

Index refresh triggers:

- App catalog changes.
- Tag assignment changes.
- Tag rename.
- App note changes.
- App install or removal scan.
- Locale or display language change, if localized tag names or app names are used.

## Performance Requirements

Quick Search must feel instant for normal local app catalogs.

Required:

- Opening the overlay should feel immediate.
- Typing should update visible results without noticeable lag.
- Search should run locally.
- No network request is required for search.
- The index may be kept in memory while TagLauncher is running.

Target:

- Result update within 50 ms for typical user catalogs.
- Search should remain smooth for at least 1,000 local app records.

## Privacy Requirements

Quick Search operates on local app metadata, user tags, and user notes.

Required:

- Do not send search queries to a server.
- Do not send app notes to a server.
- Store shortcut settings locally.
- Store recent-open and open-count data locally if used for ranking.

## Accessibility and Localization

Accessibility requirements:

- Full keyboard operation is required.
- The input field must have an accessible label.
- Result rows must expose app name and relevant metadata to accessibility APIs where supported.
- Selected state must be visually clear.

Localization requirements:

- All user-facing strings in the overlay and settings must be localizable.
- Shortcut conflict guidance must be localized.
- Search should use localized tag names where the current app language provides them.

## Non-Goals for 7.5

The following are not required for 7.5:

- Searching files, folders, contacts, browser history, or web results.
- Building a full command palette.
- AI-generated results or remote ranking.
- Pinyin search.
- Replacing Spotlight by default.
- Taking over `⌥ Space` by default.
- Forcibly intercepting system shortcuts through low-level keyboard event hooks.

## Acceptance Criteria

Quick Search overlay:

- `⇧ ⌥ Space` opens the main TagLauncher interface.
- Pressing `Space` while the main interface is visible and no text field is focused opens Quick Search.
- Quick Search appears as a floating overlay and does not reflow the app list.
- The search input is focused immediately.
- `Esc` closes Quick Search.
- `Enter` opens the selected app.
- `↑` and `↓` move through results.
- Clicking a result opens the app.

Search behavior:

- Search covers all apps known to TagLauncher, not only the currently visible tag or list.
- App name search works.
- Tag name search works.
- App note search works.
- Prefix, substring, acronym, and subsequence matches work.
- Matching is case-insensitive for Latin text.
- Direct Chinese character matching works.
- Empty query shows recent or frequently opened apps instead of the full catalog.
- No-result state is clear and does not look broken.

Ranking:

- App name matches outrank note-only matches when the query strength is comparable.
- Recent and frequent apps receive a modest boost.
- Strong textual relevance remains the dominant ranking factor.

Shortcut settings:

- Main interface shortcut is configurable.
- Direct Quick Search shortcut is configurable.
- Direct Quick Search shortcut is disabled or unset by default.
- Shortcut changes apply without restarting the app.
- Shortcut settings persist across app relaunch.
- Conflicting shortcuts are not shown as active.
- `⌘ Space` shows Spotlight-specific conflict guidance when registration fails.
- Unknown conflicts show generic conflict guidance.
- The user can retry after resolving a conflict.
- The user can choose another shortcut.

Privacy and performance:

- Search works offline.
- Search queries are not sent to any server.
- Result updates feel immediate on a normal local app catalog.

## QA Test Cases

Required manual QA scenarios:

1. Open main interface with `⇧ ⌥ Space`, press `Space`, verify Quick Search opens and input is focused.
2. Search by app name and launch the app with `Enter`.
3. Search by tag name and verify matching apps appear.
4. Search by app note and verify matching apps appear.
5. Search with non-prefix input such as `ps` for `Photoshop` and verify the app can be found.
6. Use `↑` and `↓` to change selection, then press `Enter`.
7. Open Quick Search, type a query, press `Esc`, verify the main interface remains visible.
8. Configure a direct Quick Search shortcut that is available, verify it works immediately.
9. Try to configure `⌘ Space` while Spotlight still owns it, verify conflict status and guidance.
10. Resolve or change the conflicting shortcut, click Retry, verify the status updates.
11. Relaunch TagLauncher and verify shortcut settings persist.
12. Confirm Quick Search does not send network requests during typing.

## Open Product Questions

1. Should direct Quick Search remain disabled by default, or should onboarding offer a guided choice during first run?
2. Should the empty query state prioritize recent apps, frequent apps, or a blend of both?
3. Should Quick Search always close the main interface after launching an app, or follow the current main interface behavior exactly?
4. Should app note snippets be visible by default in result rows, or only when the note field is the reason for the match?

## Release Principle

7.5 should make Quick Search feel like a native, reliable second launch path:

```text
Open.
Type.
Select.
Launch.
```

The feature should avoid shortcut fights by default, but give advanced users enough control to make TagLauncher their primary launcher when they choose to do so.
