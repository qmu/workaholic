#!/bin/sh -eu
# The finished asks whose own thread never heard that they finished.
#
# WHY THIS READER EXISTS (2026-09-03, mission
# `announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread`). An ask written in the
# channel is captured by the inbound sweep, gets its `📥 受理` receipt in its own thread, and
# becomes an `[FB]` issue. When the work lands the issue closes — but `🟢 Implemented` is a
# per-unit post of `/implement` (`workaholic:notify`, *Which thread an `/implement` unit's
# posts land in*), so an ask whose work landed through a session working it directly reaches
# no route step and its thread ends at the receipt. From the channel, an ask that shipped
# three hours ago and one nobody has started look identical.
#
# THE NEIGHBOURING READER CANNOT ANSWER IT, AND THAT WAS MEASURED BEFORE THIS WAS WRITTEN.
# `moderate/scripts/reconcile-candidates.sh` lists `repos/<slug>/pulls` and keeps only rows
# whose head matches `work-*` — the claim protocol's own branch pattern. Measured 2026-09-03
# against this repository: issue #917, closed 2026-09-02T20:32:35Z with its work merged, is
# named by no candidate and no `unresolved` row of a `--window-days 3 --limit 20` run, because
# it never had a `work-*` branch of its own to be enumerated by. The excluded term is the
# branch pattern, and the grain is the difference: that reader answers *which PULL REQUEST*,
# this one answers *which ITEM*.
#
# Usage: list-unannounced-closed-asks.sh [--limit <n>] [--root <repo-root>]
# Output: one JSON line
#   {"ok": true, "slug": "...", "limit": n, "read": n, "truncated": bool,
#    "candidates": [{"number","url","title","stem","slack_ref","closed_at",
#                    "landed": [{"number","title","url","merged_by","merged_at"}],
#                    "closed_unmerged": bool, "landed_read": "ok"|"timeline_unreadable",
#                    "landed_truncated": bool}],
#    "unresolved": [{"number","reason"}]}
#   {"ok": false, "reason": "gh_unavailable"|"slug_unresolved"|"list_failed", "detail": "..."}
#
# AN UNREADABLE READ IS `ok: false` WITH ITS REASON AND **EXIT 0**, never an empty candidate
# list. A reader that renders its own blindness as *nothing to announce* is the collapse this
# repository has twice measured and refused; the caller holds the tick silent on it rather
# than reading it as a quiet hour.
#
# WHICH CLOSED ISSUES ARE ASKS — two terms, either of which qualifies, and neither of which is
# a title match:
#
#   `slack-ref: <channel>:<ts>` in the body   the inbound sweep captured it, and
#                                             `file-inbound-ask.sh` is the ONE writer of that
#                                             marker (its dedup ledger depends on that).
#   a feedback record naming `/issues/<N>`    the record on the base is what `/specificate`
#                                             and `/fb` write; an ask filed by either carries
#                                             no `slack-ref:` at all. Measured on #917.
#
# An issue matching neither is not an ask and is not a candidate, an `unresolved` row or a
# count — it is simply not this reader's subject.
#
# THE STEM IS NOT DERIVED A SECOND WAY. A *stem* is the feedback record's filename without
# `.md`, exactly the token a thread root carries as `fb:<stem>`; that translation is stated in
# `drive/scripts/unit-feedback-stems.sh` and this reader spells it identically. That script
# itself cannot be composed here: it resolves the `feedback:` RELATION off a mission or ticket,
# and the artifact at this grain IS the record, which names no relation to itself.
#
# NEVER A CHANNEL READ. The candidate set is repository- and issue-derived only, matching the
# bound `workaholic:notify` places on every thread lookup (no full-channel read at any point).
# Whether an item was ALREADY ANNOUNCED is deliberately not answered here — that is read from
# the thread by the caller, which is the whole dedup and needs no store. This reader answers
# *which items to look at* and nothing more, the same split `reconcile-candidates.sh` states.
#
# ONE LISTING CALL DECIDES THE CANDIDATE SET. The issues endpoint returns each body, so both
# keep terms are answered from the page already fetched; which issues are candidates costs one
# call however many issues the repository has.
#
# WHAT LANDED COSTS PER-CANDIDATE READS, AND THEY ARE BOUNDED (2026-09-03, ticket
# `20260903052915-carry-what-landed-onto-each-unannounced-closed-ask`). A finish line must name
# *what landed*; the keep terms above name the item and say nothing about what closed it. Per
# candidate: **one** timeline read, plus **one** single-pull GET for each merged cross-reference
# — `merged_by` is carried by no other endpoint, which is the same reason
# `reconcile-candidates.sh` spends that GET. The second is capped by
# `WORKAHOLIC_ANNOUNCE_LANDED_MAX` (default 5) reporting `landed_truncated`, so the whole read
# count stays a function of `--limit` and never of the repository's size.
#
# A MERGED PULL REQUEST AND A HAND-CLOSED ISSUE ARE DIFFERENT SENTENCES, and folding them into
# one field is how the two drift. A candidate whose timeline names no merged cross-reference
# carries `landed: []` with `closed_unmerged: true` — *a person closed this*. A candidate whose
# timeline could not be READ carries `landed: []`, `closed_unmerged: false` and
# `landed_read: timeline_unreadable`: not knowing what closed it is not the same as knowing
# nobody merged anything, and the caller holds such a candidate rather than announcing it.
#
# AN UNRESOLVABLE FIELD IS EMPTY, NEVER SUBSTITUTED. A `merged_by` the single-pull GET could
# not answer is `""`, and the composing step states it as unresolved rather than naming a
# plausible person. The timeline carries `number`, `title`, `html_url` and `merged_at` itself,
# so those four survive a refused GET intact.
#
# PURE READ. No file, no commit, no branch, no comment, no issue, no post. GitHub is reached
# only through `gather/scripts/gh-rest.sh` (`rules/shell.md`).

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

