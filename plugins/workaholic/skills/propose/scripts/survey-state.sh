#!/bin/sh -eu
# The proposal batch's STATE SURVEY — everything the judgment needs beyond the
# feedback window.
#
#   survey-state.sh <cursor-commit> [base-branch]     # base defaults to main
#
# Output (one JSON line):
#   {"missions": [...], "queue": [{"path","title"}...], "commits": [{"sha","subject"}...]}
#
# WHY THIS EXISTS. The batch used to read feedback and nothing else, which made
# it structurally unable to answer the question a developer actually opens the
# repository with — what should I do next. Three signals constrain that answer
# and the feedback stream carries none of them: what is already planned (the
# missions), what is already queued (the todo tickets), and what has just been
# built (the commits since the cursor). A proposer blind to them re-proposes work
# that is underway or already decided, which is exactly the noise the judgment
# bar exists to prevent.
#
# IT IS A PURE READ AND IT COMPOSES THE EXISTING READERS. `mission/scripts/list.sh`
# owns mission state (including the derived progress and ownership), and
# `drive/scripts/list-todo.sh` owns the queue. This script parses neither
# frontmatter nor git plumbing of its own — a second parser is a second
# definition, and the one thing a survey must not do is disagree with the
# machinery that acts on it.
#
# THE COMMIT WINDOW IS THE SAME WINDOW AS THE FEEDBACK WINDOW. Both run from the
# cursor to the base, so "new" means one thing in this batch. An unresolvable
# cursor yields an empty commit list rather than an error: the feedback window
# reader is the one that owns cursor validity, and two readers failing
# differently on the same bad input is harder to diagnose than one.

set -eu

CURSOR="${1:-}"
BASE="${2:-main}"

if [ -z "$CURSOR" ]; then
  echo '{"error": "usage: survey-state.sh <cursor-commit> [base-branch]"}' >&2
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

doc_title() {
  # First `# ` heading, or the basename when the document has none.
  _t=$(grep -m 1 '^# ' "$1" 2>/dev/null | sed -e 's/^# *//' || true)
  if [ -z "$_t" ]; then _t=$(basename "$1"); fi
  printf '%s' "$_t"
}

# --- missions ----------------------------------------------------------------
MISSIONS=$(sh "${SCRIPT_DIR}/../../mission/scripts/list.sh" 2>/dev/null || true)
[ -n "$MISSIONS" ] || MISSIONS="[]"

# --- queue -------------------------------------------------------------------
QUEUE=""
q_sep=""
for t in $(sh "${SCRIPT_DIR}/../../drive/scripts/list-todo.sh" 2>/dev/null || true); do
  [ -f "$t" ] || continue
  QUEUE="${QUEUE}${q_sep}{\"path\": \"$(json_escape "$t")\", \"title\": \"$(json_escape "$(doc_title "$t")")\"}"
  q_sep=", "
done

# --- commits since the cursor ------------------------------------------------
COMMITS=""
c_sep=""
if git rev-parse --verify --quiet "${CURSOR}^{commit}" >/dev/null 2>&1; then
  RANGE="${CURSOR}..origin/${BASE}"
  for line in $(git log --format='%h%x1f%s' "$RANGE" 2>/dev/null | tr ' ' '\002' || true); do
    sha=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f1)
    subject=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f2- | tr '\002' ' ')
    [ -n "$sha" ] || continue
    COMMITS="${COMMITS}${c_sep}{\"sha\": \"$(json_escape "$sha")\", \"subject\": \"$(json_escape "$subject")\"}"
    c_sep=", "
  done
fi

printf '{"missions": %s, "queue": [%s], "commits": [%s]}\n' "$MISSIONS" "$QUEUE" "$COMMITS"
