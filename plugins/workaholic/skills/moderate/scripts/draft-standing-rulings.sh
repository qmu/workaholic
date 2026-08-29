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
# ═══ THE PULL REQUEST NAMES WHAT IT RULES ON, VISIBLY ════════════════════════════════
# One `ruling: <kind> / subject: <subject>` line per drafted subject goes into the body, in
# the same shape `/propose` puts `strategy: … / move: …` on an issue. `list-open-rulings.sh`
# reads it back — as a brake, and as the set of subjects whose hourly question is held while
# the diff already carries the ask. It is VISIBLE text and never an HTML comment: a fact the
# loop depends on that no human reading the pull request can see is a machine conversation a
# person cannot follow.
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
RULINGS="$(eval "sh \"\$LIST\" --root \"\${PUB}/\${ROOT}\"${JUDGE_ARGS}" 2>/dev/null || true)"
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
  out="$( cd "$PUB" && sh "$CARRY" "$strategy" "$mission" "$ROOT" 2>/dev/null || true )"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "writer_unreadable" >> "${TMP}/results"
    continue
  fi
  if [ "$(printf '%s' "$out" | jq -r '.carried // false')" = "true" ]; then
    if [ "$(printf '%s' "$out" | jq -r '.reason // ""')" = "already" ]; then
      printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "already" >> "${TMP}/results"
    else
      printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" "carried" >> "${TMP}/results"
      printf '%s/missions/active/%s/mission.md\n' "$ROOT" "$mission" >> "${TMP}/files"
    fi
  else
    printf '%s\t%s\t%s\t%s\n' attribution "$mission" "$strategy" \
      "$(printf '%s' "$out" | jq -r '.reason // "refused"')" >> "${TMP}/results"
  fi
done < "${TMP}/todo"

# --- 3b. Carry each judged mapping ruling, as a LIVE line ---------------------------
# `apply-bootstrap.sh` writes the proposed line as a COMMENT, because which account an
# address belongs to is a human's ruling and that repair proposes without deciding. Here the
# ruling HAS been made — by the run, as a judgement it hands in — so the line goes in live and
# the operator's MERGE is what makes it true. An unjudged address is untouched and keeps both
# its comment and its `undrivable-unit` question; nothing about `apply-bootstrap.sh` or
# `audit-identity-coverage.sh` moves.
: > "${TMP}/evidence"
MAP_REL=".claude/git-identities"
MAP="${PUB}/${MAP_REL}"

map_pairs() {
  # `<login>\t<address>` for every address the file names, through the format `identity.sh`
  # reads. Used only to ASSERT that a write added exactly one pair and dropped none.
  awk -F= '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    NF < 2 { next }
    { login = $1; sub(/^[[:space:]]+/, "", login); sub(/[[:space:]]+$/, "", login)
      value = $0; sub(/^[^=]*=/, "", value)
      sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value)
      if (login == "" || value == "") next
      n = split(value, parts, ",")
      for (i = 1; i <= n; i++) { a = parts[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", a)
                                 if (a != "") printf "%s\t%s\n", login, a } }
  ' "${1:-/dev/null}" 2>/dev/null | sort
}

printf '%s' "$RULINGS" \
  | jq -r '.rulings[]? | select(.kind == "identity_mapping" and .decision != "undecided")
           | .subject + "\t" + .decision' > "${TMP}/todo-map"

