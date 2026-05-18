# Initial Defaults Test Cases

Status: Approved for 7.1.0  
Owner: QA Engineer  
Input PRD: `Docs/PRD/InitialDefaults_PRD.md`

## ID-001 Fresh User Language Follows System

Preconditions:

- No saved `appLanguage` preference.
- macOS preferred language is supported by TagLauncher.

Steps:

1. Launch TagLauncher.
2. Open Settings > Language.

Expected:

- The selected language matches the supported macOS preferred language.
- If the macOS language is unsupported, English is selected.

## ID-002 Fresh User General Defaults

Preconditions:

- No saved UserDefaults for the relevant settings.

Steps:

1. Launch TagLauncher.
2. Open Settings > General.

Expected:

- Launch at login is on.
- Show in Dock is on.
- Hide app names is on.
- App List Style is Colored Grid.
- Tag position is Right.
- Tag font size is 22.
- Icon size is 80.

## ID-003 Existing User Values Are Preserved

Preconditions:

- User has manually saved different values for one or more settings.

Steps:

1. Launch the new build.
2. Open Settings > General.

Expected:

- Existing saved settings are not overwritten by the new defaults.

## ID-004 Uncommon Bubble Default Remains Off

Preconditions:

- Fresh user.

Steps:

1. Open Settings > Data.

Expected:

- Uncommon app bubble tips is off by default.
