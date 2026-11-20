#!/bin/bash
# Script to build and package LuminaVault into an installable .ipa file
# Works on macOS with Xcode installed, or inside GitHub Actions CI

set -e

PROJECT="LuminaVault.xcodeproj"
SCHEME="LuminaVault"
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/LuminaVault.xcarchive"
IPA_PATH="$BUILD_DIR/LuminaVault.ipa"

echo "=========================================================="
echo "🚀 Building and packaging LuminaVault.ipa"
echo "=========================================================="

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 1. Build .xcarchive targeting generic iOS device
echo "📦 Step 1: Compiling native ARM64 iOS Archive..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean archive

# 2. Package into Payload and Zip to .ipa
echo "📦 Step 2: Packaging Payload into LuminaVault.ipa..."
mkdir -p "$BUILD_DIR/Payload"
cp -r "$ARCHIVE_PATH/Products/Applications/LuminaVault.app" "$BUILD_DIR/Payload/"
cd "$BUILD_DIR"
zip -r "LuminaVault.ipa" Payload
cd ..

echo "=========================================================="
echo "🎉 SUCCESS: IPA created at $IPA_PATH"
echo "You can now install LuminaVault.ipa on your iPhone 14 using:"
echo " • AltStore"
echo " • Sideloadly"
echo " • TrollStore"
echo " • Apple Configurator / Xcode Devices Window"
echo "=========================================================="
