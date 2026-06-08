# CatalogOps

CatalogOps is the top-level data operations workspace for improving TagLauncher Smart Start catalogs over time.

Official runtime catalog:

- `/Users/ar/Projects/Apptag-7/Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`
- `/Users/ar/Projects/Apptag-7/Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.json`

## Operating Rule

Daily automation may discover, clean, score, tag, and summarize candidate apps, but it must not directly overwrite the official catalog.

The safe loop is:

1. Collect candidate apps from approved sources.
2. Normalize app names and identifiers.
3. Infer default system tags from the stable 22-tag set.
4. Generate short default notes only when confidence is high.
5. Produce candidate CSV/JSON files under `Candidates/`.
6. Produce QA reports under `Reports/`.
7. Promote reviewed rows into the official catalog only after human approval.

## Folders

- `Sources/`: source notes, source snapshots, and source-specific rules.
- `Scripts/`: repeatable collection, merge, QA, and promotion scripts.
- `Runs/`: daily run outputs, grouped by date.
- `Candidates/`: candidate rows ready for review.
- `Reports/`: QA summaries, duplicate checks, tag coverage reports.
- `Promoted/`: reviewed batches that were accepted into the official catalog.

## Stable Tag Contract

Candidate rows must use only the current stable system tag IDs:

`browser`, `communication`, `productivity`, `file-management`, `transfer`, `development`, `design`, `writing`, `media`, `video`, `audio`, `picture-photo`, `utilities`, `system`, `system-enhancement`, `entertainment`, `game`, `finance`, `education`, `ai-tools`, `security`, `other`.

Prefer meaningful tags over `other`. Use `other` only when no useful system tag can be assigned with confidence.

