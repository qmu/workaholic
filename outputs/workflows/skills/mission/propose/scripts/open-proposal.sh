#!/bin/sh -eu
# open-proposal.sh — THE ONE WRITER of a `/propose` proposal, and its only write is a
# GitHub issue. Nothing is written into the repository: no file, no commit, no branch, no
# pull request. `/propose` is a pure reader of this tree that speaks to the loop's own
# inbound surface, which is why it never touches the unattended-`main`-writer class
# `workaholic:ship` §7 refused twice.
#
# Usage: open-proposal.sh --strategy <slug> --move depth|breadth|contraction \
#                         --title "<title>" [--workaholic-root <dir>] <body-file>
# Output: {"ok": true, "url": "...", "number": N, "strategy": "<slug>", "move": "<move>",
#          "title": "<stamped title>", "assigned": <bool>}
#      or {"ok": false, "reason": "...", "detail": "..."} — exit 0 on a refusal, so a tick
#          reports it and continues rather than dying mid-run.
#
# ═══ WHY THE OUTPUT IS AN ISSUE AND NOT A FEEDBACK RECORD ════════════════════════════
# `[Specificate]`'s unattended entrance is `list-inbound-issues.sh`: the open GitHub issues
# assigned to the running identity. A record written straight into `.workaholic/feedbacks/`
# is NOT discovered, because discovery reads issues, not files — so a proposal filed as a
# record would be a message the loop cannot receive, and the loop would not close. This is
# the same conclusion `/fb`'s in-repo path reached (mission `register-every-fb-as-an-issue`)
# and for the same reason, so the same writer is reused rather than a second one written:
# `feedback/scripts/open-issue.sh`, which has no destination opinion and no identity opinion.
#
# AND NO RECORD IS WRITTEN ALONGSIDE IT, deliberately. `list-inbound-issues.sh` excludes an
# open issue that a feedback record already names (`already_captured`), so writing a record
# here would SUPPRESS this proposal's own ingestion — the exact defect `/fb` measured. The
# record for this ask is written by the `[Specificate]` run that takes it in hand.
#
# THE ASSIGNEE IS LOAD-BEARING. An unassigned issue is ingested by nobody, because
# discovery lists only issues assigned to the running identity and never unassigned ones.
# The login comes from `gh api user` — the identity that is about to be running the next
# `[Specificate]` tick — and `survey-strategies.sh` has already refused any strategy this
# identity does not own, so the issue's assignee and the strategy's owner are the same
# person by construction, not by hope.
#
# ═══ THE THREE HEADER LINES, AND WHY THEY ARE VISIBLE ════════════════════════════════
# This script — never the caller — writes the first three lines of the body:
#
#   kind: instruction / source: development / subject: observer_ai:[Propose] routine
#   strategy: <slug> / move: <move>
#   feedback: <ref>, <ref>
#
# Line 3 is emitted by `feedback/scripts/ask-feedback-line.sh`, the ONE writer of this
# line (2026-08-26) — lines 1 and 2 stay here, because they are this script's own markers.
#
# Line 1 carries the judgment axes `/specificate` would otherwise have to guess, in the
# shape `/fb` already uses. Line 2 is the marker `list-open-proposals.sh` reads for the
# in-flight gate. Line 3 is what CLOSES THE LOOP and it is the least obvious line in this
# file: it names the strategy's OWN feedback refs so that the mission or ticket
# `/specificate` emits carries them alongside the record that run writes. Without it the
# emitted work would cite only the new record, `strategy.feedback[] ∩ artifact.feedback[]`
# would be empty, and `attributed-work.sh` would never see the work this loop produced —
# the loop would turn and leave no trace on the direction that asked for it. Carrying the
# refs forward uses the existing MANY-VALUED `feedback:` relation exactly as designed and
# adds NO FIELD to any artifact, which is what keeps the retired `strategy:` relation and
# its ownership hop retired (`workaholic:strategy`, *Its relation to missions*).
#
# ALL THREE ARE VISIBLE TEXT, not an HTML comment. A hidden marker would be a fact the loop
# depends on that no human reading the issue can see, and the one thing this loop must never
# become is a machine conversation a person cannot follow.
#
# ═══ THE FLOOR IS PRESENCE, NEVER QUALITY — AND THAT IS THE POINT ════════════════════
# `--move` is required and closed-set, and the body must carry five headings:
#
#   ## What to change                       the change, in the imperative
#   ## Why this commits to the strategy     the tie to the Aim, not to the codebase
#   ## What this is chosen against          the fork not taken
#   ## Experience                           what the mission demands, once it lands
#   ## Tickets                              the ordered set, two or more
#
# THE UNIT IS A MISSION, NOT A CHANGE (2026-08-26, the operator's ask). A proposal plans a
# whole mission — a title (the issue's), the experience it demands, and an ordered ticket
# set — and the move is declared over that mission rather than over one edit. The
# anti-housekeeping effect comes from the SCALE as much as from the refusals: a
# mission-sized proposal cannot be "add a test" without saying so out loud.
#
# `## Tickets` carries a **two-or-more** floor, `under_planned`, mirroring
# `mission/scripts/check-floor.sh` in both discipline and wording: the count is judged in
# one place and the refusal NAMES THE ALTERNATIVE, because a proposal naming one unit of
# work is a plain ticket's worth of direction, not a mission's. The ruled scale — roughly
# 7–8 tickets, with a follow-up repair mission of 3–4 available — is stated in
# `SKILL.md` and stays the RUN'S JUDGEMENT: a floor is checkable, "roughly seven" is not,
# and this script has never pretended to grade a proposal.
#
# The third is the anti-hedging floor and the one that does the most work. `/propose` is
# defined against housekeeping: "tidy this up", "the docs drifted", "add a test" are
# `/moderate`'s job, and what they have in common is that they are chosen against NOTHING —
# nobody would argue for the mess. A proposal that cannot name what it is choosing against
# is either uncontroversial (housekeeping) or unformed, and both are refused here. Like
# every other write floor in this repository this checks PRESENCE, never quality: it cannot
# read whether the section is honest, and it does not pretend to.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts/"
FEEDBACK_SCRIPTS="${SCRIPT_DIR}/../../feedback/scripts/"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

