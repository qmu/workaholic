#!/bin/sh -eu
# unattributed-asks.sh — WHAT ASK DOES NO DIRECTION CLAIM: the open inbound asks this identity
# holds that no `active` strategy covers.
#
#   unattributed-asks.sh [--root <.workaholic>]
#
# Output: {"ok", "asks": [{"number", "title", "url", "updated_at", "age_days", "reason"}],
#          "ask_count", "exhaustive": false}
#         {"ok", "readable": false, "reason", "asks": null, "ask_count": null, "exhaustive": false}
#   `readable` is ABSENT on a completed walk, this repository's own convention, so the test is
#   `readable == false` and never `readable // true`.
#   Exit 0 always. Pure read: it writes nothing, creates nothing and reaches no writer.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
# Operator's ask, **issue #907 item 3** (2026-09-19, ticket `20260919093809`): *a move is
# declared against a strategy, so an ask with no direction can never be originated;
# `unattributed` exists on the inbound path and has no counterpart here.* MEASURED: the
# operator's own stated immediate priority belonged to no active strategy, so `/propose` was
# structurally incapable of proposing it and spent two days proposing against the directions
# that did exist.
#
# This is the MIRROR of `unattributed-work.sh`, which sits beside it. That one names what no
# direction claims on the **work already emitted** side — active missions and queued tickets.
# Nothing read the other side: an **operator ask** sitting in the inbox that no active direction
# covers was visible to nobody, because `/propose` surveys strategies and never reads the inbox
# while `list-inbound-issues.sh` knows nothing about directions.
#
# ═══ THE BOUNDARY, FIRST, BECAUSE IT SHAPES EVERYTHING BELOW ═════════════════════════
# This gives the ask VISIBILITY, not an origination path. `rules/workaholic.md`, *What May
# Originate a Mission*, permits a human's ask or a human-authored strategy and nothing else, and
# an inbound operator ask is ALREADY originable — by `/specificate`, through the path built for
# it. So nothing here proposes, creates a strategy, amends one or lifts a gate: it names the ask
# so a person can decide whether it wants a direction.
#
# ═══ IT COMPOSES; IT WALKS NOTHING ═══════════════════════════════════════════════════
# `specificate/scripts/list-inbound-issues.sh` already classifies every inbound row
# (`already_planned`, `captured_on_branch`, `self_originated`, `unassigned`, `uncaptured`); the
# direction question is a NEW AXIS over rows it already returns, never a second listing.
# `strategy/scripts/list.sh` and `read.sh` give the active directions and their `feedback:`
# refs, `read.sh` resolving the absent-stage default, which nothing here re-derives. No
# relation, no field on any artifact and no second walker.
#
# ═══ ATTRIBUTION IS A JUDGEMENT AND IS REPORTED AS ONE ═══════════════════════════════
# An ask's direction is decided by an explicit `feedback:` line, else an explicit slug, else a
# judgement against the active Aims — the ladder `/specificate` step 7 already uses. A SCRIPT
# CANNOT PERFORM THE THIRD RUNG, so this answers only the two mechanical ones:
#
#   rung 1  the ask's captured record is named in some active strategy's `feedback:` list
#           -> COVERED, absent from this output
#   rung 2  the ask's title names an active strategy's slug
#           -> COVERED, absent from this output
#   rung 3  neither -> REPORTED, `reason: "undecidable_here"`
#
# `undecidable_here` means *no line and no slug*, and a consumer must render it as that — NEVER
# as *no direction*. A script that judged an ask against an Aim would be asserting a reading
# this repository keeps as a judgement in exactly one place, and two judges of one question
# drift.
#
# ═══ A DEGRADED READ IS NAMED, NEVER AN EMPTY SET ════════════════════════════════════
# `readable: false` carries its own reason (`inbox_unreadable`, `strategy_list_unreadable`,
# `no_inbox_reader`, `no_strategy_reader`) with **null** counts and a **null** `asks` — never
# `no_unattributed_asks`, which means the opposite. `exhaustive` is `false` always: the inbox
# reader is paged and assignee-scoped by construction, so an ask this identity does not hold is
# invisible here for an ordinary reason.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INBOX="${SCRIPT_DIR}/../../specificate/scripts/list-inbound-issues.sh"
LIST="${SCRIPT_DIR}/list.sh"
READ="${SCRIPT_DIR}/read.sh"

