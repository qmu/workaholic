#!/bin/sh -eu
# The announced items whose thread may still be calling them in flight.
#
# WHY THIS READER EXISTS (2026-08-28, mission `reconcile-a-stale-thread-with-the-unit-s-real-state`).
# A finish line is posted by the run that FINISHES a unit (`workaholic:notify`, *Which
# thread an `/implement` unit's posts land in*), so when a person merges a handed-off pull
# request by hand the line is posted by nobody: the item's thread keeps `🔵 Proposed` or
# `🟡 Handoff` as its last word while the work is long merged. Measured on this repository
# on 2026-08-28 — several units hand-finished in a terminal, every affected thread still
# calling them in flight.
#
# NO EXISTING STEP CAN SEE IT. `stuck-prs` and `merge-conflicts` read **open** pull
# requests and find nothing wrong with one that already merged; `handoff-units` reads a
# claim that is still standing; `stalled-units` reads a stale tip. All four are about a
# unit that has not finished — this is about one that has.
#
# THE CANDIDATE SET IS REPOSITORY-DERIVED, NEVER A CHANNEL SCAN. `workaholic:notify` bounds
# every thread lookup at two exact-string searches with **no full-channel read at any
# point**, so deriving candidates by scanning the channel would break that bound outright
# and would make the reader's cost grow with the channel rather than with the work. It is
# also why the drill carries a breaker row wiring this at the channel: that inversion is
# the failure mode worth catching mechanically.
#
# IT DOES NOT DECIDE WHETHER A THREAD IS STALE. That needs the thread, and Slack is a
# connector held by the session rather than by a script (`step-unanswered-asks.sh`'s split,
# for its reason). This answers *which items to look at*, and nothing more.
#
# Usage: reconcile-candidates.sh [--window-days <n>] [--limit <n>] [--root <repo-root>]
# Output: one JSON line
#   {"ok": true, "slug": "...", "window_days": n, "limit": n, "total": n, "read": n,
#    "truncated": bool, "beyond_bound": n, "list_capped": bool,
#    "candidates": [{"unit","branch","number","title","url","state":"merged"|"closed",
#                    "merged_by","merged_at","stems":[...]}],
#    "unresolved": [{"number","branch","reason"}]}
#   {"ok": false, "reason": "gh_unavailable"|"list_failed", "detail": "..."}
#
# AN UNREADABLE READ IS `ok: false` WITH ITS REASON AND **EXIT 0**, never an empty
# candidate list — a reader that renders its own blindness as "nothing to reconcile" is the
# collapse `workaholic:implementation` / observability exists to refuse.
#
# `merged_by` and `merged_at` are what the reply needs to say *by whom and when*. They come
# from the single-pull GET, which is the only endpoint carrying `merged_by`; that read is
# bounded by `--limit` exactly as `pulls-state.sh` bounds its own. An unresolvable one is
# emitted EMPTY and the agent states it as unresolved — never invented.
#
# A candidate whose artifacts resolve to no feedback stem is reported in `unresolved` under
# `stems_unresolvable` and is never keyed on `unit:<id>` here: this reader answers *which
# item*, and an item with no feedback record has no thread to reconcile.
#
# PURE READ. No file, no commit, no branch, no comment, no merge, no claim touched. GitHub
# is reached only through `gather/scripts/gh-rest.sh` (`rules/shell.md`).

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts"
MISSION_RELATION="${SCRIPT_DIR}/../../mission/scripts/read-relation.sh"
STEMS="${SCRIPT_DIR}/../../drive/scripts/unit-feedback-stems.sh"
BASE="${WORKAHOLIC_BASE_REF:-origin/main}"

WINDOW="${WORKAHOLIC_RECONCILE_WINDOW_DAYS:-3}"
LIMIT="${WORKAHOLIC_RECONCILE_MAX:-10}"
ROOT="."

while [ $# -gt 0 ]; do
    case "$1" in
        --window-days) WINDOW="${2:-3}"; shift 2 ;;
        --limit)       LIMIT="${2:-10}"; shift 2 ;;
        --root)        ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

case "$WINDOW" in ''|*[!0-9]*) WINDOW=3 ;; esac
case "$LIMIT"  in ''|*[!0-9]*) LIMIT=10 ;; esac

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit_err() {
    detail=$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-300)
    printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
    exit 0
}

