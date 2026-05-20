# Clack

[![Repository Hygiene](https://github.com/In-sp3ctr3/clack/actions/workflows/repo-hygiene.yml/badge.svg)](https://github.com/In-sp3ctr3/clack/actions/workflows/repo-hygiene.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Clack is a native macOS clipboard history app that lives in the menu bar. It keeps copied text, formatted text, files, and images close at hand, then lets you search, pin, restore, preview, or clear them without opening a full window.

Clack is local-first by design. Clipboard contents are stored on your Mac and are not sent to a server.

## Install

Install the current alpha with Homebrew:

```sh
brew install --cask In-sp3ctr3/tap/clack
```

Or download the latest build from [GitHub Releases](https://github.com/In-sp3ctr3/clack/releases).

Alpha builds are unsigned and not notarized yet, so macOS may warn before opening the app. Signed and notarized releases are planned.

## What It Does

- Keeps a searchable clipboard history in the macOS menu bar.
- Stores plain text, formatted text, file URLs, and images.
- Restores saved items back to the system clipboard, with optional automatic paste behavior.
- Pins important items so they survive cleanup.
- Shows compact image thumbnails in the menu and larger previews on hover.
- Shows first copied, last copied, copy count, pasteboard types, and source confidence.
- Provides quick keyboard access to recent items, pinning, deletion, clearing, preferences, and quit.
- Supports ignore rules for apps, pasteboard types, and regular expressions.
- Keeps history local unless a future feature explicitly says otherwise.

## How It Works

Launch Clack and use the menu bar icon to open your clipboard history. Select any item to put it back on the system clipboard, then paste it wherever you were working.

Use search to narrow the list, pin items you reuse often, and clear unpinned history when it gets noisy. Hover an item to see a larger preview with metadata. Preferences include storage limits, saved content types, appearance controls, ignore lists, launch at login, shortcut configuration, and cleanup behavior.

Source labels are confidence-based. macOS does not expose a guaranteed origin for every pasteboard change, so Clack records whether the source came from the frontmost app, a recently active app fallback, or an unknown source.

## Privacy

Clipboard managers handle sensitive material by nature. Clack assumes copied data may include passwords, tokens, private messages, work content, addresses, and financial details.

Current alpha storage is a local JSON file:

```text
~/Library/Application Support/Clack/history.json
```

Depending on your preferences, that file can include copied text, rich text representations, file paths, image data, pasteboard type names, timestamps, pins, and source metadata. See [docs/PRIVACY_MODEL.md](docs/PRIVACY_MODEL.md) for the current privacy model.

Security issues should be reported through [SECURITY.md](SECURITY.md).

## Requirements

- macOS 13 Ventura or newer.
- Apple Silicon or Intel Mac.
- Swift 6.1 or a recent Xcode toolchain for local development.

Release builds are intended to be Universal 2 where the build environment supports both Apple Silicon and Intel outputs.

## Build From Source

Clone the repository, then run the core checks:

```sh
swift run ClackCoreChecks
```

Build a local app bundle:

```sh
./scripts/build_app.sh
open .build/apple/Clack.app
```

Package a local DMG:

```sh
./scripts/package_dmg.sh
open .build/apple/Clack.dmg
```

Regenerate the app icon:

```sh
./scripts/generate_app_icon.swift
```

For a single-architecture local build, use:

```sh
BUILD_UNIVERSAL=0 ./scripts/build_app.sh
```

## Project Status

Clack is in early alpha. The app is usable, released through GitHub and a project-owned Homebrew tap, and still changing quickly.

Active priorities:

- Signed and notarized releases.
- More real-world clipboard edge case testing.
- UI polish against the final design templates.
- Better empty states and failure messages.
- More shortcut customization beyond the current core actions.
- Storage hardening before a stable release.

See [docs](docs/README.md), [docs/ROADMAP.md](docs/ROADMAP.md), and [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) for more detail.

## Contributing

Contributions are welcome while the project is small and easy to shape. Good places to start:

- macOS pasteboard edge cases.
- Menu bar UX polish.
- Accessibility feedback.
- Documentation fixes.
- Privacy and storage review.

Please read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [GOVERNANCE.md](GOVERNANCE.md) before opening a pull request.

## Project Docs

- [Privacy model](docs/PRIVACY_MODEL.md)
- [Roadmap](docs/ROADMAP.md)
- [Release process](docs/RELEASE_PROCESS.md)
- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Website

The Vercel-ready download page lives in [site](site). See [site/README.md](site/README.md) for local website commands.

## License

Clack is released under the [MIT License](LICENSE).