STRATEGY=""; MOVE=""; TITLE=""; ROOT=".workaholic"
while [ $# -gt 0 ]; do
  case "$1" in
    --strategy) STRATEGY="${2:-}"; shift 2 ;;
    --move) MOVE="${2:-}"; shift 2 ;;
    --title) TITLE="${2:-}"; shift 2 ;;
    --workaholic-root) ROOT="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage", "detail": "unknown flag"}'; exit 0 ;;
    *) break ;;
  esac
done
BODY_FILE="${1:-}"

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}
refuse() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

[ -n "$STRATEGY" ] || refuse "no_strategy" "--strategy is required"
[ -n "$TITLE" ] || refuse "no_title" "--title is required"
case "$MOVE" in
  depth|breadth|contraction) ;;
  "") refuse "no_move" "--move is required: depth | breadth | contraction" ;;
  *) refuse "unknown_move" "$MOVE is not depth, breadth or contraction" ;;
esac
[ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] || refuse "no_body" "a readable body file is required"
[ -s "$BODY_FILE" ] || refuse "no_body" "the body file is empty"

for heading in "## What to change" "## Why this commits to the strategy" "## What this is chosen against" "## Experience" "## Tickets"; do
  grep -qxF "$heading" "$BODY_FILE" || refuse "missing_section" "the body carries no '${heading}' section"
done

