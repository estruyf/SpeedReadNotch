#!/bin/bash
set -euo pipefail

SCHEME="SpeedReadNotch"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/release"
ARCHIVE_ARM="$BUILD_DIR/SpeedReadNotch-arm64.xcarchive"
APP_NAME="SpeedReadNotch.app"
OUTPUT_DIR="$BUILD_DIR/universal"
OUTPUT_APP="$OUTPUT_DIR/$APP_NAME"
DMG_NAME="SpeedReadNotch.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "🧹 Cleaning previous build…"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

if [ ! -d "$PROJECT_DIR/SpeedReadNotch.xcodeproj" ]; then
    echo "❌ SpeedReadNotch.xcodeproj not found."
    echo "Please open Xcode, create a new macOS App named 'SpeedReadNotch', and ensure it is saved in: $PROJECT_DIR"
    exit 1
fi

echo "🔨 Building for Apple Silicon (arm64)…"
xcodebuild archive \
  -project "$PROJECT_DIR/SpeedReadNotch.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_ARM" \
  -destination "generic/platform=macOS" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  -quiet

ARM_APP="$ARCHIVE_ARM/Products/Applications/$APP_NAME"

echo "📦 Preparing app…"
cp -R "$ARM_APP" "$OUTPUT_APP"

echo "📦 Creating DMG…"
rm -f "$DMG_PATH"

# Using https://github.com/sindresorhus/create-dmg
create-dmg "$ARM_APP" "$BUILD_DIR"

echo ""
echo "✅ Done!"
echo "   App:  $OUTPUT_APP"
echo "   DMG:  $DMG_PATH"
echo ""
open "$BUILD_DIR"
