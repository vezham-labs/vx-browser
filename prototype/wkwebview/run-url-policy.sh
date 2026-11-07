#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-url-policy.XXXXXX")"
trap 'rm -rf "$TEMP_BUILD"' EXIT
SDK="$(xcrun --show-sdk-path)"
TEST_BINARY="$TEMP_BUILD/navigation-policy-tests"

swiftc \
  -sdk "$SDK" \
  -target arm64-apple-macosx26.0 \
  -module-cache-path "$TEMP_BUILD/module-cache" \
  -parse-as-library \
  -o "$TEST_BINARY" \
  "$ROOT/Sources/NavigationPolicy.swift" \
  "$ROOT/Tests/NavigationPolicyTests.swift"

mkdir -p "$ROOT/Evidence"
RESULT="$ROOT/Evidence/url-policy-results.json"
"$TEST_BINARY" > "$RESULT"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2); assert result["failureCount"] == 0; print("URL input policy passed:", len(result["tests"]), "checks on", result["hostOSVersion"])' "$RESULT"
