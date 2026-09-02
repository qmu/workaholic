#!/bin/sh -eu
# persist-log.sh -- carry the tick's FEEDBACK RECORDS to the base. The tick LOG goes nowhere.
#
# Usage:
#   persist-log.sh --tick <YYYYMMDD-HHMMSS> [--root <repo-root>] [--base <branch>]
#                  [--record <path>]...
#
# Output: one JSON line
#   {"persisted": true|false, "status": "filed|ok|skipped|degraded", "reason": "<stable>",
#    "summary": "<one line>", "records": [{"path": "<rel>", "state": "<state>"}]}
#
# Record states: carried | already_on_base | missing | unreadable | unlanded.
# Stable reasons: persisted | no_records | not_a_repo | root_not_repo_root | bad_tick.
#
# ==========================================================================================
# THE LOG BRANCH IS RETIRED AND MUST NOT BE REINTRODUCED (2026-09-03, the developer's
# instruction, in those words: *this strategy is never to be taken again*).
#
# WHAT IT WAS. Between 2026-09-01 and 2026-09-03 this script had a second half that published
# `.workaholic/moderations/<day>.md` to an orphan branch (`workaholic-log`), with
# `hydrate-log.sh` fetching it back at the start of every tick and `ensure-log-ref.sh` creating
# it on first use. That existed for ONE reason: a routine-fired tick ran in a container that was
# discarded, so a log left in the checkout died with it and every dedup answered *no earlier tick
# ever ran*.
#
# WHY IT WAS WRONG, MEASURED. The move traded one mess for another instead of removing it. The
# log had been ~50 commits a day on `main`; on its own branch it became 126 commits nobody ever
# read, three per tick, plus a fetch at the head of every tick and a seed commit pushed by a
# script that could reach any remote it was pointed at -- which is how the hermetic test suite
# came to push to the real origin on 2026-09-03. A branch is still a commit, a push and a ref
# somebody has to look at. The log is an operational file, and an operational file belongs on
# disk.
#
# WHAT IT IS NOW. `.workaholic/moderations/` is git-ignored and STAYS IN THE CHECKOUT. Nothing
# fetches it, nothing pushes it, and no branch is named anywhere. The tick's memory across ticks
# is the checkout itself, which is what the loop has had since 2026-09-02, when it moved onto the
# developer's own server as a session whose working directory persists.
#
# THE COST, STATED. A tick running in a container that is genuinely discarded -- the Web-routine
# fallback -- loses its log with the container, so its dedups re-fire. That is the honest price
# and it is NOT to be paid back by reintroducing a branch, a notes ref, a remote store or any
# other place a commit could land. Fix it, if it ever matters, by not running the tick somewhere
# its state cannot survive.
#
# THE RECORDS TAKE THE OTHER ROAD, AND ALWAYS DID. A feedback record is KNOWLEDGE --
# `/specificate` discovers it, `attributed-work.sh` walks it, a person opens it -- so `--record`
# carries the tick's own records to the base, named one by one. That is this script's whole job
# now, and it is why the name and the call sites did not change.
# ==========================================================================================

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
BRANCHING="${SCRIPT_DIR}/../../branching/scripts"

TICK=''
ROOT='.'
BASE='main'
RECORDS=''

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)     TICK="${2:-}"; shift 2 ;;
        --root)     ROOT="${2:-}"; shift 2 ;;
        --base)     BASE="${2:-}"; shift 2 ;;
        --record)   RECORDS="${RECORDS}${2:-}
"; shift 2 ;;
        *) printf '{"persisted": false, "status": "degraded", "reason": "unknown_argument", "summary": "unknown argument: %s", "records": []}\n' "$1"; exit 1 ;;
    esac
done

case "$TICK" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) printf '{"persisted": false, "status": "degraded", "reason": "bad_tick", "summary": "the tick id is not YYYYMMDD-HHMMSS", "records": []}\n'; exit 1 ;;
esac

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

report() {
    # $1 persisted  $2 status  $3 reason  $4 summary
    printf '{"persisted": %s, "status": "%s", "reason": "%s", "summary": "%s", "records": [%s]}\n' \
        "$1" "$2" "$3" "$(json_escape "$4")" "${RECORDS_JSON:-}"
    exit 0
}

if [ ! -d "$ROOT" ]; then
    report false skipped not_a_repo "the root ${ROOT} does not exist"
fi
root_abs=$(cd -- "$ROOT" && pwd)

# THE PUBLISH TARGET IS THE REPOSITORY THE RECORDS LIVE IN, and nothing else. A `--root` outside
# a git work tree (a drill's throwaway root, a hermetic fixture) is skipped by name rather than
# published into whatever repository the caller's cwd happens to be -- publishing one tree's
# artifacts into another repository's history is the one way this script could do real damage,
# and the retired log branch is exactly how that damage actually happened.
repo_root=$(git -C "$root_abs" rev-parse --show-toplevel 2>/dev/null || printf '')
if [ -z "$repo_root" ]; then
    report false skipped not_a_repo "the root is not inside a git repository, so there is no base to publish to"
