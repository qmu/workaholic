#!/bin/sh -eu
# Audit a repository's CLAUDE.md against the workaholify documentation standard.
# The standard is deliberately small (and extensible): CLAUDE.md must exist at the
# repo root and must REFER to the workaholify gateway (so the rules load via the
# skill/policies, not by being copied into CLAUDE.md).
#
# Usage: bash audit-claude-md.sh [repo-root]   (default: git toplevel, else .)
# Output: JSON
#   {"file": "...", "conformant": bool,
#    "checks": {"claude_md_present": bool, "refers_workaholify_gateway": bool},
#    "missing": ["<failing check id>", ...]}

set -eu

root="${1:-$(git rev-parse --show-toplevel 2>/dev/null || printf '.')}"
file="${root}/CLAUDE.md"

exists=false
refers=false
if [ -f "$file" ]; then
  exists=true
  if grep -q 'workaholify' "$file" 2>/dev/null; then
    refers=true
  fi
fi

conformant=false
if [ "$exists" = true ] && [ "$refers" = true ]; then
  conformant=true
fi

# Comma-separated JSON list of the failing check ids.
missing=''
[ "$exists" = false ] && missing='"claude_md_present"'
if [ "$refers" = false ]; then
  if [ -n "$missing" ]; then
    missing="${missing},\"refers_workaholify_gateway\""
  else
    missing='"refers_workaholify_gateway"'
  fi
fi

printf '{"file": "%s", "conformant": %s, "checks": {"claude_md_present": %s, "refers_workaholify_gateway": %s}, "missing": [%s]}\n' \
  "$file" "$conformant" "$exists" "$refers" "$missing"
