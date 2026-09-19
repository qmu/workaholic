#!/bin/sh -eu
# Close ONE source feedback issue, and only on a reconciliation that reads
# `implemented_and_verified`.
#
# WHY IT EXISTS (2026-09-19, ticket `20260919094701`). The issue's closure used to be
# decided at ingest by a `Closes #<N>` keyword on the proposal's pull request -- the act
# that merely QUEUES the work -- and by nothing afterwards. That keyword is gone from the
# ingest seam (the mission's previous ticket), so the issue is now closed by nobody, and
# this is the one act that may close it.
#
# IT ADDS AN ACTOR, NEVER A SECOND READING. `feedback-outcome.sh` stays the one derivation
# of an item's state; this script hands it the caller's facts and spends its verdict. It
# does not re-implement, widen, soften or second-guess any of its words, and it reads
# `delivery-ledger.sh`'s fold through that same reader when a request spans several pull
# requests (the caller passes the folded facts; this script takes one item).
#
# THE FOUR BOUNDS, CITED RATHER THAN RESTATED (`drive/reference/claims.md`, *When a
# bounded act may read a judgement*). An act may proceed on a reading only when it:
#   * RE-DERIVES the reading at the moment of the act -- done here, in the same
#     invocation as the close, never from a verdict a caller carried in;
#   * is IDEMPOTENT -- an issue already closed answers `already_closed` and issues no
#     second request;
#   * is REVERSIBLE -- a person reopens a GitHub issue with one click;
#   * REFUSES EVERY BOUND BY ITS OWN WORD -- every state short of
#     `implemented_and_verified` is reported as that state, with NO request made.
#
# THE SIBLING-SURFACE CASE NEEDS NO RULE OF ITS OWN. *The requested change landed on a
# different surface from the one the person asked about* is `surface_mismatch`, which the
# reader already answers now that the expected surface is persisted on the feedback
# record. It refuses here like any other state. Do not add a second test for it: two
# tests for one question is how the two drift.
#
# AN ABSENCE OF A READING IS NEVER A PROOF. A reader that could not run, or whose output
# cannot be parsed, is `unreadable` and closes nothing -- the rule this repository applies
# to `unanswerable` everywhere else.
#
# IT CLOSES AND DOES NOTHING ELSE. No label, no comment, no reassignment, no reopen, no
# milestone. The finish line the tick already composes is the only other outward act, and
# it belongs to its own seam.
#
#   close-source-issue.sh --input FILE
#
# Input:  {"issue": <number>, "item": {<one feedback-outcome.sh item>}}
# Output: one JSON line
#   {"ok": true, "issue": N, "outcome": "closed"|"already_closed"|"refused"|"unreadable",
#    "state": "<the reconciled state>", "reason": "<word>", "requested": true|false}
#   {"ok": false, "reason": "gh_unavailable"|"slug_unresolved"|"bad_input", ...}
#
# `requested` is the audit the hermetic rows assert on: it is TRUE only for a call that
# actually reached GitHub with a write, so a refusal that "did nothing" is provable
# rather than asserted.
#
# REST ONLY (`rules/shell.md`). `gh issue close` is GraphQL-backed and forbidden; the
# close is `PATCH repos/<slug>/issues/<N>` through `gather/scripts/gh-rest.sh`. The
# outcome is read from the RESPONSE, never from the exit status.
#
# THE BASE-REF GATE DOES NOT APPLY, and that is worth stating rather than leaving to be
# re-asked: it governs commits and pushes (`branching/scripts/lib/base-ref-gate.sh`), and
# this act writes no ref, no file and no commit. It touches GitHub and nothing else.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: close-source-issue.sh --input FILE"
runtime_require_json_file "$2"
INPUT=$2

emit() {
  # $1 outcome, $2 state, $3 reason, $4 requested
  printf '{"ok": true, "issue": %s, "outcome": "%s", "state": "%s", "reason": "%s", "requested": %s}\n' \
    "${ISSUE:-0}" "$1" "$2" "$3" "$4"
  exit 0
}

emit_err() {
  detail=$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-300)
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

ISSUE=$(jq -r '.issue // empty' "$INPUT" 2>/dev/null || printf '')
case "$ISSUE" in
  ''|*[!0-9]*) ISSUE=0; emit_err bad_input "issue must be a positive integer" ;;
esac
jq -e '(.item|type) == "object"' "$INPUT" >/dev/null 2>&1 || emit_err bad_input "item must be an object"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# --- 1. Re-derive the verdict, here, now -------------------------------------------
jq -c '{items: [.item]}' "$INPUT" >"$tmp/facts.json" 2>/dev/null || emit_err bad_input "item unreadable"
outcome=$(sh "$SCRIPT_DIR/feedback-outcome.sh" --input "$tmp/facts.json" 2>/dev/null || printf '')
state=$(printf '%s' "$outcome" | jq -r '.items[0].state // empty' 2>/dev/null || printf '')
[ -n "$state" ] || emit unreadable "" reader_unreadable false

if [ "$state" != implemented_and_verified ]; then
  # The state IS the refusal word. Nothing is renamed and nothing is grouped: a reader
  # sent to `surface_mismatch` and one sent to `still_queued` look at different things.
  emit refused "$state" "$state" false
fi

# --- 2. Only now is the transport touched ------------------------------------------
command -v gh >/dev/null 2>&1 || emit_err gh_unavailable "gh is not on PATH"
slug=$(sh "$GH_REST" slug 2>&1) || emit_err slug_unresolved "$slug"
[ -n "$slug" ] || emit_err slug_unresolved "gh-rest.sh slug returned empty"

current=$(sh "$GH_REST" api "repos/${slug}/issues/${ISSUE}" --jq '.state // ""' 2>/dev/null || printf '')
[ -n "$current" ] || emit unreadable "$state" issue_unreadable false
if [ "$current" = closed ]; then
  emit already_closed "$state" "" false
fi

# --- 3. The close, and its outcome read off the response ----------------------------
after=$(sh "$GH_REST" api "repos/${slug}/issues/${ISSUE}" --method PATCH -f state=closed \
  --jq '.state // ""' 2>/dev/null || printf '')
if [ "$after" = closed ]; then
  emit closed "$state" "" true
fi
emit unreadable "$state" close_unconfirmed true
