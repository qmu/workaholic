#!/bin/sh -eu
# list-stranded-publications.sh — WHICH PUBLICATIONS THE LOOP OPENED AND COULD NOT MERGE, and
# whether the base would still accept them.
#
#   list-stranded-publications.sh [--limit <n>] [--base <branch>]
#
# Output: {"ok": true, "slug": "<owner/name>", "limit": n, "total_open": n, "candidates": n,
#          "read": n, "truncated": bool, "count": n, "headless": n,
#          "publications": [{"number": N, "url": "...", "title": "...", "branch": "work-…",
#                            "created_at": "...", "author": "...",
#                            "mergeability": "clean"|"mechanical"|"content"|"unanswerable",
#                            "mergeability_reason": "",
#                            "mergeability_content_files": [...]}]}
#      or {"ok": false, "reason": "...", "detail": "...", "count": null} — WITH NO
#         `publications` KEY AT ALL.
#   Exit 0 in every case. PURE READ: no ref, no worktree, no index, no file, no merge.
#
# ═══ WHY IT EXISTS (2026-08-31, mission ═══════════════════════════════════════════════
# `repair-a-mechanically-resolvable-conflict-instead-of-reporting-it`). A publish-tree
# publication is NOT A CLAIM: `publish-tree-pr.sh` pushes `publish-main` onto a `work-…` name
# and carries no `Claim …` commit, and the claim scan keys on that commit subject rather than
# on the branch name — its own header says so, deliberately, so a publication is an ordinary
# reviewable branch to everything else. The cost was invisible until it was measured: with no
# claim row there is no `resume_reason`, no `mergeability` row, and no candidate set, so
# `list-catchable-claims.sh` — whose candidates are `report_undelivered` or `queue_drained`
# CLAIMS — can never offer one. A proposal whose auto-merge was refused therefore had no reader
# anywhere in the loop. Measured on a consuming repository: three open proposals colliding on
# `.workaholic/feedbacks/index.md` and on nothing else, the repair mechanical and total, the
# loop filing tickets and reporting the blockage hourly for a day.
#
# ═══ MEMBERSHIP IS DERIVED, NEVER KEYED ON A TITLE ════════════════════════════════════
# Three terms, each read from the tree or the pull request:
#   1. the head branch is a `work-YYYYMMDD-HHMMSS` branch — the one shape the publish seam and
#      the claim protocol both mint, and the one `guard-git-branch.sh` enforces;
#   2. the claim oracle names no claim on it — COMPOSED from `list-claims.sh`, never a second
#      reading of the claim commit. A branch the oracle owns is a claim and is the catch-up's
#      business, not this reader's;
#   2b. the head branch STILL EXISTS on the remote (2026-09-01). GitHub leaves a pull request
#      open when its head branch is deleted, so such a publication can never be merged by
#      anybody and this reader would be offering an act that cannot succeed.
#      `list-headless-pulls.sh` is its reader and asks the operator to close it, under
#      `headless-pull:<number>`; reporting it here as well would ask twice about one pull
#      request, which is the doubling term 3 already exists to prevent.
#   3. the publish seam's own refusal word is EMPTY. A `strategy_touching` or `ruling_touching`
#      publication is open ON PURPOSE — merging it is the operator's ruling and closing it is
#      their refusal — and `list-operator-facing-pulls.sh` is already its reader. Reporting it
#      here would ask two people about one pull request. The boundary is stated here so the
#      acting script inherits it rather than re-deciding it.
# A `[Proposal]` title decides nothing, in either direction: the title-keyed brake in
# `list-open-rulings.sh` is deliberate and local to it, and `list-operator-facing-pulls.sh`
# already records why a reading derives membership from the seam's word instead.
#
# ═══ THE MERGEABILITY IS COMPOSED, VERBATIM ═══════════════════════════════════════════
# `drive/scripts/claim-mergeability.sh` is the one derivation, and its four words, its reason
# and its `content_files` are carried through unchanged. It takes a BRANCH, not a claim, so it
# answers for a publication with no change at all — which is the measurement this mission's
# first ticket recorded. A second derivation here is what the claim protocol refuses by name
# everywhere else, and the two would disagree the first time either moved.
#
# ═══ IT EMITS NO CLAIM VERDICT WORD ═══════════════════════════════════════════════════
# A publication is not a claim: it has no unit, no heartbeat, no holder and no resume verdict,
# and `drive/reference/claims.md` gains no row for one. One vocabulary answering two questions
# is how the two drift.
#
# ═══ A DEGRADED READ CARRIES NO LIST AND A NULL COUNT ═════════════════════════════════
# `ok: false` emits no `publications` key and `count: null`, never an empty array with a zero:
# *nothing is stranded* and *we could not look* are opposite facts, and a consumer that saw the
# same shape for both would go quiet exactly when a person most needs the line.
#
# REST, NOT `gh pr list` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude Code
# Web session may 403 mid-run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts/"
REFUSAL_LIB="${SCRIPT_DIR}/lib/publication-refusal.sh"
AGE_LIB="${SCRIPT_DIR}/lib/publication-age.sh"
LIST_CLAIMS="${SCRIPT_DIR}/../../drive/scripts//list-claims.sh"
MERGEABILITY="${SCRIPT_DIR}/../../drive/scripts//claim-mergeability.sh"

