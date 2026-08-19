#!/bin/sh -eu
# attributed-work.sh — THE ONE READER of "which work belongs to strategy X in window W".
# Pure read: it never writes, never fetches, and degrades to an explicit empty result with
# a named reason rather than an error or a guess.
#
# Usage: attributed-work.sh <slug> [window] [workaholic-root]
#   window: any `git log --since` expression; defaults to "1 day ago" (the standup's).
#
# Output (one JSON object):
#   {slug, found, window, feedback_refs[], count, active_count, waiting_count,
#    artifacts: [{kind, path, title, state, attribution, changed_in_window, last_change}],
#    empty, empty_reason}
#
#   empty            no artifact is attributable at all
#   empty_reason     "no_slug" | "not_found" | "no_feedback_refs" | "no_citing_artifacts"
#                    | "no_activity_in_window" (attributable work exists, none of it moved
#                      inside the window — a QUIET strategy, which is a real answer and not
#                      an error) | "" when work moved
#
# ATTRIBUTION IS TRANSITIVE THROUGH THE FEEDBACK STREAM, AND ADDS NO FIELD (the Open
# Decision on ticket `20260817115231-resolve-strategy-to-activity-attribution`, resolved
# 2026-08-17). A strategy already cites the records it grew from — the many-valued
# `feedback:` relation, one-way by explicit design (`workaholic:strategy`, *What a strategy
# is not*) — and missions and tickets already carry `feedback:` refs of their own. So the
# path strategy -> feedback <- artifact exists today and needs nothing new:
#
#   strategy.feedback[]  ∩  artifact.feedback[]          -> attribution "direct"
#   strategy.feedback[]  ∩  mission.feedback[], and the artifact names that mission
#                                                        -> attribution "via_mission:<slug>"
#
# The second hop is not a convenience: `/specificate` puts the `feedback:` refs on the MISSION
# and its ticket set carries `mission:` instead, so a one-hop reader would see almost
# nothing. Both hops go through the existing single readers of their relations
# (`specificate/scripts/read-feedback-relation.sh`, `mission/scripts/read-relation.sh`); this
# script parses neither field itself, which is what keeps a second parser from ever
# disagreeing with the first.
#
# WHY NOT THE OTHER THREE CANDIDATES, so the ruling is answerable rather than merely made:
#   (a) Revive `strategy:` on a mission — removed on purpose on 2026-07-28 because it gave
#       ownership a second resolution path (the "ownership hop"), and 2026-08-13 declined
#       to bring it back. Reviving the field to power a digest would have to re-answer
#       that, and a read-only morning summary is not worth reopening the ownership model.
#   (b) THIS ONE. It adds no field, so it cannot rebuild the hop; the citation stays
#       one-way; nothing new needs a write floor, a hook or a migration.
#   (c) A strategy-side list of slugs — the artifact has exactly two writers and neither
#       edits a live strategy, so keeping such a list current needs a third writer, which
#       the design refuses.
#   (d) No attribution, repository-scoped digest — ships without a ruling, and is not what
#       was asked for.
#
# ITS WEAKNESS IS REPORTED, NEVER HIDDEN. (b) is transitive and lossy: work that answers a
# strategy without citing the same record is invisible here. That is why every artifact
# carries its `attribution` reason and why the consumer is expected to say "not attributable
# to any strategy" out loud rather than imply the digest is exhaustive. A lossy reader that
# says which rule it applied beats an exhaustive one that guesses.
#
# COST: the artifact corpus is large (hundreds of tickets), so a per-file call to a
# relation reader would be hundreds of process spawns. Both hops therefore PREFILTER with
# one grep over the corpus for the literal stems/slugs, then confirm each candidate through
# the relation's own reader. The grep decides only "worth reading"; the reader decides
# attribution.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
READ_FEEDBACK="${SCRIPT_DIR}/../../specificate/scripts//read-feedback-relation.sh"
READ_MISSION="${SCRIPT_DIR}/../../mission/scripts//read-relation.sh"

SLUG="${1:-}"
WINDOW="${2:-1 day ago}"
ROOT="${3:-.workaholic}"

