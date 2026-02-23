#!/bin/bash
set -euo pipefail

# Marksmith Build & Release Script
# Builds and packages the app into a DMG.
#
# Usage:
#   ./Scripts/build-release.sh                    # Unsigned build (default)
#   SIGN=1 ./Scripts/build-release.sh             # Signed build (requires Developer ID)
#   SIGN=1 NOTARIZE=1 ./Scripts/build-release.sh  # Signed + notarized (requires Developer ID + credentials)
#
# Prerequisites:
#   - Xcode 15+ with command line tools
#   - XcodeGen: brew install xcodegen
#   - create-dmg: brew install create-dmg (optional, falls back to hdiutil)
#   - For signing: Apple Developer ID certificate in Keychain
#   - For notarization: APPLE_ID and APPLE_TEAM_ID env vars + stored keychain profile

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

APP_NAME="Marksmith"
SCHEME="Marksmith"
CONFIGURATION="Release"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

SIGN="${SIGN:-0}"
NOTARIZE="${NOTARIZE:-0}"

echo "=== Marksmith Release Build ==="
echo "Mode: $([ "$SIGN" = "1" ] && echo "Signed" || echo "Unsigned") $([ "$NOTARIZE" = "1" ] && echo "+ Notarized" || echo "")"
echo ""

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Step 1: Generate Xcode project
echo "Step 1: Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate
echo "  Done."

# Step 2: Build or Archive
if [ "$SIGN" = "1" ]; then
    echo "Step 2: Archiving (signed)..."
    xcodebuild archive \
        -project "${APP_NAME}.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination 'generic/platform=macOS' \
        | tail -5

    echo "Step 3: Exporting archive..."
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "${PROJECT_DIR}/Scripts/ExportOptions.plist" \
        -exportPath "$EXPORT_PATH" \
        | tail -5
    echo "  Done."
else
    echo "Step 2: Building (unsigned)..."
    xcodebuild build \
        -project "${APP_NAME}.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        -destination 'platform=macOS' \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        | tail -5

    # Copy the built app to export path
    mkdir -p "$EXPORT_PATH"
    APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${APP_NAME}.app" -type d | head -1)
    if [ -z "$APP_PATH" ]; then
        echo "  ERROR: Could not find built app"
        exit 1
    fi
    cp -R "$APP_PATH" "${EXPORT_PATH}/${APP_NAME}.app"
    echo "  Done."
fi

# Step 3/4: Create DMG
echo "Step $([ "$SIGN" = "1" ] && echo "4" || echo "3"): Creating DMG..."
if command -v create-dmg &> /dev/null; then
    rm -f "$DMG_PATH"
    create-dmg \
        --volname "$APP_NAME" \
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
    echo "  create-dmg not found, using hdiutil..."
    rm -f "$DMG_PATH"
    hdiutil create -volname "$APP_NAME" -srcfolder "${EXPORT_PATH}/${APP_NAME}.app" -ov -format UDZO "$DMG_PATH"
    echo "  Done."
fi

# Step 4/5: Notarize (only if signed and requested)
if [ "$SIGN" = "1" ] && [ "$NOTARIZE" = "1" ]; then
    if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
        echo "Step 5: Notarizing..."
        xcrun notarytool submit "$DMG_PATH" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --keychain-profile "notarytool-profile" \
            --wait

        echo "Step 6: Stapling..."
        xcrun stapler staple "$DMG_PATH"
        echo "  Done."
    else
        echo "  Skipped notarization: Set APPLE_ID and APPLE_TEAM_ID environment variables."
    fi
fi

echo ""
echo "=== Build complete ==="
echo "DMG: $DMG_PATH"
if [ "$SIGN" != "1" ]; then
    echo ""
    echo "NOTE: This is an unsigned build. Recipients must go to"
    echo "System Settings → Privacy & Security → Security → Open Anyway on first launch."
fi
