# Initial Defaults PRD

Status: Approved for 7.1.0  
Owner: Product Manager  
Feature: First-install setup defaults

## Goal

A first-time TagLauncher user should immediately see the app in the intended language, with the intended visual layout and basic behavior defaults.

## Requirements

Language:

- On first launch, TagLauncher uses the system preferred language when it is supported.
- If the system language is unsupported, TagLauncher falls back to English.
- If the user later chooses a language manually, that saved preference wins.

General settings defaults for new users:

- Launch at login: on
- Show in Dock: on
- Hide app names: on
- App List Style: Colored Grid
- Tag position: Right
- Tag font size: 22
- Icon size: 80
- Uncommon app bubble tips: off

## Non-Goals

- Do not overwrite existing users' saved settings.
- Do not change the supported language list.

## Acceptance Criteria

- A fresh install with no saved preferences gets all default values above.
- Existing saved values are preserved.
- Build succeeds.
