#!/bin/sh -eu
# draft-standing-rulings.sh — TURN JUDGED STANDING RULINGS INTO ONE PULL REQUEST, so the
# operator rules by MERGING instead of by editing `main` by hand.
#
#   draft-standing-rulings.sh [--root <.workaholic>] [--judgement <subject>=<answer>]...
#
# Output: {"ok", "readable", "reason", "drafted", "rulings": [{kind, subject, decision,
#          status, reason}], "refused": [...], "published", "pr_url", "merged",
#          "merge_reason", "publish_reason"}
#   Exit 0 always.
#
# ═══ WHERE IT WRITES ═════════════════════════════════════════════════════════════════
# Into a PUBLISH TREE (`branching/scripts/open-publish-tree.sh`), never the caller's
# checkout: `.publish/` is an independent checkout of `origin/main`, so the caller's branch,
# index and working tree are left byte-identical. The claim protocol owns every `work-*`
# branch and nothing here may push into one — this is `/moderate`'s *writes nothing but its
# own tick-log line* contract, kept by writing somewhere else entirely.
#
# The candidate set is read INSIDE that tree, so the rulings are derived from the base the
# pull request will be opened against rather than from whatever the caller happens to hold.
#
# ═══ IT CARRIES; IT NEVER AUTHORS ════════════════════════════════════════════════════
# Every attribution goes through `strategy/scripts/carry-attribution.sh` — the one writer of
# a mission's carried `feedback:` line — with its bounds untouched: it appends refs the named
# strategy ALREADY cites, removes none, touches the `feedback:` line and nothing else, never
# touches the strategy file, and writes NOTHING on any refusal. Each of its refusals
# (`strategy_not_found`, `mission_not_found`, `not_active`, `no_revision`, `immutable_field`)
# is reported here BY NAME, and `already` is a success rather than a refusal: a mission that
# already carries every ref is left byte-identical.
#
# AN `undecided` CANDIDATE IS SKIPPED, NEVER DRAFTED. Which direction a mission answers is a
# reading only a person or a run can make (`list-standing-rulings.sh`), so a candidate the run
# did not judge reaches no writer at all and keeps its own hourly question.
#
# ═══ AND THE OPERATOR'S MERGE IS THE RULING ══════════════════════════════════════════
# `WORKAHOLIC_AUTO_MERGE` is never set here, and it would not matter if a caller set it:
# `publish-tree-pr.sh` derives `ruling_touching` from the tree being published and leaves the
# pull request open regardless (2026-08-28). Merging is the ruling; closing is the refusal.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BRANCHING="${SCRIPT_DIR}/../../branching/scripts"
CARRY="${SCRIPT_DIR}/../../strategy/scripts/carry-attribution.sh"
LIST="${SCRIPT_DIR}/list-standing-rulings.sh"

ROOT=".workaholic"
JUDGE_ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --judgement) JUDGE_ARGS="${JUDGE_ARGS} --judgement '$(printf '%s' "${2:-}" | sed "s/'/'\\\\''/g")'"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

json_str() { printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-300; }

emit_stop() {
  printf '{"ok": true, "readable": false, "reason": "%s", "drafted": 0, "rulings": [], "refused": [], "published": false, "pr_url": "", "merged": false, "merge_reason": "", "publish_reason": "not_attempted"}\n' \
    "$(json_str "$1")"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_stop "jq_unavailable"
[ -f "$LIST" ] || emit_stop "no_standing_rulings_reader"
[ -f "$CARRY" ] || emit_stop "no_carry_attribution_script"

# --- 1. Open the publish tree -------------------------------------------------------
OPEN_OUT="$(sh "${BRANCHING}/open-publish-tree.sh" 2>/dev/null || true)"
[ -n "$OPEN_OUT" ] && printf '%s' "$OPEN_OUT" | jq -e . >/dev/null 2>&1 || emit_stop "publish_tree_unreadable"
[ "$(printf '%s' "$OPEN_OUT" | jq -r '.ok // false')" = "true" ] \
  || emit_stop "publish_tree_$(printf '%s' "$OPEN_OUT" | jq -r '.reason // "unopened"')"
PUB="$(printf '%s' "$OPEN_OUT" | jq -r '.path')"

close_tree() { sh "${BRANCHING}/close-publish-tree.sh" >/dev/null 2>&1 || true; }

# --- 2. Read the candidate set inside that tree, with the run's judgements -----------
# `--root` is the tree's own bundle: the rulings must be derived from the base this pull
# request will be opened against.
RULINGS="$(eval "sh \"\$LIST\" --root \"\${PUB}/.workaholic\"${JUDGE_ARGS}" 2>/dev/null || true)"
if [ -z "$RULINGS" ] || ! printf '%s' "$RULINGS" | jq -e . >/dev/null 2>&1; then
  close_tree
  emit_stop "rulings_unreadable"
fi
# A DEGRADED READ DRAFTS NOTHING. A ruling that could not be read is not a ruling, and the
# operator must never be handed a pull request assembled from half a set.
if [ "$(printf '%s' "$RULINGS" | jq -r '.readable // false')" != "true" ]; then
  reason="$(printf '%s' "$RULINGS" | jq -r '.reason // "rulings_unreadable"')"
  close_tree
  emit_stop "$reason"
