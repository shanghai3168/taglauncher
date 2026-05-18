# Apptag 7.0 Smart Start GTD

## Mission

Build `Smart Start` as the first major Apptag 7.0 capability:

> A new user opens Apptag, waits briefly while apps are scanned locally, and sees most everyday apps already organized into useful tags.

This GTD document is the execution tracker. The strategy lives in `plan-deepthink.md`; the detailed project blueprint lives in `SmartStart_ProjectPlan.md`.

## Roles

### CTO / Architect / Project Manager

Owner: Codex.

Responsibilities:

- act as final technical owner and project coordinator
- receive reports from Product Manager, Designer, Coder, Ops, and QA Engineer
- decide architecture and implementation sequencing
- protect scope, data safety, and release quality
- keep this GTD document accurate

All other roles report to this role.

### Product Manager

Owner: product requirements role.

Responsibilities:

- turn product ideas into PRDs before implementation begins
- define user stories, scope, non-goals, acceptance criteria, and success metrics
- clarify first-run behavior, existing-user behavior, and edge cases
- coordinate with Designer before Coder starts UI or behavior work

Rule:

- No feature implementation starts without a PRD or a PRD-level task brief.

### Architect

Owner: Codex CTO / architecture lead.

Responsibilities:

- keep the system design coherent
- define data contracts and module boundaries
- protect existing user data
- decide what belongs in local MVP versus later AI Improve
- review risky changes before they become implementation tasks

### Designer

Owner: UX/product design role.

Responsibilities:

- define first-run user flow
- design preview, summary, undo, and existing-user behavior
- define default tag taxonomy and localized display expectations
- keep the experience simple and trust-building

### Coder

Owner: implementation role.

Responsibilities:

- implement Swift models, loaders, categorizer, backup, apply, and UI
- keep changes small and buildable
- run `bash build.sh`
- report file-level changes and technical risks

### Ops

Owner: research/data/release operations role.

Responsibilities:

- maintain candidate app datasets
- fetch and clean external source data
- verify bundle identifiers
- manage catalog QA checklists
- maintain scripts and reproducible generation notes
- later: backend/API ops for optional AI Improve

### QA Engineer

Owner: testing role.

Responsibilities:

- write test cases from the PRD before implementation is considered complete
- define acceptance scenarios for new-user, existing-user, backup, undo, localization, and failure modes
- maintain manual QA checklist and future automated test candidates
- verify implementation against PRD, not just against code assumptions

Rule:

- Every product-facing feature needs QA test cases based on the PRD before final review.

## Status Legend

```text
TODO      not started
DOING     actively being worked on
BLOCKED   waiting for decision/data/dependency
REVIEW    ready for Architect/Product review
DONE      complete and verified
```

## Current State

- Branch/worktree: `/Users/ar/Projects/Apptag-7`
- Branch name: `feature/major-upgrade-v7`
- Stable base: `v6.0.5`
- Existing implementation prep:
  - `PreferencesView` extracted from `ApptagApp.swift`
  - edit-mode UI components extracted to `EditModeViews.swift`
- Planning docs:
  - `plan-deepthink.md`
  - `SmartStart_ProjectPlan.md`
- Research artifacts:
  - `Research/SmartStart/MacCommonApps_CandidateTop1000.csv`
  - `Research/SmartStart/MacCommonApps_CandidateSources.md`

## Project Guardrails

- Do not change `/Users/ar/Projects/Apptag` stable worktree for 7.0 work.
- Do not upload user app lists in the local MVP.
- Do not silently overwrite existing user tags or app assignments.
- Do not use display text as internal identity.
- One app can belong to multiple tags.
- Default tags must display in the user's selected language.
- Every generated categorization is a draft before it touches user data.
- Every apply operation must have backup/undo.

## Workflow Rules

1. Product Manager writes the PRD or PRD-level task brief.
2. Designer produces UX notes or interaction spec when the PRD affects user experience.
3. QA Engineer writes test cases from the PRD.
4. Architect reviews data safety, architecture, and implementation order.
5. Coder implements the smallest approved slice.
6. Ops maintains data/research/build/QA support artifacts.
7. Architect/Project Manager reviews build results and decides whether the task moves to `DONE`.

No role directly ships work without reporting back to the CTO / Architect / Project Manager.

## Milestone 0: Foundation Already Done

### T00.1 Commit 6.0.5 Stable Base

- Owner: Architect
- Status: DONE
- Output: `v6.0.5` base exists for `feature/major-upgrade-v7`
- Acceptance:
  - `Apptag-7` starts from stable 6.0.5

### T00.2 Split Preferences View

