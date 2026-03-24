#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Generate AppIcon.icns from SF Symbol
if [ ! -f Resources/AppIcon.icns ]; then
    echo "==> Generating AppIcon.icns..."
    swift Resources/generate_icon.swift
fi

echo "==> Building COTP..."
swift build -c release

APP=/tmp/COTP.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/COTP "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"

codesign --force --sign - "$APP"

pkill -x COTP 2>/dev/null || true
rm -rf /Applications/COTP.app
mv "$APP" /Applications/
touch /Applications/COTP.app
open /Applications/COTP.app
echo "==> Installed COTP.app"
