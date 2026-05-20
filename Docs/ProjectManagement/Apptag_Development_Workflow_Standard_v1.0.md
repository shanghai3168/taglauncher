# Apptag Development Workflow Standard

Status: Active  
Version: 1.0  
Effective date: 2026-05-20  
Owner: Project owner / Architect  

## 1. Purpose

This document is the single authoritative workflow standard for the Apptag project.

Its job is to consolidate the process rules that were previously scattered across project notes, release docs, QA docs, PRDs, and agent instructions, so that every coder, reviewer, QA role, architect role, and operator follows the same execution model.

This document governs how work is planned, implemented, reviewed, tested, versioned, built, and released.

## 2. Authority And Precedence

1. This document is the top-level workflow authority for the repository.
2. Feature PRDs, QA cases, release checklists, and data-operation docs remain active, but they are subordinate to this workflow standard.
3. If two lower-level documents conflict, this document wins unless the conflict is resolved by an explicit new decision entry in `Decisions.md`.
4. If a coder receives a request from any role, including the project commander, that conflicts with this document, the coder must pause and cite the exact clause that is being violated before continuing.
5. No silent exceptions are allowed.

## 3. Source Documents Consolidated Here

The following documents currently contribute workflow or release constraints and are now consolidated by this standard:

| Source document | Current role after consolidation |
|---|---|
| `.hermes.md` | Pointer to this standard; no longer the main place for workflow rules |
| `Decisions.md` | Decision log for architecture, workflow exceptions, and major behavior changes |
| `CHANGELOG.md` | User-visible release change log |
| `AppStore_Submission.md` | Canonical App Store submission content and compliance notes |
| `AppStore_TODO_7.3.5_744.md` and future release TODO files | Release execution checklists for a specific version |
| `Docs/QA/*.md` | Feature-specific QA gates and manual test cases |
| `Docs/PRD/*.md` | Feature contracts, product scope, and acceptance criteria |
| `Docs/ProjectManagement/*.md` | Architecture-approved implementation plans and project management records |
| `CatalogOps/README.md` | Smart Start catalog data-operations rules |
| `SmartStart_GTD.md` | Historical role/workflow reference; future role flow should follow this standard |

## 4. Mandatory End-To-End Workflow

### 4.1 Intake And Scope Control

1. No non-trivial product-facing feature starts without one of the following:
   - an approved PRD, or
   - a PRD-level task brief that clearly defines scope, non-goals, and acceptance criteria.
2. If the request changes user-visible behavior, search rules, data behavior, persistence, or release posture, the work is non-trivial by default.
3. If scope is unclear, ambiguity must be resolved before implementation, not after code is already merged.

### 4.2 Required Delivery Sequence

The default delivery sequence is:

1. Product defines the requirement.
2. Architect reviews data safety, module boundaries, and release risk when the change is behaviorally or structurally significant.
3. QA writes or updates test cases for the feature before the feature is considered complete.
4. Coder implements the smallest approved slice that can be built and reviewed safely.
5. Coder runs the required validation commands and records risks.
6. Reviewer checks code against the PRD, QA cases, this workflow standard, and existing release constraints.
7. Release docs are updated before any version is treated as shippable.

### 4.3 Documentation Duties During Work

The following updates are mandatory when applicable:

1. `Decisions.md` must be updated for:
   - architecture decisions,
   - workflow changes,
   - intentional product behavior deviations from an approved PRD or snapshot,
   - one-off exceptions approved by the project owner.
2. `CHANGELOG.md` must be updated for any user-visible change that is intended to ship.
3. The relevant PRD, rule snapshot, or QA doc must be updated when code intentionally changes a documented feature contract.
4. If code and docs disagree, the discrepancy must be treated as an issue to resolve, not ignored as “just documentation drift”.

## 5. Roles And Responsibilities

### 5.1 Product

- Define goals, scope, non-goals, and acceptance criteria.
- Clarify edge cases before implementation.
- Do not treat unstated assumptions as approved behavior.

### 5.2 Architect

- Protect data safety, module boundaries, and release quality.
- Review risky changes before they become default implementation.
- Decide whether a behavior change is a narrow fix or a contract change that requires doc and QA updates.

### 5.3 Coder

- Keep changes small, buildable, and reviewable.
- Run the required build/validation flow.
- Report file-level changes, known risks, and any conflict with this standard.
- Do not silently widen behavior, search reach, data mutation, or release scope.

### 5.4 QA

- Write or update test cases from the PRD.
- Verify implementation against the PRD and this standard, not just against the current code.
- Treat missing QA coverage as an open risk.

### 5.5 Ops / Data Ops

- Maintain reproducible scripts, data generation notes, and QA reports.
- Do not directly overwrite official production catalogs through automation.
- Promote catalog data only after human review and approval.

## 6. Non-Negotiable Engineering Rules

