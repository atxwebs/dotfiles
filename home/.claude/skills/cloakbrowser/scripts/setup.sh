#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing CloakBrowser binary ==="
if [ -d "$HOME/.cloakbrowser/chromium-"* ]; then
    echo "Already installed:"
    ls -d "$HOME/.cloakbrowser/chromium-"*
else
    pip install --break-system-packages cloakbrowser
    python3 -m cloakbrowser install
    pip uninstall -y --break-system-packages cloakbrowser
fi

echo ""
echo "=== Installing agent-browser ==="
npm install -g agent-browser 2>/dev/null
agent-browser --version

echo ""
echo "=== Making scripts executable ==="
chmod +x "$SCRIPT_DIR"/*.py "$SCRIPT_DIR"/*.sh

echo ""
echo "Setup complete."
echo "  Crawl:    $SCRIPT_DIR/crawl.py https://example.com"
echo "  DDG:      $SCRIPT_DIR/ddg-search.py 'your query'"