- Owner: Coder
- Status: DONE
- Output: `Apptag/PreferencesView.swift`
- Acceptance:
  - `bash build.sh` passes
  - `ApptagApp.swift` no longer owns settings UI implementation

### T00.3 Split Edit Mode UI Components

- Owner: Coder
- Status: DONE
- Output: `Apptag/EditModeViews.swift`
- Acceptance:
  - `bash build.sh` passes
  - `ContentView.swift` keeps edit state and actions, while repeated UI components move out

### T00.4 Draft Smart Start Strategy

- Owner: Architect
- Status: DONE
- Output: `SmartStart_ProjectPlan.md`
- Acceptance:
  - local-first / draft-first / undo-first principles documented
  - implementation phases documented

### T00.5 Create Candidate Top 1000 Draft

- Owner: Ops
- Status: DONE
- Output: `Research/SmartStart/MacCommonApps_CandidateTop1000.csv`
- Acceptance:
  - 1000 candidate rows exist
  - source notes exist
  - limitations are documented

## Milestone 1: Data Contract

Goal:

Define the stable language that all later work uses.

### T01.0 Write Data Contract PRD

- Owner: Product Manager
- Status: DONE
- Output: PRD section for Smart Start data contract
- Requirements:
  - define why stable IDs matter
  - define multi-tag requirement
  - define user-visible impact
  - define non-goals
  - define acceptance criteria for data contract
- Acceptance:
  - Architect can derive model requirements from the PRD
  - QA Engineer can write test cases from the PRD

### T01.1 Define Stable Category IDs

- Owner: Architect
- Status: DOING
- Output: category ID list and mapping rules
- Files:
  - `Apptag/SmartCategorization/SmartCategory.swift`
- Requirements:
  - IDs are lowercase ASCII
  - display names are localized separately
  - initial IDs include `browser`, `communication`, `productivity`, `development`, `design`, `writing`, `media`, `utilities`, `system`, `entertainment`, `finance`, `education`, `ai-tools`, `security`, `other`
- Acceptance:
  - code compiles
  - no category display string is used as internal identity

### T01.2 Define Multi-Tag Assignment Contract

- Owner: Architect
- Status: DOING
- Output: assignment data model
- Files:
  - `Apptag/SmartCategorization/SmartCategorizationDraft.swift`
- Requirements:
  - one app can have multiple `categoryIDs`
  - confidence can exist per assignment
  - reason/source are preserved for preview
- Acceptance:
  - draft structure can represent `Figma -> design | productivity`
  - draft structure can represent `ChatGPT -> ai-tools | productivity`

### T01.3 Define Draft Source Types

- Owner: Architect
- Status: DOING
- Output: enum/model for draft sources
- Files:
  - `Apptag/SmartCategorization/SmartCategorizationDraft.swift`
- Source types:
  - `localCatalog`
  - `localHeuristic`
  - `manualSeed`
  - `aiImprove`
- Acceptance:
  - each assignment can explain where it came from

### T01.4 Define Auto-Apply Policy

- Owner: Architect
- Status: TODO
- Output: documented and coded policy object or helper
- Requirements:
  - new-user detection rules
  - confidence threshold
  - existing-user protection
  - no delete/replace without confirmation
- Acceptance:
  - policy can answer: auto apply, preview only, or reject

### T01.5 Write Data Contract Test Cases

- Owner: QA Engineer
- Status: DONE
- Input: T01.0 PRD
- Output: data contract test case list
- Requirements:
  - multi-tag app assignment case
  - unknown category ID case
  - local catalog source case
  - heuristic source case
  - AI Improve future source case
  - auto-apply versus preview policy case
- Acceptance:
  - test cases are traceable to PRD acceptance criteria

## Milestone 2: Default Tags And Localization

Goal:

Make default tags global, simple, and correctly localized.

### T02.0 Write Default Tags PRD

- Owner: Product Manager
- Status: TODO
- Output: PRD section for default global tags
- Requirements:
  - define target user value
  - define supported languages requirement
  - define multi-tag examples
  - define category naming constraints
  - define what must not happen
- Acceptance:
  - Designer can finalize taxonomy from PRD
  - QA Engineer can write localization test cases

### T02.1 Finalize Default Category Taxonomy

- Owner: Designer
- Status: REVIEW
- Output: approved default category list
- Requirements:
  - broad enough for global users
  - supports multi-tag assignments
  - includes `AI Tools`
  - avoids over-fragmentation
- Candidate IDs:
  - `browser`
  - `communication`
  - `productivity`
  - `development`
  - `design`
  - `writing`
  - `media`
  - `utilities`
  - `system`
  - `entertainment`
  - `finance`
  - `education`
  - `ai-tools`
  - `security`
  - `other`