fi

REFUSED="$(printf '%s' "$RULINGS" | jq -c '.judgement.refused // []')"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
: > "${TMP}/results"
: > "${TMP}/files"

# --- 3. Carry each judged attribution, through the one writer that owns that line ----
printf '%s' "$RULINGS" \
  | jq -r '.rulings[]? | select(.kind == "attribution" and .decision != "undecided")
           | .subject + "\t" + .decision' > "${TMP}/todo"

while IFS='	' read -r mission strategy; do
  [ -n "$mission" ] || continue
  out="$( cd "$PUB" && sh "$CARRY" "$strategy" "$mission" .workaholic 2>/dev/null || true )"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "writer_unreadable" >> "${TMP}/results"
    continue
  fi
  if [ "$(printf '%s' "$out" | jq -r '.carried // false')" = "true" ]; then
    if [ "$(printf '%s' "$out" | jq -r '.reason // ""')" = "already" ]; then
      printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "already" >> "${TMP}/results"
    else
      printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "carried" >> "${TMP}/results"
      printf '.workaholic/missions/active/%s/mission.md\n' "$mission" >> "${TMP}/files"
    fi
  else
    printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" \
      "$(printf '%s' "$out" | jq -r '.reason // "refused"')" >> "${TMP}/results"
  fi
done < "${TMP}/todo"

DRAFTED=$(grep -c . "${TMP}/files" 2>/dev/null || true)
[ -n "$DRAFTED" ] || DRAFTED=0

# --- 4. Publish, or close the tree having written nothing ---------------------------
PUBLISHED=false
PR_URL=""
MERGED=false
MERGE_REASON=""
PUBLISH_REASON="nothing_to_draft"

if [ "$DRAFTED" -gt 0 ]; then
  BODY_WHY="An operator ruling the loop cannot make itself, drafted as a diff so merging is the ruling and closing is the refusal."
  BODY_CHANGES="$(awk -F'\t' '$4 == "carried" { printf "- %s: carry the refs of `%s` onto mission `%s`\n", $1, $3, $2 }' "${TMP}/results")"
  BODY_EVIDENCE="$(printf '%s' "$RULINGS" | jq -r '.rulings[]? | select(.decision != "undecided")
      | "- `" + .subject + "` -> `" + .decision + "` (" + (.evidence | tostring) + ")"')"
  FILES="$(paste -sd' ' - < "${TMP}/files")"
  # Run from the CALLER'S checkout, not from inside the publish tree: `publish-tree-pr.sh`
  # resolves `.publish/` from the repository root, and inside that tree the root is the tree.
  PR_OUT="$( WORKAHOLIC_PR_TITLE="[Ruling] Standing rulings for the operator" \
    sh "${BRANCHING}/publish-tree-pr.sh" \
      "Carry the operator's standing rulings" \
      "$BODY_WHY" \
      "$BODY_CHANGES" \
      "Each ruling is the operator's to make: merging this pull request is the ruling, closing it is the refusal. Nothing here auto-merges." \
      "$BODY_EVIDENCE" \
      "Read back by strategy/scripts/attributed-work.sh and gather/scripts/identity.sh once merged." \
      $FILES 2>/dev/null || true )"
  if [ -n "$PR_OUT" ] && printf '%s' "$PR_OUT" | jq -e . >/dev/null 2>&1 \
     && [ "$(printf '%s' "$PR_OUT" | jq -r '.ok // false')" = "true" ]; then
    PUBLISHED=true
    PR_URL="$(printf '%s' "$PR_OUT" | jq -r '.pr_url // ""')"
    MERGED="$(printf '%s' "$PR_OUT" | jq -r '.merged // false')"
    MERGE_REASON="$(printf '%s' "$PR_OUT" | jq -r '.merge_reason // ""')"
    PUBLISH_REASON="published"
  else
    PUBLISH_REASON="publish_$(printf '%s' "$PR_OUT" | jq -r '.reason // "unreadable"' 2>/dev/null || printf 'unreadable')"
  fi
fi

close_tree

jq -nc \
  --rawfile results "${TMP}/results" \
  --argjson refused "$REFUSED" \
  --argjson drafted "$DRAFTED" \
  --arg published "$PUBLISHED" \
  --arg pr_url "$PR_URL" \
  --arg merged "$MERGED" \
  --arg merge_reason "$MERGE_REASON" \
  --arg publish_reason "$PUBLISH_REASON" '
  ($results | split("\n") | map(select(length > 0) | split("\t")
    | {kind: .[0], subject: .[1], decision: .[2], status: .[3]})) as $r
  | {ok: true, readable: true, reason: "",
     drafted: $drafted,
     rulings: $r,
     refused: $refused,
     published: ($published == "true"),
     pr_url: $pr_url,
     merged: ($merged == "true"),
     merge_reason: $merge_reason,
     publish_reason: $publish_reason}'