LIMIT="${WORKAHOLIC_STRANDED_PUBLICATION_LIMIT:-10}"
BASE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-10}"; shift 2 ;;
        --base)  BASE="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
case "$LIMIT" in
    ''|*[!0-9]*) LIMIT=10 ;;
esac

json_escape() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r//g'
}

emit_err() {
    detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
    printf '{"ok": false, "reason": "%s", "detail": "%s", "count": null}\n' "$1" "$detail"
    exit 0
}

command -v jq >/dev/null 2>&1 || emit_err "jq_unavailable" "jq is not on PATH"
[ -f "$REFUSAL_LIB" ] || emit_err "no_refusal_rule" "publication-refusal.sh is not present beside the branching skill"
. "$REFUSAL_LIB"
[ -f "$AGE_LIB" ] || emit_err "no_age_rule" "publication-age.sh is not present beside the branching skill"
. "$AGE_LIB"
[ -f "$LIST_CLAIMS" ] || emit_err "no_claim_reader" "list-claims.sh is not present"
[ -f "$MERGEABILITY" ] || emit_err "no_mergeability_reader" "claim-mergeability.sh is not present"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || emit_err "not_a_repository" "run it inside the repository"

# The base the mergeability is measured against, resolved exactly as the reader resolves it.
if [ -z "$BASE" ]; then
    for _sp_b in origin/main origin/master; do
        if git rev-parse --verify --quiet "${_sp_b}^{commit}" >/dev/null 2>&1; then
            BASE="$_sp_b"
            break
        fi
    done
fi
[ -n "$BASE" ] || emit_err "no_base" "no origin/main or origin/master in this clone"

# ── THE CLAIM SET, COMPOSED ONCE ─────────────────────────────────────────────────────
# A shallow scan is degraded for this reader's purposes too: across a graft boundary a claim
# branch is indistinguishable from a publication, so a truncated history would silently promote
# somebody's claim into this list and hand it to an act that must never touch one.
claims_json="$(sh "$LIST_CLAIMS" 2>/dev/null || printf '')"
[ -n "$claims_json" ] || emit_err "claim_scan_unreadable" "list-claims.sh produced nothing"
printf '%s' "$claims_json" | jq -e . >/dev/null 2>&1 \
    || emit_err "claim_scan_unreadable" "list-claims.sh output is not JSON"
case "$claims_json" in
    *'"shallow": true'*) emit_err "shallow_history" "a truncated clone cannot tell a claim branch from a publication" ;;
esac
CLAIM_BRANCHES="$(printf '%s' "$claims_json" | jq -r '.claims[]?.branch // empty' 2>/dev/null || printf '')"

# `available` EXITS 0 EVEN WHEN IT ANSWERS `ok: false`, so the FIELD is what is read — the
# discipline `catch-up-claim.sh` records. Reading the exit status instead would let an
# unreachable transport fall through to the list call and be reported as `list_failed`, which
# names the wrong thing to fix.
sh "${GATHER}/gh-rest.sh" available 2>/dev/null | grep -q '"ok": true' \
    || emit_err "gh_unavailable" "the GitHub transport is not reachable"
slug="$(sh "${GATHER}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$slug"

list="$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/pulls?state=open&sort=updated&direction=desc&per_page=50" \
    --jq '.[] | [(.number|tostring), .html_url, .title, .created_at, (.user.login // ""), (.head.ref // "")] | @tsv' 2>&1)" \
    || emit_err "list_failed" "$list"

TAB="$(printf '\t')"
total=0
candidates=0
read_count=0
count=0
headless=0
pubs=""

