# TagLauncher 7.5 PRD: Quick Search

Status: PMD rewrite for product and architecture review  
Owner: Product Manager  
Feature: Quick Search, search overlay, configurable global shortcuts  
Version: 7.5  

## Goal

TagLauncher 7.5 adds a keyboard-first Quick Search entry for users who already know what they want to launch.

Quick Search is not a filter for the currently visible app list. It searches all launchable apps known to TagLauncher across app names, tag names, and app notes.

Default launch path:

```text
Shift + Option + Space -> open main TagLauncher interface
Space                  -> open Quick Search
Type                   -> search and rank apps
Enter                  -> launch selected app
```

Advanced users can configure a direct global Quick Search shortcut. This shortcut is disabled by default.

## Product Decisions

| Topic | Decision |
|---|---|
| Default global shortcut | Keep `Shift + Option + Space` for the main interface |
| Direct Quick Search shortcut | Configurable, but disabled by default |
| `Space` behavior | Opens Quick Search only when the main interface is visible and normal typing/control interaction is not active |
| Search scope | All launchable apps, not only the current tag or current visible list |
| Empty query | Show recent apps first, then frequent apps to fill remaining slots |
| Launch success | Close Quick Search, then follow existing TagLauncher launch-window behavior |
| Launch failure | Keep the query and show a short error |
| Shortcut conflicts | Use normal shortcut registration; do not forcibly intercept system shortcuts |
| Privacy | Search and ranking data stay local |

## Scope

Required for 7.5:

- Quick Search overlay opened from the main interface with `Space`.
- Direct global Quick Search shortcut in Settings, disabled by default.
- Search across app display name, localized app name, tag name, and app note.
- Exact, prefix, substring, acronym, subsequence, and case-insensitive Latin matching.
- Direct Chinese character matching.
- Keyboard navigation and mouse launch.
- Recent and frequent app ranking boosts.
- Local persistence for shortcut settings and launch ranking data.
- Shortcut conflict detection through registration success or failure.

Not required for 7.5:

- File, folder, contact, browser history, or web search.
- Full command palette.
- AI-generated search results.
- Remote ranking or analytics.
- Pinyin matching.
- User-defined aliases.
- Replacing Spotlight by default.
- Taking over `Option + Space` by default.
- Low-level keyboard interception to steal system shortcuts.

## User Stories

1. As a user, I can open TagLauncher, press `Space`, type a few characters, and launch the selected app with `Enter`.
2. As a user, I can search by app name, tag name, or app note.
3. As a user, I can type partial or non-contiguous characters and still find relevant apps.
4. As a user, I can use arrow keys to change the selected result.
5. As a user, I can click a result to launch it.
6. As a user, I can press `Esc` to close Quick Search without losing the main interface when I opened it from the main interface.
7. As an advanced user, I can configure a direct global shortcut for Quick Search.
8. As a user, I can see whether a shortcut is active, disabled, or blocked by a conflict.

## Interaction Requirements

### Opening

When the main TagLauncher interface is visible, pressing `Space` opens Quick Search only if all conditions are true:

- Quick Search is not already open.
- No text input, search field, text area, or editable field is focused.
- No modal, popover, menu, confirmation dialog, or shortcut recorder is active.
- Focus is not on a control where `Space` is expected to activate or toggle that control.

When opened from the main interface:

- The overlay appears above the existing app list.
- The app list is not pushed, resized, or reflowed.
- The Quick Search input is focused immediately.
- The first available result is selected by default.

When opened from a direct global shortcut:

- TagLauncher opens the Quick Search overlay directly.
- The input is focused immediately.
- If the main interface was hidden before the shortcut was pressed, `Esc` hides the Quick Search window.

### Overlay

Quick Search appears as a floating overlay near the top center of the TagLauncher window.

Required behavior:

- The overlay uses the existing visual system where possible.
- The input is the primary focus.
- The result list appears below the input in the same overlay layer.
- The overlay sits above the app list and does not change the app list layout.
- The overlay supports empty, loading, result, no-result, and launch-failed states.