command -v gh >/dev/null 2>&1 || emit_err gh_unavailable "gh is not on PATH"

slug=$(sh "${GATHER}/gh-rest.sh" slug 2>&1) || emit_err list_failed "$slug"
[ -n "$slug" ] || emit_err list_failed "no repository slug"

cutoff=$(date -u -d "-${WINDOW} days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v-"${WINDOW}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
[ -n "$cutoff" ] || emit_err list_failed "the window boundary could not be computed"

# The list endpoint carries closed_at/merged_at and the head ref, which is every term of
# the filter. Only the pull requests THIS LOOP opened are candidates: a `work-*` head is
# the claim protocol's own branch pattern and nothing else may carry it.
#
# IT PAGINATES, AND THE PAGE BOUND IS REPORTED. One page of 50 cannot serve the window on
# an active repository — this one closes ~25 pull requests a day — so a single page would
# silently answer "nothing merged" for anything older than yesterday. Pages are read until
# one falls entirely outside the window or `WORKAHOLIC_RECONCILE_PAGES` is reached, and
# `list_capped` says which of the two stopped it.
PAGES="${WORKAHOLIC_RECONCILE_PAGES:-3}"
case "$PAGES" in ''|*[!0-9]*) PAGES=3 ;; esac

rows=''
list_capped=false
page=1
while [ "$page" -le "$PAGES" ]; do
    chunk=$(sh "${GATHER}/gh-rest.sh" api \
        "repos/${slug}/pulls?state=closed&sort=updated&direction=desc&per_page=50&page=${page}" \
        --jq '.[] | [(.number|tostring), (.head.ref // ""), (.merged_at // ""), (.closed_at // ""), (.html_url // ""), (.title // "")] | @tsv' \
        2>&1) || emit_err list_failed "$chunk"
    [ -n "$chunk" ] || break
    rows="${rows}${rows:+
}${chunk}"
    # The list is sorted by UPDATED, so a page's oldest close time says nothing about
    # whether the next page is inside the window — an old pull request touched today
    # rides page 1. So the bound is the page count, flatly, and it is reported.
    n_rows=$(printf '%s\n' "$chunk" | grep -c '' || true)
    if [ "${n_rows:-0}" -lt 50 ]; then break; fi
    if [ "$page" -eq "$PAGES" ]; then list_capped=true; fi
    page=$((page + 1))
done

TAB=$(printf '\t')
total=0
read_count=0
candidates=''
unresolved=''

