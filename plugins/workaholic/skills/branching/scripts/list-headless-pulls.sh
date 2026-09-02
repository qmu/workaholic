#!/bin/sh -eu
# list-headless-pulls.sh — WHICH OPEN PULL REQUESTS HAVE NO HEAD BRANCH LEFT, and can
# therefore never be merged by anybody.
#
#   list-headless-pulls.sh [--limit <n>]
#
# Output: {"ok": true, "slug": "<owner/name>", "limit": n, "total_open": n, "read": n,
#          "truncated": bool, "count": n, "foreign_head": n,
#          "pulls": [{"number": N, "url": "...", "title": "...", "branch": "...",
#                     "created_at": "...", "age_hours": n|null, "author": "..."}]}
#      or {"ok": false, "reason": "...", "detail": "...", "count": null} — WITH NO
#         `pulls` KEY AT ALL.
#   Exit 0 in every case. PURE READ: no ref, no worktree, no index, no fetch, no merge.
#
# ═══ WHY IT EXISTS (2026-09-01, ticket ═══════════════════════════════════════════════
# `20260901112558-name-an-open-pull-request-with-no-head-branch.md`). GitHub does not close a
# pull request when its head branch is deleted, and such a pull request is UNMERGEABLE BY
# CONSTRUCTION — a fact about the repository, not a judgement. Measured 2026-09-01: `#813`,
# `#799`, `#688`, `#635` and `#625` were open with no branch on the remote; their content was
# already on `main`, verified file by file, and a person closed all five by hand. Nothing in
# the loop read the state, so they sat in the open set inflating every count derived from it —
# `total_open` in both publication readers, the operator's own waiting list, and every
# `/implement` report line that reads them.
#
# ═══ IT IS NOT `list-operator-facing-pulls.sh`, AND THAT READER IS UNTOUCHED ═════════
# That one answers *which open pull requests wait on the OPERATOR'S RULING*, derived from the
# publish seam's own refusal word. A headless pull request waits on nothing and has no refusal
# word: merging it is not a ruling, because merging it is impossible. Two questions, one
# derivation each — which is the rule that reader's own header already states for itself.
#
# ═══ THE REF SET IS ONE REPOSITORY-SCOPED REST LISTING, NEVER THE LOCAL REFS ═════════
# `repos/{slug}/branches` is authoritative and needs no clone state. The tempting alternative —
# `refs/remotes/origin/*` after the claim scan's `git fetch --prune` — is cheaper and WRONG in
# the direction that costs: a clone that never fetched a branch, or a prune that half-ran,
# renders a LIVE pull request headless and asks a person to close work that is still going. The
# reading that sends somebody to close something must be the exact one.
#
# ═══ A HEAD ON ANOTHER REPOSITORY IS NOT A READING WE HAVE ═══════════════════════════
# A pull request opened from a fork carries a `head.ref` that names no branch here, and this
# listing cannot see the fork's refs. Such a pull request is COUNTED (`foreign_head`) and never
# reported headless: *we could not look* must never render as *the branch is gone*.
#
# ═══ A DEGRADED READ CARRIES NO LIST AND A NULL COUNT ════════════════════════════════
# `ok: false` emits no `pulls` key and `count: null`, never an empty array with a zero:
# *nothing is headless* and *we could not look* are opposite facts, and a consumer that saw the
# same shape for both would go quiet exactly when a person most needs the line.
#
# ═══ IT ASKS FOR A CLOSE AND PERFORMS NONE ═══════════════════════════════════════════
# The loop closes nothing. Closing another person's pull request is not a bounded act the way
# a branch delete is — the five measured cases were closed by a person who first verified the
# content was on `main` file by file — and this script's whole output is a reading.
#
# REST, NOT `gh pr list` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude Code
# Web session may 403 mid-run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts"
AGE_LIB="${SCRIPT_DIR}/lib/publication-age.sh"

LIMIT="${WORKAHOLIC_HEADLESS_PULL_LIMIT:-10}"
while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-10}"; shift 2 ;;
        --root)  shift 2 ;;
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
[ -f "$AGE_LIB" ] || emit_err "no_age_rule" "publication-age.sh is not present beside the branching skill"
. "$AGE_LIB"

# `available` EXITS 0 EVEN WHEN IT ANSWERS `ok: false`, so the FIELD is what is read — the
# discipline `list-stranded-publications.sh` records for the same probe.
sh "${GATHER}/gh-rest.sh" available 2>/dev/null | grep -q '"ok": true' \
    || emit_err "gh_unavailable" "the GitHub transport is not reachable"
slug="$(sh "${GATHER}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$slug"

# The endpoint comes FIRST and `--paginate` after it: every stubbed and real caller in this
# plugin reads the endpoint as the first argument after `api`, and a flag in that position is
# how a transport stub silently stops matching.
branches="$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/branches?per_page=100" --paginate --jq '.[].name' 2>&1)" \
    || emit_err "branches_unreadable" "$branches"

list="$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/pulls?state=open&sort=updated&direction=desc&per_page=50" \
    --jq '.[] | [(.number|tostring), .html_url, .title, .created_at, (.user.login // ""), (.head.ref // ""), (.head.repo.full_name // "")] | @tsv' 2>&1)" \
    || emit_err "list_failed" "$list"

TAB="$(printf '\t')"
total=0
read_count=0
foreign=0
count=0
pulls=""

while IFS="$TAB" read -r number url title created author head headrepo; do
    [ -n "$number" ] || continue
    total=$((total + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    read_count=$((read_count + 1))

    [ -n "$head" ] || continue

    # A head on another repository is a ref this listing cannot see. Counted, never reported.
    if [ "$headrepo" != "$slug" ]; then
        foreign=$((foreign + 1))
        continue
    fi

    if printf '%s\n' "$branches" | grep -qx -- "$head" 2>/dev/null; then
        continue
    fi

    count=$((count + 1))
    pulls="${pulls:+${pulls}, }{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"branch\": \"$(json_escape "$head")\", \"created_at\": \"$(json_escape "$created")\", \"age_hours\": $(publication_age_json "$created"), \"author\": \"$(json_escape "$author")\"}"
done <<EOF
$list
EOF

truncated=false
[ "$total" -le "$LIMIT" ] || truncated=true

printf '{"ok": true, "slug": "%s", "limit": %s, "total_open": %s, "read": %s, "truncated": %s, "count": %s, "foreign_head": %s, "pulls": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$total" "$read_count" "$truncated" "$count" "$foreign" "$pulls"
