#!/bin/sh -eu
# THE CARRY FLOOR, AS A VERDICT THE PUBLISH SEAM CAN ACT ON.
#
#   check-carry-floor.sh [--refs "<ref>,<ref>"]... <artifact-path>...
#
# Output: {"ok", "checked", "missing": [{"artifact", "ref"}], "reason", "repair"}
#   exit 0 when the floor holds, exit 1 when it does not -- so a seam that forgets to read
#   the JSON still fails rather than publishing a violation. The refusal rides stderr, the
#   pass rides stdout, exactly as `mission/scripts/check-floor.sh` does.
#
# THE RULE: when the ask carried feedback refs that RESOLVED and the run emitted a mission
# or a ticket, those refs must be on what it emitted. Reading the ask's line
# (`read-ask-feedback-refs.sh`) and reporting it still leaves the failure reachable -- a run
# that reads the refs and then forgets to pass them to `scaffold-draft.sh` /
# `scaffold-proposed-ticket.sh` publishes a mission whose `feedback:` list is missing the
# strategy's refs, and the loss reaches `main`. Downstream it reads as
# `no_citing_artifacts`, which is byte-identical to a direction nothing has answered yet:
# the failure is invisible AND self-perpetuating, because `/propose` treats
# `no_citing_artifacts` as explicitly not a refusal.
#
# WHY A SEAM CHECK AND NOT A WRITE-TIME ONE, and why here. This is the same shape and the
# same seam as the two-ticket floor: the artifacts do not all exist while any one of them is
# being authored, so the only place the question is answerable is after the set is written
# and before it is published. The count-in-one-place reasoning applies unchanged -- the
# alternative is an inline comparison at each publishing path, and four inline checks drift.
#
# THE RELATION IS READ THROUGH ITS ONE READER. `read-feedback-relation.sh` is the single
# reader of an artifact's `feedback:` list and its header states the rule: two parsers of one
# field eventually disagree, and the side that under-reads re-proposes answered feedback. A
# floor that parsed frontmatter itself would be exactly that second parser, and it would fail
# in the worst direction -- refusing correct publishes, or passing broken ones, depending on
# which side under-read.
#
# ═══ WHAT IT DELIBERATELY DOES NOT CHECK ═════════════════════════════════════════════
# * NOT WHETHER THE WORK ADVANCES THE DIRECTION. This checks a string in a file. Whether a
#   mission actually serves the strategy that asked for it is a judgment, and no floor in
#   this repository has ever pretended to make one (`open-proposal.sh`: the floor is
#   presence, never quality).
# * NOT EVERY ARTIFACT. The caller names WHICH artifacts must carry the refs -- the mission
#   when there is one, the loose ticket when there is not. A mission's tickets need not
#   repeat its refs: `attributed-work.sh` already reaches a ticket through
#   `via_mission:<slug>`, so demanding them everywhere would force noise into every ticket's
#   frontmatter to buy an attribution that already works.
# * NOT A REF THAT DID NOT RESOLVE. The reader already dropped those with a reason; a run
#   cannot be required to carry a record that does not exist.
# * NOTHING WHEN THERE IS NOTHING TO CHECK. No refs on the ask, or a record-only outcome
#   that emitted no artifact, is `ok: true` with `checked: 0` -- a real pass, not a
#   degradation. A record-only run reports the refs it WOULD have carried (step 13); it is
#   not this script's business to turn that into a refusal.
#
# It adds no field to any artifact and reads no relation that does not already exist, so the
# `strategy:` relation retired on 2026-07-28 and its ownership hop stay retired.
#
# `checked` counts the (artifact, ref) PAIRS examined -- the size of what was proved, not the
# size of either input, so a pass over two artifacts and three refs cannot be mistaken for a
# pass that examined nothing.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
READER="${SCRIPT_DIR}/read-feedback-relation.sh"

REFS=""
ARTIFACTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --refs) REFS="${REFS}${REFS:+,}${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage", "repair": "check-carry-floor.sh [--refs \"<ref>,<ref>\"] <artifact-path>..."}' >&2; exit 1 ;;
    *) break ;;
  esac
done
for a in "$@"; do
  ARTIFACTS="${ARTIFACTS}${a}
"
done

# Normalise the ref list exactly as both readers of this relation normalise it, so the
# floor cannot refuse over a difference in whitespace or bracketing.
REF_LIST="$(printf '%s\n' "$REFS" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true)"

esc() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

if [ -z "$REF_LIST" ]; then
  printf '{"ok": true, "checked": 0, "missing": [], "reason": "no_refs_carried"}\n'
  exit 0
fi

if [ -z "$ARTIFACTS" ]; then
  printf '{"ok": true, "checked": 0, "missing": [], "reason": "record_only"}\n'
  exit 0
fi

missing=""
checked=0
absent=""

while IFS= read -r artifact; do
  [ -n "$artifact" ] || continue
  if [ ! -r "$artifact" ]; then
    absent="${absent}${absent:+, }\"$(esc "$artifact")\""
    continue
  fi
  # `</dev/null` so the reader cannot consume the heredoc this loop is reading from.
  have="$(sh "$READER" "$artifact" </dev/null 2>/dev/null || true)"
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    checked=$((checked + 1))
    found=0
    # A plain substring test would match a ref that is a suffix of another; compare the
    # reader's output line by line instead.
    if [ -n "$have" ]; then
      printf '%s\n' "$have" | grep -qxF -- "$ref" && found=1 || found=0
    fi
    [ "$found" = "1" ] && continue
    missing="${missing}${missing:+, }{\"artifact\": \"$(esc "$artifact")\", \"ref\": \"$(esc "$ref")\"}"
  done <<REFS
${REF_LIST}
REFS
done <<ARTIFACTS
${ARTIFACTS}
ARTIFACTS

# A named artifact that is not there is its own refusal, never a silent pass: the caller
# asserted it emitted that file, and the floor cannot prove anything about a file it
# cannot read.
if [ -n "$absent" ]; then
  printf '{"ok": false, "checked": %d, "missing": [%s], "unreadable": [%s], "reason": "artifact_unreadable", "repair": "%s"}\n' \
    "$checked" "$missing" "$absent" \
    "name the paths the run actually emitted, relative to the publish tree; the floor cannot read the one(s) listed under \\\"unreadable\\\"." >&2
  exit 1
fi

if [ -n "$missing" ]; then
  # The repair names WHAT TO RE-RUN, not just the rule. A refusal stating only the rule
  # leaves the caller retrying the same thing (implementation/observability); here the
  # artifacts are already scaffolded and the record is already written, so the correct
  # action is to put the refs on what exists and re-check before step 10 publishes.
  joined="$(printf '%s\n' "$REF_LIST" | tr '\n' ' ' | sed -e 's/[[:space:]]*$//')"
  printf '{"ok": false, "checked": %d, "missing": [%s], "reason": "carried_ref_missing", "repair": "%s"}\n' \
    "$checked" "$missing" \
    "put every carried ref on the emitted artifact before publishing: re-run scaffold-draft.sh (a mission) or scaffold-proposed-ticket.sh --loose --feedback (a loose ticket) with the record from step 3 followed by: $(esc "$joined") -- or add the missing ref(s) to that artifact's feedback: list, then re-run this check. Do not publish and do not fall back to record-only: the record is already written and the artifacts already exist." >&2
  exit 1
fi

printf '{"ok": true, "checked": %d, "missing": []}\n' "$checked"
