#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Convert app.png → AppIcon.icns
if [ ! -f Resources/AppIcon.icns ] || [ app.png -nt Resources/AppIcon.icns ]; then
    echo "==> Generating AppIcon.icns..."
    ICONSET=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z $size $size app.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        double=$((size * 2))
        sips -z $double $double app.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
    rm -rf "$(dirname "$ICONSET")"
fi

echo "==> Building COTP..."
swift build -c release

APP=/tmp/COTP.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/COTP "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp cotp-18x2.png "$APP/Contents/Resources/"

codesign --force --sign - "$APP"

pkill -x COTP 2>/dev/null || true
rm -rf /Applications/COTP.app
mv "$APP" /Applications/
touch /Applications/COTP.app
open /Applications/COTP.app
echo "==> Installed COTP.app"
