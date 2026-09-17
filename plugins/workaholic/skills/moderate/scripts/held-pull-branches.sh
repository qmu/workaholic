#!/bin/sh -eu
# Read the claim oracle's deliberately person-held pull-request branches once per tick.

if [ -n "${WORKAHOLIC_TICK_HELD_PULLS:-}" ] && [ -s "${WORKAHOLIC_TICK_HELD_PULLS}" ]; then
    cat "${WORKAHOLIC_TICK_HELD_PULLS}"
    exit 0
fi

if [ -z "${WORKAHOLIC_TICK_CLAIMS:-}" ] || [ ! -s "${WORKAHOLIC_TICK_CLAIMS}" ]; then
    printf '{"readable":false,"reason":"no_claim_snapshot","branches":[]}\n'
    exit 0
fi
claims=$(cat "${WORKAHOLIC_TICK_CLAIMS}" 2>/dev/null || true)
printf '%s' "$claims" | jq -e '.claims | type == "array"' >/dev/null 2>&1 \
    || { printf '{"readable":false,"reason":"claims_unreadable","branches":[]}\n'; exit 0; }
printf '%s' "$claims" | jq -c '{readable:true,reason:"",branches:[.claims[] | select(.resume_reason == "awaiting_verification") | .branch] | unique}'
