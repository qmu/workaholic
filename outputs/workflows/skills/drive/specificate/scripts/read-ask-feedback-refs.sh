#!/bin/sh -eu
# THE SINGLE READER OF AN ASK'S OWN `feedback:` LINE.
#
#   read-ask-feedback-refs.sh [feedbacks-dir] < <the ask body>
#
# Output: {"line_found": true|false, "carried": [...], "dropped": [{"ref", "reason"}]}
#   exit 0 in EVERY case, including no line at all -- see *Exit discipline* below.
#
# THE ASK ARRIVES ON STDIN, not as a path, because the ask that matters most is a GitHub
# issue body (`/propose`'s proposal, `/fb`'s issue) and there is no file to name. A caller
# holding a file pipes it in; nothing here needs to know which it was.
#
# ═══ WHY THIS EXISTS AT ALL ══════════════════════════════════════════════════════════
# `reference/workflow.md` step 3b told the run to "read the line, verify each ref exists
# under `.workaholic/feedbacks/`, and pass the surviving refs to steps 8 and 9" -- BY EYE.
# The `feedback:` relation already has exactly one reader on the ARTIFACT side
# (`read-feedback-relation.sh`, whose header states the rule: two parsers of one field
# eventually disagree, and the side that under-reads re-proposes answered feedback). The
# ask's own line is a second surface of the same relation and it had no reader at all --
# which is the loop's fourth link carried by a paragraph. A forgotten carry leaves
# `strategy.feedback[] n artifact.feedback[]` empty, and `attributed-work.sh` then answers
# `no_citing_artifacts` -- byte-identical to a direction nothing has answered yet.
#
# THE WRITER IS THE AUTHORITY ON THE FORMAT. `propose/scripts/open-proposal.sh` composes
# the line as visible body text, deliberately, and writes it as the third line:
#
#   feedback: <ref>, <ref>
#
# The inline-list (`feedback: [a.md, b.md]`) and bare-scalar (`feedback: a.md`) forms are
# tolerated too, matching `read-feedback-relation.sh`'s normalisation exactly, so the two
# readers of this relation cannot disagree about what a ref IS.
#
# ONLY THE FIRST SUCH LINE IS READ, and only at the start of a line. An ask is prose a
# human or a routine wrote; the word can occur again further down (a quoted body, a code
# fence, a sentence about feedback), and reading every match would let ordinary prose
# inject refs into a published artifact.
#
# ═══ A REF IS RESOLVED, NEVER INVENTED AND NEVER REWRITTEN ═══════════════════════════
# Each ref is looked up as a plain filename under the feedbacks directory. What does not
# resolve is DROPPED WITH A NAMED REASON (implementation/observability) rather than
# guessed at, corrected, or silently discarded:
#
#   dir_missing      the feedbacks directory itself is absent -- a degraded read, which
#                    is not the same statement as "this record does not exist"
#   not_found        the directory is there and the record is not
#   unreadable       the path exists but cannot be read
#   not_a_filename   the ref is not a bare filename (it carries a path separator) -- the
#                    relation holds filenames, so this is malformed input, and resolving
#                    it would also let a ref reach outside the directory
#
# A dropped ref never blocks the proposal (SKILL.md, *Carry the ask's own feedback refs
# forward*); it is named in the run report and the pull-request body. A ref repeated on
# the line is carried once, in first-seen order.
#
# EXIT DISCIPLINE: exit 0 always. An ask with no `feedback:` line is the ORDINARY case --
# most asks are typed by a human and name nothing -- so a non-zero exit would make the
# common path look like a failure. `line_found: false` says which case it was, the same
# discipline `list-inbound-issues.sh` uses for its `{ok: false}`. This is a PURE READ: it
# resolves paths and writes nothing, so it is equally safe before and after the judgment.

set -eu

DIR="${1:-.workaholic/feedbacks}"

BODY="$(cat || true)"

# One awk pass, and it must distinguish "a line with no refs" from "no line": both would
# reduce to the empty string through `$(...)`, so the answer is prefixed with a flag byte.
RAW="$(printf '%s\n' "$BODY" | awk '
{
  if ($0 ~ /^[ \t]*feedback:[ \t]*/) {
    sub(/^[ \t]*feedback:[ \t]*/, "")
    sub(/[ \t]+$/, "")
    printf "1%s", $0
    found = 1
    exit
  }
}
END { if (!found) printf "0" }
' || printf '0')"

FOUND="$(printf '%s' "$RAW" | cut -c1)"
VALUE="$(printf '%s' "$RAW" | cut -c2-)"

if [ "$FOUND" = "1" ]; then
  line_found="true"
else
  line_found="false"
fi

# The same normalisation `read-feedback-relation.sh` applies to the artifact side.
REFS="$(printf '%s\n' "$VALUE" \
  | tr -d '[]' \
  | tr ',' '\n' \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v '^$' || true)"

esc() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

carried=""
dropped=""
seen="|"

while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  case "$seen" in
    *"|${ref}|"*) continue ;;
  esac
  seen="${seen}${ref}|"

  reason=""
  case "$ref" in
    */*) reason="not_a_filename" ;;
  esac
  if [ -z "$reason" ]; then
    if [ ! -d "$DIR" ]; then
      reason="dir_missing"
    elif [ ! -e "${DIR}/${ref}" ]; then
      reason="not_found"
    elif [ ! -r "${DIR}/${ref}" ]; then
      reason="unreadable"
    fi
  fi

  if [ -z "$reason" ]; then
    carried="${carried}${carried:+, }\"$(esc "$ref")\""
  else
    dropped="${dropped}${dropped:+, }{\"ref\": \"$(esc "$ref")\", \"reason\": \"${reason}\"}"
  fi
done <<REFS
${REFS}
REFS

printf '{"line_found": %s, "carried": [%s], "dropped": [%s]}\n' \
  "$line_found" "$carried" "$dropped"