# The ticket floor, counted over the `## Tickets` section only — an ordered list item or a
# bullet, up to the next `## ` heading.
TICKETS=$(awk '
/^## Tickets[ \t]*$/ { inside = 1; next }
inside && /^## / { inside = 0 }
inside && /^[ \t]*([0-9]+\.|[-*])[ \t]+[^ \t]/ { n++ }
END { print n + 0 }
' "$BODY_FILE")
if [ "$TICKETS" -lt 2 ]; then
  refuse "under_planned" "the '## Tickets' section names ${TICKETS} ticket(s); a mission is proposed with two or more. One unit of work is a plain ticket's worth of direction - say so in the body and propose a mission that decomposes, or let /fb carry the bare direction."
fi

READ="$(sh "${STRATEGY_SCRIPTS}/read.sh" "$STRATEGY" "$ROOT" 2>/dev/null || true)"
[ -n "$READ" ] || refuse "strategy_unreadable" "read.sh produced no output for ${STRATEGY}"
command -v jq >/dev/null 2>&1 || refuse "jq_unavailable" "jq is not on PATH"
[ "$(printf '%s' "$READ" | jq -r '.found // false')" = "true" ] || refuse "strategy_not_found" "$STRATEGY"
[ "$(printf '%s' "$READ" | jq -r '.status // ""')" = "active" ] || refuse "strategy_not_active" "$STRATEGY"
# `read.sh` emits `feedback` as the raw comma-separated frontmatter STRING, not an array —
# unlike `attributed-work.sh`, whose `feedback_refs` is a list. Both shapes are accepted
# here rather than one of them being normalised elsewhere: this script is the only caller
# that needs the wire form, and widening a shared reader's output to suit one caller is how
# two readers of one relation start disagreeing.
REFS="$(printf '%s' "$READ" | jq -r 'if (.feedback | type) == "array" then (.feedback | join(", ")) else (.feedback // "") end')"
[ -n "$REFS" ] || refuse "no_feedback_refs" "${STRATEGY} cites no feedback record, so nothing could be attributed back to it"

command -v gh >/dev/null 2>&1 || refuse "gh_unavailable" "gh is not on PATH"
login="$(gh api user --jq .login 2>&1)" || refuse "identity_unresolved" "$login"
[ -n "$login" ] || refuse "identity_unresolved" "gh api user returned an empty login"
repo_slug="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1)" || refuse "slug_unresolved" "$repo_slug"

COMPOSED="$(mktemp)"
trap 'rm -f "$COMPOSED"' EXIT INT TERM
{
  printf 'kind: instruction / source: development / subject: observer_ai:[Propose] routine\n'
  printf 'strategy: %s / move: %s\n' "$STRATEGY" "$MOVE"
  # Line 3 goes through the ONE writer of this line (2026-08-26): the sweep and `/fb` are
  # about to want the same line, and the reader's own header forbids a second parser --
  # so the writing side gets the same single-writer treatment before it is multiplied.
  sh "${FEEDBACK_SCRIPTS}/ask-feedback-line.sh" "$REFS"
  printf '\n'
  printf 'This ask was opened by the `[Propose]` routine against the strategy named above.\n'
  printf 'Carry the `feedback:` refs on that line onto whatever this proposal becomes, so the\n'
  printf 'work stays attributable to the direction that asked for it.\n\n'
  cat "$BODY_FILE"
} > "$COMPOSED"

SCAN="$(sh "${FEEDBACK_SCRIPTS}/scan-outbound-body.sh" "$COMPOSED" 2>/dev/null || true)"
if [ -n "$SCAN" ] && [ "$(printf '%s' "$SCAN" | jq -r '.verdict // "pass"')" = "block" ]; then
  refuse "scan_blocked" "$(printf '%s' "$SCAN" | jq -c '.findings')"
fi

OPENED="$(sh "${FEEDBACK_SCRIPTS}/open-issue.sh" --assignee "$login" "$repo_slug" "$TITLE" "$COMPOSED" 2>&1 || true)"
if [ -z "$OPENED" ] || [ "$(printf '%s' "$OPENED" | jq -r '.ok // false' 2>/dev/null || echo false)" != "true" ]; then
  refuse "open_failed" "$OPENED"
fi

printf '%s' "$OPENED" | jq -c --arg s "$STRATEGY" --arg m "$MOVE" \
  '{ok: true, url: .url, number: (.url | split("/") | last | tonumber),
    strategy: $s, move: $m, assigned: (.assigned // false)}'
