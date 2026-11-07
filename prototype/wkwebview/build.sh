#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${WK_BUILD_DIR:-$ROOT/build}"
BUNDLE_ID="${WK_BUNDLE_ID:-internal.vezham.WKPrototype}"
ENTITLEMENTS="${WK_ENTITLEMENTS:-$ROOT/entitlements.plist}"
APP="$BUILD_DIR/VezhamWKPrototype.app"
CONTENTS="$APP/Contents"
SDK="$(xcrun --show-sdk-path)"

mkdir -p "$BUILD_DIR"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

swiftc \
  -sdk "$SDK" \
  -target arm64-apple-macosx26.0 \
  -module-cache-path "$BUILD_DIR/module-cache" \
  -O \
  -parse-as-library \
  -framework AppKit \
  -framework AVFoundation \
  -framework WebKit \
  -framework Security \
  -o "$CONTENTS/MacOS/VezhamWKPrototype" \
  "$ROOT/Sources/NavigationPolicy.swift" \
  "$ROOT/Sources/LocalInteractionProbe.swift" \
  "$ROOT/Sources/Phase3Measurements.swift" \
  "$ROOT/Sources/main.swift"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>VezhamWKPrototype</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Vezham WK Prototype</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsLocalNetworking</key><true/></dict>
</dict>
</plist>
PLIST

if [[ "${WK_MEDIA_CAPTURE_TEST:-0}" == "1" ]]; then
  /usr/libexec/PlistBuddy -c 'Add :NSCameraUsageDescription string "Temporary Phase 3 test: the browser will deny a synthetic camera request."' "$CONTENTS/Info.plist"
  /usr/libexec/PlistBuddy -c 'Add :NSMicrophoneUsageDescription string "Temporary Phase 3 test: the browser will deny a synthetic microphone request."' "$CONTENTS/Info.plist"
fi

codesign --force --sign - --options runtime \
  --entitlements "$ENTITLEMENTS" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "Built and verified: $APP"
