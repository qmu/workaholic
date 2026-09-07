#!/bin/sh -eu
# Whether a RUNNING loop subagent is still advancing, or is blocked on something nobody
# will answer.
#
# WHY IT EXISTS (2026-09-06, mission `see-a-frozen-runner-and-give-back-its-slot`).
# `ListAgents` reports `running` for both "executing a tool" and "blocked forever on a
# permission dialog nobody will answer". Measured 2026-09-06 in an unattended `/work` loop:
# `implement-10` made its last tool call at 05:42:49 UTC and was reported `running` by nine
# consecutive `ListAgents` calls until the parent stopped it by hand at 06:21:18 -- 38m29s,
# during which it held a fan-out slot and the loop ran one runner short.
#
# WHAT THE LOCALIZATION ESTABLISHED, and what it ruled OUT. The ticket's instruction was to
# record what a frozen run and a healthy one leave behind over the same window, and to use
# only what MOVES in one and is FLAT in the other. Measured on this repository, 2026-09-06:
#
#   * The claim branch tip / heartbeat -- FLAT IN BOTH, so it is not the evidence. The beat
#     is step 0 of every ticket rather than a cadence (`workaholic:drive` §4), so a run
#     legitimately mid-ticket carries an old tip: record `20260906121540` measured exactly
#     that, and `batch-20260831141002` was resumed at 33 minutes while working. Reading it
#     here would inherit that false positive. It is besides that carried on a REMOTE ref
#     (`heartbeat.sh`), so reading it would cost the network this reader may not spend.
#   * The tick log's `loop-finish-<name>` -- FLAT IN BOTH. It is written when a run is first
#     observed IDLE, so during any run, healthy or frozen, there is nothing to read.
#   * Archived tickets and the pull request -- the first moves once per ticket (the tip's own
#     granularity, flat in both during a long one); the second is a network read.
#   * The claim WORKTREE'S OWN FILES -- MOVES during healthy work and is FLAT during a freeze.
#     Measured in one reading: the worktree of a run that was mid-ticket had a newest mtime
#     101 seconds old, while three worktrees of runs that had stopped read 15, 17 and 18
#     hours. Every edit, every archive and every story write lands there, and a frozen run
#     writes nothing at all.
#
# So the evidence is the newest mtime under `.worktrees/<unit-id>/`, and nothing else.
#
# WHAT IT CANNOT DO, STATED RATHER THAN GUESSED AROUND. Nothing this repository owns is keyed
# by LOOP SUBAGENT NAME: a claim is keyed by unit, a worktree by unit, `loop-finish-<name>` by
# role. So a name cannot in general be bound to the worktree its runner is writing in, and this
# reader REFUSES that binding by name instead of inventing it -- `ambiguous_binding` -- exactly
# where a guess would be wrong. The two exact cases are still exact: every name is `advancing`
# when at least as many worktrees are advancing as there are runners, and every name is
# `not_advancing` when none is and every claim was readable.
#
# `frozen_count` COUNTS THE NAMES THIS READER ACTUALLY ANSWERED `not_advancing`, and nothing
# else. The tempting definition is `running - advancing`, which is sound about how MANY runners
# are stuck while naming none of them -- and a consumer told "one is frozen" while every name
# reads `unreadable` would free a slot on a reading the reader refused to make. An unreadable
# name frees nothing; `running` and `advancing` are reported beside it, so the gap stays visible
# to a reader without being spendable by one.
#
# `started` age is NOT read, and must not come back: it is retired as a cadence source
# (`commands/infinite-development.md` §2) because it measured the previous run's start plus its
# whole duration.
#
# A READING THAT CANNOT BE MADE IS `unreadable:<reason>`, NEVER `not_advancing`. A wrong
# `not_advancing` sends the loop after a runner that is working; the repository's standing rule
# is that a gate which cannot be read is not a gate. In particular, with NO claim worktree on
# disk at all the answer is `no_claim_evidence` and never `not_advancing` -- a runner still in
# its survey has claimed nothing yet and has no worktree to move.
#
# IT STOPS NO AGENT, CHANGES NO ALLOCATION AND MAKES NO NETWORK CALL. It is a pure read; the
# accounting is `commands/infinite-development.md` §2's and the killing is nobody's.
#
# Usage: read-runner-advance.sh [--names <name,name,...>] [repo-root]
#   WORKAHOLIC_RUNNER_ADVANCE_STALE_MINUTES  how long a worktree may be flat before its runner
#                                            is not advancing (default 30). It matches the
#                                            claim heartbeat's own resume window rather than
#                                            inventing a second liveness constant, and it is
#                                            deliberately longer than any read-only stretch a
#                                            healthy run takes between writes.
# Output: one JSON line, ALWAYS exit 0.
#   {"stale_minutes": N, "running": N, "advancing": N, "frozen_count": N,
#    "claims": [{"unit": "...", "verdict": "advancing"|"not_advancing"|"unreadable",
#                "reason": "", "idle_seconds": N|null}],
#    "names":  [{"name": "...", "role": "...", "verdict": "...", "reason": ""}]}
#   {"readable": false, "reason": "<word>", ...nulls}
#
# `readable` IS ABSENT ON A SUCCESSFUL READ -- the `merge_policy` / `status:` convention this
# repository already holds: absent means it completed, so a consumer tests `readable == false`
# and never `readable // true`.

set -eu

names_arg=''
root=''

