#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
source scripts/version.sh
if [ "$(uname -m)" != "arm64" ]; then
  echo "O instalador completo requer Apple Silicon: o CLI incluído é darwin-arm64." >&2
  exit 1
fi
# Pin both source and binary archive, independent of the downloaded checksum file.
(cd vendor/mole && shasum -a 256 -c pinned.sha256)
./scripts/build-app.sh
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tocadesk-installer.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
PAYLOAD="$STAGE/payload"
CLI="$PAYLOAD/Library/Application Support/TocaDesk/CLI"
SOURCES="$PAYLOAD/Library/Application Support/TocaDesk/Sources"
mkdir -p "$CLI" "$SOURCES" "$PAYLOAD/Applications" "$STAGE/source" "$STAGE/binaries"
tar -xzf vendor/mole/source-V1.51.0.tar.gz -C "$STAGE/source"
tar -xzf vendor/mole/binaries-darwin-arm64.tar.gz -C "$STAGE/binaries"
UPSTREAM="$STAGE/source/Mole-1.51.0"
cp "$UPSTREAM/mole" "$UPSTREAM/mo" "$UPSTREAM/LICENSE" "$UPSTREAM/README.md" "$CLI/"
ditto "$UPSTREAM/bin" "$CLI/bin"
ditto "$UPSTREAM/lib" "$CLI/lib"
cp "$STAGE/binaries/analyze-darwin-arm64" "$CLI/bin/analyze-go"
cp "$STAGE/binaries/status-darwin-arm64" "$CLI/bin/status-go"
chmod 755 "$CLI/mole" "$CLI/mo" "$CLI/bin/analyze-go" "$CLI/bin/status-go"
# Distribute the corresponding complete, unmodified source and build instructions.
cp vendor/mole/source-V1.51.0.tar.gz vendor/mole/pinned.sha256 "$SOURCES/"
cp packaging/SOURCE-NOTICE.txt "$SOURCES/"
ditto "$ROOT/dist/Toca Desk.app" "$PAYLOAD/Applications/Toca Desk.app"
chmod -R u+w "$PAYLOAD"
# Explicitly disable bundle relocation: always install into /Applications.
pkgbuild --analyze --root "$PAYLOAD" "$STAGE/components.plist"
if ! /usr/libexec/PlistBuddy -c 'Set :0:BundleIsRelocatable false' "$STAGE/components.plist"; then
  /usr/libexec/PlistBuddy -c 'Add :0:BundleIsRelocatable bool false' "$STAGE/components.plist"
fi
pkgbuild --root "$PAYLOAD" --component-plist "$STAGE/components.plist" --scripts packaging/scripts --identifier local.tocadesk.complete --version "$APP_VERSION" --install-location / --ownership recommended "$STAGE/TocaDeskComponents.pkg"
mkdir -p "$STAGE/resources"
cp packaging/resources/* "$STAGE/resources/"
sed "s/@APP_VERSION@/$APP_VERSION/g" packaging/Distribution.xml > "$STAGE/Distribution.xml"
sed "s/@APP_VERSION@/$APP_VERSION/g" packaging/resources/welcome.html > "$STAGE/resources/welcome.html"
productbuild --distribution "$STAGE/Distribution.xml" --resources "$STAGE/resources" --package-path "$STAGE" "$ROOT/dist/TocaDesk-Installer.pkg"
pkgutil --payload-files "$STAGE/TocaDeskComponents.pkg" > "$ROOT/dist/TocaDesk-Installer-files.txt"
shasum -a 256 "$ROOT/dist/TocaDesk-Installer.pkg" > "$ROOT/dist/TocaDesk-Installer.sha256"
echo "Instalador criado: $ROOT/dist/TocaDesk-Installer.pkg"
