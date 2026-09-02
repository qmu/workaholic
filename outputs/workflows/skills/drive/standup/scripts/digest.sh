#!/bin/sh -eu
# digest.sh — the per-strategy daily digest, as data. PURE READ: no file, no commit, no
# branch, no pull request, no merge, no deployment, no network call. Everything it reports
# is derived from this checkout.
#
# Usage: digest.sh [window] [workaholic-root]
#   window: any `git log --since` expression; defaults to "1 day ago" — a standup's
#           "what moved since yesterday".
#
# Output (one JSON object):
#   {window, date, token, commit_count, strategy_count, active_strategy_count,
#    degraded_count, due_soon_count, target_horizon_days, queued_total, noop, noop_reason,
#    strategies: [{slug, title, status, target_date, days_to_target, assignees,
#                  readable, reason, count, active_count, waiting_count, empty_reason,
#                  moved: [{kind, title, state}], waiting: [{kind, title, state}],
#                  moved_omitted, waiting_omitted,
#                  missions: [{slug, title, path, readable, reason,
#                              checked, total, queued}], missions_omitted}],
#    strategies_omitted, unattributed: {moved, waiting}, errors: []}
#
# THE MISSION GRAIN (2026-09-01, ticket `20260901083237`). The operator's ordinary
# question — "so how many todos are left?" — was answered by no reading this loop had,
# and by four ad-hoc git commands by hand. Every part of the answer already existed and
# none of them was composed at the grain the question asks, so `missions[]` and
# `queued_total` are a COMPOSITION and not a new walker: `attributed-work.sh` says which
# missions belong to the direction (`waiting_mission_slugs`) and carries each one's title
# and path in `artifacts[]`, `mission/scripts/progress.sh` computes `checked`/`total`,
# `mission/scripts/queue-size.sh` counts what is queued under it, and
# `drive/scripts/list-todo.sh` is the repository's queue. No relation is parsed here, no
# second attribution reader is introduced, and NO ARTIFACT GAINS A FIELD — which is the
# standing rule for this layer (`CLAUDE.md`, *The strategy layer*).
#
# IT IS A SIBLING BLOCK, NOT A RESHAPE. `waiting_count` and `waiting[]` each already have
# consumers and a render; adding the mission grain beside them leaves every existing field
# unchanged in name and meaning, which is what lets `/standup` and `/moderate`'s
# `strategy-digest` adopt it independently.
#
# A MISSION GRAIN THAT COULD NOT BE READ IS NAMED, NEVER ZEROED. `progress.sh` or
# `queue-size.sh` failing gives that one entry `readable: false`, its own reason
# (`mission_progress_unreadable` / `mission_queue_unreadable` / `mission_unreadable`) and
# NULL counts — the rule the honesty line and the strategy record already hold themselves
# to. A zero would read as "this mission has nothing left", which is the opposite.
# `queued_total` is null for the same reason when the queue itself could not be read.
#
# ZERO STRATEGIES IS A CLEAN NO-OP, NOT AN EMPTY DIGEST (`noop: true`,
# `noop_reason: "no_strategies"`). This repository is in that state today, so it is the
# first case that has to be right: a digest about nothing is a daily post that trains its
# readers to ignore the surface, which `workaholic:notify`'s bright line refuses.
# `noop_reason: "no_activity"` is the second silence — nothing moved under any strategy and
# no strategy's own date is close enough to be worth saying (see the gate at the bottom,
# which states why waiting work alone does not break it).
#
# ATTRIBUTION IS NOT THIS SCRIPT'S QUESTION. It calls
# `strategy/scripts/attributed-work.sh`, the one reader of "which work belongs to strategy
# X in window W", and does no relation parsing of its own (`workaholic:strategy`, *Which
# work belongs to a strategy*). What this script owns is the *shape* of a morning: the
# strategy set, the schedule proximity, the caps, and the honesty line below.
#
# THE HONESTY LINE. Attribution through the feedback stream is transitive and lossy, so the
# digest reports `unattributed` — work that moved or waits and belongs to no strategy the
# reader could see. A summary that omitted it would read as exhaustive.
#
# A DEGRADED READ IS NOT A QUIET STRATEGY (2026-08-29, mission
# `keep-the-closing-link-readable-as-the-corpus-grows`). `attributed-work.sh` reports
# `readable: false` when the walk itself could not complete, and its counts are then NULL. A
# strategy read that way used to render exactly like one nothing had happened under — same
# empty `moved`, same empty `waiting`, and it did not count toward `active_strategy_count`,
# so it fell into the `no_activity` silence. Each record now carries `readable` and its
# `reason`, `degraded_count` sits beside the other counts, `attribution_unreadable:<slug>`
# is added to `errors`, and EVERY strategy degraded is its own named no-op
# (`all_attribution_unreadable`) rather than a digest of nothing.
#
# AND THE HONESTY LINE ITSELF GOES NULL when any read was degraded. Its counts are derived
# by SUBTRACTING what the strategies attributed, so a direction whose walk failed pushes its
# own work into `unattributed` — the reading would over-report for a reason that has nothing
# to do with attribution. Null, never a zero and never an inflated number.
#
# BOUNDED BY CONSTRUCTION. `STANDUP_MAX_STRATEGIES` (default 8) and `STANDUP_MAX_ITEMS`
# (default 3) cap the render, and every cut is counted in an `*_omitted` field — the digest
# stays readable as strategies accumulate, and it never silently truncates.
#
# NO GITHUB READ AT ALL, which is why no `gh-rest.sh` call appears below: everything a
# standup needs — what landed, what is queued, whose direction it advances — is in the
# repository, and a daily unattended read that cannot fail on a token or a 403 is worth
# more than a pull-request count. `rules/shell.md`'s "GitHub over REST only" is satisfied
# by having no such read, not by skipping one.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
STRATEGY_LIST="${SCRIPT_DIR}/../../strategy/scripts//list.sh"
ATTRIBUTED="${SCRIPT_DIR}/../../strategy/scripts//attributed-work.sh"
PROGRESS="${SCRIPT_DIR}/../../mission/scripts//progress.sh"
QUEUE_SIZE="${SCRIPT_DIR}/../../mission/scripts//queue-size.sh"
LIST_TODO="${SCRIPT_DIR}/../../drive/scripts//list-todo.sh"

