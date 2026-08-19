#!/bin/sh -eu
# The open pull requests and why each one is not merging.
#
# WHY ONE READER FOR TWO STEPS. Steps 4 (conflict state) and 6 (what failed to
# auto-merge) ask the same REST questions of the same pull requests and would
# otherwise each pay for them, hourly. This resolves them once; each step decides
# what to do with the answer. It is a **pure read**: no merge, no push, no comment.
#
# THE PER-PULL GET IS THE POINT. `GET /repos/{}/pulls` does not carry mergeability
# — `mergeable` and `mergeable_state` exist only on the single-pull endpoint — so a
# reader that used the list alone could not tell a conflicted pull request from a
# healthy one, which is exactly the distinction both steps exist to draw. The
# per-pull reads are bounded by `--limit` (default 10) and the cap is REPORTED, so
# a busy repository is never silently half-read.
#
# GitHub computes mergeability lazily: a pull request it has not yet checked
# answers `mergeable: null`. That is `unknown`, never `clean` — a tick that read
# "not conflicted" out of "not computed yet" would go quiet exactly when a human
# most needs the line.
#
# Usage: pulls-state.sh [--limit <n>] [--root <repo-root>]
# Output: one JSON line
#   {"ok": true, "slug": "...", "limit": n, "total_open": n, "read": n, "truncated": bool,
#    "pulls": [{"number","title","url","branch","draft","mergeable","mergeable_state","blocked_by"}]}
#   {"ok": false, "reason": "gh_unavailable"|"list_failed", "detail": "..."}
#
# `blocked_by` is this script's one judgement, and it is mechanical:
#   conflict         mergeable == false            (the branch and the base disagree)
#   draft            draft == true
#   checks           mergeable_state == unstable
#   review           mergeable_state == blocked    (a required review or check gate)
#   behind           mergeable_state == behind
#   unknown          mergeable == null             (GitHub has not computed it yet)
#   ""               nothing is blocking it

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts"

LIMIT=10

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
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit_err() {
    detail=$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-300)
    printf '{"ok": false, "reason": "%s", "detail": "%s", "pulls": []}\n' "$1" "$detail"
    exit 0
}

command -v gh >/dev/null 2>&1 || emit_err gh_unavailable "gh is not on PATH"

slug=$(sh "${GATHER}/gh-rest.sh" slug 2>&1) || emit_err list_failed "$slug"
[ -n "$slug" ] || emit_err list_failed "no repository slug"

numbers=$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/pulls?state=open&sort=updated&direction=desc&per_page=50" \
    --jq '.[] | (.number|tostring)' 2>&1) || emit_err list_failed "$numbers"

total=0
read_count=0
pulls=''
for n in $numbers; do
    total=$((total + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    row=$(sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/${n}" \
        --jq '[(.number|tostring), .html_url, .head.ref, (.draft|tostring),
               (if .mergeable == null then "null" else (.mergeable|tostring) end),
               (.mergeable_state // ""), .title] | @tsv' 2>/dev/null) || continue
    [ -n "$row" ] || continue
    read_count=$((read_count + 1))
    TAB=$(printf '\t')
    IFS="$TAB" read -r number url branch draft mergeable state title <<EOF
$row
EOF
    blocked=''
    if [ "$mergeable" = "false" ]; then
        blocked=conflict
    elif [ "$draft" = "true" ]; then
        blocked=draft
    elif [ "$mergeable" = "null" ]; then
        blocked=unknown
    else
        case "$state" in
            unstable) blocked=checks ;;
            blocked)  blocked=review ;;
            behind)   blocked=behind ;;
            dirty)    blocked=conflict ;;
            *)        blocked='' ;;
        esac
    fi
    pulls="${pulls:+${pulls}, }{\"number\": ${number}, \"title\": \"$(json_escape "$title")\", \"url\": \"$(json_escape "$url")\", \"branch\": \"$(json_escape "$branch")\", \"draft\": ${draft}, \"mergeable\": \"$(json_escape "$mergeable")\", \"mergeable_state\": \"$(json_escape "$state")\", \"blocked_by\": \"${blocked}\"}"
done

truncated=false
[ "$total" -le "$LIMIT" ] || truncated=true

printf '{"ok": true, "slug": "%s", "limit": %s, "total_open": %s, "read": %s, "truncated": %s, "pulls": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$total" "$read_count" "$truncated" "$pulls"
