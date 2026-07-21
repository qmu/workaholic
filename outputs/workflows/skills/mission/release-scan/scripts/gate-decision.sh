#!/bin/sh -eu
# Map a scan-branch-safety.sh verdict (read on stdin) to a ship gate decision,
# so the tier policy is deterministic and testable rather than only prose:
#   - any finding            -> decision "block"
#   - any `hard` finding     -> overridable false (a secret is NEVER bypassable)
#   - only override/confirm  -> overridable true  (/ship may record an override)
#   - no findings            -> decision "pass"
#
# Usage: scan-branch-safety.sh ... | gate-decision.sh
# Output: {"decision": "pass"|"block", "overridable": bool, "hard": N, "total": N}

set -eu

input=$(cat 2>/dev/null || true)

total=$(printf '%s' "$input" | grep -oE '"category":' | grep -c . || true)
hard=$(printf '%s' "$input" | grep -oE '"severity":[ ]*"hard"' | grep -c . || true)

decision=pass
overridable=true
if [ "${total:-0}" -gt 0 ]; then
    decision=block
    if [ "${hard:-0}" -gt 0 ]; then
        overridable=false
    fi
fi

printf '{"decision": "%s", "overridable": %s, "hard": %s, "total": %s}\n' \
    "$decision" "$overridable" "${hard:-0}" "${total:-0}"
