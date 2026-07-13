import importlib.util
from pathlib import Path


SCRIPT = Path(__file__).with_name("44_consolidate_credibility_completed_batches.py")


def load_script():
    spec = importlib.util.spec_from_file_location("consolidate_batches", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_parse_args_requires_explicit_run():
    module = load_script()
    args = module.parse_args(["--base-dir", "backup", "--batch-label", "active_batch_017"])
    assert args.run is False
    assert args.batch_label == ["active_batch_017"]


def test_index_unique_rejects_duplicate_pid(tmp_path):
    module = load_script()
    source = tmp_path / "source.jsonl"
    records = [{"pid": "S001"}, {"pid": "S001"}]
    try:
        module.index_unique(records, source)
    except ValueError as exc:
        assert "Duplicate PID S001" in str(exc)
    else:
        raise AssertionError("duplicate PID was accepted")
