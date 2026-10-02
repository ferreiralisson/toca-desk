#!/usr/bin/env python3
"""Exercise version selection against disposable repositories, never the project."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

PREPARE = Path(__file__).with_name('prepare-release.py').resolve()

class ReleaseVersionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='tocadesk-version-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Release test')
        self.git('config', 'user.email', 'release@example.invalid')
        (self.root / 'VERSION').write_text('0.1.3\n')
        self.git('add', 'VERSION')
        self.git('commit', '-qm', 'Initial')
        self.git('remote', 'add', 'origin', str(self.root))
        self.git('tag', 'v0.1.9')
        self.git('tag', 'v0.1.10')

    def git(self, *args):
        subprocess.run(['git', '-C', str(self.root), *args], check=True, capture_output=True)

    def prepare(self, version):
        return subprocess.run(['python3', str(PREPARE)], cwd=self.root,
                              env={**os.environ, 'RELEASE_VERSION': version},
                              capture_output=True, text=True)

    def test_automatic_patch_uses_numeric_latest_tag(self):
        self.assertEqual(self.prepare('').returncode, 0)
        self.assertEqual((self.root / 'VERSION').read_text(), '0.1.11\n')

    def test_explicit_minor_version(self):
        self.assertEqual(self.prepare('0.2.0').returncode, 0)
        self.assertEqual((self.root / 'VERSION').read_text(), '0.2.0\n')

    def test_invalid_or_reused_versions_leave_file_unchanged(self):
        for version in ['0.1.10', '0.1.2', 'v0.2.0', '01.2.3', '0.2.0; echo unsafe', '0.2.0-beta']:
            with self.subTest(version=version):
                self.assertNotEqual(self.prepare(version).returncode, 0)
                self.assertEqual((self.root / 'VERSION').read_text(), '0.1.3\n')

    def test_dirty_checkout_is_rejected(self):
        (self.root / 'unfinished.txt').write_text('work in progress')
        self.assertNotEqual(self.prepare('').returncode, 0)
        self.assertEqual((self.root / 'VERSION').read_text(), '0.1.3\n')

if __name__ == '__main__':
    unittest.main()
