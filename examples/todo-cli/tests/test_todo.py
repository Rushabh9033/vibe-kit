"""Tests for todo-cli. Run from examples/todo-cli/ with:

    python -m unittest tests

Each test echoes an AC in its name (vibe-kit convention).
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src" / "todo.py"

# Make `import todo` work when invoked from the repo root.
sys.path.insert(0, str(SRC.parent))


class TodoCliTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env = {**os.environ, "TODO_CLI_STORE": str(Path(self.tmp.name) / "todos.json")}

    def tearDown(self):
        self.tmp.cleanup()

    def _run(self, *args):
        return subprocess.run(
            [sys.executable, str(SRC), *args],
            capture_output=True, text=True, env=self.env,
        )

    def test_AC1_add_creates_todo(self):
        r = self._run("add", "buy milk")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.strip(), "1")
        r = self._run("list")
        self.assertIn("buy milk", r.stdout)

    def test_AC2_list_shows_open_only(self):
        self._run("add", "first")
        self._run("add", "second")
        self._run("done", "1")
        r = self._run("list")
        self.assertNotIn("first", r.stdout)
        self.assertIn("second", r.stdout)

    def test_AC3_done_marks_complete(self):
        self._run("add", "task")
        self._run("done", "1")
        r = self._run("list")
        self.assertEqual(r.stdout.strip(), "")

    def test_AC4_rm_deletes(self):
        self._run("add", "task")
        r = self._run("rm", "1")
        self.assertEqual(r.returncode, 0)
        r = self._run("list")
        self.assertEqual(r.stdout.strip(), "")
        r = self._run("done", "1")
        self.assertEqual(r.returncode, 3)

    def test_AC5_unknown_subcommand(self):
        r = self._run("frobnicate")
        self.assertEqual(r.returncode, 1)
        self.assertIn("usage:", r.stderr)

    def test_AC6_persistence_across_invocations(self):
        self._run("add", "alpha")
        self._run("add", "beta")
        r = self._run("list")
        self.assertIn("alpha", r.stdout)
        self.assertIn("beta", r.stdout)


if __name__ == "__main__":
    unittest.main()