- Acceptance:
  - Architect approves IDs
  - Product approves user-facing meaning

### T02.2 Add Localization Keys For Default Categories

- Owner: Coder
- Status: TODO
- Output: localization keys in all supported language JSON files
- Files:
  - `Apptag/Localization/*.json`
- Required key pattern:
  - `smart.category.browser`
  - `smart.category.communication`
  - `smart.category.productivity`
  - etc.
- Acceptance:
  - every supported language file contains every category key
  - no default category displays in the wrong language
  - `jq empty Apptag/Localization/*.json` passes

### T02.3 Review Localized Category Names

- Owner: Designer
- Status: TODO
- Output: review notes for all category translations
- Requirements:
  - avoid awkward machine translations where possible
  - keep labels short
  - maintain category meaning across languages
- Acceptance:
  - Chinese Simplified and English reviewed first
  - all other languages marked as reviewed or needs native review

### T02.4 Write Default Tag Localization Test Cases

- Owner: QA Engineer
- Status: TODO
- Input: T02.0 PRD and T02.1 taxonomy
- Output: localization test cases
- Requirements:
  - every supported language has every key
  - current language controls displayed default tag names
  - no English fallback appears when a localized value exists
  - internal IDs remain stable after language switch
- Acceptance:
  - test cases cover all supported language JSON files

## Milestone 3: Candidate App Dataset Cleanup

Goal:

Turn the candidate Top 1000 into a production-ready starter catalog.

### T03.0 Write Candidate Dataset Cleanup Plan

- Owner: Ops
- Status: DONE
- Output: `Research/SmartStart/CandidateDataset_CleanupPlan.md`
- Acceptance:
  - non-GUI filters documented
  - bundle ID verification workflow documented
  - icon-pack/App Store enrichment plan documented
  - reviewStatus states documented
  - first suspicious row types identified

### T03.1 Filter Non-GUI / Non-App Entries

- Owner: Ops
- Status: TODO
- Input: `Research/SmartStart/MacCommonApps_CandidateTop1000.csv`
- Output: cleaned candidate CSV
- Requirements:
  - remove obvious CLI-only tools where no app bundle exists
  - keep developer tools that ship a GUI app
  - preserve source notes
- Acceptance:
  - cleaned file has a `reviewStatus` column
  - removed rows are traceable

### T03.2 Verify Bundle Identifiers For Top 300

- Owner: Ops
- Status: TODO
- Input: cleaned candidate CSV
- Output: verified bundle identifier table
- Requirements:
  - verify first 300 rows
  - mark uncertain IDs
  - do not guess production IDs without review
- Acceptance:
  - rows are marked `bundle_verified`, `bundle_uncertain`, or `no_bundle`

### T03.3 Review Category Candidates For Top 300

- Owner: Designer
- Status: TODO
- Input: top 300 candidate rows
- Output: reviewed category assignment CSV
- Requirements:
  - allow multiple category IDs per app
  - prefer broad tags
  - mark controversial apps for discussion
- Acceptance:
  - no row in top 300 has only unchecked heuristic category

### T03.4 Add Real Icon-Pack Source Signals

- Owner: Ops
- Status: TODO
- Output: updated dataset with icon library source columns
- Sources to investigate:
  - macOSicons
  - Replacicon sources
  - DarkOS
  - Glacier Icons
  - Adam's MacOS Icons
- Acceptance:
  - document which sources are machine-readable
  - document which sources are manual-only
  - add real icon-pack mention counts where allowed

### T03.5 Add Mac App Store Ranking Signals

- Owner: Ops
- Status: TODO
- Output: dataset enriched with App Store ranking columns
- Requirements:
  - try US, CN, JP, KR, GB, DE, FR if endpoint allows
  - track country/source separately
- Acceptance:
  - if API is unavailable, document blocker and fallback

### T03.6 Write Candidate Dataset QA Cases

- Owner: QA Engineer
- Status: TODO
- Input: cleaned candidate dataset
- Output: dataset QA checklist
- Requirements:
  - duplicate normalized names
  - duplicate bundle identifiers
  - missing category candidates
  - non-GUI app markers
  - manual review status coverage
- Acceptance:
  - Ops can run checklist before producing catalog input

## Milestone 4: Local Catalog MVP

Goal:

Create the bundled local catalog used by Smart Start.

### T04.0 Write Local Catalog PRD

- Owner: Product Manager
- Status: TODO
- Output: PRD section for local catalog MVP
- Requirements:
  - define why local catalog exists
  - define first version size target
  - define confidence behavior
  - define multi-tag behavior
  - define failure behavior if catalog is missing/malformed
