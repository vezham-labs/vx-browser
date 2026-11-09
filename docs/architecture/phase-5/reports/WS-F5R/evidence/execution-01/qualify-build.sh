#!/bin/bash
set -euo pipefail
draft=/private/tmp/vx-wsf5r.aWxqL0
output="/private/tmp/vx-wsf5r-resume-034205fb/xcode"
mkdir -p "$output/clang" "$output/swift" "$output/packages"
cd "$draft"
python3 apps/browser-macos/Tools/native_host.py chrome
CLANG_MODULE_CACHE_PATH="$output/clang" SWIFTPM_MODULECACHE_OVERRIDE="$output/swift" \
  xcodebuild -project apps/browser-macos/VezhamBrowser.xcodeproj \
  -scheme VezhamBrowser -configuration Debug -destination platform=macOS,arch=arm64 \
  -derivedDataPath "$output/DerivedData" -packageCachePath "$output/packages" \
  -clonedSourcePackagesDirPath "$output/SourcePackages" -resultBundlePath "$output/result.xcresult" \
  build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES MACOSX_DEPLOYMENT_TARGET=26.0 \
  PRODUCT_BUNDLE_IDENTIFIER=internal.vezham.browser.wsf5.qualification
