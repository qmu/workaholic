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
# AND THE FIRST READ IS WHAT SCHEDULES THE COMPUTATION (2026-09-01, ticket
# `20260901082631`). The lazy field is not merely *sometimes* uncomputed: requesting
# the pull request is the request that STARTS the background merge job, so the tick's
# own first per-pull read is systematically the one most likely to answer `null`. With
# nothing looking again, a *not yet* became an hourly finding, a `stuck-prs` reminder
# and eventually a question against a person's daily budget. Measured (issue #838):
# `stuck-prs` reported `403:unknown 407:unknown 409:unknown 430:unknown` hour after
# hour, and reading each pull request by hand settled all four on the first try —
# because the hand read was the SECOND read.
#
# SO THE SECOND LOOK LIVES HERE, IN THE ONE READER, and not in either step. Both
# consuming steps compose this script, so both inherit the settled answer and neither
# gains a network call of its own — which is the whole reason the per-tick cache was
# put here rather than in the callers (see the cache's own note below). A step-level
# re-read would give `stuck-prs` and `merge-conflicts` a call each and re-open exactly
# the drift that cache exists to close.
#
# IT IS BOUNDED, AND THE BOUND IS NAMED. A repository with fifty open pull requests
# must not turn an hourly tick into a poller, so the second look is ONE re-read after
# ONE short wait — never a retry loop — capped by how many rows
# (`WORKAHOLIC_PULLS_STATE_REREAD_MAX`, default 5) and by how long in total
# (`WORKAHOLIC_PULLS_STATE_REREAD_BUDGET_SECONDS`, default 10). Rows past either cap
# keep the answer they had. A row that stays `null` after the second look is STILL
# `unknown`: the vocabulary does not move, because that is still the honest word for a
# row GitHub has not computed, and `merge-conflicts`'s `uncomputed` count still
# distinguishes *could not look* from *looked and found nothing*.
#
# AND THE SPEND IS REPORTED. `reread_attempted` / `reread_settled` / `reread_capped`
# say how many rows got the second look and how many it settled, so a tick that spent
# the budget and learned nothing says so rather than looking like a tick that never
# tried.
#
# Usage: pulls-state.sh [--limit <n>] [--root <repo-root>]
# Env:   WORKAHOLIC_PULLS_STATE_REREAD_MAX (default 5) — rows the second look may re-read
#        WORKAHOLIC_PULLS_STATE_REREAD_WAIT (default 2) — seconds to wait once, before it
#        WORKAHOLIC_PULLS_STATE_REREAD_BUDGET_SECONDS (default 10) — total seconds it may take
# Output: one JSON line
#   {"ok": true, "slug": "...", "limit": n, "total_open": n, "read": n, "truncated": bool,
#    "reread_attempted": n, "reread_settled": n, "reread_capped": bool,
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

# THE CAPS ARE COST CONTROLS, NOT GATES, so a non-numeric or empty value falls back to
# the default rather than failing the read — `condition-age.sh`'s own rule for its walk
# bound. A `0` is a legitimate value at every one of them: it turns the second look off.
REREAD_MAX="${WORKAHOLIC_PULLS_STATE_REREAD_MAX:-5}"
REREAD_WAIT="${WORKAHOLIC_PULLS_STATE_REREAD_WAIT:-2}"
REREAD_BUDGET="${WORKAHOLIC_PULLS_STATE_REREAD_BUDGET_SECONDS:-10}"
case "$REREAD_MAX" in ''|*[!0-9]*) REREAD_MAX=5 ;; esac
case "$REREAD_WAIT" in ''|*[!0-9]*) REREAD_WAIT=2 ;; esac
case "$REREAD_BUDGET" in ''|*[!0-9]*) REREAD_BUDGET=10 ;; esac

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

TAB=$(printf '\t')

# ONE PULL REQUEST, ONE ROW OF TSV — the shape both passes speak, so the second look
# rewrites an answer rather than re-deriving a classification. `gh`'s own `@tsv` escapes
# any tab or newline inside a title, so splitting on the tab is safe by construction.
read_pull() {
    sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/$1" \
        --jq '[(.number|tostring), .html_url, .head.ref, (.draft|tostring),
               (if .mergeable == null then "null" else (.mergeable|tostring) end),
               (.mergeable_state // ""), .title] | @tsv' 2>/dev/null
}

total=0
read_count=0
rows=''
for n in $numbers; do
    total=$((total + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    row=$(read_pull "$n") || continue
    [ -n "$row" ] || continue
    read_count=$((read_count + 1))
    rows="${rows}${row}
"
done

# THE SECOND LOOK. One short wait, then at most `REREAD_MAX` re-reads inside
# `REREAD_BUDGET` seconds, over the rows that answered `null` — never a retry loop, and
# never a row that already has an answer. A row past either cap keeps what it had, and
# `reread_capped` says the budget, not the transport, is why.
reread_attempted=0
reread_settled=0
reread_capped=false
uncomputed=$(printf '%s' "$rows" | awk -F"$TAB" 'NF && $5 == "null"' | wc -l | tr -d ' ')
if [ "${uncomputed:-0}" -gt 0 ] && [ "$REREAD_MAX" -gt 0 ] && [ "$REREAD_BUDGET" -gt 0 ]; then
    [ "$REREAD_WAIT" -eq 0 ] || sleep "$REREAD_WAIT"
    started=$(date +%s 2>/dev/null || echo 0)
    settled_rows=''
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        mergeable=$(printf '%s' "$row" | cut -d"$TAB" -f5)
        if [ "$mergeable" = "null" ]; then
            now=$(date +%s 2>/dev/null || echo 0)
            if [ "$reread_attempted" -ge "$REREAD_MAX" ] \
                || [ $((now - started)) -ge "$REREAD_BUDGET" ]; then
                reread_capped=true
            else
                reread_attempted=$((reread_attempted + 1))
                number=$(printf '%s' "$row" | cut -d"$TAB" -f1)
                # STDIN IS CLOSED FOR THE RE-READ. This loop's own input is the heredoc
                # of rows, and a transport that read stdin would eat the rows behind it.
                again=$(read_pull "$number" </dev/null) || again=''
                if [ -n "$again" ]; then
                    case "$(printf '%s' "$again" | cut -d"$TAB" -f5)" in
                        null) ;;
                        *) reread_settled=$((reread_settled + 1)); row="$again" ;;
                    esac
                fi
            fi
        fi
        settled_rows="${settled_rows}${row}
"
    done <<EOF
$rows
EOF
    rows="$settled_rows"
fi

pulls=''
while IFS= read -r row; do
    [ -n "$row" ] || continue
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
done <<EOF
$rows
EOF

truncated=false
[ "$total" -le "$LIMIT" ] || truncated=true

printf '{"ok": true, "slug": "%s", "limit": %s, "total_open": %s, "read": %s, "truncated": %s, "reread_attempted": %s, "reread_settled": %s, "reread_capped": %s, "pulls": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$total" "$read_count" "$truncated" \
    "$reread_attempted" "$reread_settled" "$reread_capped" "$pulls"