### 6.1 User Data Safety

1. No feature may silently overwrite existing user tags, notes, or meaningful preferences unless an approved product decision explicitly says so.
2. Automatic classification, seeding, migration, or cleanup work must preserve user-authored data by default.
3. Destructive or hard-to-reverse behavior requires backup, undo, confirmation, or an equivalent safety control.

### 6.2 Product Contract Integrity

1. Code must not silently diverge from approved product scope.
2. If implementation intentionally exceeds PRD scope, the PRD and QA docs must be updated before the behavior is treated as accepted.
3. “The code already does it” is not by itself approval.

### 6.3 Search And Ranking Changes

Search behavior is release-sensitive.

Any change to search scope, matching type, ranking, fuzzy behavior, pinyin handling, searchable fields, or default suggestion logic must include:

1. an explicit statement of the rule change,
2. before/after example queries,
3. updated PRD or rule-snapshot documentation when the contract changes,
4. regression review for both precision and recall,
5. QA coverage for representative edge cases.

No coder may quietly broaden search recall by adding extra matching paths without documenting and reviewing the tradeoff.

### 6.4 Catalog And Ruleset Operations

1. Smart Start catalog automation may generate candidates, reports, and cleaned outputs.
2. Automation must not directly overwrite the official runtime catalog.
3. Promotion into the official catalog requires human approval.
4. Stable tag IDs must remain stable and must not be replaced by localized display names.

## 7. Versioning, Build, And Release Rules

### 7.1 Version Metadata Ownership

1. `CFBundleShortVersionString` is the committed marketing version and must remain stable in source control until intentionally changed.
2. `CFBundleVersion` uses the format `YYYYMMDD.HHmm`.
3. Version and build values shown in source, changelog, release docs, and shipped artifacts must agree.

### 7.2 Build Must Not Pollute The Source Tree

This is a hard rule.

1. The build process must not mutate tracked source files as part of normal packaging.
2. Build metadata that changes per build, including `CFBundleVersion`, must be injected into the built app bundle artifact, not written back into the repository working copy.
3. `Apptag/Info.plist` is source configuration, not build output.
4. If a build changes tracked files, the build flow is defective and must be fixed.

### 7.3 Required Fix For The Current Build Flow

The current `build.sh` behavior that rewrites the tracked `Apptag/Info.plist` is not acceptable as a long-term workflow.

The required remediation is:

1. copy the source `Info.plist` into the app bundle,
2. write the dynamic build number only into the bundle copy,
3. leave the tracked source plist unchanged,
4. verify after build that `git status --short` does not show tracked changes caused by packaging.

Any alternative that relies on manually reverting the file, ignoring the file, or asking humans not to commit the change is only a temporary workaround and is not considered a valid final fix.

### 7.4 Release Readiness Gates

A version is not release-ready until all of the following are true:

1. build succeeds,
2. version/build metadata are internally consistent,
3. relevant manual QA or smoke checks are completed,
4. `CHANGELOG.md` is updated,
5. release docs are updated when the build is intended for external distribution,
6. no known blocker remains open without explicit sign-off.

## 8. Required Validation And Review Gates

### 8.1 Minimum Validation Per Change

At minimum, the implementer or reviewer must verify:

1. the project still builds,
2. the directly affected feature still works,
3. no tracked source file was unintentionally modified by the validation process,
4. relevant docs remain aligned with the code.

### 8.2 Feature-Specific Gates

In addition to the minimum validation:

- Initial-default changes must preserve existing user values and satisfy the initial-default QA cases.
- Smart Start catalog changes must satisfy the catalog validation gates and QA reports before bundling.
- Release-bound changes must be checked against `AppStore_Submission.md` and the active release checklist.
- Search changes must satisfy the search-and-ranking rules in section 6.3.

## 9. Conflict Handling And Escalation

If a request conflicts with this standard:

1. the coder must stop,
2. the coder must identify the exact clause number,
3. the coder must explain the consequence of violating it,
4. the work may continue only if:
   - the request is changed to comply, or
   - a deliberate one-time exception is approved and recorded in `Decisions.md`.

The project commander is not exempt from this process. Instructions from above can change the standard, but they do not silently bypass it.

## 10. Practical Operating Checklist

Before marking work complete, confirm:

- Is the requirement documented well enough to implement safely?
- Does the change need PRD, QA, changelog, or decision-log updates?
- Does the change protect existing user data?
- Does the build pass?
- Did the build leave the repo clean?
- Do release/version docs still match the artifact?
- If the behavior changed, is the contract documentation updated too?

## 11. Future Maintenance Rule

When this workflow standard is updated:

1. increment the document version,
2. record the reason in `Decisions.md`,
3. update any pointer docs that reference the authoritative workflow standard.

Until superseded by a newer version, this document is the workflow contract for Apptag.
