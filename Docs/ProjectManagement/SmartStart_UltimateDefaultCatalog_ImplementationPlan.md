# Smart Start Ultimate Default Catalog Implementation Plan

Status: Architect approved for implementation  
Owner: Architect  
Target version: 7.1.0

## Decision

Use two generated artifacts:

- Review CSV: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`
- Runtime JSON: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.json`

The CSV keeps the Product Manager review shape. The JSON is what the app consumes, because it can carry localized notes without turning the review CSV into a very wide human-unfriendly file.

## Runtime Rules

- Match by exact bundle identifier first.
- Fall back to `normalizedName`.
- Apply all `defaultTag` values.
- If a note exists for the current app language, seed it only when the user has no note.
- Apps receiving a seeded catalog note are automatically marked as Uncommon with automatic source.
- Existing user notes and tag assignments are not overwritten silently.
- Existing Apple default note fallback can remain while the catalog is being consolidated; it uses the same `appNotes` store and does not create a separate user-facing note path.

## Build Rules

`build.sh` must copy the runtime JSON into the app bundle resources. The old `SmartStartAppDefaultTags.csv` copy can remain as a fallback during transition.

## Validation Gates

- `node Research/SmartStart/Scripts/build-ultimate-default-catalog.mjs`
- generated report must show:
  - invalid tag rows: 0
  - empty normalized names: 0
  - exact other rows: 0
  - localized note issues: 0
- `bash build.sh`

## Follow-Up

Non-Chinese localized notes are currently generated as localized tag-summary notes. They are safe, short, and language-correct, but high-traffic languages can be manually polished later.