WINDOW="${1:-1 day ago}"
ROOT="${2:-.workaholic}"
MAX_STRATEGIES="${STANDUP_MAX_STRATEGIES:-8}"
MAX_ITEMS="${STANDUP_MAX_ITEMS:-3}"
HORIZON="${STANDUP_TARGET_HORIZON:-14}"

TODAY=$(date -u +%Y-%m-%d)
TOKEN="standup:${TODAY}"

# THE HEADLINE NUMBER IS COMMITS (2026-08-24, the developer's question the morning the
# first digest posted: a bare "67 moved" was read as nothing in particular). One repository
# commit count over the window — a unit a reader already owns — where the per-strategy
# `count` stays what attribution can actually see (artifacts). Offline-safe: an unreadable
# log renders 0 rather than failing the morning.
COMMIT_COUNT=$(git rev-list --count --since="$WINDOW" HEAD 2>/dev/null || printf '0')
case "$COMMIT_COUNT" in ''|*[!0-9]*) COMMIT_COUNT=0 ;; esac

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
trap 'rm -rf "$TMP"; exit 130' INT
trap 'rm -rf "$TMP"; exit 143' TERM
trap 'rm -rf "$TMP"; exit 129' HUP

: > "${TMP}/errors"

# THE REPOSITORY'S OWN QUEUE, read once and through the queue's one reader. It is
# computed here — before the first `emit`, including the ones that exit early — because
# "how much is left" is an answer the operator wants even from a morning that turned out
# to be a no-op: a digest that could not read the strategy set still knows the queue.
# NULL, NEVER ZERO, when the read failed: zero is the answer "nothing is left".
if QUEUED_LIST=$(sh "$LIST_TODO" "$ROOT" 2>/dev/null); then
    QUEUED_TOTAL=$(printf '%s\n' "$QUEUED_LIST" | awk 'NF { n++ } END { print n + 0 }')
else
    QUEUED_TOTAL=null
    printf 'queue_unreadable\n' >> "${TMP}/errors"
fi

emit() {
    # $1 = strategies JSON array, $2 = strategies_omitted, $3 = noop, $4 = noop_reason,
    # $5 = total strategy count, $6 = active strategy count, $7 = unattributed JSON,
    # $8 = due-soon strategy count
    printf '%s' "$1" > "${TMP}/strategies.json"
    printf '%s' "$7" > "${TMP}/unattributed.json"
    jq -nc \
        --arg window "$WINDOW" --arg date "$TODAY" --arg token "$TOKEN" \
        --argjson commits "$COMMIT_COUNT" \
        --argjson omitted "$2" --argjson noop "$3" --arg reason "$4" \
        --argjson total "$5" --argjson active "$6" --argjson due "$8" \
        --argjson degraded "${9:-0}" \
        --argjson horizon "$HORIZON" \
        --argjson queued_total "$QUEUED_TOTAL" \
        --slurpfile s "${TMP}/strategies.json" \
        --slurpfile u "${TMP}/unattributed.json" \
        --rawfile errs "${TMP}/errors" '
        {window: $window, date: $date, token: $token,
         commit_count: $commits,
         strategy_count: $total, active_strategy_count: $active,
         degraded_count: $degraded,
         due_soon_count: $due, target_horizon_days: $horizon,
         queued_total: $queued_total,
         noop: $noop, noop_reason: $reason,
         strategies: $s[0], strategies_omitted: $omitted,
         unattributed: $u[0],
         errors: ($errs | split("\n") | map(select(length > 0)))}'
}

