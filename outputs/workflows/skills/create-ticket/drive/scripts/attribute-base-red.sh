#!/bin/sh -eu
# Which merge turned the base red? The attribution walk — it asks WHICH COMMIT, never WHAT
# STATE, so `read-base-checks.sh` stays the one derivation of a commit's check state.
#
# WHY IT EXISTS (2026-08-27, mission `read-whether-the-base-survived-what-the-loop-merged`).
# A red tip says the base is broken; it does not say what broke it, and the tip is very often
# not the culprit — the loop merges every half hour, so several commits routinely sit between
# the breaking merge and whatever happens to be at the head when somebody looks.
#
# THE WALK. From the base tip, backwards, calling the reader per commit until it answers
# `green`. The attributed commit is the OLDEST commit after that green one that reads `red` —
# the first thing that broke, not the last thing that was pushed.
#
# `unattributable` IS A FIRST-CLASS ANSWER, NEVER THE TIP BY DEFAULT. Blaming the head
# because the walk ran out of room is the failure this outcome exists to prevent. It is
# reached three ways, each named in `reason`:
#
#   bound_exhausted       the walk hit its ceiling without reaching a green commit
#   history_start         the walk reached the start of history without one
#   unanswerable_in_walk  a commit between the tip and the last green could not be read, so
#                         which commit broke it is genuinely unknown — the walk STOPS there
#                         rather than blaming the oldest red it happens to have seen, since
#                         the unreadable commit may itself be red
#
# THE WALK IS BOUNDED AND THE BOUND IS REPORTED. It costs one network read per commit
# inspected, so an unbounded walk over a busy base is a call per commit with no ceiling.
# `WORKAHOLIC_BASE_ATTRIBUTION_MAX` (default 20) is the ceiling; the interesting culprit is
# almost always recent.
#
# IT ASSUMES ONE COMMIT PER PULL REQUEST, which is what a squash-merged base gives and what
# makes this walk tractable here. A repository that merges differently puts several commits
# on the base per pull request, and the walk still works — it just attributes the commit
# rather than the merge, and the pull-request lookup below maps it back. The assumption is
# stated rather than encoded silently.
#
# IT MAKES NO LOCAL FETCH. The caller freshens (`branching/scripts/sync-main.sh` in a driving
# run, a fresh clone in a routine's container) and the tip it walked is reported, so a stale
# ref is visible rather than silently assumed current. Adding a fetch here would put network
# I/O into a script whose only other network reads are the reader's.
#
# NOTHING MAY ACT ON WHAT THIS ANSWERS. It is a judgement about a judgement: the underlying
# red can be falsified by a re-run, so an attribution built on it can be too
# (`drive/reference/claims.md`, *Proofs and judgements*). Report it, ask about it; never
# revert, re-run, gate, hold or merge on it.
#
# Usage: attribute-base-red.sh [<tip-ref>]        (default: $WORKAHOLIC_BASE_REF or origin/main)
# Output: one JSON line
#   {"ok": bool, "state": "green|red|unattributable|unanswerable", "tip",
#    "attributed": {"commit", "pull_request", "pull_request_number", "author"}|null,
#    "last_green", "walked", "bound": {"max_commits": <n>}, "reason"}
#
#   state       `red` means a culprit was named; `unattributable` means the base IS red and
#               no culprit could be named; `unanswerable` means the tip itself could not be
#               read (the reader's own reason rides in `reason`).
#   attributed  null unless `state` is `red`. A failed pull-request lookup leaves
#               `pull_request`/`author` unstated and KEEPS the finding — the attribution is
#               still real without a URL.
#   walked      how many commits the reader was called on.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"
READ_CHECKS="${SCRIPT_DIR}/read-base-checks.sh"

MAX="${WORKAHOLIC_BASE_ATTRIBUTION_MAX:-20}"
case "$MAX" in ''|*[!0-9]*) MAX=20 ;; esac
if [ "$MAX" -lt 1 ]; then MAX=1; fi

TIP_REF="${1:-${WORKAHOLIC_BASE_REF:-origin/main}}"

TIP=""
WALKED=0
LAST_GREEN=""

# $1 state, $2 reason, $3 attributed (JSON object or `null`).
emit() {
    _ok=true
    case "$1" in unanswerable) _ok=false ;; esac
    printf '{"ok": %s, "state": "%s", "tip": "%s", "attributed": %s, "last_green": "%s", "walked": %s, "bound": {"max_commits": %s}, "reason": "%s"}\n' \
        "$_ok" "$1" "$TIP" "${3:-null}" "$LAST_GREEN" "$WALKED" "$MAX" "${2:-}"
    exit 0
}

