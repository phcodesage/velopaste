#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
"$PROJECT_DIR/scripts/build.sh"
mkdir -p "$HOME/Applications"
ditto "$PROJECT_DIR/dist/Velopaste.app" "$HOME/Applications/Velopaste.app"
echo "Installed: $HOME/Applications/Velopaste.app"
open "$HOME/Applications/Velopaste.app"
