# Smart Start PRD: Ultimate Default Catalog

Status: Draft for product review  
Owner: Product Manager  
Feature: Apptag 7.0 Smart Start  
Source request: `/Users/ar/Downloads/需求-数据初始化-标签的智能整理.md`

## Product Goal

When a new user opens TagLauncher for the first time, the app should use a bundled local catalog to classify installed Mac apps into useful tags and seed short app notes where available.

The user should feel that TagLauncher already understands many common apps, instead of asking them to build every tag from zero.

## Problem

We now have several valuable research datasets, but they are not yet one production-ready catalog:

- a manually reviewed Top 1000-era default tag table
- a 5000-app expanded candidate table with reviewed tags
- a 478-app persona-based table with strong one-line Chinese notes
- a 200-game list
- Apple official/default app classification and note work

If these stay separate, implementation will be fragile: matching may be inconsistent, duplicate apps may appear, one app may receive conflicting tags, notes may not be localized, and the product may not know which source should win.

This PRD defines the final catalog requirements before Coder starts implementation.

## Source Inputs

Canonical source files currently available in the repo:

| Source | Path | Current Rows | Role |
|---|---:|---:|---|
| Expanded 5000 master | `Research/SmartStart/MacCommonApps_CandidateTop5000_Master.csv` | 5000 | Main tag baseline |
| Persona unique apps | `Research/SmartStart/PersonaTopApps/MacPersonaTopApps_Unique.csv` | 478 | Adds curated notes and validates high-value profession apps |
| Game list | `Research/SmartStart/game.csv` | 200 | Adds/strengthens game coverage |
| Top 1000 review | `Research/SmartStart/AppDefaultTags_Review.csv` | 962 | Legacy manually reviewed fallback/verification |
| Apple default apps | `Apptag/AppleDefaultAppNotes.swift` | code source | Apple app notes and uncommon/familiar distinction |

Note: the external request mentions `MacCommonAppsCandidateTop5000Master.csv`; the actual current repo file is `MacCommonApps_CandidateTop5000_Master.csv`.

## Final Catalog Output

The PM-required review table must use these core columns:

```text
Name
normalizedName
defaultTag
bundleIdentifier
defaultNote-ZH
```

Requirements:

- `Name` is the user-recognizable app name.
- `normalizedName` is required for every row and must never be blank.
- `defaultTag` is a pipe-separated list of stable tag IDs, for example `design|productivity`.
- `bundleIdentifier` is preferred for matching. If unknown, the CSV value must be `null`.
- `defaultNote-ZH` is optional. If present, it must be at most 80 Unicode characters.

For production use, localized notes must also exist. The physical representation can be one CSV with additional columns or a generated JSON resource, but the final product must support note lookup by current app language.

Supported note languages must match current localization files:

```text
ar
ar-Najdi
cs
da
de
en
es
fr
id
it
ja
ko
ms
nb
nl
nn
no
pl
pt-BR
ro
ru
sr-Cyrl
sv
th
tr
uk
vi
zh-Hans
zh-Hant
```

If a note exists in Chinese, every supported language must have a corresponding localized note before release. Each localized note must respect the same 80-character limit.

## Stable Tag Rules

`defaultTag` must use stable tag IDs, not localized display names.

Allowed stable tag IDs are the Smart Start IDs already defined by the data contract, including:

```text
browser
communication
productivity
file-management
transfer
development
design
writing
media
video
audio
picture-photo
utilities
system
system-enhancement
entertainment
game
finance
education
ai-tools
security
other
```

Rules:

- One app can have multiple tags.
- `other` is allowed only as a last resort.
- If an app has any meaningful tag, `other` should be removed.
- The final report must show the remaining `other` count.
- Unknown tag IDs are invalid and must block release of the catalog.

## Merge Priority

The merge must be deterministic.

Recommended precedence:

