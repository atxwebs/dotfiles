#!/usr/bin/env python3
"""Run all cloakbrowser E2E tests."""
import os
import subprocess
import sys
from pathlib import Path

TEST_DIR = Path(__file__).parent
TESTS = ["test_concurrent.py", "test_crawl_sequential.py", "test_turnstile.py"]
if os.environ.get("CLOAK_STEALTH_TEST", "0") in ("1", "true"):
    TESTS.append("test_stealth.py")

TIMEOUTS = {
    "test_turnstile.py": 300,
    "test_stealth.py": 300,
}


def main():
    failed = []
    for name in TESTS:
        script = TEST_DIR / name
        print(f"\n{'=' * 40}\n>>> {name}\n{'=' * 40}")
        r = subprocess.run(
            [sys.executable, str(script)],
            timeout=TIMEOUTS.get(name, 180),
        )
        if r.returncode != 0:
            failed.append(name)

    print(f"\n{'=' * 40}")
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        sys.exit(1)
    print("ALL TESTS PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
