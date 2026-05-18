# Smart Start Test Cases: Ultimate Default Catalog

Status: Draft for PRD review  
Owner: QA Engineer  
Feature: Apptag 7.0 Smart Start  
Input PRD: `Docs/PRD/SmartStart_PRD_UltimateDefaultCatalog.md`

## Scope

These tests verify the final default catalog before Coder uses it in the product. They cover source ingestion, schema normalization, deduplication, tag validity, note localization, note length, first-install application behavior, and existing-user safety.

## Test Data Sources

- `Research/SmartStart/MacCommonApps_CandidateTop5000_Master.csv`
- `Research/SmartStart/PersonaTopApps/MacPersonaTopApps_Unique.csv`
- `Research/SmartStart/game.csv`
- `Research/SmartStart/AppDefaultTags_Review.csv`
- Apple default app source from `Apptag/AppleDefaultAppNotes.swift`

## Catalog QA Test Cases

### SS-UC-001 Source Files Are Present And Readable

Preconditions:

- Repo checkout is `/Users/ar/Projects/Apptag-7`.

Steps:

1. Verify every PRD source path exists.
2. Parse each CSV source with headers.
3. Read the Apple default app source file.

Expected:

- All source files are present.
- CSV files parse without malformed row errors.
- Required source headers are detected.

### SS-UC-002 Final Catalog Core Schema Is Correct

Steps:

1. Generate or inspect the final catalog.
2. Verify required core columns:
   - `Name`
   - `normalizedName`
   - `defaultTag`
   - `bundleIdentifier`
   - `defaultNote-ZH`

Expected:

- All required columns exist exactly once.
- Column names are stable.
- Extra localized-note columns or generated JSON are allowed only if documented.

### SS-UC-003 Normalized Name Is Never Empty

Steps:

1. Inspect every final catalog row.
2. Check `normalizedName`.

Expected:

- No blank `normalizedName`.
- Values are deterministic and suitable for matching.
- If source normalized name was missing, generated fallback is present.

### SS-UC-004 Missing Bundle Identifier Uses Null

Steps:

1. Inspect every final catalog row.
2. Find rows without known bundle identifiers.

Expected:

- Missing bundle identifier is represented as `null` in the review CSV.
- Known bundle identifiers are preserved as strings.
- No accidental empty string is used for missing bundle ID.

### SS-UC-005 Default Tags Use Only Approved Stable IDs

Steps:

1. Split every `defaultTag` by `|`.
2. Compare each ID against the approved Smart Start stable ID list.

Expected:

- No unknown tag IDs.
- No localized tag names.
- No uppercase or whitespace-padded IDs.
- Rows with invalid tags block catalog release.

### SS-UC-006 Multi-Tag Rows Are Preserved

Representative apps:

- Figma
- ChatGPT
- Steam
- VLC
- Photoshop
- Finder
- Transmit

Steps:

1. Inspect final `defaultTag` values.
2. Confirm multi-tag apps keep all meaningful tags.

Expected:

- Multi-tag values remain pipe-separated.
- No app is collapsed to a single old-style category when multiple tags are meaningful.

### SS-UC-007 Other Is Minimized

Steps:

1. Count rows whose `defaultTag` is exactly `other`.
2. Count rows where `other` appears with meaningful tags.
3. Inspect the generation report.

Expected:

- If meaningful tags exist, `other` is removed.
- Remaining `other` rows are reported.
- The report gives Product a clear number to review.

### SS-UC-008 Exact Bundle Deduplication

Preconditions:

- Two source rows refer to the same lowercased bundle identifier.

Steps:

1. Generate final catalog.
2. Search by that bundle identifier.

Expected:

- Only one final row exists.
- Tags are merged.
- Best available note is preserved.
- Source provenance appears in the generation report.

### SS-UC-009 Normalized Name Deduplication

Preconditions:

- Two source rows share the same normalized name and no usable bundle identifier.

Steps:

1. Generate final catalog.
2. Search by normalized name.

Expected:

- Deterministic duplicates are merged.
- If identity is uncertain, rows are not merged silently.
- Uncertain cases are written to manual review.

### SS-UC-010 Ambiguous Duplicate Review File Exists

Steps:

1. Generate final catalog.
2. Inspect the manual duplicate review output.

Expected:

- A review file exists even if it is empty.
- Ambiguous duplicate candidates include enough evidence for Product/Architect to decide.

### SS-UC-011 Persona Notes Flow Into Final Catalog

Representative source:

- `Research/SmartStart/PersonaTopApps/MacPersonaTopApps_Unique.csv`

Steps:

1. Pick persona rows with `defaultNoteZH`.
2. Find corresponding final catalog rows.

Expected:

