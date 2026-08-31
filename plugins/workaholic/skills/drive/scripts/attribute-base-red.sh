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
# A COMMIT NOTHING RAN ON IS WALKED PAST, AND ONLY THAT ONE (2026-08-31, mission
# `read-the-base-s-colour-past-a-bookkeeping-tip`). The loop's own bookkeeping commits are
# excluded from every workflow's path filter — correctly — so the tip is very often a commit
# no check ran on, and this walk used to return on ANY unanswerable tip before it began.
# Measured: `base_unreadable:tip_no_checks` every tick for a day while the base was green
# throughout, which is the reading being unreachable exactly where the loop is busiest.
#
# `no_checks` IS A STATEMENT ABOUT THE COMMIT; every other unanswerable reason is a statement
# about US. Nothing ran on a `no_checks` commit, so it was never observed to break anything and
# there is a defined answer one step back — the walk continues, at the tip and inside the walk
# alike, and such a commit is SKIPPED rather than counted green, red or unreadable. A
# `reader_failed`, `rate_limited`, `session_refused`, `checks_pending` or `unparseable_response`
# commit may itself be red, so each stays terminal and emits exactly what it always did.
# `checks_pending` most of all: the base has not finished answering, and walking past it would
# report an older commit's colour as though it were current.
#
# A SKIPPED COMMIT IS NEVER AN ATTRIBUTION. `oldest_red` only ever holds a commit the reader
# answered `red` for, so a walk that skipped its way to a green ancestor with no red in between
# answers `green` — the ancestor's colour — rather than blaming a commit nothing ran on.
#
# THE READER IS UNTOUCHED AND STAYS THREE-VALUED. This changes which reasons the WALK
# continues past, never what a commit's state is; `read-base-checks.sh` remains the one
# derivation and its `reason` vocabulary is what the continuation keys on, read from its JSON.
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
# THE ANSWER SAYS WHERE IT WAS READ (2026-08-31, the same mission's second ticket). Once the
# walk continues past a bookkeeping tip the colour is an ANCESTOR'S, and a reader who is not
# told that reads it as the tip's — "green" and "green at <sha>, two commits behind the tip" are
# different sentences, and the second is the true one. `read_at` names the commit whose reading
# produced the emitted colour and `read_at_distance` how far behind the tip it sits; BOTH ARE
# NULL when the colour was read at the tip itself, so a repository whose tip carries checks sees
# the values it always saw. The distance is STATED, never thresholded: a green ancestor fifteen
# commits back is a weaker statement than one directly behind, and a threshold nobody chose is
# how a reading becomes a verdict — the operator judges.
#
# Usage: attribute-base-red.sh [<tip-ref>]        (default: $WORKAHOLIC_BASE_REF or origin/main)
# Output: one JSON line
#   {"ok": bool, "state": "green|red|unattributable|unanswerable", "tip",
#    "attributed": {"commit", "pull_request", "pull_request_number", "author"}|null,
#    "last_green", "walked", "read_at", "read_at_distance",
#    "bound": {"max_commits": <n>}, "reason"}
#
#   state       `red` means a culprit was named; `unattributable` means the base IS red and
#               no culprit could be named; `unanswerable` means no colour could be read at all
#               — the tip could not be read for our own reasons (`tip_<reason>`), or the walk
#               skipped past commits nothing ran on and ran out of room before reaching one
#               with a reading (`bound_exhausted` / `history_start`, with no red seen).
#   attributed  null unless `state` is `red`. A failed pull-request lookup leaves
#               `pull_request`/`author` unstated and KEEPS the finding — the attribution is
#               still real without a URL.
#   walked      how many commits the reader was called on.
#   read_at     the commit whose reading produced the emitted colour — the newest commit the
#               reader answered `green` or `red` for. `null` when that was the tip, and `null`
#               on `unanswerable`, where no colour was read anywhere.
#   read_at_distance
#               how many commits behind the tip `read_at` sits. `null` exactly when `read_at`
#               is, so the two are read together or not at all.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"
READ_CHECKS="${SCRIPT_DIR}/read-base-checks.sh"

MAX="${WORKAHOLIC_BASE_ATTRIBUTION_MAX:-20}"
case "$MAX" in ''|*[!0-9]*) MAX=20 ;; esac
if [ "$MAX" -lt 1 ]; then MAX=1; fi

