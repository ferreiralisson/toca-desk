#!/usr/bin/env python3
"""Validate dispatch input before writing files or creating a release commit."""
import os
from pathlib import Path
import re
import subprocess

version = os.environ.get('RELEASE_VERSION', '').strip()
pattern = r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
if version and not re.fullmatch(pattern, version):
    raise SystemExit('Use uma versão X.Y.Z sem v, espaços ou sufixos.')
subprocess.run(['git', 'fetch', 'origin', '--tags'], check=True)
tags = subprocess.check_output(['git', 'tag', '--list'], text=True).splitlines()
versions = [tuple(map(int, tag[1:].split('.'))) for tag in tags
            if tag.startswith('v') and re.fullmatch(pattern, tag[1:])]
versions.append(tuple(map(int, Path('VERSION').read_text().strip().split('.'))))
if not version:
    major, minor, patch = max(versions)
    version = f'{major}.{minor}.{patch + 1}'
if tuple(map(int, version.split('.'))) <= max(versions):
    raise SystemExit('A nova versão deve ser maior que VERSION e todas as tags de versão existentes.')
if subprocess.check_output(['git', 'status', '--porcelain'], text=True).strip():
    raise SystemExit('O checkout precisa estar limpo.')
Path('VERSION').write_text(version + '\n')