- `defaultNote-ZH` is copied into the final catalog.
- Existing tags are not lost.
- If the same app also appears in the 5000 master, persona note augments rather than duplicates the row.

### SS-UC-012 Notes Respect 80-Character Limit

Steps:

1. Inspect `defaultNote-ZH`.
2. Inspect every localized note field or generated localized-note resource.

Expected:

- No note exceeds 80 Unicode characters.
- Empty notes are allowed only when the row has no source note.
- Over-limit notes block release.

### SS-UC-013 Localized Notes Exist For Every Supported Language

Preconditions:

- A row has `defaultNote-ZH`.

Steps:

1. Verify localized notes for:
   `ar`, `ar-Najdi`, `cs`, `da`, `de`, `en`, `es`, `fr`, `id`, `it`, `ja`, `ko`, `ms`, `nb`, `nl`, `nn`, `no`, `pl`, `pt-BR`, `ro`, `ru`, `sr-Cyrl`, `sv`, `th`, `tr`, `uk`, `vi`, `zh-Hans`, `zh-Hant`.
2. Validate length for each localized note.

Expected:

- Every supported language has a note for every row that has a Chinese source note.
- No localized note exceeds 80 characters.
- Missing or over-limit translations appear in a QA report and block release.

### SS-UC-014 Game List Adds Or Strengthens Game Tags

Steps:

1. Pick known game rows from `game.csv`.
2. Locate final catalog rows.

Expected:

- Game apps have `game`.
- Entertainment-oriented games may also have `entertainment`.
- Existing useful non-game tags are not destroyed when game tags are added.

### SS-UC-015 Apple Default Apps Are Included Consistently

Steps:

1. Pick familiar Apple apps such as Safari, Mail, Photos, Calendar.
2. Pick less familiar Apple utility apps such as Automator, Console, ColorSync Utility, Script Editor.
3. Inspect final catalog rows.

Expected:

- Apple apps have stable tags.
- Apple notes live in the same final default catalog concept, not in a separate user-facing note store.
- Familiar/unfamiliar Apple behavior remains consistent with the PRD.

## Product Behavior Test Cases

### SS-UC-101 Fresh Install Applies Catalog Tags

Preconditions:

- Empty/fresh user store.
- Installed apps include several catalog matches.

Steps:

1. Launch the app.
2. Let local app scan complete.
3. Inspect resulting tag assignments.

Expected:

- Apps are matched against the final catalog.
- Exact bundle identifier matches win.
- All matched stable tags are applied as localized user-visible tags.
- One app can appear under multiple tags.

### SS-UC-102 Fresh Install Seeds Localized Notes

Preconditions:

- Empty/fresh user store.
- Current app language is not Simplified Chinese.
- Installed app has a catalog note.

Steps:

1. Launch the app and let initialization complete.
2. Inspect the seeded app note.

Expected:

- Note is seeded in the current app language.
- Note is no more than 80 characters.
- If language is changed later, existing stored note behavior follows the implementation decision documented by Architect.

### SS-UC-103 Apps With Seeded Notes Are Marked Uncommon Automatically

Preconditions:

- Empty/fresh user store.
- Installed app matches a catalog row with a note.

Steps:

1. Run first initialization.
2. Inspect uncommon marker/source.

Expected:

- App is marked Uncommon.
- Source is automatic/system seeded, not treated as user manual note creation.
- Existing Uncommon bubble display rules still control whether the bubble appears.

### SS-UC-104 Existing User Is Not Silently Overwritten

Preconditions:

- User already has custom tags or app assignments.

Steps:

1. Launch with final catalog available.
2. Inspect store before and after launch.

Expected:

- Existing assignments are not silently replaced.
- Existing notes are not overwritten.
- Any apply path requires preview/confirmation and backup.

### SS-UC-105 User Note Has Priority Over Catalog Note

Preconditions:

- Store already has a user-written note for an app.
- Catalog also has a default note for that app.

Steps:

1. Run catalog application or re-application.
2. Inspect app note.

Expected:

- User-written note remains unchanged.
- Catalog default note does not overwrite it.

### SS-UC-106 No Catalog Match Does Nothing Harmful

Preconditions:

- Installed app is not in catalog.

Steps:

1. Run first initialization.
2. Inspect the app's tags and notes.

Expected:

- No fake note is created.
- No invalid tag is assigned.
- App may remain uncategorized or go through existing fallback behavior only if explicitly documented.

## Release Gate

QA should not pass this feature until:

- Catalog generation report exists.
- Duplicate review report exists.
- Translation QA report exists.
- All notes are within 80 characters.
- No invalid tag IDs exist.
- Fresh-install behavior is verified.
- Existing-user safety is verified.
