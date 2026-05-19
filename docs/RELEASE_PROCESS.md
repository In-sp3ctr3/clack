# Release Process

Clack has no packaged app release yet. This document defines the intended release flow so the project has a clear path before the first build.

## Versioning

Use semantic versioning once releases begin:

- `MAJOR` for incompatible changes.
- `MINOR` for new user-facing features.
- `PATCH` for fixes and small maintenance releases.

Early releases may use `0.x.y` while the product is still changing quickly.

## Release Checklist

1. Confirm all CI checks pass on `main`.
2. Update `CHANGELOG.md`.
3. Build the app for macOS.
4. Produce a Universal 2 artifact when supported.
5. Sign and notarize the app when credentials are available.
6. Generate checksums for downloadable artifacts.
7. Create a GitHub Release with release notes and artifacts.
8. Update the website download link.

## Distribution

GitHub Releases should be the source of truth for downloadable artifacts. The website can link to the latest release, but it should not hide the GitHub release history.

## Packages

Clack is a desktop app, so GitHub Packages is not expected to be part of the first release. If the project later publishes reusable libraries or package-manager artifacts, that decision should be documented here.
