#!/bin/sh -eu
# The proposer's STATE SURVEY — everything the judgment needs beyond the ask in
# hand.
#
#   survey-state.sh [since-commit] [base-branch]      # base defaults to main
#
# Output (one JSON line):
#   {"missions": [...], "queue": [{"path","title"}...],
#    "commits": [{"sha","subject"}...], "since": "<rev>", "since_reason": "..."}
#
# WHY THIS EXISTS. The judgment used to read feedback and nothing else, which made
# it structurally unable to answer the question a developer actually opens the
# repository with — what should I do next. Three signals constrain that answer
# and an ask carries none of them: what is already planned (the missions), what is
# already queued (the todo tickets), and what has just been built (the recent
# commits). A proposer blind to them proposes work that is underway or already
# decided, which is exactly the noise the judgment bar exists to prevent.
#
# THE RANGE IS AN ARGUMENT, AND ITS ORIGIN IS REPORTED. The cursor this script
# once took disappeared with the merged-main window (2026-08-04 ruling): the
# proposer now runs at the capture seam, where there is no window at all. So the
# commit range is either GIVEN by the caller (`since_reason: given`) or a bounded
# recent slice of the base (`recent`, WORKAHOLIC_PROPOSE_COMMIT_WINDOW, default
# 20). It is never inferred from state the caller cannot see, and an unresolvable
# argument is reported as `unresolvable` with no commits rather than silently
# falling back — a constraint that quietly became empty is worse than one that
# says it could not be read.
#
# IT IS A PURE READ AND IT COMPOSES THE EXISTING READERS. `mission/scripts/list.sh`
# owns mission state (including the derived progress and ownership), and
# `drive/scripts/list-todo.sh` owns the queue. This script parses neither
# frontmatter nor git plumbing of its own — a second parser is a second
# definition, and the one thing a survey must not do is disagree with the
# machinery that acts on it.
#
set -eu

SINCE="${1:-}"
BASE="${2:-main}"
WINDOW="${WORKAHOLIC_PROPOSE_COMMIT_WINDOW:-20}"

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

# --- recent commits ----------------------------------------------------------
# Resolve the base once: a checkout with no origin (the publish tree's own case is
# a clone, but a bare fixture is not) still has a local base to read.
BASE_REV=""
for candidate in "origin/${BASE}" "$BASE"; do
  if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null 2>&1; then
    BASE_REV="$candidate"
    break
  fi
done

RANGE=""
SINCE_REASON="none"
if [ -n "$SINCE" ]; then
  if git rev-parse --verify --quiet "${SINCE}^{commit}" >/dev/null 2>&1 && [ -n "$BASE_REV" ]; then
    RANGE="${SINCE}..${BASE_REV}"
    SINCE_REASON="given"
  else
    SINCE_REASON="unresolvable"
  fi
elif [ -n "$BASE_REV" ]; then
  RANGE="-n ${WINDOW} ${BASE_REV}"
  SINCE_REASON="recent"
fi

COMMITS=""
c_sep=""
if [ -n "$RANGE" ]; then
  # shellcheck disable=SC2086 — RANGE is a built argument list, deliberately split.
  for line in $(git log --format='%h%x1f%s' $RANGE 2>/dev/null | tr ' ' '\002' || true); do
    sha=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f1)
    subject=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f2- | tr '\002' ' ')
    [ -n "$sha" ] || continue
    COMMITS="${COMMITS}${c_sep}{\"sha\": \"$(json_escape "$sha")\", \"subject\": \"$(json_escape "$subject")\"}"
    c_sep=", "
  done
fi

printf '{"missions": %s, "queue": [%s], "commits": [%s], "since": "%s", "since_reason": "%s"}\n' \
  "$MISSIONS" "$QUEUE" "$COMMITS" "$(json_escape "$SINCE")" "$SINCE_REASON"
