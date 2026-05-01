"""Assert installed amd-triton matches the pin in the given requirements file."""

import re
import sys
from importlib.metadata import version

import triton

req_path = sys.argv[1]
with open(req_path) as f:
    m = re.search(r"^amd-triton==(\S+)", f.read(), re.M)
if not m:
    sys.exit(f"no amd-triton pin found in {req_path}")
expected = m.group(1)

got = version("amd-triton")
if got != expected:
    sys.exit(f"amd-triton mismatch: expected {expected}, got {got}")
print(f"triton {triton.__version__} amd-triton {got}")
