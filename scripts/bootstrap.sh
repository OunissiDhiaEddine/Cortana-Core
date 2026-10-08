#!/usr/bin/env bash
# Generates CortanaCore.xcodeproj from project.yml (the project file is not committed).
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate
echo "Open CortanaCore.xcodeproj"