while [ $# -gt 0 ]; do
    case "$1" in
        --names)
            shift
            names_arg="${1:-}"
            ;;
        --names=*)
            names_arg="${1#--names=}"
            ;;
        -*)
            printf '{"readable": false, "reason": "bad_argument", "stale_minutes": null, "running": null, "advancing": null, "frozen_count": null, "claims": [], "names": []}\n'
            exit 0
            ;;
        *)
            root="$1"
            ;;
    esac
    shift
done

emit_unreadable() {
    printf '{"readable": false, "reason": "%s", "stale_minutes": null, "running": null, "advancing": null, "frozen_count": null, "claims": [], "names": []}\n' "$1"
    exit 0
}

stale_minutes="${WORKAHOLIC_RUNNER_ADVANCE_STALE_MINUTES:-30}"
case "$stale_minutes" in
    ''|*[!0-9]*) emit_unreadable bad_window ;;
    0) emit_unreadable bad_window ;;
esac
window=$((stale_minutes * 60))

if [ -z "$root" ]; then
    root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
[ -d "$root" ] || emit_unreadable no_repo_root

now=$(date -u +%s 2>/dev/null || true)
case "${now:-}" in
    ''|*[!0-9]*) emit_unreadable no_clock ;;
esac

# --- The evidence: one row per claim worktree on disk. -----------------------------------
# `.worktrees/<unit-id>/` is the claim protocol's own path, so enumerating it needs no git
# call and no network read. A worktree with no readable file is `unreadable`, never flat.
worktrees_dir="$root/.worktrees"
claims=''
advancing=0
unreadable_claims=0

if [ -d "$worktrees_dir" ]; then
    for d in "$worktrees_dir"/*/; do
        [ -d "$d" ] || continue
        unit=$(basename "$d")
        newest=$(find "$d" -type f -not -path '*/.git/*' -printf '%T@\n' 2>/dev/null \
            | sort -rn | head -1 | cut -d. -f1)
        case "${newest:-}" in
            ''|*[!0-9]*)
                claims="$claims$(printf '{"unit": "%s", "verdict": "unreadable", "reason": "no_files", "idle_seconds": null}' "$unit")"
                unreadable_claims=$((unreadable_claims + 1))
                continue
                ;;
        esac
        idle=$((now - newest))
        [ "$idle" -lt 0 ] && idle=0
        if [ "$idle" -lt "$window" ]; then
            verdict=advancing
            advancing=$((advancing + 1))
        else
            verdict=not_advancing
        fi
        claims="$claims$(printf '{"unit": "%s", "verdict": "%s", "reason": "", "idle_seconds": %s}' "$unit" "$verdict" "$idle")"
    done
fi

claim_rows=$(printf '%s' "$claims" | jq -s '.' 2>/dev/null) || emit_unreadable claims_unreadable
claim_count=$(printf '%s' "$claim_rows" | jq 'length' 2>/dev/null) || emit_unreadable claims_unreadable

# --- The answer, per running loop name. ---------------------------------------------------
# Only an `implement` name holds a claim and therefore leaves any of the evidence above; every
# other role writes through a publish tree that is closed behind it, so it is refused by name
# rather than assumed healthy.
running=0
names=''

for n in $(printf '%s' "$names_arg" | tr ',' ' '); do
    [ -n "$n" ] || continue
    role="${n%%-*}"
    [ "$role" = implement ] && running=$((running + 1))
done

frozen_count=0

for n in $(printf '%s' "$names_arg" | tr ',' ' '); do
    [ -n "$n" ] || continue
    role="${n%%-*}"
    if [ "$role" != implement ]; then
        verdict=unreadable
        reason=role_holds_no_claim
    elif [ "$claim_count" -eq 0 ]; then
        # No worktree exists to have moved, so nothing here can distinguish a runner still
        # surveying from one that is frozen.
        verdict=unreadable
        reason=no_claim_evidence
    elif [ "$advancing" -ge "$running" ]; then
        verdict=advancing
        reason=''
    elif [ "$advancing" -eq 0 ] && [ "$unreadable_claims" -eq 0 ]; then
        verdict=not_advancing
        reason=''
        frozen_count=$((frozen_count + 1))
    elif [ "$advancing" -eq 0 ]; then
        # Every claim that COULD be read is flat, but at least one could not be read at all,
        # so "none is advancing" is not established.
        verdict=unreadable
        reason=claim_evidence_incomplete
    else
        # Some runner is frozen and the repository owns nothing that says which: a claim is
        # keyed by unit and a worktree by unit, never by loop name. `frozen_count` carries
        # what is soundly known; this name carries the refusal.
        verdict=unreadable
        reason=ambiguous_binding
    fi
    names="$names$(printf '{"name": "%s", "role": "%s", "verdict": "%s", "reason": "%s"}' "$n" "$role" "$verdict" "$reason")"
done

name_rows=$(printf '%s' "$names" | jq -s '.' 2>/dev/null) || emit_unreadable names_unreadable

printf '%s\n%s\n' "$claim_rows" "$name_rows" | jq -s -c \
    --argjson stale "$stale_minutes" \
    --argjson running "$running" \
    --argjson advancing "$advancing" \
    --argjson frozen "$frozen_count" \
    '{stale_minutes: $stale, running: $running, advancing: $advancing,
      frozen_count: $frozen, claims: .[0], names: .[1]}' 2>/dev/null \
    || emit_unreadable render_failed