# --- The strategy set --------------------------------------------------------------
# An unreadable area is reported by name; it is never rendered as "no strategies", which
# would be the digest asserting a quiet morning it did not actually read.
if ! LIST=$(sh "$STRATEGY_LIST" --status active "$ROOT" 2>/dev/null); then
    printf 'strategy_list_unreadable\n' >> "${TMP}/errors"
    emit '[]' 0 true strategy_list_unreadable 0 0 '{"moved": 0, "waiting": 0}' 0 0
    exit 0
fi
TOTAL=$(printf '%s' "$LIST" | jq '.count')

if [ "$TOTAL" -eq 0 ]; then
    emit '[]' 0 true no_strategies 0 0 '{"moved": 0, "waiting": 0}' 0 0
    exit 0
fi

# --- The mission grain, composed from readers that already exist -------------------
# One entry per mission the direction has queued work under, in `waiting_mission_slugs`'
# own order. The title and the path ride `artifacts[]`, which the reader already
# populated for exactly these missions, so naming a mission costs no frontmatter parse
# here; a mission the artifact list cannot match falls back to its slug as its title and
# to its slug as `progress.sh`'s argument, which resolves against the repository.
# Passing the PATH when there is one is deliberate: `progress.sh` derives its root from
# the artifact's own location, so a worktree's mission is never read out of a sibling.
strategy_missions() {
    _sm_w="$1"
    : > "${TMP}/mission-records"
    printf '%s' "$_sm_w" | jq -r '.waiting_mission_slugs[]? // empty' > "${TMP}/mission-slugs" \
        2>/dev/null || : > "${TMP}/mission-slugs"
    while IFS= read -r _sm_slug; do
        [ -n "$_sm_slug" ] || continue
        _sm_meta=$(printf '%s' "$_sm_w" | jq -c --arg s "$_sm_slug" \
            '[.artifacts[]? | select(.kind == "mission" and ((.path | split("/"))[-2]) == $s)][0] // {}' \
            2>/dev/null || printf '{}')
        _sm_path=$(printf '%s' "$_sm_meta" | jq -r '.path // ""')
        _sm_title=$(printf '%s' "$_sm_meta" | jq -r '.title // ""')
        [ -n "$_sm_title" ] || _sm_title="$_sm_slug"
        _sm_target="$_sm_slug"
        if [ -n "$_sm_path" ] && [ -f "$_sm_path" ]; then _sm_target="$_sm_path"; fi

        _sm_checked=null
        _sm_total=null
        _sm_queued=null
        _sm_reason=""
        if _sm_prog=$(sh "$PROGRESS" "$_sm_target" 2>/dev/null); then
            _sm_checked=$(printf '%s' "$_sm_prog" | jq -r '.checked')
            _sm_total=$(printf '%s' "$_sm_prog" | jq -r '.total')
        else
            _sm_reason="mission_progress_unreadable"
        fi
        if _sm_q=$(sh "$QUEUE_SIZE" "$_sm_slug" "$ROOT" 2>/dev/null); then
            _sm_queued=$(printf '%s' "$_sm_q" | jq -r '.todo')
        elif [ -n "$_sm_reason" ]; then
            _sm_reason="mission_unreadable"
        else
            _sm_reason="mission_queue_unreadable"
        fi
        case "$_sm_checked" in ''|*[!0-9]*) _sm_checked=null ;; esac
        case "$_sm_total" in ''|*[!0-9]*) _sm_total=null ;; esac
        case "$_sm_queued" in ''|*[!0-9]*) _sm_queued=null ;; esac

        jq -nc --arg slug "$_sm_slug" --arg title "$_sm_title" --arg path "$_sm_path" \
            --arg reason "$_sm_reason" \
            --argjson checked "$_sm_checked" --argjson total "$_sm_total" \
            --argjson queued "$_sm_queued" '
            {slug: $slug, title: $title, path: $path,
             readable: ($reason == ""), reason: $reason,
             checked: $checked, total: $total, queued: $queued}' >> "${TMP}/mission-records"
    done < "${TMP}/mission-slugs"
    jq -sc '.' < "${TMP}/mission-records"
}