- Acceptance:
  - Architect can review catalog format
  - QA Engineer can write catalog loader test cases

### T04.1 Create SmartCategorization Directory

- Owner: Coder
- Status: TODO
- Output: `Apptag/SmartCategorization/`
- Acceptance:
  - files are included automatically by `build.sh`

### T04.2 Create Starter Catalog JSON

- Owner: Coder
- Status: TODO
- Input: reviewed top candidate rows
- Output: `Apptag/SmartCategorization/SmartCategoryCatalog.json`
- Requirements:
  - start with 80-150 reviewed entries
  - include multiple category IDs where appropriate
  - include confidence and source
- Acceptance:
  - JSON decodes
  - no unknown category IDs
  - no duplicate bundle identifiers

### T04.3 Implement Catalog Loader

- Owner: Coder
- Status: TODO
- Output: `SmartCategoryCatalog.swift`
- Requirements:
  - load bundled JSON
  - validate duplicate bundle identifiers
  - validate category IDs
  - fail gracefully if JSON is missing or malformed
- Acceptance:
  - `bash build.sh` passes
  - malformed JSON path is handled without crash

### T04.4 Implement Matching By Bundle Identifier

- Owner: Coder
- Status: TODO
- Output: exact-match categorization function
- Requirements:
  - exact bundle ID match wins
  - app name fallback is not used in this task
- Acceptance:
  - known app returns expected category IDs
  - unknown app returns nil/unassigned

### T04.5 Write Local Catalog Test Cases

- Owner: QA Engineer
- Status: TODO
- Input: T04.0 PRD
- Output: catalog test case list
- Requirements:
  - valid catalog loads
  - malformed catalog does not crash
  - duplicate bundle ID is detected
  - unknown category ID is detected
  - one app can map to multiple category IDs
- Acceptance:
  - Coder can use cases during implementation verification

## Milestone 5: Smart Categorizer MVP

Goal:

Generate a full local categorization draft without mutating user data.

### T05.1 Implement SmartCategorizer

- Owner: Coder
- Status: TODO
- Output: `SmartCategorizer.swift`
- Requirements:
  - input `[AppInfo]`
  - output `SmartCategorizationDraft`
  - exact catalog match first
  - heuristic fallback second
  - unassigned list for misses
- Acceptance:
  - no writes to `TagDatabase`
  - same input produces same output

### T05.2 Implement Local Heuristic Rules

- Owner: Architect
- Status: TODO
- Output: rule specification and coded helper
- Rules:
  - system app path
  - browser names
  - development keywords
  - media keywords
  - communication keywords
  - AI tool keywords
- Acceptance:
  - rules have lower confidence than catalog matches
  - rules never override exact catalog matches

### T05.3 Add Developer Validation Harness

- Owner: Ops
- Status: TODO
- Output: repeatable command or script for categorizer smoke checks
- Requirements:
  - can run against fixture apps
  - outputs draft JSON
  - does not require real user data
- Acceptance:
  - Coder can run it before UI work

### T05.4 Write Smart Categorizer Test Cases

- Owner: QA Engineer
- Status: TODO
- Input: categorizer PRD/task brief
- Output: categorizer test case list
- Requirements:
  - exact catalog match wins
  - heuristic fallback works
  - unmatched apps become unassigned
  - multi-tag output survives
  - same input produces same output
- Acceptance:
  - test cases cover success, uncertain, and failure states

## Milestone 6: Safe Apply, Backup, Undo

Goal:

Make generated drafts safe to apply.

### T06.0 Write Backup/Undo PRD

- Owner: Product Manager
- Status: TODO
- Output: PRD section for applying Smart Start safely
- Requirements:
  - define existing-user protection
  - define new-user auto-apply behavior
  - define backup and undo expectations
  - define what replace means
  - define no-delete behavior
- Acceptance:
  - QA Engineer can write data-safety test cases
  - Architect can approve apply policy

### T06.1 Implement Tag Backup Service

- Owner: Coder
- Status: TODO
- Output: `TagBackupService.swift`
- Requirements:
  - create snapshot before apply
  - support one-click undo
  - do not require cloud
- Acceptance:
  - previous store can be restored after apply

### T06.2 Implement Draft Apply Adapter

- Owner: Coder
- Status: TODO
- Output: draft-to-`TagDatabase.Store` apply function
- Requirements:
  - create missing tags
  - preserve existing tags
  - support multiple tags per app
  - do not delete assignments silently
- Acceptance:
  - can apply a draft to a store copy
  - existing assignments survive unless explicitly replaced

