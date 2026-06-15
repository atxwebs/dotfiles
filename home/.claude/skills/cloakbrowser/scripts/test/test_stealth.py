#!/usr/bin/env python3
"""Stealth tests via our agent-browser CDP stack (not cloakbrowser.launch).

Upstream evaluators from examples/stealth_test.py; page comes from browser_lib.

Run directly:
  python3 test_stealth.py

Included in run_tests.py only when CLOAK_STEALTH_TEST=1 (~2 min, network).
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(__file__))
from test_lib import TestRun, exit_with

from browser_lib import connect_cdp, disconnect_cdp, ensure_daemon


def test_bot_sannysoft(page):
    page.goto("https://bot.sannysoft.com", wait_until="networkidle", timeout=30000)
    time.sleep(3)
    results = page.evaluate("""() => {
        const rows = document.querySelectorAll('table tr');
        const data = {};
        rows.forEach(r => {
            const cells = r.querySelectorAll('td');
            if (cells.length >= 2) {
                const key = cells[0].innerText.trim();
                const cls = cells[1].className || '';
                data[key] = {passed: !cls.includes('failed')};
            }
        });
        return data;
    }""")
    failed = [k for k, v in results.items() if not v["passed"]]
    total = len(results)
    return {"passed": total - len(failed), "total": total, "failed": failed}


def test_bot_incolumitas(page):
    page.goto("https://bot.incolumitas.com", wait_until="networkidle", timeout=30000)
    last_total = 0
    results = {"passed": 0, "failed": 0, "failedTests": [], "total": 0}
    for _ in range(15):
        time.sleep(2)
        results = page.evaluate("""() => {
            const text = document.body.innerText;
            const okMatches = text.match(/"\\w+":\\s*"OK"/g) || [];
            const failMatches = text.match(/"\\w+":\\s*"FAIL"/g) || [];
            const failedTests = failMatches.map(m => m.match(/"(\\w+)"/)[1]);
            return {
                passed: okMatches.length,
                failed: failMatches.length,
                failedTests,
                total: okMatches.length + failMatches.length
            };
        }""")
        if results["total"] >= 30 and results["total"] == last_total:
            break
        last_total = results["total"]
    return results


def test_browserscan(page):
    page.goto("https://www.browserscan.net/bot-detection", wait_until="networkidle", timeout=30000)
    time.sleep(5)
    return page.evaluate("""() => {
        const text = document.body.innerText;
        const normalMatches = text.match(/Normal/g);
        const abnormalMatches = text.match(/Abnormal/g);
        return {
            normal: normalMatches ? normalMatches.length : 0,
            abnormal: abnormalMatches ? abnormalMatches.length : 0,
        };
    }""")


def test_deviceandbrowserinfo(page):
    page.goto("https://deviceandbrowserinfo.com/are_you_a_bot", wait_until="domcontentloaded", timeout=30000)
    time.sleep(8)
    return page.evaluate("""() => {
        const text = document.body.innerText;
        const botMatch = text.match(/"isBot":\\s*(true|false)/);
        const isBot = botMatch ? botMatch[1] === 'true' : null;
        const checks = {};
        const patterns = [
            'isBot', 'hasBotUserAgent', 'hasWebdriverTrue',
            'isHeadlessChrome', 'isAutomatedWithCDP', 'hasSuspiciousWeakSignals',
            'isPlaywright', 'hasInconsistentChromeObject'
        ];
        patterns.forEach(p => {
            const match = text.match(new RegExp('"' + p + '":\\s*(true|false)'));
            if (match) checks[p] = match[1] === 'true';
        });
        return {isBot, checks};
    }""")


def test_fingerprintjs(page):
    page.goto("https://demo.fingerprint.com/web-scraping", wait_until="domcontentloaded", timeout=30000)
    time.sleep(8)
    try:
        page.click("button:has-text('Search')", timeout=5000)
        time.sleep(5)
    except Exception:
        pass
    return page.evaluate("""() => {
        const text = document.body.innerText;
        const hasFlights = text.includes('Price per adult') || text.includes('$');
        const isBlocked = text.includes('request was blocked') || text.includes('bot visit detected');
        return {passed: hasFlights && !isBlocked, isBlocked, hasFlights};
    }""")


def test_recaptcha(page):
    page.goto(
        "https://recaptcha-demo.appspot.com/recaptcha-v3-request-scores.php",
        wait_until="domcontentloaded",
        timeout=30000,
    )
    score = None
    for _ in range(15):
        time.sleep(2)
        score = page.evaluate("""() => {
            const text = document.body.innerText;
            const match = text.match(/"score":\\s*(\\d+\\.\\d+)/);
            return match ? parseFloat(match[1]) : null;
        }""")
        if score is not None:
            break
    return {"score": score}


STEALTH_TESTS = (
    {
        "name": "bot.sannysoft.com",
        "runner": test_bot_sannysoft,
        "pass": lambda r: len(r.get("failed", [])) == 0,
        "verdict": lambda r: f"{r['passed']}/{r['total']} passed"
            + ("" if not r.get("failed") else f" (FAILED: {', '.join(r['failed'])})"),
    },
    {
        "name": "bot.incolumitas.com",
        "runner": test_bot_incolumitas,
        "pass": lambda r: set(r.get("failedTests", [])) <= {"WEBDRIVER", "connectionRTT"},
        "verdict": lambda r: f"{r.get('passed', 0)}/{r.get('total', 0)} passed"
            + (f" (FAILED: {', '.join(r.get('failedTests', []))})" if r.get("failedTests") else " — ALL GREEN"),
    },
    {
        "name": "BrowserScan",
        "runner": test_browserscan,
        "pass": lambda r: r.get("abnormal", 1) == 0,
        "verdict": lambda r: f"Normal: {r.get('normal', 0)}, Abnormal: {r.get('abnormal', 0)}",
    },
    {
        "name": "deviceandbrowserinfo.com",
        "runner": test_deviceandbrowserinfo,
        "pass": lambda r: not r.get("isBot", True),
        "verdict": lambda r: f"isBot: {r.get('isBot', 'unknown')}"
            + (f" checks: {json.dumps(r.get('checks', {}))}" if r.get("checks") else ""),
    },
    {
        "name": "FingerprintJS",
        "runner": test_fingerprintjs,
        "pass": lambda r: r.get("passed", False),
        "verdict": lambda r: (
            "PASSED (flights shown)" if r.get("passed") else
            "BLOCKED" if r.get("isBlocked") else "NO FLIGHTS"
        ),
    },
    {
        "name": "reCAPTCHA v3 (Google)",
        "runner": test_recaptcha,
        "pass": lambda r: (r.get("score") or 0) >= 0.7,
        "verdict": lambda r: f"Score: {r.get('score', 'N/A')}",
        "skip_dns": "recaptcha-demo.appspot.com",
    },
)


def main():
    print("=" * 60)
    print("Stealth tests (agent-browser CDP + browser_lib)")
    print("=" * 60)

    run = TestRun("test_stealth")
    pw = browser = page = None
    try:
        ws_url = ensure_daemon("about:blank")
        pw, browser, _ctx, page = connect_cdp(ws_url, block=False)

        for spec in STEALTH_TESTS:
            name = spec["name"]
            print(f"\n--- {name} ---")
            try:
                result = spec["runner"](page)
                ok = spec["pass"](result)
                verdict = spec["verdict"](result)
                print(f"Result: [{'PASS' if ok else 'FAIL'}] {verdict}")
                if ok:
                    run.ok(f"{name} — {verdict}")
                else:
                    run.fail(f"{name} — {verdict}")
            except Exception as e:
                err = str(e)
                blocked_host = spec.get("skip_dns")
                if blocked_host and ("ERR_NAME_NOT_RESOLVED" in err or "NAME_NOT_RESOLVED" in err):
                    print(f"Skip: DNS blocked ({blocked_host}) — dnscrypt/adblock?")
                    run.skip(f"{name} — DNS blocked for {blocked_host}")
                else:
                    print(f"Error: {e}")
                    run.fail(f"{name} — {e}")
    finally:
        if pw is not None:
            disconnect_cdp(pw, browser, page)

    print()
    return run.finish()


if __name__ == "__main__":
    sys.exit(main())
