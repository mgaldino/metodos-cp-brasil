#!/usr/bin/env python3

import argparse
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).with_name("25_run_credibility_prompt_v3_integral_codex_batch.py")
SPEC = importlib.util.spec_from_file_location("credibility_runner", SCRIPT)
RUNNER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(RUNNER)


class RunMetadataTests(unittest.TestCase):
    def args(self, stem="active_batch_016", model="gpt-5.6-terra", effort="medium"):
        return argparse.Namespace(
            combined_stem=stem,
            model=model,
            model_reasoning_effort=effort,
            service_tier="default",
            codex_bin="codex",
        )

    def test_effective_runtime_prefers_explicit_arguments(self):
        with patch.object(RUNNER, "codex_config", return_value={"model": "fallback"}):
            runtime = RUNNER.effective_runtime(self.args())
        self.assertEqual(runtime["model"], "gpt-5.6-terra")
        self.assertEqual(runtime["model_reasoning_effort"], "medium")
        self.assertEqual(runtime["service_tier"], "default")

    def test_metadata_is_written_and_compatible_resume_is_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = root / "manifest.csv"
            manifest.write_text("pid,input_text_hash,task_packet_file\nP1,h,p\n", encoding="utf-8")
            dirs = {"combined": root / "combined"}
            dirs["combined"].mkdir()
            rows = [{"pid": "P1"}]
            with patch.object(RUNNER, "codex_version", return_value="codex-cli test"):
                first = RUNNER.write_run_metadata(self.args(), manifest, rows, dirs)
                second = RUNNER.write_run_metadata(self.args(), manifest, rows, dirs)
            self.assertEqual(first, second)
            payload = json.loads(first.read_text(encoding="utf-8"))
            self.assertEqual(payload["contract"]["model"], "gpt-5.6-terra")
            self.assertEqual(payload["contract"]["model_reasoning_effort"], "medium")

    def test_metadata_rejects_model_change_on_resume(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = root / "manifest.csv"
            manifest.write_text("pid,input_text_hash,task_packet_file\nP1,h,p\n", encoding="utf-8")
            dirs = {"combined": root / "combined"}
            dirs["combined"].mkdir()
            rows = [{"pid": "P1"}]
            with patch.object(RUNNER, "codex_version", return_value="codex-cli test"):
                RUNNER.write_run_metadata(self.args(), manifest, rows, dirs)
                with self.assertRaisesRegex(ValueError, "refusing to mix"):
                    RUNNER.write_run_metadata(
                        self.args(model="gpt-5.6-sol", effort="medium"), manifest, rows, dirs
                    )

    def test_pid_provenance_must_match_contract(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            dirs = {"provenance": root / "provenance"}
            dirs["provenance"].mkdir()
            contract = {"model": "gpt-5.6-terra", "model_reasoning_effort": "medium"}
            self.assertFalse(RUNNER.provenance_matches("P1", contract, dirs))
            RUNNER.save_pid_provenance("P1", contract, dirs)
            self.assertTrue(RUNNER.provenance_matches("P1", contract, dirs))
            self.assertFalse(
                RUNNER.provenance_matches("P1", {**contract, "model": "gpt-5.6-sol"}, dirs)
            )

    def test_codex_home_is_used_for_config_resolution(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / "config.toml"
            config.write_text('model = "gpt-5.6-terra"\n', encoding="utf-8")
            with patch.dict("os.environ", {"CODEX_HOME": tmp}):
                self.assertEqual(RUNNER.codex_config()["model"], "gpt-5.6-terra")


if __name__ == "__main__":
    unittest.main()