while IFS="$TAB" read -r number url title created author head; do
    [ -n "$number" ] || continue
    total=$((total + 1))

    # TERM 1: the branch shape. Cheap, offline, and it drops every pull request that could not
    # be a publication before a single per-pull read is spent on it.
    case "$head" in
        work-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
        *) continue ;;
    esac

    # TERM 2: the claim oracle owns it, or it does not.
    if printf '%s\n' "$CLAIM_BRANCHES" | grep -qx -- "$head" 2>/dev/null; then
        continue
    fi

    # TERM 2b: THE BRANCH STILL EXISTS (2026-09-01, ticket
    # `20260901112558-name-an-open-pull-request-with-no-head-branch.md`). A pull request whose
    # head branch was deleted stays open on GitHub and can never be merged by anybody, so
    # offering it here would ask `settle-stranded-publication.sh` for an act that cannot
    # succeed — and would ask a second person about a pull request
    # `branching/scripts/list-headless-pulls.sh` already names under `headless-pull:<number>`.
    # The remote-tracking refs are exact for this test because `list-claims.sh` above has
    # already run `git fetch --prune`; a stale read can only DROP a publication for one tick,
    # never invent one, and the reading that sends somebody to close something is the REST one.
    if ! git rev-parse --verify --quiet "refs/remotes/origin/${head}^{commit}" >/dev/null 2>&1; then
        headless=$((headless + 1))
        continue
    fi

    # Everything past here costs a per-pull read, so the cap is spent on CANDIDATES rather than
    # on every open pull request — and `truncated` is reported against the candidate count, so
    # a busy repository is never silently half-read.
    candidates=$((candidates + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    read_count=$((read_count + 1))

    # TERM 3: the seam's own refusal word. The adapter is `list-operator-facing-pulls.sh`'s,
    # kept identical on purpose: one rule, two readings of it, and neither restates the other.
    files="$(sh "${GATHER}/gh-rest.sh" api \
        "repos/${slug}/pulls/${number}/files?per_page=100" 2>/dev/null || printf '')"
    [ -n "$files" ] || continue
    printf '%s' "$files" | jq -e . >/dev/null 2>&1 || continue
    stream="$(printf '%s' "$files" | jq -r '
        .[]? |
        ((.status // "") | if . == "added" then "A"
                           elif . == "modified" then "M"
                           elif . == "removed" then "D"
                           elif . == "renamed" then "R"
                           elif . == "copied" then "C"
                           else "?" end) as $st
        | (if ((.patch // "") | test("(^|\n)[+-]feedback:")) then "1" else "0" end) as $moved
        | [$st, .filename, $moved] | @tsv' 2>/dev/null || printf '')"
    word="$(printf '%s\n' "$stream" | publication_refusal_word)"
    [ -z "$word" ] || continue

    mb="$(sh "$MERGEABILITY" "$head" "$BASE" 2>/dev/null || printf '')"
    class="$(printf '%s' "$mb" | sed -n 's/.*"class": "\([^"]*\)".*/\1/p')"
    reason="$(printf '%s' "$mb" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')"
    content_files="$(printf '%s' "$mb" | sed -n 's/.*"content_files": \(\[[^]]*\]\).*/\1/p')"
    # An unreadable reading is `unanswerable` WITH ITS REASON, never `clean`: a wrong `clean`
    # would hand a branch nobody proved to the act, while a wrong `unanswerable` only leaves a
    # publication for the next tick.
    if [ -z "$class" ]; then
        class="unanswerable"
        [ -n "$reason" ] || reason="mergeability_unreadable"
    fi
    [ -n "$content_files" ] || content_files="[]"

    count=$((count + 1))
    pubs="${pubs:+${pubs}, }{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"branch\": \"$(json_escape "$head")\", \"created_at\": \"$(json_escape "$created")\", \"age_hours\": $(publication_age_json "$created"), \"author\": \"$(json_escape "$author")\", \"mergeability\": \"$(json_escape "$class")\", \"mergeability_reason\": \"$(json_escape "$reason")\", \"mergeability_content_files\": ${content_files}}"
done <<EOF
$list
EOF

truncated=false
[ "$candidates" -le "$LIMIT" ] || truncated=true

printf '{"ok": true, "slug": "%s", "limit": %s, "total_open": %s, "candidates": %s, "read": %s, "truncated": %s, "count": %s, "headless": %s, "publications": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$total" "$candidates" "$read_count" "$truncated" "$count" "$headless" "$pubs"
