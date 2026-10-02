#!/usr/bin/env python3
"""Check the actual installer payload and corresponding source before publishing."""
from pathlib import Path
import plistlib
import subprocess
import tarfile
import tempfile
import xml.etree.ElementTree as ET

version = Path('VERSION').read_text().strip()
with tempfile.TemporaryDirectory(prefix='tocadesk-release-check-') as tmp:
    expanded = Path(tmp) / 'package'
    subprocess.run(['pkgutil', '--expand-full', 'dist/TocaDesk-Installer.pkg', str(expanded)], check=True)
    apps = list(expanded.rglob('Toca Desk.app'))
    assert len(apps) == 1
    app = apps[0]
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    assert info['CFBundleShortVersionString'] == version
    assert info['CFBundleVersion'] == version
    assert info['CFBundleName'] == 'Toca Desk'
    arch = subprocess.check_output(['lipo', '-archs', str(app / 'Contents/MacOS/TocaDesk')], text=True).strip()
    assert arch == 'arm64', arch
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    package_info = list(expanded.rglob('PackageInfo'))
    assert any(ET.parse(p).getroot().get('version') == version for p in package_info)
    assert (app / 'Contents/Resources/LICENSE').is_file()
    assert list(expanded.rglob('source-V1.51.0.tar.gz'))
with tarfile.open('dist/TocaDesk-source.tar.gz') as archive:
    assert archive.extractfile('TocaDesk-source/VERSION').read().decode().strip() == version
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    assert archive.extractfile('TocaDesk-source/SOURCE-REVISION.txt').read().decode().strip() == revision
print(f'Instalador e fonte da versão {version} verificados.')