Visible result count: 6 to 8 rows.

### Empty Query

When the query is empty:

- Show up to 6 apps.
- Sort by most recently opened first.
- If fewer than 6 recent apps exist, fill the remaining slots with most frequently opened apps.
- Do not show the full app catalog.
- If no history exists, show an empty prompt: `Start typing to search apps, tags, and notes.`

Recent and frequent data must use successful TagLauncher-mediated app launches, not only launches from Quick Search.

### Typing and Selection

While the user types:

- Results update in real time.
- If the user has not manually changed selection, select the top-ranked result after each query update.
- If the user manually selected a result and that result remains visible after the query update, preserve the selection.
- If the selected result disappears, select the top-ranked result.
- If there are no results, no item is selected and `Enter` does nothing.
- If there are no results, show: `No apps found.`

### Keyboard

| Key | Behavior |
|---|---|
| `Up` | Move selection to the previous result; stay at the first result when already first |
| `Down` | Move selection to the next result; stay at the last result when already last |
| `Enter` | Launch the selected result |
| `Esc` | Close Quick Search |
| `Space` inside input | Insert a space character |

`Esc` behavior:

- If Quick Search was opened from the visible main interface, close only Quick Search and return to the main interface.
- If Quick Search was opened directly while the main interface was hidden, close Quick Search and hide the window.

### Mouse

- Hovering a result highlights it and updates the active selection.
- Clicking a result launches the app.
- Clicking inside the main interface but outside the overlay closes Quick Search and leaves the main interface visible.
- Clicking outside the TagLauncher window follows existing app behavior.

## Search Requirements

### Searchable Fields

| Field | Required | Ranking weight |
|---|---:|---|
| App display name | Yes | Highest |
| Localized app name | Yes, when available | Highest |
| Tag names | Yes | High |
| App note | Yes | Medium |
| Bundle identifier | Optional | Low |

Future fields such as aliases, pinyin, command history, and TagLauncher actions must not block 7.5.

### Query Normalization

Before matching:

- Trim leading and trailing whitespace.
- Collapse repeated spaces.
- Match Latin text case-insensitively.
- Treat punctuation in app names as separators for acronym matching.
- Keep Chinese characters as searchable characters.

Multi-word queries use `AND` semantics:

- Every query token must match at least one searchable field.
- Different tokens may match different fields on the same app.
- Ranking sums the best score from each matched token.

### Match Types

Required match types:

| Type | Example |
|---|---|
| Exact | `figma` matches `Figma` |
| Prefix | `fig` matches `Figma` |
| Substring | `shop` matches `Photoshop` |
| Acronym | `gc` matches `Google Chrome` |
| Subsequence | `ps` matches `Photoshop` |
| Case-insensitive Latin | `chrome`, `Chrome`, and `CHROME` match the same app |
| Direct Chinese character | `设计` matches a tag, name, or note containing `设计` |

Acronyms are generated from app display names and localized names by splitting on spaces, punctuation, and camel-case boundaries.

Subsequence matching applies only when the query token has at least 2 characters. It ranks below exact, prefix, substring, and acronym matches.

Pinyin matching is out of scope for 7.5.

## Ranking Requirements

Ranking must be deterministic and testable.

Scoring model for 7.5:

```text
finalScore = textScore + behaviorBoost
textScore = sum(best token score for each query token)
behaviorBoost = min(recentBoost + frequencyBoost, 20)
```

Field weights:

| Field | Weight |
|---|---:|
| App display name / localized name | 100 |
| Tag name | 70 |
| App note | 45 |
| Bundle identifier | 20 |

Match type weights:

| Match type | Weight |
|---|---:|
| Exact | 100 |
| Prefix | 80 |
| Substring | 60 |
| Acronym | 55 |
| Subsequence | 35 |

Position bonus:

- Add up to 10 points for earlier matches in the field.
- Do not apply position bonus to exact matches.

Behavior boosts:

- `recentBoost`: maximum 15 points.
- `frequencyBoost`: maximum 10 points.
- Combined behavior boost must never exceed 20 points.
- Behavior boost must not let a note-only weak match outrank a strong app-name match for the same query.

