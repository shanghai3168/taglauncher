# TagLauncher Help PDFs

Versioned help package for TagLauncher `7.6.0`.

## Contents

- 29 localized PDF files: `Taglauncher-help-<language>.pdf`
- `manifest.json`: language, filename, size, SHA-256, and GitHub Release base URL
- `Taglauncher-help-multilang-report.txt`: generation report
- `preview/contact-sheet.png`: visual QA contact sheet
- `source/Taglauncher-Help.excalidraw`: source drawing used to generate the PDFs

## Git Policy

These PDFs are intentionally tracked in git.

Reasoning:

- Help content is part of the product release contract.
- Future app versions may need matching help versions.
- Every PDF is below GitHub's 100MB per-file limit.
- Keeping them as regular git files keeps the release asset source auditable, while the app opens immutable GitHub Release asset URLs.

If future help packages become much larger, move old versions to GitHub Releases or a documentation repository and keep only the active version in this repo.

## Public URL Shape

After creating a public GitHub Release for tag `v7.6.0` in `shanghai3168/taglauncher` and uploading the PDFs as release assets, the app opens:

```text
https://github.com/shanghai3168/taglauncher/releases/download/v7.6.0/Taglauncher-help-<language>.pdf
```

The app falls back to English if the current language is not mapped.
