#!/bin/bash
# Package committed source and exact Swift dependency sources for a release.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
  echo "Commit all release changes before packaging source." >&2
  exit 1
fi
ROOT="$(pwd)"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tocadesk-source.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/TocaDesk-source/dependencies" "$ROOT/dist"
git archive HEAD | tar -xf - -C "$STAGE/TocaDesk-source"
git rev-parse HEAD > "$STAGE/TocaDesk-source/SOURCE-REVISION.txt"
python3 - "$ROOT" "$STAGE/TocaDesk-source" <<'PY'
import json, pathlib, subprocess, sys
root, output = map(pathlib.Path, sys.argv[1:])
for pin in json.loads((root / 'Package.resolved').read_text())['pins']:
    name = pin['identity']
    revision = pin['state']['revision']
    candidates = [p for p in (root / '.build/checkouts').iterdir() if p.name.lower() == name.lower()]
    if len(candidates) != 1:
        raise SystemExit(f'Run swift build first: missing checkout {name}')
    checkout = candidates[0]
    actual = subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != revision:
        raise SystemExit(f'Unexpected dependency revision: {name}')
    target = output / 'dependencies' / name
    target.mkdir()
    archive = subprocess.run(['git', '-C', str(checkout), 'archive', revision], check=True, stdout=subprocess.PIPE).stdout
    subprocess.run(['tar', '-xf', '-', '-C', str(target)], input=archive, check=True)
PY
cat > "$STAGE/TocaDesk-source/BUILDING-SOURCE.md" <<'DOC'
# Corresponding source for Toca Desk

SOURCE-REVISION.txt identifies the exact application repository commit.
README.md documents requirements and the application/installer build commands.
The dependencies/ directory contains the exact Swift dependency source trees,
including their original licenses, at the revisions in Package.resolved.
Swift Package Manager normally fetches those same revisions from their remotes.
The Mole CLI source, build files, license and pinned binary archives are under
vendor/mole; see its README.md and packaging/SOURCE-NOTICE.txt for rebuilding.

Build the application with ./scripts/build-app.sh and the complete Apple Silicon
installer with ./scripts/build-installer.sh. The initial build requires internet
to resolve package dependencies. All generated output is written to dist/.
DOC
COPYFILE_DISABLE=1 tar -czf "$ROOT/dist/TocaDesk-source.tar.gz" -C "$STAGE" TocaDesk-source
echo "Fonte correspondente: $ROOT/dist/TocaDesk-source.tar.gz"