# --- Per strategy, through the one attribution reader ------------------------------
printf '%s' "$LIST" | jq -r '.strategies[] | .slug' > "${TMP}/slugs"

: > "${TMP}/attributed-paths"
: > "${TMP}/records"
KEPT=0
OMITTED=0
DEGRADED=0
while IFS= read -r slug; do
    [ -n "$slug" ] || continue
    if [ "$KEPT" -ge "$MAX_STRATEGIES" ]; then
        OMITTED=$((OMITTED + 1))
        continue
    fi
    if ! W=$(sh "$ATTRIBUTED" "$slug" "$WINDOW" "$ROOT" 2>/dev/null); then
        printf 'attribution_unreadable:%s\n' "$slug" >> "${TMP}/errors"
        continue
    fi
    # A WALK THAT DID NOT COMPLETE IS NAMED, AND KEPT (2026-08-29). The reader exits 0 and
    # says `readable: false`, so the non-zero branch above never fires for it — dropping the
    # record here would delete the strategy from the morning instead of reporting it. The
    # test is `readable == false`: in jq `//` treats `false` itself as empty.
    if [ "$(printf '%s' "$W" | jq -r '.readable == false')" = "true" ]; then
        printf 'attribution_unreadable:%s\n' "$slug" >> "${TMP}/errors"
        DEGRADED=$((DEGRADED + 1))
    fi
    printf '%s' "$W" | jq -r '.artifacts[].path' >> "${TMP}/attributed-paths"
    # A DEGRADED WALK GETS NO MISSION GRAIN, and that is not a second silence: its
    # `waiting_mission_slugs` is empty for the same reason its counts are null, so
    # composing over it would render "no missions" for a direction nobody could read.
    # The record already says `readable: false`, which is where a consumer looks.
    MISSIONS='[]'
    if [ "$(printf '%s' "$W" | jq -r '.readable == false')" != "true" ]; then
        MISSIONS=$(strategy_missions "$W")
    fi
    W=$(printf '%s' "$W" | jq -c --argjson m "$MISSIONS" '. + {_missions: $m}')
    printf '%s\n' "$W" >> "${TMP}/records"
    KEPT=$((KEPT + 1))
done < "${TMP}/slugs"

sort -u "${TMP}/attributed-paths" -o "${TMP}/attributed-paths"

# --- The honesty line: what moved or waits under no strategy -----------------------
# Counted over the same two corpora the reader walks, minus everything it attributed.
: > "${TMP}/all-work"
for d in todo archive; do
    [ -d "${ROOT}/tickets/${d}" ] || continue
    find "${ROOT}/tickets/${d}" -name '*.md' -type f 2>/dev/null >> "${TMP}/all-work" || :
