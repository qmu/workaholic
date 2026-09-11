#!/bin/sh -eu
# persist-log.sh -- carry the tick's FEEDBACK RECORDS to the base. The tick LOG goes nowhere.
#
# Usage:
#   persist-log.sh --tick <YYYYMMDD-HHMMSS> [--root <repo-root>] [--base <branch>]
#                  [--record <path>]...
#
# Output: one JSON line
#   {"persisted": true|false, "status": "filed|ok|skipped|degraded", "reason": "<stable>",
#    "summary": "<one line>", "records": [{"path": "<rel>", "state": "<state>"}],
#    "publication": null | {"branch": "work-…", "pr_url": "<url>", "merged": true|false,
#                           "merge_reason": "<seam's word>"}}
#
# Record states: carried | already_on_base | missing | unreadable | unlanded.
#   carried          the record is on the base: its pull request opened and the seam merged it
#   already_on_base  the base already holds it (immutable; success, not a conflict)
#   unlanded         not on the base -- carries `reason`: the seam's own word (`merge_not_allowed`,
#                    `scan_finding`, `no_gh`, `pr_failed`, `push_failed`, …), or
#                    `publication_open` when an unmerged `work-*` branch already carries the
#                    record, so no second pull request is opened for it
# Stable reasons: persisted | unlanded | no_records | not_a_repo | root_not_repo_root | bad_tick |
#                 log_destination_is_base.
#
# THE RECORDS TRAVEL BEHIND A PULL REQUEST, NEVER AS A DIRECT COMMIT TO THE BASE (2026-09-11,
# issue #1151, the operator's rule verbatim: *runtime cadence logs and unattended maintenance
# records must not update the base branch directly … route durable repository artifacts through
# a claim or publish branch and pull request with the normal checks*). Measured on `origin/main`
# over the last 600 first-parent commits: 17 `Record the tick's feedback findings` commits
# (2026-09-06 to 2026-09-11) landed through `publish-tree-commit.sh`, the direct seam. They now go
# through `publish-tree-pr.sh` under `WORKAHOLIC_AUTO_MERGE=1` with a `[Record]` title: the
# seam opens the pull request and merges it when the release scan passes, so `carried` still
# means *on the base* and a pull request left open is `unlanded` with the seam's reason.
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

