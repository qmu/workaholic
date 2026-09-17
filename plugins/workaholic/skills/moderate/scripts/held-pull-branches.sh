#!/bin/sh -eu
# Read the claim oracle's deliberately person-held pull-request branches once per tick.

if [ -n "${WORKAHOLIC_TICK_HELD_PULLS:-}" ] && [ -s "${WORKAHOLIC_TICK_HELD_PULLS}" ]; then
    cat "${WORKAHOLIC_TICK_HELD_PULLS}"
    exit 0
fi

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
LISTER="${SCRIPT_DIR}/../../drive/scripts/list-claims.sh"
[ -f "$LISTER" ] || { printf '{"readable":false,"reason":"no_claim_reader","branches":[]}\n'; exit 0; }
claims=$(sh "$LISTER" 2>/dev/null || true)
printf '%s' "$claims" | jq -e '.claims | type == "array"' >/dev/null 2>&1 \
    || { printf '{"readable":false,"reason":"claims_unreadable","branches":[]}\n'; exit 0; }
printf '%s' "$claims" | jq -c '{readable:true,reason:"",branches:[.claims[] | select(.resume_reason == "awaiting_verification") | .branch] | unique}'
