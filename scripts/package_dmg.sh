#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/apple/Clack.app}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/.build/apple/Clack.dmg}"
VOLUME_NAME="${VOLUME_NAME:-Clack}"
STAGE_DIR="$ROOT_DIR/.build/dmg/$VOLUME_NAME"

if [[ "$(uname -s)" != "Darwin" ]] || ! command -v hdiutil >/dev/null 2>&1; then
  echo "DMG packaging requires macOS with hdiutil." >&2
  exit 1
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "App bundle not found: $APP_DIR" >&2
  echo "Run ./scripts/build_app.sh first." >&2
  exit 1
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR" "$(dirname "$DMG_PATH")"

cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "$DMG_PATH"
