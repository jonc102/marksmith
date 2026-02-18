#!/bin/bash
set -euo pipefail

# MarkdownPaste Build & Release Script
# Archives, code-signs, notarizes, and packages the app into a DMG.
#
# Prerequisites:
#   - Xcode 15+ with command line tools
#   - XcodeGen: brew install xcodegen
#   - create-dmg: brew install create-dmg
#   - Valid Apple Developer ID certificate
#   - App-specific password for notarization

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

APP_NAME="MarkdownPaste"
SCHEME="MarkdownPaste"
CONFIGURATION="Release"
ARCHIVE_PATH="${PROJECT_DIR}/build/${APP_NAME}.xcarchive"
EXPORT_PATH="${PROJECT_DIR}/build/export"
DMG_PATH="${PROJECT_DIR}/build/${APP_NAME}.dmg"

echo "=== MarkdownPaste Release Build ==="
echo ""

# Step 1: Generate Xcode project
echo "Step 1: Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate
echo "  Done."

# Step 2: Archive
echo "Step 2: Archiving..."
xcodebuild archive \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_STYLE=Automatic \
    | tail -5
echo "  Done."

# Step 3: Export
echo "Step 3: Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "${PROJECT_DIR}/ExportOptions.plist" \
    -exportPath "$EXPORT_PATH" \
    | tail -5
echo "  Done."

# Step 4: Create DMG
echo "Step 4: Creating DMG..."
if command -v create-dmg &> /dev/null; then
    rm -f "$DMG_PATH"
    create-dmg \
        --volname "$APP_NAME" \
        --volicon "${EXPORT_PATH}/${APP_NAME}.app/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 190 \
        --app-drop-link 450 190 \
        "$DMG_PATH" \
        "${EXPORT_PATH}/${APP_NAME}.app" \
        || true
    echo "  Done."
else
    echo "  Warning: create-dmg not found. Creating simple DMG with hdiutil..."
    rm -f "$DMG_PATH"
    hdiutil create -volname "$APP_NAME" -srcfolder "${EXPORT_PATH}/${APP_NAME}.app" -ov -format UDZO "$DMG_PATH"
    echo "  Done."
fi

# Step 5: Notarize
echo "Step 5: Notarizing..."
if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --keychain-profile "notarytool-profile" \
        --wait

    echo "Step 6: Stapling..."
    xcrun stapler staple "$DMG_PATH"
    echo "  Done."
else
    echo "  Skipped: Set APPLE_ID and APPLE_TEAM_ID environment variables for notarization."
fi

echo ""
echo "=== Build complete ==="
echo "DMG: $DMG_PATH"
