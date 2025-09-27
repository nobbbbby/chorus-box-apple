#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
PROJECT_PATH="$PROJECT_DIR/Chorus Box.xcodeproj"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required to run the test suite" >&2
  exit 1
fi

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme ApplicationLibraryTests \
  -destination 'platform=macOS,arch=x86_64' \
  test
