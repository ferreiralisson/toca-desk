#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$(pwd)/dist/Toca Desk.app"
[ -d "$APP" ] || ./scripts/build-app.sh
codesign --verify --deep --strict "$APP"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tocadesk-package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/Toca Desk.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Toca Desk" -srcfolder "$STAGE" -ov -format UDZO "dist/TocaDesk.dmg"
hdiutil verify "dist/TocaDesk.dmg"