### T06.3 Architect Data-Safety Review

- Owner: Architect
- Status: TODO
- Output: review notes
- Acceptance:
  - no data-loss path identified
  - existing-user behavior approved before UI integration

### T06.4 Write Backup/Undo Test Cases

- Owner: QA Engineer
- Status: TODO
- Input: T06.0 PRD
- Output: backup/undo test cases
- Requirements:
  - apply to empty store
  - apply to existing user store
  - undo after apply
  - multiple tags per app
  - malformed draft rejected
  - existing assignments preserved
- Acceptance:
  - data-safety cases pass before first-run UI integration

## Milestone 7: First-Run Flow And UI

Goal:

Make Smart Start visible and useful to users.

### T07.0 Write First-Run Smart Start PRD

- Owner: Product Manager
- Status: TODO
- Output: PRD for first-run Smart Start user experience
- Requirements:
  - define first-run trigger
  - define progress/result states
  - define summary content
  - define undo and edit entry points
  - define existing-user behavior
  - define AI Improve placeholder behavior
- Acceptance:
  - Designer can produce UX spec
  - QA Engineer can write end-to-end test cases

### T07.1 Design First-Run Smart Start Screen

- Owner: Designer
- Status: TODO
- Output: UX spec
- Requirements:
  - scanning/progress state
  - organizing state
  - result summary
  - edit button
  - undo button
  - future AI Improve placeholder
- Acceptance:
  - Product approves copy and flow

### T07.2 Implement Smart Start Summary View

- Owner: Coder
- Status: TODO
- Output: `SmartStartSummaryView.swift`
- Acceptance:
  - shows organized count, created tags, unassigned count
  - supports undo and continue editing

### T07.3 Integrate New-User Auto Apply

- Owner: Coder
- Status: TODO
- Requirements:
  - run after first app scan
  - only for new users
  - only high-confidence assignments
  - set `smartStartCompleted`
- Acceptance:
  - new user sees organized state
  - existing user is not changed silently

### T07.4 Existing-User Preview Entry

- Owner: Designer
- Status: TODO
- Output: UX spec for manual Smart Start preview
- Acceptance:
  - existing users can safely opt in
  - no surprise overwrites

### T07.5 Write First-Run UI Test Cases

- Owner: QA Engineer
- Status: TODO
- Input: T07.0 PRD and T07.1 UX spec
- Output: first-run UI test cases
- Requirements:
  - new user flow
  - existing user flow
  - undo flow
  - no catalog available
  - no apps matched
  - language switch before/after Smart Start
- Acceptance:
  - manual QA can run the cases before release

## Milestone 8: Build, QA, Release Readiness

Goal:

Make the feature shippable.

### T08.1 Build Verification

- Owner: Ops
- Status: TODO
- Command:
  - `bash build.sh`
- Acceptance:
  - build succeeds
  - generated app launches locally if manually tested

### T08.2 Localization Verification

- Owner: Ops
- Status: TODO
- Commands:
  - `jq empty Apptag/Localization/*.json`
- Acceptance:
  - every localization file is valid JSON
  - every Smart Start key exists in every language

### T08.3 Manual QA Checklist

- Owner: QA Engineer
- Status: TODO
- Scenarios:
  - fresh user
  - existing user
  - undo after apply
  - no catalog file
  - malformed catalog file
  - uncommon apps
  - multiple tags per app
- Acceptance:
  - checklist exists
  - pass/fail results recorded

### T08.4 Final CTO Review

- Owner: Architect
- Status: TODO
- Acceptance:
  - scope matches local MVP
  - no cloud upload added
  - no silent overwrite risk
  - follow-up AI Improve tasks are separated

## Backlog: Later AI Improve

### B01 Define AI Improve API Contract

- Owner: Architect
- Status: TODO
- Output: request/response schema
- Note: not required for local MVP

### B02 Design Privacy Consent Copy

- Owner: Designer
- Status: TODO
- Output: consent modal copy
- Note: not required for local MVP

### B03 Build Stateless Categorization API

- Owner: Ops
- Status: TODO
- Output: backend prototype
- Note: not required for local MVP

### B04 Implement AI Client

- Owner: Coder
- Status: TODO
- Output: `AICategorizationClient.swift`
- Note: not required for local MVP

## Immediate Next Action

Start with:

```text
T01.1 Define Stable Category IDs
T01.2 Define Multi-Tag Assignment Contract
T01.3 Define Draft Source Types
```

Reason:

These tasks create the shared data language. They unblock catalog loading, categorizer logic, preview UI, backup/apply, and later AI Improve without touching real user data.
