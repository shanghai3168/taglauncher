# Publishing Privacy And Support Pages On GitHub

App Store Connect needs public URLs for privacy policy and support. The simplest path is GitHub Pages.

## Recommended URL Shape

If you publish from this repository with GitHub Pages, use URLs like:

- Privacy Policy: `https://[GITHUB_USER_OR_ORG].github.io/[REPO_NAME]/privacy/`
- Support: `https://[GITHUB_USER_OR_ORG].github.io/[REPO_NAME]/support/`

Exact URLs depend on the GitHub owner, repository name, and Pages settings.

## Files To Publish

Copy these release-pack files into a public `docs/` folder in the GitHub repository:

```text
docs/privacy.md
docs/privacy.zh-Hans.md
docs/support.md
```

Suggested source mapping:

```text
Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.md -> docs/privacy.md
Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.zh-Hans.md -> docs/privacy.zh-Hans.md
Release/AppStore-7.6.0-20260527.0124/Support/SUPPORT.md -> docs/support.md
```

Replace all placeholders before publishing:

- `[YOUR NAME OR COMPANY NAME]`
- `[PRIVACY OR SUPPORT EMAIL]`
- `[SUPPORT EMAIL]`
- `[PUBLIC PRIVACY POLICY URL]`

## GitHub Pages Setup

1. Push the repository to GitHub.
2. Open the repository on GitHub.
3. Go to `Settings` -> `Pages`.
4. Under `Build and deployment`, choose:
   - Source: `Deploy from a branch`
   - Branch: `main`
   - Folder: `/docs`
5. Save.
6. Wait for GitHub Pages to publish.
7. Open the generated URLs in a private browser window and confirm they are public.
8. Paste the public privacy and support URLs into App Store Connect.

## Alternative: Dedicated Website Repository

If you prefer a clean URL, create a separate public repository named `[GITHUB_USER_OR_ORG].github.io`.

Then publish:

```text
privacy.md
privacy.zh-Hans.md
support.md
```

The URLs become:

```text
https://[GITHUB_USER_OR_ORG].github.io/privacy/
https://[GITHUB_USER_OR_ORG].github.io/support/
```

## App Store Connect Fields

Use:

- Privacy Policy URL: the public privacy page.
- Support URL: the public support page.

If you localize App Store metadata later, you can also provide localized privacy policy URLs per locale.