TIP_REF="${1:-${WORKAHOLIC_BASE_REF:-origin/main}}"

TIP=""
WALKED=0
LAST_GREEN=""

# WHERE THE COLOUR WAS READ. Set exactly once, at the newest commit the reader answered `green`
# or `red` for; a skipped commit never sets it, because nothing was read there. A distance of 0
# is the tip, which is rendered `null` — the pre-existing shape for a repository whose tip
# carries checks.
READ_AT=""
READ_DISTANCE=0

# $1 state, $2 reason, $3 attributed (JSON object or `null`).
emit() {
    _ok=true
    case "$1" in unanswerable) _ok=false ;; esac
    _read_at=null
    _read_distance=null
    if [ -n "$READ_AT" ] && [ "$READ_DISTANCE" -gt 0 ]; then
        _read_at="\"${READ_AT}\""
        _read_distance="$READ_DISTANCE"
    fi
    printf '{"ok": %s, "state": "%s", "tip": "%s", "attributed": %s, "last_green": "%s", "walked": %s, "read_at": %s, "read_at_distance": %s, "bound": {"max_commits": %s}, "reason": "%s"}\n' \
        "$_ok" "$1" "$TIP" "${3:-null}" "$LAST_GREEN" "$WALKED" \
        "$_read_at" "$_read_distance" "$MAX" "${2:-}"
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
# tip we could not read for OUR OWN reasons is our own degradation and never a finding about
# the repository. A tip nothing ran on is neither — it is a commit with a defined answer one
# step back, so the walk continues past it.
read_commit "$TIP"
WALKED=1
case "$RC_STATE" in
    green|red) READ_AT="$TIP"; READ_DISTANCE=0 ;;
esac
case "$RC_STATE" in
    green) LAST_GREEN="$TIP"; emit green ;;
    unanswerable)
        case "$RC_REASON" in
            no_checks) ;;
            *) emit unanswerable "tip_${RC_REASON}" ;;
        esac
        ;;
esac

# `oldest_red` walks backwards with the loop; when a green commit turns up, whatever it holds
# is the first commit that broke the base. It starts EMPTY unless the tip itself read red, so a
# skipped tip can never be attributed — an empty `oldest_red` at a green commit means the base
# is green, read at that ancestor.
oldest_red=""
case "$RC_STATE" in red) oldest_red="$TIP" ;; esac

for sha in $commits; do
    if [ "$sha" = "$TIP" ]; then continue; fi
    if [ "$WALKED" -ge "$MAX" ]; then break; fi
    WALKED=$((WALKED + 1))
    read_commit "$sha"
    case "$RC_STATE" in
        green|red)
            if [ -z "$READ_AT" ]; then
                READ_AT="$sha"
                READ_DISTANCE=$((WALKED - 1))
            fi
            ;;
    esac
    case "$RC_STATE" in
        green)
            LAST_GREEN="$sha"
            if [ -n "$oldest_red" ]; then
                emit red "" "$(attributed_json "$oldest_red")"
            fi
            emit green
            ;;
        red)
            oldest_red="$sha"
            ;;
        *)
            case "$RC_REASON" in
                # Nothing ran on it, so it was never observed to break anything: skip it and
                # keep walking. It is not green, not red, and not a candidate for attribution.
                no_checks) ;;
                # A commit we could not read may itself be red, so the oldest red we happen to
                # have seen is not provably the first one. Stop rather than guess.
                *) emit unattributable "unanswerable_in_walk:${RC_REASON}" ;;
            esac
            ;;
    esac
done

# The walk ran out of room without reaching a commit that answered green. That is the start of
# history only when the candidate list was shorter than the bound allowed; otherwise the bound
# is what stopped it — and the bound is reported rather than guessed past, which is the whole
# honesty of this walk.
REASON=history_start
if [ "$WALKED" -ge "$MAX" ]; then REASON=bound_exhausted; fi

# WITH A RED IN HAND the base IS red and no culprit could be named; with none, no colour was
# read at all — every commit inspected was skipped — and saying `unattributable` there would
# assert a red nothing observed.
if [ -n "$oldest_red" ]; then emit unattributable "$REASON"; fi
emit unanswerable "$REASON"
