#!/usr/bin/env bash
# Start the Atlas Copco Intervention Report local server on Linux.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec "$SCRIPT_DIR/serve.sh" "$@"