done
UNATTR_MOVED=0
UNATTR_WAITING=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -qxF "$f" "${TMP}/attributed-paths" && continue
    case "$f" in
        */tickets/todo/*) UNATTR_WAITING=$((UNATTR_WAITING + 1)) ;;
        *) if [ -n "$(git log -1 --since="$WINDOW" --format=%h -- "$f" 2>/dev/null || true)" ]; then
               UNATTR_MOVED=$((UNATTR_MOVED + 1))
           fi ;;
    esac
done < "${TMP}/all-work"

# --- Assemble, capping the item lists ---------------------------------------------
# `days_to_target` is the one thing a commit list cannot say and the most useful line the
# digest can produce: a dated, owned direction approaching its date with nothing moving.
STRATEGIES=$(jq -sc \
    --argjson max_items "$MAX_ITEMS" \
    --argjson list "$(printf '%s' "$LIST")" \
    --arg today "$TODAY" '
    def days($t): if ($t | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
        then ((($t + "T00:00:00Z") | fromdateiso8601) - (($today + "T00:00:00Z") | fromdateiso8601)) / 86400 | floor
        else null end;
    . as $work
    | [ $work[]
        | . as $w
        | ($list.strategies[] | select(.slug == $w.slug)) as $s
        | ($w.artifacts | map(select(.changed_in_window))) as $moved
        | ($w.artifacts | map(select(.kind == "ticket" and .state == "queued"))) as $waiting
        | {slug: $w.slug, title: ($s.title // $w.slug), status: $s.status,
           target_date: $s.target_date, days_to_target: days($s.target_date),
           assignees: $s.assignees,
           # THE DECLARED STAGE, so the digest names the phase beside the title (2026-08-29,
           # mission `make-a-direction-s-lifecycle-a-declared-stage`). It rides off `list.sh`,
           # which resolves the absent-means-進行中 default through `read.sh` — no new read and
           # no second derivation. A row the list could not match carries "" and the render
           # says the stage is unreadable rather than printing 進行中, because a default that
           # hides a failed read is what `readable` exists to prevent.
           stage: ($s.stage // ""),
           # A QUIET STRATEGY AND ONE THE READER COULD NOT SEE INTO MUST NOT RENDER ALIKE
           # (2026-08-29) — the digest already holds itself to exactly that for the
           # unattributed count. `readable` is ABSENT on a completed walk, by the contract
           # that reader states, so `== false` is the test and `// true` would be wrong.
           readable: ($w.readable != false),
           reason: ($w.reason // ""),
           count: $w.count, active_count: $w.active_count, waiting_count: $w.waiting_count,
           empty_reason: $w.empty_reason,
           moved: ($moved[0:$max_items] | map({kind, title, state})),
           waiting: ($waiting[0:$max_items] | map({kind, title, state})),
           moved_omitted: ([($moved | length) - $max_items, 0] | max),
           waiting_omitted: ([($waiting | length) - $max_items, 0] | max),
           # THE SAME CAP AND THE SAME OMISSION COUNT the two lists above carry: the
           # mission grain is the largest block the digest emits, so it is bounded by
           # construction and every cut is counted rather than silently dropped.
           missions: (($w._missions // [])[0:$max_items]),
           missions_omitted: ([(($w._missions // []) | length) - $max_items, 0] | max)} ]' \
    < "${TMP}/records")
[ -n "$STRATEGIES" ] || STRATEGIES='[]'

ACTIVE=$(printf '%s' "$STRATEGIES" | jq '[.[] | select(.active_count > 0)] | length')
DUE=$(printf '%s' "$STRATEGIES" | jq --argjson h "$HORIZON" \
    '[.[] | select(.days_to_target != null and .days_to_target <= $h)] | length')
UNATTRIBUTED=$(printf '{"moved": %s, "waiting": %s}' "$UNATTR_MOVED" "$UNATTR_WAITING")
# NULL, NOT A NUMBER, WHEN ANY WALK FAILED (2026-08-29). The count is derived by SUBTRACTING
# what the strategies attributed, so a direction whose walk failed pushes its own work into
# this figure — it would over-report for a reason that has nothing to do with attribution.
if [ "$DEGRADED" -gt 0 ]; then
    UNATTRIBUTED='{"moved": null, "waiting": null}'
fi

# EVERY STRATEGY DEGRADED IS ITS OWN NAMED NO-OP, never `no_activity` and never a digest of
# nothing. It sits beside `strategy_list_unreadable`: both say the morning could not be read,
# rather than asserting a quiet one. A PARTIAL degradation is not a no-op — the strategies
# that were read still have a morning, and the degraded ones are named in the render.
if [ "$KEPT" -gt 0 ] && [ "$DEGRADED" -ge "$KEPT" ]; then
    emit "$STRATEGIES" "$OMITTED" true all_attribution_unreadable "$TOTAL" 0 "$UNATTRIBUTED" "$DUE" "$DEGRADED"
    exit 0
fi

# THE SECOND SILENCE, and the one rule that decides whether a morning is news.
# Something moved under a strategy, or a strategy's own date is inside the horizon
# (`STANDUP_TARGET_HORIZON`, default 14 days — overdue included, since a passed date is the
# loudest version of the same fact). Anything else is an idle morning and posts nothing:
#   - Waiting work alone is NOT news every morning. A queued ticket that sat there
#     yesterday will sit there tomorrow, and a digest that repeats it daily is the
#     recurring post `workaholic:notify`'s bright line refuses. It still RIDES a digest
#     that had a reason to exist — "what is waiting" is half of what a standup is for.
#   - An approaching date IS news daily, and it terminates: "a dated, owned direction
#     approaching its date with no activity" is the single most useful line this command
#     can produce (ticket `20260817115232`, *Considerations*), and the horizon bounds how
#     long it can repeat.
#   - `unattributed` work never breaks the silence. A repository-wide changelog is what
#     this digest is deliberately not; /catch is where that question is asked.
if [ "$ACTIVE" -eq 0 ] && [ "$DUE" -eq 0 ]; then
    emit "$STRATEGIES" "$OMITTED" true no_activity "$TOTAL" 0 "$UNATTRIBUTED" "$DUE" "$DEGRADED"
    exit 0
fi

emit "$STRATEGIES" "$OMITTED" false "" "$TOTAL" "$ACTIVE" "$UNATTRIBUTED" "$DUE" "$DEGRADED"
