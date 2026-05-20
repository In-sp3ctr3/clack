# Roadmap

This roadmap is intentionally lightweight. It should guide the first releases without pretending the project is bigger than it is.

## Current Alpha

- Native macOS menu bar app.
- Watch the system pasteboard for copied text, formatted text, file URLs, and images.
- Store local clipboard history.
- Show a searchable menu or popover.
- Click an item to restore it to the clipboard.
- Hover an item to preview content and metadata.
- Clear history.
- Quit from the menu bar.
- Package a local `.app` bundle.
- Preferences for storage size, sorting, appearance, pins, ignore rules, launch at login, and cleanup behavior.
- Configurable shortcuts for opening Clack, pinning, and deleting.
- Selected-row keyboard navigation in the popover.
- First-pass accessibility labels and hints for the popover and preferences.
- Universal 2 macOS builds where the build environment supports both architectures.
- Dated GitHub prereleases with checksums.
- DMG packaging for alpha downloads.
- Custom app icon.
- Homebrew cask installation through the project tap.

## Next: UI Template Pass

- Apply the final menu and preferences templates.
- Tighten spacing, row density, hover preview placement, and empty states.
- Verify common flows with screenshots before release.

## Workflow Polish

- Improve empty states and failure messaging.
- Extend shortcut customization beyond the current core actions.
- Add signed release artifacts.

## Keyboard-First Usage

- Configurable shortcuts for recent items beyond the default `Command` + number behavior.
- Deeper VoiceOver review with real assistive technology testing.

## Distribution

- Signed and notarized releases if an Apple Developer account is available.
- Public download page deployment on Vercel.

## Later Ideas

- Optional sensitive-content rules.
- Export/import local history.
- Optional encrypted storage.
- Optional deeper source and Universal Clipboard attribution if Apple exposes stronger public pasteboard origin APIs.
