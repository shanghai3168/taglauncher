# GitHub Help Publishing Notes

## Current Plan

The app opens localized help PDFs from:

```text
https://github.com/shanghai3168/taglauncher/releases/download/v7.6.0/Taglauncher-help-<language>.pdf
```

This requires the GitHub repository to be available at:

```text
shanghai3168/taglauncher
```

If the actual repository owner, name, or release tag is different, update the Help PDF URL in `Apptag/PreferencesView.swift` before release.

## Why PDFs Are In Git

The localized help PDFs are tracked as versioned release assets because help content must match the app version. The app opens GitHub Release asset URLs so the shipped binary does not depend on the mutable `main` branch and does not bundle 106MB of PDFs inside the Mac app.

Current package:

- Version: `v7.6.0`
- PDF count: `29`
- Total PDF size: about `106MB`
- Largest PDF: about `5MB`

This is acceptable for the first release because no single file is near GitHub's 100MB file limit. Revisit this if future versions keep many old help packages in the main repo.

## Publishing Checklist

- [ ] Confirm the GitHub repository is `shanghai3168/taglauncher`.
- [ ] Create a public GitHub Release for tag `v7.6.0`.
- [ ] Upload all 29 PDFs from `Docs/Help/v7.6.0/` as Release assets.
- [ ] Open one Release asset URL in a browser:
  - `https://github.com/shanghai3168/taglauncher/releases/download/v7.6.0/Taglauncher-help-en.pdf`
- [ ] Open TagLauncher, open Preferences, go to About, and click Open Help PDF.
- [ ] Switch app language to Simplified Chinese, go to About, and click Open Help PDF; it should open `Taglauncher-help-zh.pdf`.
- [ ] Switch app language to Traditional Chinese, go to About, and click Open Help PDF; it should open `Taglauncher-help-zh-Hant.pdf`.

## If The Repo Is Private

Private GitHub repository URLs are not appropriate for end-user help. Use one of these instead:

- Make only the help repository public.
- Use GitHub Pages from a public repository.
- Attach the PDFs to a public GitHub Release and keep the app's Help PDF URL pointed at that release.
- Host the PDFs on the product website/CDN.

## Source Code Policy

Do not push the TagLauncher app source code to `shanghai3168/taglauncher`.
That public repository is currently used only for immutable Help PDF release assets.