US=$(printf '\037')

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit_empty() {
    printf '{"slug": "%s", "found": %s, "window": "%s", "feedback_refs": %s, "count": 0, "active_count": 0, "waiting_count": 0, "artifacts": [], "empty": true, "empty_reason": "%s"}\n' \
        "$(json_escape "$SLUG")" "$1" "$(json_escape "$WINDOW")" "$2" "$3"
}

[ -n "$SLUG" ] || { emit_empty false '[]' no_slug; exit 0; }

FILE="${ROOT}/strategies/${SLUG}.md"
[ -f "$FILE" ] || { emit_empty false '[]' not_found; exit 0; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
trap 'rm -rf "$TMP"; exit 130' INT
trap 'rm -rf "$TMP"; exit 143' TERM
trap 'rm -rf "$TMP"; exit 129' HUP

# --- The strategy's own citations, through the relation's single reader ------------
sh "$READ_FEEDBACK" "$FILE" > "${TMP}/refs" 2>/dev/null || : > "${TMP}/refs"
REFS_JSON=$(jq -Rs 'split("\n") | map(select(length > 0))' < "${TMP}/refs")

[ -s "${TMP}/refs" ] || { emit_empty true "$REFS_JSON" no_feedback_refs; exit 0; }

# Grep patterns: the record filename and its bare stem, since an artifact may cite either.
sed -e 's/\.md$//' "${TMP}/refs" | grep -v '^$' | sort -u > "${TMP}/stems"
cat "${TMP}/refs" "${TMP}/stems" | grep -v '^$' | sort -u > "${TMP}/patterns"

# --- The corpus: every artifact that can carry a relation --------------------------
# Missions across both areas, tickets across the two-state tree plus the retired
# directories the living migration has not yet converged (omitting those would make an
# un-migrated repository's work silently unattributable), and branch stories.
: > "${TMP}/corpus"
for d in "${ROOT}/missions/active" "${ROOT}/missions/archive"; do
    [ -d "$d" ] || continue
    find "$d" -mindepth 2 -maxdepth 2 -name 'mission.md' -type f 2>/dev/null >> "${TMP}/corpus" || :
done
for d in todo archive icebox abandoned; do
    [ -d "${ROOT}/tickets/${d}" ] || continue
    find "${ROOT}/tickets/${d}" -name '*.md' -type f 2>/dev/null >> "${TMP}/corpus" || :
done
if [ -d "${ROOT}/stories" ]; then
    find "${ROOT}/stories" -maxdepth 1 -name '*.md' -type f 2>/dev/null \
        | grep -vE '/(README|index)\.md$' >> "${TMP}/corpus" || :
fi
sort -u "${TMP}/corpus" -o "${TMP}/corpus"

[ -s "${TMP}/corpus" ] || { emit_empty true "$REFS_JSON" no_citing_artifacts; exit 0; }

# --- Hop 1: artifacts citing one of the strategy's records -------------------------
# The stream both hops feed is `<path><US><mission-slug-or-empty>`, so the record emitter
# below has one shape to read rather than two.
: > "${TMP}/hits"
: > "${TMP}/direct"
xargs grep -lFf "${TMP}/patterns" < "${TMP}/corpus" 2>/dev/null > "${TMP}/cand1" || : > "${TMP}/cand1"
while IFS= read -r f; do
    [ -n "$f" ] || continue
    if sh "$READ_FEEDBACK" "$f" 2>/dev/null | sed -e 's/\.md$//' | grep -qxFf "${TMP}/stems"; then
        printf '%s\n' "$f" >> "${TMP}/direct"
        printf '%s%s\n' "$f" "$US" >> "${TMP}/hits"
    fi
done < "${TMP}/cand1"

# --- Hop 2: artifacts naming a mission that hop 1 attributed -----------------------
: > "${TMP}/mission-slugs"
while IFS= read -r f; do
    case "$f" in
        */mission.md) basename "$(dirname "$f")" >> "${TMP}/mission-slugs" ;;
    esac