resolve_artifacts() {
    # $1 = branch. Prints one artifact path per line, deduped, existing files only.
    #
    # THREE LOCAL SOURCES, NO NETWORK. The branch's own merge commit names every artifact
    # the unit published — which is what resolves a `/specificate` proposal, whose mission
    # and tickets carry the record's refs by the carry floor. The branch-keyed ticket
    # archive and the story's `mission:` relation cover the rest: a ticket written to
    # `todo/` by one merge and archived by another is at neither path the diff named.
    _branch="$1"
    {
        _merge=$(git -C "$ROOT" log "$BASE" --merges --format='%H %s' -n 200 2>/dev/null \
            | grep -E " from [^ /]+/${_branch}\$" | head -1 | cut -d' ' -f1 || true)
        if [ -n "${_merge:-}" ]; then
            git -C "$ROOT" diff --name-only "${_merge}^1" "$_merge" 2>/dev/null | while IFS= read -r _p; do
                case "$_p" in
                    .workaholic/missions/*/mission.md) ;;
                    .workaholic/tickets/*.md) ;;
                    *) continue ;;
                esac
                if [ -f "${ROOT}/${_p}" ]; then
                    printf '%s\n' "${ROOT}/${_p}"
                else
                    # The ticket moved (todo -> archive) after that merge; the basename is
                    # stable, so the current path is the one match under `tickets/`.
                    find "${ROOT}/.workaholic/tickets" -name "$(basename "$_p")" -type f 2>/dev/null || true
                fi
            done
        fi
        _dir="${ROOT}/.workaholic/tickets/archive/${_branch}"
        if [ -d "$_dir" ]; then
            find "$_dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null || true
        fi
        _story="${ROOT}/.workaholic/stories/${_branch}.md"
        if [ -f "$_story" ] && [ -f "$MISSION_RELATION" ]; then
            sh "$MISSION_RELATION" "$_story" 2>/dev/null | while IFS= read -r _slug; do
                [ -n "$_slug" ] || continue
                for _area in active archive; do
                    _m="${ROOT}/.workaholic/missions/${_area}/${_slug}/mission.md"
                    if [ -f "$_m" ]; then printf '%s\n' "$_m"; fi
                done
            done
        fi
    } | sort -u
}

unit_of() {
    # $1 = branch, $2 = the resolved artifact paths. The mission slug when one is
    # reachable — from the story's `mission:` relation, else from a mission the unit
    # published — else the branch. An identifier for the report, never a thread key.
    _story="${ROOT}/.workaholic/stories/${1}.md"
    _slug=''
    if [ -f "$_story" ] && [ -f "$MISSION_RELATION" ]; then
        _slug=$(sh "$MISSION_RELATION" "$_story" 2>/dev/null | head -1 || true)
    fi
    if [ -z "$_slug" ]; then
        for _a in $2; do
            case "$_a" in
                */.workaholic/missions/*/mission.md)
                    _slug=$(dirname "$_a"); _slug=$(basename "$_slug"); break ;;
            esac
        done
    fi
    printf '%s' "${_slug:-$1}"
}

add_unresolved() {
    unresolved="${unresolved:+${unresolved}, }{\"number\": $1, \"branch\": \"$(json_escape "$2")\", \"reason\": \"$3\"}"
}

OLDIFS=$IFS
IFS='
'
for row in $rows; do
    [ -n "$row" ] || continue
    IFS="$TAB"
    # shellcheck disable=SC2086
    set -- $row
    IFS=$OLDIFS
    number="${1:-}"; branch="${2:-}"; merged_at="${3:-}"; closed_at="${4:-}"; url="${5:-}"; title="${6:-}"
    case "$branch" in work-*) ;; *) continue ;; esac
    when="${merged_at:-$closed_at}"
    [ -n "$when" ] || continue
    # ISO-8601 Z timestamps sort lexicographically, so `sort` is the whole comparison.
    [ "$(printf '%s\n%s\n' "$cutoff" "$when" | sort | head -1)" = "$cutoff" ] || continue

    total=$((total + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    read_count=$((read_count + 1))

    state=closed
    if [ -n "$merged_at" ]; then state=merged; fi

    merged_by=''
    if [ "$state" = merged ]; then
        merged_by=$(sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/${number}" \
            --jq '.merged_by.login // ""' 2>/dev/null || true)
    fi

    arts=$(resolve_artifacts "$branch" | tr '\n' ' ')
    stems_json='[]'
    if [ -n "${arts# }" ] && [ -f "$STEMS" ]; then
        # shellcheck disable=SC2086
        out=$(sh "$STEMS" $arts 2>/dev/null || true)
        if [ -n "$out" ]; then
            stems_json=$(printf '%s' "$out" | jq -c '.stems // []' 2>/dev/null || echo '[]')
        fi
    fi
    if [ "$stems_json" = '[]' ]; then
        add_unresolved "$number" "$branch" stems_unresolvable
        continue
    fi

    # shellcheck disable=SC2086
    unit=$(unit_of "$branch" "$arts")
    candidates="${candidates:+${candidates}, }{\"unit\": \"$(json_escape "$unit")\", \"branch\": \"$(json_escape "$branch")\", \"number\": ${number}, \"title\": \"$(json_escape "$title")\", \"url\": \"$(json_escape "$url")\", \"state\": \"${state}\", \"merged_by\": \"$(json_escape "$merged_by")\", \"merged_at\": \"$(json_escape "$when")\", \"stems\": ${stems_json}}"
done
IFS=$OLDIFS

beyond=$((total - read_count))
[ "$beyond" -ge 0 ] || beyond=0
truncated=false
[ "$beyond" -eq 0 ] || truncated=true

printf '{"ok": true, "slug": "%s", "window_days": %s, "limit": %s, "total": %s, "read": %s, "truncated": %s, "beyond_bound": %s, "list_capped": %s, "candidates": [%s], "unresolved": [%s]}\n' \
    "$(json_escape "$slug")" "$WINDOW" "$LIMIT" "$total" "$read_count" "$truncated" "$beyond" "$list_capped" "$candidates" "$unresolved"
