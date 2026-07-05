#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# serve.sh — Start a local Python HTTP server for the Intervention Report app.
#
# Works on: macOS · Linux · WSL2 · Windows (Git Bash / MSYS2 / Cygwin)
#
# Usage:
#   ./serve.sh              # serves on port 8000, opens browser
#   ./serve.sh 3000         # serves on port 3000, opens browser
#   ./serve.sh --no-browser # serves on port 8000, does not open browser
#
# Press Ctrl+C to stop the server.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Resolve the script's own directory so it works from any cwd.
# On Windows (Git Bash) BASH_SOURCE[0] may look like /c/path or C:/path.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Default port
PORT=8000
OPEN_BROWSER=true

# Parse args
for arg in "$@"; do
    case "$arg" in
        --no-browser) OPEN_BROWSER=false ;;
        -h|--help)
            sed -n '3,11p' "${BASH_SOURCE[0]:-$0}"
            exit 0
            ;;
        *)
            # Numeric → port
            if [[ "$arg" =~ ^[0-9]+$ ]]; then
                PORT="$arg"
            else
                echo "Unknown argument: $arg"
                echo "Usage: $0 [port] [--no-browser]"
                exit 1
            fi
            ;;
    esac
done

# ---- Detect Python ----------------------------------------------------------
PYTHON=""
for cmd in python3 python py; do
    if command -v "$cmd" &>/dev/null; then
        # Verify it can actually run a module (some 'python' on Windows is a stub)
        if "$cmd" -c "import http.server" 2>/dev/null; then
            PYTHON="$cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo "❌ Python is not installed or not on PATH."
    echo "   Install Python 3:  https://www.python.org/downloads/"
    echo "   On WSL2/Ubuntu:    sudo apt install python3"
    echo "   On macOS (brew):   brew install python3"
    exit 1
fi

PY_VERSION="$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo "✓ Using: $PYTHON (Python $PY_VERSION)"

# ---- Check that index.html exists -------------------------------------------
if [ ! -f "$SCRIPT_DIR/index.html" ]; then
    echo "❌ index.html not found in: $SCRIPT_DIR"
    echo "   Make sure serve.sh is in the project root next to index.html."
    exit 1
fi

# ---- Detect the best URL for localhost --------------------------------------
# WSL2: localhost forwarding usually works, but Windows browser can't always
# reach 0.0.0.0 — use 127.0.0.1 which works everywhere.
HOST="127.0.0.1"
URL="http://${HOST}:${PORT}/"

# ---- Open browser -----------------------------------------------------------
open_browser() {
    if [ "$OPEN_BROWSER" = false ]; then
        return
    fi

    # Detect OS / environment
    local uname_s
    uname_s="$(uname -s 2>/dev/null || echo Unknown)"

    case "$uname_s" in
        Darwin)
            # macOS
            open "$URL" 2>/dev/null || true
            ;;
        Linux)
            # Check if we're inside WSL2
            if grep -qi microsoft /proc/version 2>/dev/null; then
                # WSL2 — use powershell to open in the Windows default browser
                powershell.exe -NoProfile -Command "Start-Process '$URL'" 2>/dev/null \
                    || wslview "$URL" 2>/dev/null \
                    || explorer.exe "$URL" 2>/dev/null \
                    || true
            else
                # Native Linux
                xdg-open "$URL" 2>/dev/null || sensible-browser "$URL" 2>/dev/null || true
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash / MSYS2 / Cygwin)
            start "" "$URL" 2>/dev/null || cmd.exe /c start "" "$URL" 2>/dev/null || true
            ;;
        *)
            echo "  (Could not auto-detect browser opener for: $uname_s)"
            echo "  Open this URL manually: $URL"
            ;;
    esac
}

# ---- Start server -----------------------------------------------------------
echo ""
echo "────────────────────────────────────────────────────────"
echo "  Atlas Copco Intervention Report — Local Server"
echo "────────────────────────────────────────────────────────"
echo "  📂  Serving:  $SCRIPT_DIR"
echo "  🌐  URL:      $URL"
echo "  ⏹️   Stop:     Ctrl+C"
echo "────────────────────────────────────────────────────────"
echo ""

# Open browser after a tiny delay (so the server is listening first)
( sleep 1 && open_browser ) &

# Start the server
#   --bind 127.0.0.1  → don't expose to the whole LAN
#   --directory       → serve from the script's directory regardless of cwd
cd "$SCRIPT_DIR"

# Python 3.7+ supports --directory; older versions need cd (already done above)
"$PYTHON" -m http.server "$PORT" --bind "$HOST" 2>/dev/null || \
    "$PYTHON" -m http.server "$PORT" --bind "$HOST"
