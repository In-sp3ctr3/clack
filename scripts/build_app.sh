#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-release}"
BUILD_UNIVERSAL="${BUILD_UNIVERSAL:-1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/apple/Clack.app"

cd "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Packaging/Clack.icns" "$APP_DIR/Contents/Resources/Clack.icns"
cp "$ROOT_DIR/Packaging/ClackMenuBarTemplate.png" "$APP_DIR/Contents/Resources/ClackMenuBarTemplate.png"

if [[ "$(uname -s)" == "Darwin" && "$BUILD_UNIVERSAL" == "1" && -x "$(command -v lipo)" ]]; then
  swift build --configuration "$CONFIGURATION" --triple arm64-apple-macosx13.0 --product Clack
  swift build --configuration "$CONFIGURATION" --triple x86_64-apple-macosx13.0 --product Clack

  ARM_BINARY_DIR="$(swift build --configuration "$CONFIGURATION" --triple arm64-apple-macosx13.0 --show-bin-path)"
  X86_BINARY_DIR="$(swift build --configuration "$CONFIGURATION" --triple x86_64-apple-macosx13.0 --show-bin-path)"

  lipo -create "$ARM_BINARY_DIR/Clack" "$X86_BINARY_DIR/Clack" -output "$APP_DIR/Contents/MacOS/Clack"
else
  swift build --configuration "$CONFIGURATION" --product Clack

  BINARY_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
  cp "$BINARY_DIR/Clack" "$APP_DIR/Contents/MacOS/Clack"
fi

chmod +x "$APP_DIR/Contents/MacOS/Clack"

echo "$APP_DIR"
