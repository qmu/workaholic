#!/bin/sh -eu
# Plan ONE change to ONE routine, and emit the exact content a developer must confirm.
# Pure read: this reaches no API and changes nothing. Applying is the command's act, and
# only after `authorize-routine-change.sh` accepts the digest emitted here.
#
#   plan-routine-change.sh <create|refresh|remove> <template-id> <repo-url> --live <file> [--enable]
#
# Output (one JSON line):
#   {"action","template","repo","name","trigger","cron_expression","model","enabled",
#    "prompt","trigger_id","noop":false,"confirm_digest":"sha256:…"[,"resolves":[...]]
#    [,"manual_deletion_url","removal_means"]}
#   {"action","template","repo","noop":true,"reason":"…","detail":"…"}
#
# ============ WHY A PLAN AND A DIGEST, RATHER THAN JUST DOING IT ============
#
# A routine is a standing, outward-facing process that will act on a repository unattended.
# Bringing one into existence, or re-pointing one, is the developer's act — that is the
# rule both loop runbooks state for cron and the decision of 2026-08-03 generalised beyond
# it (`SKILL.md` §5). The confirmation is therefore **verbatim and one at a time**: the
# developer reads the exact name, trigger, schedule, model and prompt this plan carries.
#
# The digest is what makes that checkable rather than merely instructed. It covers exactly
# the fields a human can verify by eye, so a "yes" to one body cannot authorize a
# different one, and one "yes" cannot cover a batch. What it deliberately does NOT do is
# prove a human was present — no script can — so it is not sold as that. It closes the
# substitution: confirm this, send that.
#
# NOOPS CARRY NO DIGEST. `no_drift`, `already_exists`, `already_disabled`, `not_present`,
# `disabled_routine` and `no_live_input` are all reported reasons with nothing to
# authorize — a refresh of an undrifted routine changes nothing AND SAYS SO, rather than
# sending an update that quietly rewrites the same values.
#
# "REMOVE" MEANS DISABLE. The routines API has no delete at all. Removal is an update
# setting `enabled: false`, reported as such and paired with the fact that deleting the
# entry is a human act at <https://claude.ai/code/routines>. The prompt shown for a
# removal is the LIVE one, not the template's: the developer is switching off what is
# actually there, which may have drifted.

set -eu

ACTION="${1:-}"
TEMPLATE="${2:-}"
REPO="${3:-}"
[ -n "$ACTION" ] && [ -n "$TEMPLATE" ] && [ -n "$REPO" ] || {
  echo '{"noop": true, "reason": "usage", "detail": "plan-routine-change.sh <create|refresh|remove> <template-id> <repo-url> --live <file> [--enable]"}' >&2
  exit 1
}
shift 3

LIVE_FILE=""
ENABLE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --live) LIVE_FILE="${2:-}"; shift 2 ;;
    --enable) ENABLE=1; shift ;;
    *) printf '{"noop": true, "reason": "unknown_argument", "detail": "%s"}\n' "$1" >&2; exit 1 ;;
  esac
done
[ -n "$LIVE_FILE" ] || {
  echo '{"noop": true, "reason": "no_live_file", "detail": "pass --live <file> holding the RemoteTrigger list response"}' >&2
  exit 1
}

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPO_CLEAN=$(printf '%s' "$REPO" | sed -e 's#/$##' -e 's#\.git$##')

python3 "${SCRIPT_DIR}/lib/routine_change.py" plan \
  "$ACTION" "$TEMPLATE" "$REPO_CLEAN" "$LIVE_FILE" "$SCRIPT_DIR" "$ENABLE"
