#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-findzoom.XXXXXX")"
trap 'rm -rf "$TEMP_BUILD"' EXIT
BUNDLE_ID="internal.vezham.WKPrototype.FindZoom.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
EXECUTABLE="$BUILD_DIR/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype"
"$EXECUTABLE" --test-find-zoom --test-run-id "$RUN_ID"

RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
RESULT="$RESULTS_DIR/find-zoom-results-$RUN_ID.json"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2); assert result["failureCount"] == 0; print("Find and zoom harness passed:", len(result["tests"]), "checks")' "$RESULT"
echo "Results: $RESULT"
