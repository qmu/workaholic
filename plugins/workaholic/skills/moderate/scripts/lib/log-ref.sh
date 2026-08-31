#!/bin/sh
# The tick log's ref, defined once — sourced by the publisher and by the one reader.
#
# WHY A LIB FOR ONE STRING (2026-08-31, mission `take-the-moderation-tick-s-log-off-main`).
# Two scripts have to agree about where the log lives: `persist-log.sh` pushes to it and
# `log-read.sh` fetches from it. A string spelled twice is a string that drifts once, and
# the failure would be silent in the worst way — the publisher writing where nothing reads.
# The ruling that chose this ref is `workaholic:moderate`, *Where the log lives, and why it
# is not `main`*; this file is that ruling's one executable copy.
#
# WHY `refs/heads/`. It is the ONLY namespace a routine's container can push to. Measured
# 2026-08-31 in a routine-class container: `refs/moderations/*`, `refs/claims/*` and
# `refs/notes/*` each answered `error: RPC failed; HTTP 403` on create. That is not a
# preference to revisit — a design needing another namespace does not run where this runs.
#
# WHY THIS NAME. It matches neither `work-YYYYMMDD-HHMMSS` nor `release/YYYYMMDD-HHMMSS`,
# the two literal patterns the loop mints, so no reader keyed on those can take it for a
# unit or a release. `list-claims.sh` excludes it by name (its claim-commit filter would
# reject it anyway — that is a backstop, not the rule).
#
# The remote-tracking name is derived, never spelled separately, for the same reason.

# The ref as it exists on the remote.
WORKAHOLIC_LOG_REF='refs/heads/workaholic/moderation-log'

# Where a fetch parks it locally.
WORKAHOLIC_LOG_REMOTE_REF='refs/remotes/origin/workaholic/moderation-log'

# The one path inside the ref's tree. The ref's history is an ORPHAN — it shares no commit
# with the base — so this tree carries the day files and nothing else.
WORKAHOLIC_LOG_DIR_REL='.workaholic/moderations'

# Fetch the log ref into its remote-tracking name. Echoes one word:
#   ok               the ref was fetched and exists
#   absent           origin answered and carries no such ref (a repository whose first
#                    tick has not run — the ordinary state, never a degradation)
#   unreachable      origin is configured and the fetch failed
#   no_origin        no remote is configured (a local-only checkout; nothing is wrong)
#
# `absent` and `unreachable` are deliberately different words. Collapsing them would let a
# failed fetch read as *the log is empty*, and every dedup in the tick would re-fire — the
# one failure the log exists to prevent.
workaholic_log_fetch() {
    _lf_dir=${1:-.}
    if ! git -C "$_lf_dir" remote get-url origin >/dev/null 2>&1; then
        printf 'no_origin'
        return 0
    fi
    if git -C "$_lf_dir" fetch --no-tags --quiet origin \
        "+${WORKAHOLIC_LOG_REF}:${WORKAHOLIC_LOG_REMOTE_REF}" >/dev/null 2>&1; then
        printf 'ok'
        return 0
    fi
    # A fetch of a ref the remote does not have fails the same way one it cannot reach
    # does, so the two are told apart by asking the remote whether the ref is there at
    # all. `ls-remote` is one bounded call and answers exactly that question.
    if git -C "$_lf_dir" ls-remote --exit-code origin "$WORKAHOLIC_LOG_REF" >/dev/null 2>&1; then
        printf 'unreachable'
    else
        # `ls-remote` succeeded in reaching origin and found nothing (exit 2), or could
        # not reach it either. The first is `absent`; the second is `unreachable`.
        if git -C "$_lf_dir" ls-remote origin >/dev/null 2>&1; then
            printf 'absent'
        else
            printf 'unreachable'
        fi
    fi
}
