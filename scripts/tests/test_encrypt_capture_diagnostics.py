#!/usr/bin/env python3
"""Actual public-key encryption of synthetic evidence; never reads a private key."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT/'.github/scripts/encrypt-capture-diagnostics.py'
CERT = ROOT/'.github/scripts/shk-ci-diagnostics.public.pem'
TOKEN = b'SYNTHETIC_PRIVATE_DIAGNOSTIC_DO_NOT_PUBLISH_20261021'


class EncryptedDiagnostics(unittest.TestCase):
    def fixture(self):
        temporary = tempfile.TemporaryDirectory(prefix='shk-public-encryption-fixture-')
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.runtime_root = root
        raw = root/'shk-capture-diagnostics'/'heizkoerpercalc'
        raw.mkdir(parents=True,mode=0o700)
        (raw/'metadata.json').write_text('{"captureExitCode":1}')
        (raw/'failure.png').write_bytes(TOKEN)
        return root, raw, root/'shk-encrypted-diagnostics'/'heizkoerpercalc'/'failure.cms'

    def invoke(self, raw, output, cert=CERT):
        return subprocess.run(['python3',str(HELPER),str(raw),str(output),str(cert)],
                              env=dict(os.environ,RUNNER_TEMP=str(self.runtime_root)),
                              capture_output=True, timeout=15)

    def test_public_cert_encrypts_only_owned_diagnostics_and_removes_raw_after_validation(self):
        root, raw, output = self.fixture()
        result = self.invoke(raw, output)
        self.assertEqual(result.returncode,0,result.stderr.decode())
        self.assertTrue(output.is_file())
        self.assertNotIn(TOKEN,output.read_bytes())
        self.assertFalse(raw.exists())
        self.assertEqual(sorted(p.name for p in output.parent.iterdir()),['failure.cms'])
        check = subprocess.run(['openssl','cms','-cmsout','-inform','DER','-in',str(output),'-noout'],capture_output=True)
        self.assertEqual(check.returncode,0,check.stderr.decode())

    def test_unknown_certificate_fails_closed_without_deleting_raw_or_creating_output(self):
        root, raw, output = self.fixture()
        cert = root/'other.pem'
        cert.write_text('not the pinned public certificate')
        result = self.invoke(raw,output,cert)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('certificate SHA',result.stderr.decode())
        self.assertTrue(raw.exists())
        self.assertFalse(output.exists())

    def test_symlink_never_archives_an_outside_file(self):
        root, raw, output = self.fixture()
        outside = root/'outside.txt'
        outside.write_bytes(TOKEN)
        (raw/'window.txt').symlink_to(outside)
        result = self.invoke(raw,output)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('owned regular file',result.stderr.decode())
        self.assertTrue(outside.exists())
        self.assertTrue(raw.exists())
        self.assertFalse(output.exists())

    def test_unexpected_file_cannot_expand_archive_scope(self):
        _, raw, output = self.fixture()
        (raw/'unrelated.txt').write_bytes(TOKEN)
        result = self.invoke(raw,output)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('unexpected diagnostic entry',result.stderr.decode())
        self.assertTrue(raw.exists())
        self.assertFalse(output.exists())

    def test_owned_but_unexpected_directory_cannot_be_archived_or_deleted(self):
        root, raw, output = self.fixture()
        wrong = root/'outside-scope'
        raw.rename(wrong)
        result = self.invoke(wrong,output)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('owned diagnostic scope',result.stderr.decode())
        self.assertTrue(wrong.exists())
        self.assertFalse(output.exists())

    def test_workflow_uploads_only_ciphertext_not_raw_diagnostics(self):
        workflow=(ROOT/'.github/workflows/android-store-screenshots.yml').read_text()
        self.assertIn('name: Encrypt capture failure diagnostics',workflow)
        section=workflow.split('name: Preserve capture failure diagnostics',1)[1].split('\n  persist:',1)[0]
        self.assertIn('/failure.cms',section)
        self.assertNotIn('path: ${{ runner.temp }}/shk-capture-diagnostics/',section)
        self.assertIn('retention-days: 7',section)


if __name__=='__main__': unittest.main()
