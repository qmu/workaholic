#!/bin/sh
# Shared push helper for the ship flow. Source this file and call `push_and_report`
# after a commit; it pushes, NEVER fails the caller, and reports what happened.
#
# Why this exists: both ship scripts that push (extract-deferred-concerns.sh,
# commit-release-note.sh) used to end with
#
#     git push >/dev/null 2>&1 || true
#
# and then print `{"status":"ok"}` regardless. The defect was the `2>&1` — it threw away
# the diagnosis, leaving a silent no-op indistinguishable from a success. Measured on the
# ship of PR #86 (2026-07-15): the push did not run (local `main` had no upstream), the
# script reported `status:ok`, and local `main` sat two commits ahead of `origin/main` —
# exactly the divergence extract-deferred-concerns.sh's header says the push prevents.
#
# THIS HELPER never fails the caller; the caller decides what the outcome is worth.
# extract-deferred-concerns.sh keeps it non-fatal (it pushes AFTER the PR has merged,
# where aborting buys nothing) and surfaces `pushed`/`push_error` in its JSON.
# commit-release-note.sh pushes BEFORE the merge and turns any failure except
# no_remote into a hard stop — a note that is not on the remote is a PR about to
# merge without its release note, and pre-merge is when stopping is still cheap.
#
# The failure this guards against in NORMAL use is not a missing upstream: `git clone`
# writes `branch.<name>.remote`, so a fresh clone pushes fine. It is a REJECTED push —
# a non-fast-forward because `origin/main` moved while the ship ran, a protected branch,
# or no network. Those are exactly the cases where a silent divergence costs the most,
# because someone else's commit is already involved.
#
# Sets two variables the caller reads:
#   PUSH_OK    — "true" | "false"
#   PUSH_ERROR — "" when pushed; otherwise a short, non-secret cause token.
#
# PUSH_ERROR is a CLASSIFIED TOKEN, never git's raw stderr. A remote URL can carry a
# credential and this value is printed to stdout and read by /ship, so the raw text must
# not escape. Classify, do not echo.

# Reads: nothing. Writes: PUSH_OK, PUSH_ERROR.
push_and_report() {
    PUSH_OK=false
    PUSH_ERROR=""

    if [ -z "$(git remote 2>/dev/null || true)" ]; then
        PUSH_ERROR="no_remote"
        return 0
    fi

    if ! git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
        PUSH_ERROR="no_upstream"
        return 0
    fi

    _po_out=$(git push 2>&1) && { PUSH_OK=true; return 0; }

    # Classify. Order matters: a rejected push also prints "error", so test the
    # specific causes before the generic fallback.
    case "$_po_out" in
        *'non-fast-forward'*|*'fetch first'*|*'rejected'*) PUSH_ERROR="rejected_non_fast_forward" ;;
        *'protected branch'*|*'pre-receive hook declined'*) PUSH_ERROR="rejected_by_remote" ;;
        *'Could not resolve host'*|*'unable to access'*|*'Connection'*|*'Could not read from remote'*) PUSH_ERROR="network" ;;
        *'Permission denied'*|*'Authentication failed'*|*'access rights'*) PUSH_ERROR="permission_denied" ;;
        *) PUSH_ERROR="push_failed" ;;
    esac
    return 0
}