Tie-break order:

1. Higher `textScore`.
2. App name or localized name match beats tag match.
3. Tag match beats note match.
4. More recent successful TagLauncher launch.
5. Higher launch count.
6. Shorter display name.
7. Alphabetical display name.

Minimum ranking examples:

| Query | Expected behavior |
|---|---|
| `fig` | `Figma` app-name prefix ranks above apps whose notes contain `fig` |
| `shop` | `Photoshop` substring match is returned |
| `gc` | `Google Chrome` acronym match is returned |
| `ps` | `Photoshop` subsequence match is returned, but below stronger exact/prefix matches |
| `design` | Apps tagged `Design` rank above apps with `design` only in notes when text strength is otherwise comparable |
| `ai` | A frequently launched AI app may outrank a weak note-only match, but not an exact app-name match |

## Result Row Requirements

Each result row includes:

- App icon.
- App display name.
- Matched tag names when the tag field contributed to the match.
- Note snippet only when the note field contributed to the match.
- Clear selected state.

Can ship without:

- Highlight matched text inside names, tags, or notes.
- Show bundle identifier as secondary text only when useful for disambiguation.

Rows must stay compact. Quick Search is not a detail view.

## Launch Behavior

When the user presses `Enter` or clicks a result:

1. Attempt to launch the selected app.
2. If launch succeeds, update `lastOpenedAt` and `openCount`.
3. Close Quick Search.
4. Apply the existing TagLauncher behavior for hiding or keeping the main interface after launching an app.

If launch fails:

- Keep Quick Search open.
- Keep the user's query.
- Do not update `lastOpenedAt` or `openCount`.
- Show: `Could not open this app. Try again or choose another app.`

## Shortcut Settings

Settings must expose:

| Setting | Default |
|---|---|
| Main interface shortcut | `Shift + Option + Space` |
| Direct Quick Search shortcut | Disabled |

Required actions:

- Record shortcut.
- Clear shortcut.
- Restore default main interface shortcut.
- Retry registration after conflict resolution.
- Open macOS Keyboard Shortcuts settings when supported.

Shortcut status:

| Status | Meaning |
|---|---|
| Active | Shortcut registered successfully and works immediately |
| Conflict | Shortcut could not be registered because macOS or another app already uses it |
| Disabled | No shortcut is assigned |

When the user records a shortcut:

- TagLauncher attempts to register it immediately.
- If registration succeeds, save it and show `Active`.
- If registration fails, show `Conflict` and do not present it as active.
- If a previous shortcut was active, keep the previous shortcut active until the new shortcut registers successfully.
- Shortcut changes must not require app restart.

Known macOS shortcuts that need specific guidance when registration fails:

| Shortcut | Default macOS use |
|---|---|
| `Command + Space` | Spotlight |
| `Option + Command + Space` | Finder search window |
| `Control + Space` | Previous input source |
| `Control + Option + Space` | Next input source |
| `Control + Command + Space` | Emoji and symbols |

Conflict copy rules:

- If the shortcut is a known macOS default and registration fails, show the specific macOS guidance.
- For all other failures, show: `This shortcut is already used by macOS or another app. Choose another shortcut, or change the shortcut in the other app and try again.`
- TagLauncher must not use low-level keyboard interception to bypass macOS shortcut ownership.

## Data Requirements

Search document fields:

```text
appId
bundleIdentifier
displayName
localizedNames
tagNames
note
lastOpenedAt
openCount
```

Index refresh triggers:

- App catalog changes.
- App install or removal scan.
- Tag assignment changes.
- Tag rename.
- App note changes.
- App language or locale changes when localized names or tags are available.

Launch ranking data:

- Stored locally.
- Updated only after successful TagLauncher-mediated app launches.
- Existing users start with empty history and `openCount = 0`.
- When an app is removed from the local catalog, remove its associated ranking data.

## Performance Requirements

Search must run locally and work offline.

Targets:

