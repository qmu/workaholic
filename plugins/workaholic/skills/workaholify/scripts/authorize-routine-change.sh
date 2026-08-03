#!/bin/sh -eu
# The gate between a confirmed routine body and an API call. Pure read; it applies
# nothing itself (a shell script cannot reach `RemoteTrigger`) — it decides whether the
# command may.
#
#   authorize-routine-change.sh --plan <plan-file> --digest <confirmed-digest>
#
# Output (one JSON line):
#   {"authorized":true,"action","template","trigger_id",
#    "apply":{"name","trigger","cron_expression","model","enabled","prompt"}}
#   {"authorized":false,"reason":"unreadable_plan"|"noop_plan"|"no_digest"
#                               |"plan_tampered"|"digest_mismatch","detail":"…"}
#
# THE CONFIRMATION BAR IS ENFORCED HERE RATHER THAN DESCRIBED. Two independent checks,
# and they refuse different mistakes:
#
#   plan_tampered   — the plan file no longer hashes to its own digest, so what the
#                     developer read and what is about to be sent are not the same thing.
#   digest_mismatch — the digest echoed back with the confirmation is not this plan's, so
#                     a "yes" given to one routine cannot carry another. This is what makes
#                     the confirmation ONE AT A TIME: a single yes has exactly one digest.
#
# WHAT IT HONESTLY CANNOT DO is prove a human was present — no script run by the agent
# that would be bypassing the human can. It is not sold as that. It closes the
# substitution (confirm this, send that) and the batching (one yes, many routines), which
# are the two failures a standing outward-facing process cannot survive.
#
# A NOOP PLAN IS NEVER AUTHORIZED. `no_drift`, `already_disabled` and their siblings carry
# no digest at all, so "refresh everything" over a clean fleet applies nothing rather than
# rewriting identical values.

set -eu

PLAN=""
DIGEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --digest) DIGEST="${2:-}"; shift 2 ;;
    *) printf '{"authorized": false, "reason": "unknown_argument", "detail": "%s"}\n' "$1" >&2; exit 1 ;;
  esac
done

[ -n "$PLAN" ] || { echo '{"authorized": false, "reason": "no_plan", "detail": "pass --plan <plan-file>"}' >&2; exit 1; }
[ -n "$DIGEST" ] || { echo '{"authorized": false, "reason": "no_digest_given", "detail": "pass --digest <the digest shown with the confirmed body>"}' >&2; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

python3 "${SCRIPT_DIR}/lib/routine_change.py" authorize "$PLAN" "$DIGEST"