while IFS='	' read -r address login; do
  [ -n "$address" ] || continue
  # THE FILE'S ABSENCE IS A BOOTSTRAP REPAIR, NOT A RULING. `apply-bootstrap.sh` owns the
  # header it scaffolds; writing a second copy here is how two owners of one format drift.
  if [ ! -f "$MAP" ]; then
    printf '%s\t%s\t%s\t%s\n' identity_mapping "$address" "$login" "no_mapping_file" >> "${TMP}/results"
    continue
  fi
  ans="$(sh "${SCRIPT_DIR}/../../gather/scripts/identity.sh" "$address" "$MAP" 2>/dev/null || true)"
  if [ -n "$ans" ] && [ "$(printf '%s' "$ans" | jq -r '.resolved // false' 2>/dev/null || printf false)" = "true" ]; then
    # Already named live. Never a duplicate line and never a rewrite.
    printf '%s\t%s\t%s\t%s\n' identity_mapping "$address" "$login" "already" >> "${TMP}/results"
    continue
  fi
  matches=$(grep -c "^[[:space:]]*${login}=" "$MAP" 2>/dev/null || true)
  [ -n "$matches" ] || matches=0
  map_pairs "$MAP" > "${TMP}/pairs-before"
  case "$matches" in
    0)
      # A login the mapping does not name yet: one new live line, appended.
      printf '%s=%s\n' "$login" "$address" >> "$MAP"
      status=mapped ;;
    1)
      # The login already has a line, so a SECOND line would be dead weight: `identity.sh`
      # takes the first row a login matches, and a second row would resolve this address to
      # ITSELF as canonical — leaving `owns.sh` answering `other` exactly as it does today.
      # The format's own second field is what makes one person's addresses one person, so the
      # address is appended there. Nothing is replaced, dropped or reordered, which is what
      # the assertion below proves rather than trusts.
      awk -v login="$login" -v addr="$address" '
        $0 ~ "^[[:space:]]*" login "=" && !done { printf "%s,%s\n", $0, addr; done = 1; next }
        { print }
      ' "$MAP" > "${TMP}/map-cand"
      cp "${TMP}/map-cand" "$MAP"
      status=alias_appended ;;
    *)
      printf '%s\t%s\t%s\t%s\n' identity_mapping "$address" "$login" "login_ambiguous" >> "${TMP}/results"
      continue ;;
  esac
  # APPEND-ONLY, ASSERTED. Every address the file named before must still be named, and
  # exactly one may be new. A write that fails this is reverted from the pre-image rather
  # than shipped, because a wrong mapping line makes work drivable by the wrong person.
  map_pairs "$MAP" > "${TMP}/pairs-after"
  lost=$(comm -23 "${TMP}/pairs-before" "${TMP}/pairs-after" | grep -c . || true)
  gained=$(comm -13 "${TMP}/pairs-before" "${TMP}/pairs-after" | grep -c . || true)
  if [ "${lost:-0}" -ne 0 ] || [ "${gained:-0}" -ne 1 ]; then
    ( cd "$PUB" && git checkout -- "$MAP_REL" 2>/dev/null ) || true
    printf '%s\t%s\t%s\t%s\n' identity_mapping "$address" "$login" "not_append_only" >> "${TMP}/results"
    continue
  fi
  ( cd "$PUB" && git add "$MAP_REL" 2>/dev/null ) || true
  printf '%s\t%s\t%s\t%s\n' identity_mapping "$address" "$login" "$status" >> "${TMP}/results"
  grep -qxF "$MAP_REL" "${TMP}/files" 2>/dev/null || printf '%s\n' "$MAP_REL" >> "${TMP}/files"
  # THE GIT HISTORY THAT SUPPORTS THE JUDGEMENT, so the operator rules on evidence rather
  # than on the machine's assertion: how many commits that address authored, and under which
  # author names — the closest thing git holds to the login being claimed.
  n_commits=$( cd "$PUB" && git log --all --format='%ae' 2>/dev/null | grep -cxF "$address" || true )
  names=$( cd "$PUB" && git log --all --format='%ae	%an' 2>/dev/null \
           | awk -F'	' -v a="$address" '$1 == a { print $2 }' | sort -u | paste -sd', ' - || true )
  printf -- '- `%s` -> login `%s`: %s commit(s) in this history, authored as: %s\n' \
    "$address" "$login" "${n_commits:-0}" "${names:-none recorded}" >> "${TMP}/evidence"
done < "${TMP}/todo-map"

DRAFTED=$(grep -c . "${TMP}/files" 2>/dev/null || true)
[ -n "$DRAFTED" ] || DRAFTED=0

# --- 4. Publish, or close the tree having written nothing ---------------------------
PUBLISHED=false
PR_URL=""
MERGED=false
MERGE_REASON=""
PUBLISH_REASON="nothing_to_draft"

if [ "$DRAFTED" -gt 0 ]; then
  # THE MARKERS RIDE `why`, WHICH IS THE ONE ARGUMENT THE PULL-REQUEST BODY RENDERS
  # (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`). They were
  # composed into `changes` — argument 3 — which `publish-tree-pr.sh` forwards to `commit.sh`
  # and never writes into the body: that body is `## Overview` (from `why`) plus the seam's own
  # generated `## Artifacts` and `## Notes`. So every marker this script has ever written landed
  # in the COMMIT MESSAGE, `list-open-rulings.sh` read the body and found none, and
  # `ruling-suppression.sh` answered `held: {}` for every open ruling — measured verbatim on
  # #694, whose commit message carries all four lines and whose body carries none.
  #
  # The seam gains NO body-fragment parameter: its positionals are `commit.sh`'s and end in an
  # open-ended `[files...]`, so a new one could not be told from a filename, and a second
  # body-composition path would exist for every publication rather than for this one caller.
  # The markers stay VISIBLE text under `## Overview`, each on its own line, which is what
  # `list-open-rulings.sh`'s `^ruling: ` match reads and what a person reading the pull request
  # can follow.
  BODY_WHY="An operator ruling the loop cannot make itself, drafted as a diff so merging is the ruling and closing is the refusal.

$(awk -F'\t' '$4 == "carried" || $4 == "mapped" || $4 == "alias_appended" { printf "ruling: %s / subject: %s\n", $1, $2 }' "${TMP}/results")"
  BODY_CHANGES="$(awk -F'\t' '
    $4 == "carried" { printf "- attribution: carry the refs of `%s` onto mission `%s`\n", $3, $2 }
    $4 == "mapped" { printf "- identity mapping: name `%s` as login `%s` (new entry)\n", $2, $3 }
    $4 == "alias_appended" { printf "- identity mapping: name `%s` as another address of login `%s`\n", $2, $3 }
  ' "${TMP}/results")"
  BODY_EVIDENCE="$(printf '%s' "$RULINGS" | jq -r '.rulings[]? | select(.decision != "undecided")
      | "- `" + .subject + "` -> `" + .decision + "` (" + (.evidence | tostring) + ")"'
    cat "${TMP}/evidence")"
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
