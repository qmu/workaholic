#!/bin/sh -eu
# Gather context for spec updates
# Outputs branch info, tickets, existing specs, and diff

set -eu

BASE_BRANCH="${1:-main}"

# Get current branch
BRANCH=$(git branch --show-current)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "=== BRANCH ==="
echo "$BRANCH"
echo ""

# List archived tickets
ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive/${BRANCH}"
echo "=== TICKETS ==="
if [ -d "$ARCHIVE_DIR" ]; then
    ls -1 "$ARCHIVE_DIR"/*.md 2>/dev/null || echo "No archived tickets"
else
    echo "No archived tickets"
fi
echo ""

# List existing specs
echo "=== SPECS ==="
find "${ROOT}/.workaholic/specs" -name "*.md" -type f 2>/dev/null | sort || echo "No specs found"
echo ""

# Get diff against base
echo "=== DIFF ==="
git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null || echo "No diff available"
echo ""

# Get current commit hash
echo "=== COMMIT ==="
git rev-parse --short HEAD
echo ""

# List actual file structure for validation
echo "=== ACTUAL STRUCTURE ==="
echo "agents/"
ls -1 plugins/work/agents/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
echo ""
echo "commands/"
ls -1 plugins/work/commands/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
echo ""
echo "rules/"
ls -1 plugins/work/rules/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || echo "  (none)"
echo ""
echo "skills/"
for skill_dir in plugins/work/skills/*/; do
  skill_name=$(basename "$skill_dir")
  echo "  ${skill_name}/"
  if [ -d "${skill_dir}sh" ]; then
    ls -1 "${skill_dir}sh/"*.sh 2>/dev/null | xargs -I{} basename {} | sed 's/^/    /' || true
  fi
done
