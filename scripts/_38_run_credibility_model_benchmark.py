"""Import shim for tests of the numbered benchmark runner."""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import sys


_PATH = Path(__file__).with_name("38_run_credibility_model_benchmark.py")
_SPEC = spec_from_file_location("credibility_model_benchmark_runner", _PATH)
if _SPEC is None or _SPEC.loader is None:
    raise ImportError(f"Could not load benchmark runner from {_PATH}")
_MODULE = module_from_spec(_SPEC)
sys.modules[_SPEC.name] = _MODULE
_SPEC.loader.exec_module(_MODULE)

globals().update(
    {
        name: value
        for name, value in vars(_MODULE).items()
        if not name.startswith("__")
    }
)