LIMIT="${WORKAHOLIC_ANNOUNCE_CLOSED_MAX:-10}"
LANDED_MAX="${WORKAHOLIC_ANNOUNCE_LANDED_MAX:-5}"
ROOT="."

while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-10}"; shift 2 ;;
        --root)  ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

case "$LIMIT" in ''|*[!0-9]*) LIMIT=10 ;; esac
case "$LANDED_MAX" in ''|*[!0-9]*) LANDED_MAX=5 ;; esac

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit_err() {
    detail=$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-300)
    printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
    exit 0
}

command -v gh >/dev/null 2>&1 || emit_err gh_unavailable "gh is not on PATH"

slug=$(sh "$GH_REST" slug 2>&1) || emit_err slug_unresolved "$slug"
[ -n "$slug" ] || emit_err slug_unresolved "gh-rest.sh slug returned empty"

# Newest first. Pull requests share the issues endpoint and are dropped by `.pull_request`,
# which is the documented discriminator; a title filter is deliberately not used, here or
# anywhere (`/specificate`'s discovery states the same rule).
#
# EVERY FIELD CARRIES A `-` SENTINEL. A TAB is IFS *whitespace*, so two adjacent empty fields
# collapse into one and every later field shifts left — the defect `reconcile-candidates.sh`
# records against its own `merged_at`. Emitting a sentinel for all five costs one mapping back
# and removes the whole class.
rows=$(sh "$GH_REST" api \
    "repos/${slug}/issues?state=closed&sort=updated&direction=desc&per_page=100" \
    --jq '.[]
          | select(.pull_request == null)
          | [ (.number|tostring),
              (.closed_at // "-"),
              (((.body // "") | [scan("slack-ref: ([A-Z0-9]+:[0-9]+[.][0-9]+)")]) as $r
                 | if ($r|length) > 0 then $r[0][0] else "-" end),
              (.html_url // "-"),
              (if (.title // "") == "" then "-" else .title end) ]
          | @tsv' 2>&1) || emit_err list_failed "$rows"

FEEDBACKS="${ROOT}/.workaholic/feedbacks"

record_stem_for_issue() {
    # $1 = issue number. The stem of the feedback record naming this issue's URL, or empty.
    #
    # THE MATCH IS BOUNDED ON THE RIGHT. `issues/91` is a prefix of `issues/917`, so a bare
    # substring search attributes one ask's thread to another's issue — the kind of wrong
    # thread `workaholic:notify` forbids outright ("a wrong thread is worse than none").
    [ -d "$FEEDBACKS" ] || return 0
    _hit=$(grep -rlE "issues/${1}([^0-9]|\$)" "$FEEDBACKS" 2>/dev/null \
        | grep -v '/index\.md$' | sort | head -1 || true)
    [ -n "${_hit:-}" ] || return 0
    _base=$(basename "$_hit")
    printf '%s' "${_base%.md}"
}

# What closed this issue, as the timeline records it.
#
# The cross-referenced event's `source.issue` carries `number`, `title`, `html_url` and
# `pull_request.merged_at` — every field a finish line needs except `merged_by`, which lives
# only on the single-pull GET. An UNMERGED cross-reference is not a landing and is filtered
# here: a pull request that mentioned the issue and was closed did not close it.
#
# Sets LANDED_JSON, LANDED_COUNT, LANDED_READ and LANDED_TRUNCATED. Never fatal: a refused
# read answers `timeline_unreadable` with an empty list, which the caller must not read as
# *nobody merged anything*.
landed_for_issue() {
    LANDED_JSON=''
    LANDED_COUNT=0
    LANDED_READ=ok
    LANDED_TRUNCATED=false

    _tl=$(sh "$GH_REST" api \
        "repos/${slug}/issues/${1}/timeline?per_page=100" \
        --jq '.[]
              | select(.event == "cross-referenced")
              | .source.issue
              | select(.pull_request != null)
              | select(((.pull_request.merged_at) // "") != "")
              | [ (.number|tostring),
                  (.pull_request.merged_at),
                  (.html_url // "-"),
                  (if (.title // "") == "" then "-" else .title end) ]
              | @tsv' 2>&1) || { LANDED_READ=timeline_unreadable; return 0; }

    _seen=''
    _oldifs=$IFS
    IFS='
'
    for _r in $_tl; do
        [ -n "$_r" ] || continue
        IFS="$TAB"
        # shellcheck disable=SC2086
        set -- $_r
        IFS='
'
        _n="${1:-}"; _at="${2:-}"; _u="${3:-}"; _t="${4:-}"
        [ -n "$_n" ] || continue
        # One pull request can cross-reference an issue more than once.
        case " ${_seen} " in *" ${_n} "*) continue ;; esac
        _seen="${_seen} ${_n}"
        if [ "$LANDED_COUNT" -ge "$LANDED_MAX" ]; then
            LANDED_TRUNCATED=true
            break
        fi
        LANDED_COUNT=$((LANDED_COUNT + 1))
        if [ "$_u" = "-" ]; then _u=""; fi
        if [ "$_t" = "-" ]; then _t=""; fi
        # `merged_by` is on no other endpoint. Unresolvable stays EMPTY — a finish line says
        # *by whom* only when somebody read who.
        _by=$(sh "$GH_REST" api "repos/${slug}/pulls/${_n}" \
            --jq '.merged_by.login // ""' 2>/dev/null || true)
        _by=$(printf '%s' "${_by:-}" | tr -d '\n')
        LANDED_JSON="${LANDED_JSON:+${LANDED_JSON}, }{\"number\": ${_n}, \"title\": \"$(json_escape "$_t")\", \"url\": \"$(json_escape "$_u")\", \"merged_by\": \"$(json_escape "$_by")\", \"merged_at\": \"$(json_escape "$_at")\"}"
    done
    IFS=$_oldifs
}

TAB=$(printf '\t')
OLDIFS=$IFS
read_count=0
truncated=false
candidates=''
unresolved=''

IFS='
'
for row in $rows; do
    [ -n "$row" ] || continue
    IFS="$TAB"
    # shellcheck disable=SC2086
    set -- $row
    IFS=$OLDIFS
    number="${1:-}"; closed_at="${2:-}"; slack_ref="${3:-}"; url="${4:-}"; title="${5:-}"
    [ -n "$number" ] || continue
    if [ "$closed_at" = "-" ]; then closed_at=""; fi
    if [ "$slack_ref" = "-" ]; then slack_ref=""; fi
    if [ "$url" = "-" ]; then url=""; fi
    if [ "$title" = "-" ]; then title=""; fi

    stem=$(record_stem_for_issue "$number")

    # THE KEEP FILTER. Neither term means this closed issue is not an ask at all, and it
    # leaves without being counted anywhere.
    if [ -z "$slack_ref" ] && [ -z "$stem" ]; then
        continue
    fi

    if [ "$read_count" -ge "$LIMIT" ]; then
        truncated=true
        break
    fi
    read_count=$((read_count + 1))

    if [ -z "$stem" ]; then
        # Captured by the sweep, but no record on the base resolves it — so there is no
        # `fb:<stem>` to search for and no thread to announce into. Named, never invented.
        unresolved="${unresolved:+${unresolved}, }{\"number\": ${number}, \"reason\": \"stems_unresolvable\"}"
        continue
    fi

    landed_for_issue "$number"
    # `closed_unmerged` is a POSITIVE reading and is claimed only on one: the timeline was read
    # and named no merged pull request. An unreadable timeline leaves it false and says so.
    closed_unmerged=false
    if [ "$LANDED_READ" = ok ] && [ "$LANDED_COUNT" -eq 0 ]; then closed_unmerged=true; fi

    candidates="${candidates:+${candidates}, }{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"stem\": \"$(json_escape "$stem")\", \"slack_ref\": \"$(json_escape "$slack_ref")\", \"closed_at\": \"$(json_escape "$closed_at")\", \"landed\": [${LANDED_JSON}], \"closed_unmerged\": ${closed_unmerged}, \"landed_read\": \"${LANDED_READ}\", \"landed_truncated\": ${LANDED_TRUNCATED}}"
done
IFS=$OLDIFS

printf '{"ok": true, "slug": "%s", "limit": %s, "read": %s, "truncated": %s, "candidates": [%s], "unresolved": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$read_count" "$truncated" "$candidates" "$unresolved"