- Opening the overlay must not block on network or app scanning.
- For 1,000 local app records, visible results must update within 50 ms at p95 on a typical supported Mac.
- Typing must remain visually smooth while the index is in memory.
- The app can keep the search index in memory while TagLauncher is running.

Performance measurement includes query processing and result list update, not app launch time.

## Privacy Requirements

- Do not send search queries to a server.
- Do not send app names, tag names, app notes, shortcut settings, recent launch data, or launch counts to a server for this feature.
- Store shortcut settings locally.
- Store recent and frequent launch data locally.

## Accessibility and Localization

Accessibility:

- Full keyboard operation is required.
- The input must have an accessible label.
- Result rows must expose app name and relevant metadata to accessibility APIs where supported.
- Selected state must be visually clear.
- No-result and launch-failed states must be announced where supported.

Localization:

- All user-facing strings must be localizable.
- Shortcut conflict guidance must be localizable.
- Search uses localized app and tag names when available.

## Acceptance Criteria

Quick Search:

- `Shift + Option + Space` opens the main TagLauncher interface.
- Pressing `Space` in the valid main-interface state opens Quick Search.
- Quick Search appears as a floating overlay and does not reflow the app list.
- The input is focused immediately.
- Empty query shows recent/frequent apps, not the full catalog.
- No-result state is clear.
- Launch-failed state keeps the query visible.

Search:

- Searches all launchable apps known to TagLauncher.
- Searches app display name, localized name when available, tag names, and app notes.
- Supports exact, prefix, substring, acronym, subsequence, case-insensitive Latin, and direct Chinese character matching.
- Multi-word queries require every token to match.
- Ranking follows the field, match type, behavior boost, and tie-break rules in this PRD.

Keyboard and mouse:

- `Up` and `Down` change selection.
- `Enter` launches the selected result.
- `Enter` does nothing when there is no result.
- `Esc` closes Quick Search with the correct behavior for the way it was opened.
- Hover updates active selection.
- Clicking a result launches it.
- Clicking the main interface outside the overlay closes Quick Search and keeps the main interface visible.

Shortcuts:

- Main interface shortcut is configurable.
- Direct Quick Search shortcut is configurable and disabled by default.
- Shortcut changes apply without restart.
- Shortcut settings persist across relaunch.
- Failed shortcut registration is shown as `Conflict`, not `Active`.
- Previous active shortcut remains active if a new shortcut fails registration.
- Known macOS conflicts show specific guidance.
- Unknown conflicts show generic guidance.
- Retry works after the user resolves the conflict.

Privacy and performance:

- Search works offline.
- Search does not send queries or app notes to a server.
- Result updates meet the 1,000-record p95 target.

## QA Scenarios

1. Open the main interface with `Shift + Option + Space`, press `Space`, and verify Quick Search opens with input focused.
2. Press `Space` while a text field, modal, menu, or shortcut recorder is active and verify Quick Search does not open.
3. Open Quick Search with an empty query and verify recent apps appear first.
4. Verify an empty-history user sees `Start typing to search apps, tags, and notes.`
5. Search by app name and launch with `Enter`.
6. Search by localized app name when available.
7. Search by tag name and verify tagged apps appear.
8. Search by app note and verify the note snippet appears only when the note matched.
9. Search `gc` and verify acronym matching.
10. Search `ps` and verify subsequence matching.
11. Search Chinese characters and verify direct Chinese matching.
12. Use `Up` and `Down`, then press `Enter` to launch the selected result.
13. Press `Esc` after opening from the main interface and verify the main interface remains visible.
14. Press `Esc` after opening from a direct global shortcut while the window was hidden and verify the window hides.
15. Configure an available direct Quick Search shortcut and verify it works immediately.
16. Configure `Command + Space` while Spotlight owns it and verify conflict status and Spotlight-specific guidance.
17. After a failed shortcut registration, verify the previous active shortcut still works.
18. Resolve or change the conflicting shortcut, click Retry, and verify status updates.
19. Relaunch TagLauncher and verify shortcut settings persist.
20. Confirm typing in Quick Search sends no network requests.
21. Test 1,000 app records and verify visible results update within the performance target.
