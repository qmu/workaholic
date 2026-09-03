#!/bin/sh -eu
# May this pull request be merged, as far as its OWN checks are concerned? The one
# derivation of that gate, composing `read-base-checks.sh` on the pull request's head
# commit and answering `pass` or `refuse` with the refusal's own word.
#
# WHY IT EXISTS (2026-09-03). The loop merged without ever reading the checks on the branch
# it was merging. MEASURED on this repository, 2026-09-03: PR #957 merged at 04:57:39Z while
# its own `Loop Drills` run completed at 05:01:08Z -- three and a half minutes AFTER the
# merge -- and it was red. #960 and #961 merged the same way. `main` then carried a red
# `Loop Drills` from 03:59Z to 08:10Z, four hours, with six further merges landing on it,
# and the workflow that runs on every pull request precisely to catch a drill regression
# gated nothing at all, because nobody waited for it.
#
# WHAT IT DOES NOT CHANGE. `main` is still the continuously auto-merged development branch
# and quality is still gated at the `release/*` QA window (`CLAUDE.md`, *The release tier*).
# This gate is narrower than that argument: it asks only whether the branch BROKE SOMETHING
# ITSELF, which is a question about the unit in hand and not a QA window.
#
# IT REFUSES ON TWO WORDS AND PROCEEDS ON EVERY OTHER DEGRADATION, and that asymmetry is the
# design rather than an oversight:
#   checks_red      -- a completed failure. A reading we DID make; a re-run cannot un-fail it.
#   checks_pending  -- the branch has not finished answering. Merging here is exactly the
#                      measured defect, so waiting is the whole point.
#   anything else   -- no transport, no `gh`, a rate limit, an unparseable body, a commit
#                      nothing has checked. The gate PASSES and names the reading it could
#                      not make. THE COST IS STATED: a repository whose checks this session
#                      cannot read is exactly as ungated as it was before this existed. The
#                      alternative -- refusing on an absence -- parks every unit forever in
#                      any repository with no CI, which is a worse failure than the one this
#                      cures.
#
# A REFUSAL IS NOT A FAILURE. The pull request stays open, the claim stays standing, and the
# next tick's `retry-undelivered.sh` delivers it once the checks conclude -- the machinery
# that already exists for a merge the transport refused. Nothing here re-runs a check, holds
# a claim, closes a pull request or writes anything anywhere.
#
# IT IS RE-DERIVED AT THE MOMENT OF THE ACT by every caller, never cached and never carried
# on an artifact, which is what licenses a bounded act to read a judgement at all
# (`drive/reference/claims.md`, *When a bounded act may read a judgement*).
#
# WORKAHOLIC_MERGE_CHECK_GATE=0 turns it off, answering `pass` with reason `gate_disabled`.
# ABSENT MEANS ON, so a repository that declares nothing is gated.
#
# Usage: branch-checks.sh <pr-number>
# Output: one JSON line, exit 0 in every case including every degradation.
#   {"ok": bool, "pr": N, "head": "<sha>", "gate": "pass"|"refuse", "reason": "",
#    "state": "green|red|unanswerable|unread", "failing": [{"name","conclusion"}]}
#
#   ok      false exactly when the gate could not be derived from a reading (`gate` is then
#           `pass` with an `unreadable:` reason, or `refuse` on one of the two words).
#   reason  "" on a clean pass; `checks_red` / `checks_pending` on a refusal;
#           `unreadable:<read-base-checks reason>` or `gate_disabled` on a degraded pass.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"
READ_CHECKS="${SCRIPT_DIR}/read-base-checks.sh"

PR="${1:-}"

# $1 gate, $2 reason, $3 state, $4 failing (JSON array), $5 head
emit() {
    _ok=true
    case "${2:-}" in ''|checks_red|checks_pending) ;; *) _ok=false ;; esac
    printf '{"ok": %s, "pr": "%s", "head": "%s", "gate": "%s", "reason": "%s", "state": "%s", "failing": %s}\n' \
        "$_ok" "$PR" "${5:-}" "$1" "${2:-}" "${3:-unread}" "${4:-[]}"
    exit 0
}

case "${WORKAHOLIC_MERGE_CHECK_GATE:-1}" in
    0|no|false) emit pass gate_disabled ;;
esac

case "$PR" in
    ''|*[!0-9]*) emit pass unreadable:no_pull_request ;;
esac

[ -f "$GH_REST" ] || emit pass unreadable:no_transport_script
[ -f "$READ_CHECKS" ] || emit pass unreadable:no_reader

slug=$(sh "$GH_REST" slug 2>/dev/null || true)
case "$slug" in
    */*) ;;
    *) emit pass unreadable:slug_unresolved ;;
esac

# One repository-scoped REST read for the head commit; never `gh pr view`, which is
# GraphQL-backed and refusable mid-run (`rules/shell.md`).
pr_body=$(sh "$GH_REST" api "repos/${slug}/pulls/${PR}" 2>/dev/null || true)
head=$(printf '%s' "$pr_body" | jq -r '.head.sha // empty' 2>/dev/null || true)
[ -n "$head" ] || emit pass unreadable:head_unresolved

checks=$(sh "$READ_CHECKS" "$head" 2>/dev/null || true)
state=$(printf '%s' "$checks" | jq -r '.state // empty' 2>/dev/null || true)
reason=$(printf '%s' "$checks" | jq -r '.reason // ""' 2>/dev/null || true)
failing=$(printf '%s' "$checks" | jq -c '.failing // []' 2>/dev/null || printf '[]')
[ -n "$state" ] || emit pass unreadable:reader_unreadable unread "[]" "$head"

case "$state" in
    green) emit pass "" green "[]" "$head" ;;
    red)   emit refuse checks_red red "$failing" "$head" ;;
esac

# Every remaining state is `unanswerable`, and only one of its reasons is a refusal.
case "$reason" in
    checks_pending) emit refuse checks_pending unanswerable "[]" "$head" ;;
esac
emit pass "unreadable:${reason:-unknown}" unanswerable "[]" "$head"