done < "${TMP}/direct"
sort -u "${TMP}/mission-slugs" -o "${TMP}/mission-slugs"

if [ -s "${TMP}/mission-slugs" ]; then
    xargs grep -lFf "${TMP}/mission-slugs" < "${TMP}/corpus" 2>/dev/null > "${TMP}/cand2" || : > "${TMP}/cand2"
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        grep -qxF "$f" "${TMP}/direct" && continue
        m=$(sh "$READ_MISSION" "$f" 2>/dev/null | grep -xFf "${TMP}/mission-slugs" | head -n1 || true)
        [ -n "$m" ] || continue
        printf '%s%s%s\n' "$f" "$US" "$m" >> "${TMP}/hits"
    done < "${TMP}/cand2"
fi

# --- Facts per attributed artifact ------------------------------------------------
# `kind` from the path, `state` from the artifact's own `status:` field with the path as
# the fallback for a ticket the living migration has not reached (the same order
# `catch/scripts/scan-window.sh` reads it in), and the window fact from git — the only
# place recency can honestly come from, since no artifact stores its own last-touched date.
fm_status() {
    awk '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        /^status:[ \t]*/ { sub(/^status:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

emit_records() {
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        f=${line%"$US"*}
        mission=${line#*"$US"}
        if [ -n "$mission" ]; then
            attribution="via_mission:${mission}"
        else
            attribution=direct
        fi
        [ -f "$f" ] || continue

        case "$f" in
            */mission.md) kind=mission ;;
            */tickets/*)  kind=ticket ;;
            *)            kind=story ;;
        esac

        title=$(sed -n 's/^#[[:space:]]\{1,\}\(.*\)/\1/p' "$f" | head -n1)
        [ -n "$title" ] || title=$(sed -n 's/^title:[[:space:]]*//p' "$f" | head -n1)

        state=$(fm_status "$f")
        if [ -z "$state" ]; then
            case "$f" in
                */tickets/todo/*)      state=queued ;;
                */tickets/archive/*)   state=done ;;
                */tickets/icebox/*)    state=icebox ;;
                */tickets/abandoned/*) state=abandoned ;;
                */missions/active/*)   state=active ;;
                *)                     state="" ;;
            esac
        fi

        last=$(git log -1 --since="$WINDOW" --format=%cs -- "$f" 2>/dev/null || true)
        if [ -n "$last" ]; then
            changed=true
        else
            changed=false
            last=$(git log -1 --format=%cs -- "$f" 2>/dev/null || true)
        fi

        printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\036' \
            "$kind" "$f" "$title" "$state" "$attribution" "$changed" "$last"
    done
}

# The record/field separators are written as jq \u escapes rather than as literal control
# bytes so the filter survives every editor, diff and copy this file passes through.
ARTIFACTS=$(emit_records < "${TMP}/hits" | jq -Rs '
    split("")
    | map(select((gsub("\\s"; "") | length) > 0))
    | map(split(""))
    | map({kind: .[0], path: .[1], title: .[2], state: .[3],
           attribution: .[4], changed_in_window: (.[5] == "true"), last_change: .[6]})
    | sort_by([(if .changed_in_window then 0 else 1 end), .kind, .path])')
[ -n "$ARTIFACTS" ] || ARTIFACTS='[]'

printf '%s' "$ARTIFACTS" > "${TMP}/artifacts.json"
jq -nc \
    --arg slug "$SLUG" \
    --arg window "$WINDOW" \
    --argjson refs "$REFS_JSON" \
    --slurpfile arts "${TMP}/artifacts.json" '
    ($arts[0]) as $a
    | ($a | map(select(.changed_in_window)) | length) as $active
    | ($a | map(select(.kind == "ticket" and .state == "queued")) | length) as $waiting
    | {slug: $slug, found: true, window: $window, feedback_refs: $refs,
       count: ($a | length), active_count: $active, waiting_count: $waiting,
       artifacts: $a,
       empty: (($a | length) == 0),
       empty_reason: (if ($a | length) == 0 then "no_citing_artifacts"
                      elif $active == 0 then "no_activity_in_window"
                      else "" end)}'
