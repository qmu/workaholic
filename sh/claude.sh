#!/usr/bin/env bash
# Launch Claude Code with local workaholic plugins for self-development.
# Usage: bash sh/claude.sh [additional claude args...]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

exec claude \
  --plugin-dir "$REPO_DIR/plugins/core" \
  --plugin-dir "$REPO_DIR/plugins/drivin" \
  --plugin-dir "$REPO_DIR/plugins/trippin" \
  "$@"
