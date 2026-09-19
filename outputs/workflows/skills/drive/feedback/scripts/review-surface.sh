#!/bin/sh -eu
# THE ONE READER of the review surface a person's ask named — the package, route,
# screen or page they will look at to judge whether the work landed.
#
# WHY IT EXISTS (2026-09-19, ticket `20260919094701`). `feedback-outcome.sh` has
# always compared an `expected_surface` against a `verified_surface`, and a tree-wide
# walk found `expected_surface` in exactly two files, in both as an INPUT. No artifact
# carried it, so the value the gate compared was whatever the agent composing the facts
# wrote at report time — the one party whose claim the gate exists to check. A gate
# whose input is asserted by the party it checks is not a gate.
#
# THE ARTIFACT IS THE FEEDBACK RECORD, and why that one rather than the ticket or the
# mission is stated once, in the writer's own header (`create.sh`, beside this file).
# Nothing is restated here.
#
# AND IT LIVES IN THIS SKILL RATHER THAN BESIDE ITS ONE CONSUMER, deliberately: this
# skill defines the record's schema and owns its scripts, and a reader placed in `work/`
# would pull that whole skill -- and transitively `moderate/` and `workaholify/` -- into
# the cross-agent closure of every bundle carrying `feedback` (`drive/SKILL.md` names
# the same hazard for the condition-age reader). Measured at the build: 18 directories
# of unrelated skill appeared in `outputs/workflows/` the first time it was written there.
#
#   review-surface.sh <feedback-ref>...
#   review-surface.sh --stdin          # one ref per line, EMPTY LINES PRESERVED
#
# The stdin form exists because the answer is read back BY POSITION: an item whose
# `feedback` is empty must still produce a row, and an empty positional argument
# cannot survive the shell's own word splitting. A caller folding N items into N rows
# uses `--stdin`; a person asking about one record uses the positional form.
#
# Output: one JSON line
#   {"surfaces": [{"feedback": "<ref as given>", "surface": "<string>",
#                  "readable": true|false, "reason": "<word>"}...]}
#
# FOUR ANSWERS, NONE COLLAPSED INTO ANOTHER:
#   readable true,  surface "<value>"  — the ask named a surface and it was read.
#   readable true,  surface ""         — the record names none. The ORDINARY case:
#                                        most asks are not about a rendered screen,
#                                        and the consumer answers `surface_unresolved`.
#   readable false, reason record_not_found | record_unreadable | no_feedback_ref
#                                      — an absence of a READING, never an absence of
#                                        a surface. The consumer answers its own word
#                                        for it, distinct from `surface_unresolved`,
#                                        on the rule this repository applies to
#                                        `unanswerable` everywhere else.
#
# The record is resolved from the ref the item already carries: a leading `fb:` and a
# trailing `.md` are both stripped, because the stream's refs are written both ways
# (`unit-feedback-stems.sh` answers bare stems, `feedback:` lines carry filenames).
# Nothing else is normalised and no search is performed — a ref that does not name a
# record answers `record_not_found` rather than matching something that looks like it.
#
# PURE READ. It writes nothing, reaches no network, and exits 0 for every answer
# including an empty argument list.

set -eu

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DIR="${WORKAHOLIC_FEEDBACKS_DIR:-${ROOT}/.workaholic/feedbacks}"

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

refs_file=$(mktemp "${TMPDIR:-/tmp}/workaholic-review-surface.XXXXXX")
trap 'rm -f "$refs_file"' EXIT HUP INT TERM
if [ "${1:-}" = "--stdin" ]; then
  cat >"$refs_file"
else
  for ref in "$@"; do printf '%s\n' "$ref" >>"$refs_file"; done
fi

rows=""
while IFS= read -r ref; do
  stem=$ref
  case "$stem" in fb:*) stem=${stem#fb:} ;; esac
  case "$stem" in *.md) stem=${stem%.md} ;; esac

  surface=""
  readable=true
  reason=""

  if [ -z "$stem" ]; then
    readable=false; reason=no_feedback_ref
  elif [ ! -f "${DIR}/${stem}.md" ]; then
    readable=false; reason=record_not_found
  else
    # The frontmatter's own first block, and only that: a `review_surface:` line in the
    # body is prose about the field, not the field. `sed` stops at the closing `---`.
    block=$(sed -n '1{/^---$/!q};1d;/^---$/q;p' "${DIR}/${stem}.md" 2>/dev/null || printf '')
    if [ -z "$block" ]; then
      readable=false; reason=record_unreadable
    else
      surface=$(printf '%s\n' "$block" \
        | sed -n 's/^review_surface:[[:space:]]*//p' | head -1 \
        | sed -e 's/[[:space:]]*$//')
    fi
  fi

  rows="${rows:+${rows}, }{\"feedback\": \"$(json_escape "$ref")\", \"surface\": \"$(json_escape "$surface")\", \"readable\": ${readable}, \"reason\": \"${reason}\"}"
done <"$refs_file"

printf '{"surfaces": [%s]}\n' "$rows"