1. Apple default app data wins for Apple official apps where bundle ID identifies the app.
2. Persona table wins for `defaultNote-ZH` when it has a note.
3. Expanded 5000 master is the main default tag baseline.
4. Game list can add `game` and `entertainment` tags to existing rows, or create a new row if missing.
5. Top 1000 review can fill gaps or act as a verification fallback.

Tag merge behavior:

- Tags are additive unless a source clearly corrects an earlier bad tag.
- Duplicate tags are removed while preserving stable order.
- `other` is removed when stronger tags exist.
- Conflicts that cannot be safely resolved must be written to a manual review file.

Note merge behavior:

- Existing user-written notes are never part of the catalog merge.
- Persona notes are catalog defaults only.
- Apple default notes can be included in the same final catalog as default notes; they must not require a separate user-facing storage path.
- If a catalog row has no note, note fields remain blank.

## Deduplication Rules

The final catalog must not contain duplicate apps.

Deduplication identity order:

1. Exact lowercased `bundleIdentifier`, if present and not `null`.
2. Exact `normalizedName`.
3. Known alias rules, only when deterministic.

When two rows share the same identity:

- Merge tags.
- Prefer non-null bundle identifiers.
- Prefer clearer `Name`, usually the common product name.
- Preserve the best note if one exists.
- Preserve source provenance in a generation report.

Ambiguous cases:

- If the script cannot decide whether two rows are the same app, do not guess.
- Write them to a manual review file for Product/Architect confirmation.

## Translation Requirements

All localized notes must be product-quality short copy, not literal awkward translations.

Rules:

- Every translation must be no more than 80 Unicode characters.
- If the target language naturally needs a shorter phrase, concise is preferred.
- Product meaning must stay consistent across languages.
- File names, app names, and technical product names should generally remain as official names unless the language commonly localizes them.
- If a translation cannot be confidently generated, it must be flagged in a review report rather than silently omitted.

## Product Application Rules

On first install / fresh user state:

1. Scan local installed apps.
2. Match each app against the final catalog.
3. Match by exact bundle identifier first.
4. If bundle identifier is missing or unmatched, match by `normalizedName`.
5. Apply all matched `defaultTag` values.
6. If the matched catalog row has a localized note for the current language, seed that note.
7. Every app that receives a catalog note is automatically marked as Uncommon.

Important behavior:

- System-seeded uncommon marking should be treated as automatic, not as a user manual action.
- If the user later edits the note manually, the existing manual-note behavior can take over.
- If the user removes the Uncommon tag or the auto-uncommon rule removes it after enough launches, the note may remain in storage but the bubble display must follow the existing settings rules.
- Do not overwrite existing user notes.
- Do not overwrite existing user tag choices silently.

Existing-user behavior:

- Existing users should not get silent destructive changes.
- If the user already has meaningful tags or app assignments, catalog application should be preview/confirmation based, with backup.

## Acceptance Criteria

Product accepts the catalog generation work when:

- Final catalog exists.
- It contains the five PM-required core columns.
- `normalizedName` is non-empty for every row.
- Missing bundle identifiers are represented as `null`.
- `defaultTag` contains only approved stable IDs.
- No duplicate app remains in the final catalog.
- Ambiguous possible duplicates are listed in a review report.
- Remaining `other` count is reported.
- Every note is at most 80 Unicode characters.
- Every Chinese note has localized versions for all supported app languages before release.
- A generation report documents source counts, merge counts, dedupe counts, conflicts, and translation QA.
- Implementation has a clear product rule for first install application.

## Non-Goals

- No cloud upload of the user's installed app list.
- No AI Improve server in this task.
- No UI redesign in this PRD.
- No code implementation until PRD and QA test cases are reviewed.
- No requirement that every unknown app receive a note.

## Open Product Decisions

1. Should the human review table remain CSV while the app consumes generated JSON?
2. Should `defaultNote-ZH` be renamed to `defaultNote-zh-Hans` in production, while preserving the PM review column name?
3. What maximum acceptable remaining `other` count should block release?
4. Should Apple default app rows be generated from Swift source into the catalog, or should the Apple default source move into the same data pipeline?
