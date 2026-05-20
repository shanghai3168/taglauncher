# Smart Start Ultimate Default Catalog Report

Generated: 2026-05-19T20:08:23.394Z

## Inputs

- curated CSV: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`
- curated rows: 5223
- curated rows after alias dedupe: 5223
- alias duplicates removed: 0
- unknown tager tokens: 0

## Outputs

- Review CSV: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`
- Runtime JSON: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.json`
- Duplicate review: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_DuplicateReview.csv`
- Translation QA: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_TranslationQA.md`

## Summary

- Final rows: 5223
- Rows with Chinese default notes: 4423
- Rows with source Chinese notes from curated CSV: 4423
- Rows with Apple note fallback attached: 0
- Invalid tag rows: 0
- Empty normalizedName rows: 0
- Exact `other` rows: 0
- Mixed `other` rows after cleanup: 0
- Tag changes vs previous runtime JSON: 0
- Chinese note changes vs previous runtime JSON: 0
- Bundle identifier changes vs previous runtime JSON: 0
- Unknown tager tokens: 0
- Note quality issues: 0

## Tag Distribution

- browser: 115
- communication: 261
- productivity: 324
- file-management: 129
- transfer: 219
- development: 678
- design: 223
- writing: 301
- media: 718
- video: 217
- audio: 291
- picture-photo: 272
- utilities: 2498
- system: 19
- system-enhancement: 594
- entertainment: 383
- game: 347
- finance: 94
- education: 71
- ai-tools: 185
- security: 218

## Notes

- Runtime tags are generated from the curated CSV `tager` column, not the legacy `defaultTag` column.
- Runtime notes are generated only from real source notes. The generator must not synthesize notes from app names or category labels.
- Missing translations are intentionally omitted until a real translation pipeline or reviewed translation table provides them.