PUBLICATION_JSON=null
report() {
    # $1 persisted  $2 status  $3 reason  $4 summary
    printf '{"persisted": %s, "status": "%s", "reason": "%s", "summary": "%s", "records": [%s], "publication": %s}\n' \
        "$1" "$2" "$3" "$(json_escape "$4")" "${RECORDS_JSON:-}" "${PUBLICATION_JSON:-null}"
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

# THE BASE IS AN OUTRIGHT REFUSAL FOR THE LOG, NOT A DEFAULT (ticket `20260902042038`). The log
# branch is retired above and the log now travels nowhere at all -- but the ONE road out of this
# script still leads to the base, and it takes whatever path a caller names. A `--record` naming a
# `.workaholic/moderations/` day file would therefore put the tick log on `main` through the
# publication seam, which is exactly the accumulation the retirement removed: measured on a
# consuming repository, 2026-08-20 to 2026-08-31, hundreds of `Log the * tick` commits, 12 day
# files, roughly 7,000 lines.
#
# KEYED ON THE DESTINATION, NEVER ON MIGRATION STATE. A check that asked whether a repository had
# converged would reproduce the defect on every repository whose migration is incomplete -- which
# is every repository, since there is no migration any more. The path is the whole test.
#
# IT REFUSES THE CALL, WRITES NOTHING, AND EXITS 0. The tick continues and `run.sh` reports the
# refusal by name, because a persist that could not run must read as a named degradation rather
# than as a quiet success.
#
# IT DOES NOT TOUCH `--record`'s ORDINARY BASE WRITE, AND MUST NOT BE WIDENED INTO IT. A feedback
# record is knowledge and belongs on the base by design; only the log is refused here.
# The loop is a `for` over a newline-split list rather than a `read` pipeline on purpose: a
# pipeline's body runs in a subshell, where `report`'s own `exit` would end that subshell and let
# the refused call carry on into the publication.
_oldifs="$IFS"
IFS='
'
for _r in $RECORDS; do
    IFS="$_oldifs"
    [ -n "$_r" ] || continue
    case "$_r" in
        .workaholic/moderations/*|*/.workaholic/moderations/*|.workaholic/moderations)
            report false degraded log_destination_is_base \
                "a record named the tick log (${_r}); the log is git-ignored and goes nowhere, so nothing was written"
            ;;
    esac
    IFS='
'
done
IFS="$_oldifs"

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
            # A RECORD ALREADY ON AN UNMERGED PUBLICATION IS NOT PUBLISHED AGAIN. The pull-request
            # road means a record can sit on a `work-*` branch for a while before it reaches the
            # base, and a second tick naming the same path would open a second pull request for
            # it. The walk is `/specificate`'s own (`lib/unmerged-branches.sh`): git-native, one
            # fetch of the `work-*` heads, over-reading on every ambiguity, which is the safe
            # direction for a dedup.
            (cd "$repo_root" && git fetch --quiet origin '+refs/heads/work-*:refs/remotes/origin/work-*' 2>/dev/null) || true
            UNMERGED_BRANCHES_LABEL=persist-log
            . "${SCRIPT_DIR}/../../specificate/scripts/lib/unmerged-branches.sh"
            (cd "$repo_root" && unmerged_branches_added_paths "origin/${BASE}" .workaholic/feedbacks 2>/dev/null) > "$WORK/on-branch" || : > "$WORK/on-branch"
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
                _open_ref=$(awk -F'\t' -v p="$rel" '$2 == p { print $1; exit }' "$WORK/on-branch" 2>/dev/null || printf '')
                if [ -n "$_open_ref" ]; then
                    RECORDS_JSON="${RECORDS_JSON}${_rsep}$(printf '{"path": "%s", "state": "unlanded", "reason": "publication_open", "branch": "%s"}' "$(json_escape "$rel")" "$(json_escape "${_open_ref#refs/remotes/origin/}")")"
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
                # THE ROAD IS THE PULL-REQUEST SEAM (2026-09-11): `WORKAHOLIC_AUTO_MERGE=1` lets the
                # seam merge behind the release scan, and the `[Record]` title names the class on
                # the pull-request list. The method and the squash body stay the seam's own
                # derivations (`merge-method.sh`, `merge-commit-body.sh`); nothing is spelled here.
                rec_out=$(cd "$repo_root" && WORKAHOLIC_PUBLISH_BASE="$BASE" WORKAHOLIC_AUTO_MERGE=1 \
                    WORKAHOLIC_PR_TITLE="[Record] Feedback findings from tick ${TICK}" \
                    sh "${BRANCHING}/publish-tree-pr.sh" \
                    "Record the tick's feedback findings" \
                    "A finding the moderation tick wrote is staged by create.sh and stops there, so without this publication it is reported filed and never lands." \
                    "The findings this tick filed reach ${BASE} through this pull request, where /specificate's discovery and the attribution walk read them." \
                    "None" \
                    "None" \
                    "Each record named one by one; a record already on the base or on an open publication is left untouched." \
                    $RECORD_PATHS 2>/dev/null || true)
                _pub_ok=$(printf '%s' "$rec_out" | sed -n 's/.*"ok": *\([a-z]*\).*/\1/p')
                _pub_merged=$(printf '%s' "$rec_out" | sed -n 's/.*"merged": *\([a-z]*\).*/\1/p')
                _pub_branch=$(printf '%s' "$rec_out" | sed -n 's/.*"branch": *"\([^"]*\)".*/\1/p')
                _pub_url=$(printf '%s' "$rec_out" | sed -n 's/.*"pr_url": *"\([^"]*\)".*/\1/p')
                if [ "$_pub_ok" = true ]; then
                    _pub_reason=$(printf '%s' "$rec_out" | sed -n 's/.*"merge_reason": *"\([^"]*\)".*/\1/p')
                else
                    _pub_reason=$(printf '%s' "$rec_out" | sed -n 's/.*"reason": *"\([^"]*\)".*/\1/p')
                fi
                [ -n "$_pub_reason" ] || _pub_reason=publish_failed
                [ "$_pub_merged" = true ] || _pub_merged=false
                PUBLICATION_JSON=$(printf '{"branch": "%s", "pr_url": "%s", "merged": %s, "merge_reason": "%s"}' \
                    "$(json_escape "$_pub_branch")" "$(json_escape "$_pub_url")" "$_pub_merged" "$(json_escape "$_pub_reason")")
                if [ "$_pub_ok" != true ] || [ "$_pub_merged" != true ]; then
                    # Not on the base: reported per record rather than as a status of the whole
                    # call, carrying the seam's own word. A pull request left open is `unlanded`
                    # exactly as a refused push was, and the next tick's stranded-publication
                    # act (or a person) lands it; this seam never retries on its own.
                    RECORDS_JSON=$(printf '%s' "$RECORDS_JSON" | sed "s/\"state\": \"carried\"/\"state\": \"unlanded\", \"reason\": \"$(json_escape "$_pub_reason")\"/g")
                fi
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
_unlanded=$(printf '%s' "${RECORDS_JSON:-}" | grep -o '"state": "unlanded"' | wc -l | tr -d ' ')
if [ "$_carried" -eq 0 ] && [ "$_unlanded" -gt 0 ]; then
    # Nothing reached the base: a named degradation, never a quiet success. The records are
    # pushed (or already on an open publication) and are landed by the pull request, not by
    # this seam.
    report false degraded unlanded "${_unlanded} record(s) published behind a pull request and not yet on ${BASE}; the tick log stays in this checkout"
fi
report true filed persisted "${_carried} record(s) carried to ${BASE} behind a merged pull request; the tick log stays in this checkout"
