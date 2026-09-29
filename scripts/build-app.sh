#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift scripts/create-icon.swift "$(pwd)/Assets"
iconutil -c icns Assets/TocaDesk.iconset -o Assets/TocaDesk.icns
swift build --build-system native -c release
BIN_DIR="$(swift build --build-system native -c release --show-bin-path)"
APP="$(pwd)/dist/Toca Desk.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
chmod -R u+w "$APP"
cp "$BIN_DIR/TocaDesk" "$APP/Contents/MacOS/TocaDesk"
for resource in "$BIN_DIR"/*.bundle; do
  [ -e "$resource" ] || continue
  cp -R "$resource" "$APP/Contents/Resources/"
done
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Toca Desk</string>
<key>CFBundleDisplayName</key><string>Toca Desk</string>
<key>CFBundleIdentifier</key><string>local.tocadesk.app</string>
<key>CFBundleExecutable</key><string>TocaDesk</string>
<key>CFBundleIconFile</key><string>TocaDesk</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.2</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
cp Assets/TocaDesk.icns "$APP/Contents/Resources/"
cp LICENSE THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/"
cp -R LICENSES "$APP/Contents/Resources/"
codesign --force --deep --sign - "$APP"
echo "Aplicativo criado: $APP"
