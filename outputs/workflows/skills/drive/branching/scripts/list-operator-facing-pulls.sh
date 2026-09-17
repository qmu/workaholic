#!/bin/sh -eu
# list-operator-facing-pulls.sh — WHICH OPEN PULL REQUESTS ARE THE OPERATOR'S, derived from
# the publish seam's own refusal word and from nothing else.
#
#   list-operator-facing-pulls.sh [--limit <n>]
#
# Output: {"ok": true, "slug": "<owner/name>", "limit": n, "total_open": n, "read": n,
#          "truncated": bool,
#          "pulls": [{"number": N, "url": "...", "title": "...", "refusal_word": "...",
#                     "created_at": "...", "author": "..."}]}
#      or {"ok": false, "reason": "...", "detail": "..."} — WITH NO `pulls` KEY AT ALL.
#   Exit 0 in every case. PURE READ: it writes nothing, merges nothing, closes nothing.
#
# ═══ MEMBERSHIP IS THE SEAM'S WORD, NEVER A TITLE ════════════════════════════════════
# `branching/scripts/lib/publication-refusal.sh` is the one rule; this script only ADAPTS
# `GET /repos/{}/pulls/{}/files` into the normalised stream that rule reads. A pull request the
# operator retitled, edited, or opened themselves is still theirs, and keying on the `[Ruling] `
# prefix would lose exactly that one. A `[Proposal]` publication that auto-merged is not theirs
# and never appears here, whatever its title says.
#
# ═══ IT IS NOT `list-open-rulings.sh`, AND THAT SCRIPT IS UNTOUCHED ══════════════════
# That one is a BRAKE — *at most one open ruling at a time* — and its header records why the
# title decides its membership: a pull request a person retitled is still one the operator must
# rule on, so for a brake, over-inclusion by title is the safe direction. This is a READING of a
# different question (*which open pull requests wait on the operator*), whose bounds differ.
# Two consumers, two questions, one derivation each.
#
# ═══ WHAT IT DOES NOT ANSWER ═════════════════════════════════════════════════════════
# It never says what HAPPENED to a pull request — that is `publication-effect.sh`, one question
# per script. It never says whose the pull request is beyond the seam's word, never resolves an
# addressee, and never decides whether anybody should be asked about it.
#
# ═══ THE READS ARE BOUNDED AND THE CAP IS REPORTED ═══════════════════════════════════
# `pulls-state.sh`'s precedent, and its default of 10. The per-pull `files` read is what carries
# the shape, so it cannot come from the list endpoint; a busy repository is never silently
# half-read.
# Each selected operator-facing row adds one PR-detail read and one local
# claim-mergeability reading; the existing per-run limit bounds both. Age uses the
# shared publication-age helper. Ref discovery/fetch remains the coordinator's job.
#
# ═══ A DEGRADED READ CARRIES NO PULL LIST ════════════════════════════════════════════
# `ok: false` emits no `pulls` key rather than an empty one: *nothing waits on the operator* and
# *we could not look* are opposite facts, and a consumer that saw `[]` for both would go quiet
# exactly when a person most needs the line.
#
# REST, NOT `gh pr list` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude Code
# Web session may 403 mid-run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts"
REFUSAL_LIB="${SCRIPT_DIR}/lib/publication-refusal.sh"

LIMIT="${WORKAHOLIC_OPERATOR_PULL_LIMIT:-10}"
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
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r//g'
}

emit_err() {
    detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
    printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
    exit 0
}

command -v jq >/dev/null 2>&1 || emit_err "jq_unavailable" "jq is not on PATH"
[ -f "$REFUSAL_LIB" ] || emit_err "no_refusal_rule" "publication-refusal.sh is not present beside the branching skill"
. "$REFUSAL_LIB"
. "$SCRIPT_DIR/lib/publication-age.sh"

sh "${GATHER}/gh-rest.sh" available >/dev/null 2>&1 || emit_err "gh_unavailable" "the GitHub transport is not reachable"

slug="$(sh "${GATHER}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$slug"

# The list endpoint gives the candidates and their coordinates; it cannot give the shape.
list="$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/pulls?state=open&sort=updated&direction=desc&per_page=50" \
    --jq '.[] | [(.number|tostring), .html_url, .title, .created_at, (.user.login // "")] | @tsv' 2>&1)" \
    || emit_err "list_failed" "$list"

TAB="$(printf '\t')"
total=0
read_count=0
pulls=""

while IFS="$TAB" read -r number url title created author; do
    [ -n "$number" ] || continue
    total=$((total + 1))
    [ "$read_count" -lt "$LIMIT" ] || continue
    read_count=$((read_count + 1))

    # The adapter. `status` comes back as a word (`added`/`modified`/`removed`/`renamed`/
    # `copied`) and the rule reads git's letter, so it is mapped here — in the adapter, which is
    # the only thing this script owns about the rule.
    files="$(sh "${GATHER}/gh-rest.sh" api \
        "repos/${slug}/pulls/${number}/files?per_page=100" 2>/dev/null || printf '')"
    [ -n "$files" ] || emit_err files_unreadable "pull ${number}"
    printf '%s' "$files" | jq -e 'type=="array"' >/dev/null 2>&1 || emit_err files_unreadable "pull ${number}"
    [ "$(printf '%s' "$files" | jq length)" -lt 100 ] || emit_err files_truncated "pull ${number}"

    shape_input=$(mktemp)
    printf '%s' "$files" > "$shape_input"
    stream=$(sh "$SCRIPT_DIR/publication-shape.sh" --input "$shape_input" 2>/dev/null) || {
        rm -f "$shape_input"
        emit_err shape_unreadable "pull ${number}"
    }
    rm -f "$shape_input"

    word="$(printf '%s\n' "$stream" | publication_refusal_word)"
    [ -n "$word" ] || continue

    detail=$(sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/${number}" 2>/dev/null || printf '{}')
    head=$(printf '%s' "$detail" | jq -r '.head.ref // empty' 2>/dev/null || true)
    base=$(printf '%s' "$detail" | jq -r '.base.ref // "main"' 2>/dev/null || printf main)
    mb=$(sh "$SCRIPT_DIR/../../drive/scripts/claim-mergeability.sh" "origin/$head" "origin/$base" 2>/dev/null || printf '{}')
    extra=$(printf '%s' "$mb" | jq -c --argjson age "$(publication_age_json "$created")" \
      '{mergeability:(.class // "unanswerable"),mergeability_reason:(.reason // "unreadable"),
      already_current:(.already_current // false),conflicted_files:(.conflicted_files // []),
      mergeability_content_files:(.content_files // []),age_hours:$age}')

    row=$(jq -cn --argjson number "$number" --arg url "$url" --arg title "$title" --arg word "$word" \
      --arg created "$created" --arg author "$author" --arg head "$head" --arg base "$base" --argjson extra "$extra" \
      '{number:$number,url:$url,title:$title,refusal_word:$word,created_at:$created,author:$author,branch:$head,base:$base}+$extra')
    pulls="${pulls:+${pulls}, }$row"
done <<EOF
$list
EOF

truncated=false
[ "$total" -le "$LIMIT" ] || truncated=true
[ "$total" -lt 50 ] || truncated=true

printf '{"ok": true, "slug": "%s", "limit": %s, "total_open": %s, "read": %s, "truncated": %s, "pulls": [%s]}\n' \
    "$(json_escape "$slug")" "$LIMIT" "$total" "$read_count" "$truncated" "$pulls"
