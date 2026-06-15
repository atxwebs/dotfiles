#!/usr/bin/env python3
"""Run all cloakbrowser E2E tests."""
import subprocess
import sys
from pathlib import Path

TEST_DIR = Path(__file__).parent
TESTS = ("test_concurrent.py", "test_crawl_sequential.py", "test_turnstile.py")


def main():
    failed = []
    for name in TESTS:
        script = TEST_DIR / name
        print(f"\n{'=' * 40}\n>>> {name}\n{'=' * 40}")
        r = subprocess.run([sys.executable, str(script)], timeout=300 if name == "test_turnstile.py" else 180)
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
