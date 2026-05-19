# Clack

[![Repository Hygiene](https://github.com/In-sp3ctr3/clack/actions/workflows/repo-hygiene.yml/badge.svg)](https://github.com/In-sp3ctr3/clack/actions/workflows/repo-hygiene.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Clack is a native macOS clipboard memory tool. It lives in the menu bar, remembers what you copy, and lets you quickly search, pin, restore, or clean up clipboard items without breaking your flow.

> Project status: early planning. The public repo foundation is in place, and the app implementation is next.

## Goals

- Keep a searchable local history of copied text.
- Restore any saved item to the macOS clipboard with one click.
- Pin important items so they survive history cleanup.
- Support fast keyboard-driven access to recent items.
- Show useful metadata such as first copied, last copied, and copy count.
- Respect privacy by keeping clipboard history local by default.

## Planned macOS Experience

- Menu bar app with a compact popover.
- Search box at the top of the clipboard history.
- Recent clipboard items listed with preview text.
- Keyboard shortcuts for the top history entries.
- Hover/details view for expanded content and metadata.
- Preferences, clear history, about, and quit actions.

Clack will target macOS as a Universal 2 app where possible, so one release can support both Apple Silicon and Intel Macs.

## Privacy

Clipboard managers handle sensitive data by nature. Clack's default design principle is local-first: no clipboard contents should leave the device unless a future feature explicitly asks for user consent and documents what is shared.

If you find a privacy or security issue, please see [SECURITY.md](SECURITY.md).

## Download

There is no release yet. When Clack has its first usable build, downloads will be published through GitHub Releases and linked from the project website.

## Contributing

This is a small project, but it should still be easy to contribute to. Start with [CONTRIBUTING.md](CONTRIBUTING.md), then open an issue or pull request.

Good first contributions while the app is young:

- Product feedback on the MVP scope.
- macOS clipboard edge cases.
- Menu bar UX suggestions.
- Documentation fixes.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).

## License

Clack is released under the [MIT License](LICENSE).
