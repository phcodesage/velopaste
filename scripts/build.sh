#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$PROJECT_DIR/dist/Velopaste.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Velopaste" "$APP/Contents/MacOS/Velopaste"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ ! -f Resources/AppIcon.icns ]; then
    swift scripts/make-icon.swift Resources/AppIcon.png
    ICONSET="$PROJECT_DIR/.build/Velopaste.iconset"
    mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        doubled=$((size * 2))
        sips -z "$doubled" "$doubled" Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier app.velopaste --timestamp=none "$APP"
echo "Built: $APP"