[ -f "$READ_CHECKS" ] || emit unanswerable no_reader_script
[ -f "$GH_REST" ] || emit unanswerable no_transport_script

TIP=$(git rev-parse --verify "${TIP_REF}^{commit}" 2>/dev/null || true)
[ -n "$TIP" ] || emit unanswerable base_ref_unresolved

# The walk's candidate list, newest first. One extra commit is requested so the walk can tell
# "the bound stopped me" from "history stopped me" without a second git call.
commits=$(git rev-list --max-count=$((MAX + 1)) "$TIP" 2>/dev/null || true)
[ -n "$commits" ] || emit unanswerable no_history

# ONE READER CALL PER COMMIT, and both fields come out of it. Asking twice would double the
# walk's network cost to learn two halves of one answer — and the two calls could disagree,
# since a check run can conclude between them.
RC_STATE=""
RC_REASON=""
read_commit() {
    RC_STATE=unanswerable
    RC_REASON=reader_failed
    _out=$(sh "$READ_CHECKS" "$1" 2>/dev/null || true)
    [ -n "$_out" ] || return 0
    _s=$(printf '%s' "$_out" | jq -r '.state // ""' 2>/dev/null || true)
    case "$_s" in
        green|red|unanswerable) RC_STATE="$_s" ;;
        *) return 0 ;;
    esac
    RC_REASON=$(printf '%s' "$_out" | jq -r '.reason // ""' 2>/dev/null || true)
}

# WHICH PULL REQUEST LANDED THIS COMMIT, and who wrote it. A failed lookup is NOT a failed
# attribution: the coordinates are left unstated and the finding stands, exactly as
# `step-undelivered-units.sh` handles an `unanswerable` pull-request lookup.
attributed_json() {
    _commit="$1"
    _url=""
    _number=null
    _author=""
    _slug=$(sh "$GH_REST" slug 2>/dev/null || true)
    case "$_slug" in
        */*)
            if _body=$(sh "$GH_REST" api "repos/${_slug}/commits/${_commit}/pulls?per_page=10" 2>/dev/null); then
                if printf '%s' "$_body" | jq -e 'type == "array"' >/dev/null 2>&1; then
                    _row=$(printf '%s' "$_body" | jq -c '
                        (   ([.[] | select(.merged_at != null)] | sort_by(.merged_at) | last)
                         // (. | sort_by(.created_at) | last)
                        ) // empty' 2>/dev/null || true)
                    if [ -n "$_row" ]; then
                        _url=$(printf '%s' "$_row" | jq -r '.html_url // ""' 2>/dev/null || printf '')
                        _number=$(printf '%s' "$_row" | jq '.number // null' 2>/dev/null || printf 'null')
                        case "$_number" in '') _number=null ;; esac
                        _author=$(printf '%s' "$_row" | jq -r '.user.login // ""' 2>/dev/null || printf '')
                    fi
                fi
            fi
            ;;
    esac
    printf '{"commit": "%s", "pull_request": "%s", "pull_request_number": %s, "author": "%s"}' \
        "$_commit" "$_url" "$_number" "$_author"
}

# THE TIP DECIDES WHETHER THERE IS ANYTHING TO ATTRIBUTE AT ALL. A green tip is silence; a
# tip we could not read is our own degradation and never a finding about the repository.
read_commit "$TIP"
WALKED=1
case "$RC_STATE" in
    green) LAST_GREEN="$TIP"; emit green ;;
    unanswerable) emit unanswerable "tip_${RC_REASON}" ;;
esac

# From here the tip is red. `oldest_red` walks backwards with the loop; when a green commit
# turns up, whatever `oldest_red` holds is the first commit that broke the base.
oldest_red="$TIP"
for sha in $commits; do
    if [ "$sha" = "$TIP" ]; then continue; fi
    if [ "$WALKED" -ge "$MAX" ]; then emit unattributable bound_exhausted; fi
    WALKED=$((WALKED + 1))
    read_commit "$sha"
    case "$RC_STATE" in
        green)
            LAST_GREEN="$sha"
            emit red "" "$(attributed_json "$oldest_red")"
            ;;
        red)
            oldest_red="$sha"
            ;;
        *)
            # A commit we could not read may itself be red, so the oldest red we happen to
            # have seen is not provably the first one. Stop rather than guess.
            emit unattributable "unanswerable_in_walk:${RC_REASON}"
            ;;
    esac
done

# The loop ran out of commits without a green one. That is the start of history only when the
# candidate list was shorter than the bound allowed; otherwise the bound is what stopped it.
if [ "$WALKED" -ge "$MAX" ]; then emit unattributable bound_exhausted; fi
emit unattributable history_start
