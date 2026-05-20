# Release Process

Clack publishes preliminary macOS builds through GitHub Releases. Early artifacts are useful for testing, but they should stay marked as prereleases until signing and notarization are in place.

## Versioning

Use semantic versioning once releases begin:

- `MAJOR` for incompatible changes.
- `MINOR` for new user-facing features.
- `PATCH` for fixes and small maintenance releases.

Early releases may use `0.x.y` while the product is still changing quickly. Alpha builds should use prerelease tags such as `v0.1.0-alpha.1`.

## Release Checklist

1. Confirm all CI checks pass on `main`.
2. Update `CHANGELOG.md`.
3. Run `swift run ClackCoreChecks`.
4. Build the app for macOS with `./scripts/build_app.sh`.
5. Package the DMG with `./scripts/package_dmg.sh` when testing release assets locally.
6. Confirm the app artifact is Universal 2 when supported.
7. Tag the release with `vX.Y.Z` or `vX.Y.Z-alpha.N`.
8. The release workflow publishes a dated GitHub prerelease with dated DMG, zip, and checksum assets.
9. Sign and notarize the app when credentials are available.
10. Replace unsigned artifacts before promoting a release out of prerelease.
11. Update the website download link.
12. Update the Homebrew cask in the project tap.

## Distribution

GitHub Releases should be the source of truth for downloadable artifacts. The website can link to the latest release, but it should not hide the GitHub release history.

Preliminary builds use the release date in both the title and artifact names, for example `Clack-0.1.0-alpha.1-2026-05-19.dmg`.

The project-owned Homebrew tap lives at [In-sp3ctr3/homebrew-tap](https://github.com/In-sp3ctr3/homebrew-tap). After publishing a new release, update `Casks/clack.rb` with the new version, release date, and DMG SHA-256, then confirm:

```sh
brew install --cask In-sp3ctr3/tap/clack
```

The cask can move to Homebrew's official cask repository after stable signed and notarized releases are available and the project meets Homebrew's acceptance expectations.

## Signing and Notarization

Unsigned alpha builds are acceptable for early testers, but stable releases should be signed and notarized.

Signing and notarization require:

- An Apple Developer Program account.
- A Developer ID Application certificate.
- A hardened runtime signing configuration.
- Notarization credentials stored as GitHub Actions secrets.
- A local verification pass using `spctl` and `codesign`.

Until those credentials exist, release notes and install docs must clearly state that alpha builds are unsigned and not notarized.

## Packages

Clack is a desktop app, so GitHub Packages is not expected to be part of the first release. If the project later publishes reusable libraries or package-manager artifacts, that decision should be documented here.
