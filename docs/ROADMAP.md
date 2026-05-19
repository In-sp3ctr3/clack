# Roadmap

This roadmap is intentionally lightweight. It should guide the first releases without pretending the project is bigger than it is.

## Current Alpha

- Native macOS menu bar app.
- Watch the system pasteboard for copied text.
- Store local clipboard history.
- Show a searchable menu or popover.
- Click an item to restore it to the clipboard.
- Clear history.
- Quit from the menu bar.
- Package a local `.app` bundle.
- Preferences for storage size, sorting, appearance, pins, ignore rules, launch at login, and cleanup behavior.
- Selected-row keyboard navigation in the popover.
- First-pass accessibility labels and hints for the popover and preferences.
- Universal 2 macOS builds where the build environment supports both architectures.
- Dated GitHub prereleases with checksums.

## Next: Workflow Polish

- Add stronger source-app metadata where macOS exposes it.
- Improve empty states and failure messaging.
- Add editable global shortcuts.
- Add signed release artifacts.

## Keyboard-First Usage

- Configurable shortcuts for recent items.
- Deeper VoiceOver review with real assistive technology testing.

## Distribution

- Signed and notarized releases if an Apple Developer account is available.
- DMG packaging.
- Public download page deployment.

## Later Ideas

- Optional sensitive-content rules.
- Export/import local history.
- Rich content support beyond plain text.
- Better Universal Clipboard metadata where macOS makes it available.
