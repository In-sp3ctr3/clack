# Changelog

All notable changes to Clack will be documented in this file.

This project follows a simple versioned changelog format inspired by Keep a Changelog.

## Unreleased

### Added

- Added the initial open-source repository foundation.
- Added the first native macOS menu bar app scaffold.
- Added local clipboard history storage, search, pinning, deletion, clearing, and preferences.
- Added Swift checks for clipboard history behavior.
- Added multi-pane preferences for general, storage, appearance, pins, ignore, and advanced settings.
- Added preliminary release packaging for version tags.
- Added dated GitHub prereleases for preliminary builds.
- Added DMG packaging for local builds and GitHub prereleases.
- Added a custom macOS app icon.
- Added a Vercel-ready download page scaffold.
- Added formatted text, file, and image clipboard storage.
- Added image thumbnails in the menu and image previews in the hover detail card.
- Added confidence-based source app metadata.
- Added configurable shortcuts for opening Clack, pinning items, and deleting items.
- Added a compact row-anchored hover preview for clipboard content and metadata.

### Changed

- Aligned download copy and preferences with the current alpha behavior.
- Added selected-row keyboard navigation in the clipboard popover.
- Improved accessibility labels and hints across the menu bar, popover, and preferences.
- Refined the clipboard menu header, footer, image rows, and keyboard shortcuts.
- Refined preferences layout, tab switching, hit targets, pins table, and ignore list panels.

### Fixed

- Fixed stale hover preview popovers remaining visible after pointer movement.
- Fixed Finder image-file copies showing only file names instead of image previews.
- Fixed preference panes clipping their toolbar or bottom content at the default window size.