ROOT=".workaholic"
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-.workaholic}"; shift 2 ;;
        *) shift ;;
    esac
done

degraded() {
    printf '{"ok": true, "readable": false, "reason": "%s", "asks": null, "ask_count": null, "exhaustive": false}\n' "$1"
    exit 0
}

[ -f "$INBOX" ] || degraded no_inbox_reader
[ -f "$LIST" ] && [ -f "$READ" ] || degraded no_strategy_reader

strategies=$(sh "$LIST" --status active "$ROOT" 2>/dev/null || true)
[ -n "$strategies" ] && printf '%s' "$strategies" | jq -e '.strategies' >/dev/null 2>&1 \
    || degraded strategy_list_unreadable

inbox=$(sh "$INBOX" 2>/dev/null || true)
[ -n "$inbox" ] && printf '%s' "$inbox" | jq -e '.ok == true' >/dev/null 2>&1 \
    || degraded inbox_unreadable

# The covering terms, gathered once: every active slug, and every `feedback:` ref those
# directions cite. `read.sh` is the one reader of a strategy file and is what resolves the
# absent-stage default; nothing here re-derives it.
slugs=$(printf '%s' "$strategies" | jq -r '.strategies[].slug' 2>/dev/null || true)
refs=''
for slug in $slugs; do
    one=$(sh "$READ" "$slug" "$ROOT" 2>/dev/null || true)
    [ -n "$one" ] || continue
    # `read.sh` renders `feedback` as the frontmatter list's INNER TEXT — a comma-separated
    # string, not an array — so it is split here rather than indexed. Both shapes are accepted
    # so a future reader that returns an array needs no change on this side.
    got=$(printf '%s' "$one" | jq -r '
        (.feedback // "")
        | if type == "array" then .[]
          else (split(",")[] | gsub("^[[:space:]]+|[[:space:]]+$"; "")) end
        | select(length > 0)' 2>/dev/null || true)
    refs="${refs}${got}
"
done

slug_json=$(printf '%s\n' "$slugs" | jq -Rn '[inputs | select(length > 0)]' 2>/dev/null || printf '[]')
refs_json=$(printf '%s\n' "$refs" | jq -Rn '[inputs | select(length > 0)]' 2>/dev/null || printf '[]')

# The new axis over the rows the inbox reader already returned. A row is covered when rung 1 or
# rung 2 holds; everything else is `undecidable_here` and is reported.
#
# Rung 1 matches on the record's own stem in either direction, because a strategy cites
# `<stem>.md` while a row may carry the record's path — a containment test either way is the
# honest comparison and never a similarity match.
out=$(printf '%s' "$inbox" | jq -c \
    --argjson slugs "$slug_json" --argjson refs "$refs_json" \
    --arg now "$(date -u +%s)" '
    [ .issues[]
      | . as $i
      | ($i.record // "") as $rec
      | (($rec | length) > 0 and any($refs[]; . as $r
            | ($r | length) > 0 and (($rec | contains($r)) or ($r | contains($rec))))) as $by_ref
      | (any($slugs[]; . as $s
            | ($s | length) > 0 and (($i.title // "") | contains($s)))) as $by_slug
      | select(($by_ref or $by_slug) | not)
      | {number: $i.number, title: ($i.title // ""), url: ($i.url // ""),
         updated_at: ($i.updated_at // null),
         age_days: (if ($i.updated_at // "") == "" then null
                    else ((($now | tonumber) - ($i.updated_at | fromdateiso8601)) / 86400 | floor) end),
         reason: "undecidable_here"} ]' 2>/dev/null || printf '')
[ -n "$out" ] || degraded inbox_unreadable

count=$(printf '%s' "$out" | jq 'length' 2>/dev/null || printf '')
[ -n "$count" ] || degraded inbox_unreadable

printf '{"ok": true, "asks": %s, "ask_count": %s, "exhaustive": false}\n' "$out" "$count"
