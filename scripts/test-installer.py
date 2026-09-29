#!/usr/bin/env python3
"""Exercise postinstall in disposable roots without installing on the host."""
import pathlib
import subprocess
import tempfile

script = pathlib.Path(__file__).resolve().parent.parent / 'packaging/scripts/postinstall'

def setup(root):
    cli = root / 'Library/Application Support/TocaDesk/CLI/mo'
    cli.parent.mkdir(parents=True)
    cli.write_text('#!/bin/bash\nexit 0\n')
    cli.chmod(0o755)

def run(root):
    return subprocess.run(['/bin/bash', str(script), '', '', str(root)], capture_output=True, text=True)

with tempfile.TemporaryDirectory(prefix='tocadesk-installer-test-') as tmp:
    root = pathlib.Path(tmp)
    setup(root)
    assert run(root).returncode == 0
    alias = root / 'usr/local/bin/mo'
    assert alias.is_file() and alias.stat().st_mode & 0o111
    assert 'exec "/Library/Application Support/TocaDesk/CLI/mo" "$@"' in alias.read_text()
    alias.write_text('existing installation\n')
    assert run(root).returncode == 0
    assert alias.read_text() == 'existing installation\n'
    alias.unlink()
    alias.symlink_to('/missing/existing/mole')
    assert run(root).returncode == 0 and alias.is_symlink()
    assert str(alias.readlink()) == '/missing/existing/mole'
    print('PASS: fresh install, reinstall and existing/broken symlink preserved')

with tempfile.TemporaryDirectory(prefix='tocadesk-installer-test-') as tmp:
    root = pathlib.Path(tmp)
    setup(root)
    (root / 'usr').mkdir()
    (root / 'untouched').mkdir()
    (root / 'usr/local').symlink_to(root / 'untouched')
    assert run(root).returncode == 0
    assert not list((root / 'untouched').iterdir())
    print('PASS: redirected directory does not receive privileged writes')

with tempfile.TemporaryDirectory(prefix='tocadesk-installer-test-') as tmp:
    root = pathlib.Path(tmp)
    assert run(root).returncode != 0
    assert not (root / 'usr').exists()
    print('PASS: missing CLI is reported as a failed installation')