fi
if [ "$root_abs" != "$repo_root" ]; then
    report false skipped root_not_repo_root "the root is not the repository root (${root_abs} vs ${repo_root})"
fi

# Scratch for the record list. Outside the repository and the publish tree, so a run that dies
# mid-way leaves neither carrying a stray file.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# THE SEAM (2026-08-23). `create.sh` stages a feedback record and stops, so a record the inbound
# sweep or issue triage wrote never reached the base -- the finding was made, reported as filed,
# and lost. It travels with no `work-*` branch, no claim, no pull request and no merge.
#
# SCOPED TO THE TICK'S OWN RECORDS, NAMED ONE BY ONE (`--record`), never a sweep of whatever
# happens to be staged -- a sweep would let an unrelated file in the container ride an
# unattended commit to the base, which is the one thing this seam must never become.
#
# A RECORD ON THE BASE IS NEVER REWRITTEN. A feedback record is immutable by its own skill's
# rule, so "already there" is success, not a conflict, and two concurrent ticks writing
# different records both land because they touch different files.
#
# A FAILURE IS REPORTED PER RECORD, never as a status of the whole call: the records are
# independent files and one that could not be carried says so by name beside the ones that were.
RECORD_PATHS=''
RECORDS_JSON=''
if [ -n "$RECORDS" ]; then
    _rsep=''
    printf '%s\n' "$RECORDS" | while IFS= read -r _r; do
        [ -n "$_r" ] || continue
        printf '%s\n' "$_r"
    done > "$WORK/records" 2>/dev/null || : > "$WORK/records"

    rec_open=$(cd "$repo_root" && sh "${BRANCHING}/open-publish-tree.sh" "$BASE" 2>/dev/null || true)
    case "$rec_open" in
        *'"ok": true'*)
            rec_path="${repo_root}/.publish"
            while IFS= read -r rel; do
                [ -n "$rel" ] || continue
                src="${root_abs}/${rel}"
                dst="${rec_path}/${rel}"
                if [ ! -f "$src" ]; then
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "missing"}' "$(json_escape "$rel")")"
                    _rsep=', '
                    continue
                fi
                if [ -f "$dst" ]; then
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "already_on_base"}' "$(json_escape "$rel")")"
                    _rsep=', '
                    continue
                fi
                mkdir -p "$(dirname -- "$dst")" 2>/dev/null || true
                if cp "$src" "$dst" 2>/dev/null; then
                    RECORD_PATHS="${RECORD_PATHS} ${rel}"
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "carried"}' "$(json_escape "$rel")")"
                else
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "unreadable"}' "$(json_escape "$rel")")"
                fi
                _rsep=', '
            done < "$WORK/records"

            if [ -n "$RECORD_PATHS" ]; then
                # THE BASE IS AN ENVIRONMENT VARIABLE ON THAT SCRIPT, not an argument, so this
                # publication names its destination explicitly rather than inheriting a default.
                rec_out=$(cd "$repo_root" && WORKAHOLIC_PUBLISH_BASE="$BASE" sh "${BRANCHING}/publish-tree-commit.sh" \
                    "Record the tick's feedback findings" \
                    "A finding the moderation tick wrote is staged by create.sh and stops there, so without this commit it is reported filed and never lands." \
                    "The findings this tick filed are on ${BASE}, where /specificate's discovery and the attribution walk read them." \
                    "None" \
                    "None" \
                    "Each record named one by one; a record already on the base is left untouched." \
                    $RECORD_PATHS 2>/dev/null || true)
                case "$rec_out" in
                    *'"ok": true'*) ;;
                    *)
                        # Reported per record rather than as a status of the whole call.
                        RECORDS_JSON=$(printf '%s' "$RECORDS_JSON" | sed 's/"state": "carried"/"state": "unlanded"/g')
                        ;;
                esac
            fi
            (cd "$repo_root" && sh "${BRANCHING}/close-publish-tree.sh" "$BASE" >/dev/null 2>&1 || true)
            ;;
        *)
            RECORDS_JSON=$(printf '%s' "$RECORDS_JSON")
            while IFS= read -r rel; do
                [ -n "$rel" ] || continue
                RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "unlanded"}' "$(json_escape "$rel")")"
                _rsep=', '
            done < "$WORK/records"
            ;;
    esac
fi


if [ -z "$RECORDS" ]; then
    report false skipped no_records "the tick named no records to carry; its log stays in this checkout, which is where it belongs"
fi

_carried=$(printf '%s' "${RECORDS_JSON:-}" | grep -o '"state": "carried"' | wc -l | tr -d ' ')
report true filed persisted "${_carried} record(s) carried to ${BASE}; the tick log stays in this checkout"
