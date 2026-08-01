#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./bin/tailwindcss -i static/css/input.css -o static/css/app.css --minify
echo "✅ CSS зібрано → static/css/app.css"
