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

# RESOLVED ONCE PER TICK, USED TWICE — and now actually so (2026-08-29, ticket
# `20260829092043`). `reference/workflow.md` has said that of step 6 since the reader shipped,
# and the implementation did not hold it: steps 4 and 6 each called this script, so a tick made
# two rounds of `GET /repos/{slug}/pulls/{n}`.
#
# THAT IS A CORRECTNESS DEFECT, NOT MERELY WASTE, because the field the whole reading keys on
# is computed LAZILY: GitHub answers `mergeable: null` until a background merge job finishes,
# and requesting the pull request is what schedules it. So the first resolution can answer
# `unknown` for a branch the second answers `conflict`, and two steps of one tick then state
# different things about the same pull requests with neither wrong about what it read.
# Measured on tick `20260829-085055` (issue #710): `merge-conflicts` reported `none conflicted`
# while `stuck-prs` named four — #622, #625, #633, #688 — over the same open set.
#
# THE CACHE LIVES IN THE ONE READER RATHER THAN IN ITS CALLERS. Both steps stay byte-identical,
# which is what keeps their summaries, their `stuck:<digest>` key and step 4's silence provably
# unchanged; and "resolved once per tick" becomes a property of the reader rather than a
# sentence each caller must remember. `run.sh` resolves once before the step loop and names the
# file in `WORKAHOLIC_TICK_PULLS_STATE` — the seam `WORKAHOLIC_TICK_REPORTS` already
# established. A step run STANDALONE sees no variable and resolves for itself, exactly as before.
#
# THE CACHE IS KEYED ON THE LIMIT IT WAS RESOLVED AT. A caller asking for a wider read than the
# cached one would otherwise be served a silently truncated answer, so a mismatch falls through
# to a fresh resolution rather than being served the wrong bytes.
if [ -n "${WORKAHOLIC_TICK_PULLS_STATE:-}" ] && [ -s "${WORKAHOLIC_TICK_PULLS_STATE}" ]; then
    cached=$(cat "${WORKAHOLIC_TICK_PULLS_STATE}" 2>/dev/null || true)
    case "$cached" in
        *"\"limit\": ${LIMIT},"*)
            printf '%s\n' "$cached"
            exit 0
            ;;
    esac
fi

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
