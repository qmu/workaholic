#!/bin/sh -eu
# How many TICKETS name this mission -- the single answer to "does this mission have a
# plan, and is any of it still drivable".
#
#   queue-size.sh <mission-slug> [workaholic-root]
#
# Output: {"slug": "...", "todo": N, "archive": N, "total": N,
#          "floor": 2, "meets_floor": bool}
#   todo    -- tickets in tickets/todo/**  naming the slug: what is left to drive
#   archive -- tickets in tickets/archive/** naming the slug: what has been driven
#   total   -- todo + archive: whether a plan exists at all
#   floor / meets_floor -- the TICKET FLOOR verdict (mission/SKILL.md, *Granularity ->
#          The ticket floor*): a mission is created with two or more tickets, or it is
#          not a mission. `meets_floor` is `total >= floor`.
#
# THE FLOOR IS A VERDICT ON THIS COUNTER, NEVER A THIRD COUNT. Four seams create a
# mission and all four must refuse a sub-floor one; four inline counts would drift, and
# the drift would be invisible because each seam is exercised separately. `total` is
# already exactly the quantity the floor is about, so the verdict rides here.
#
# IT IS COMPUTED, NOT ENFORCED, HERE. This script is a pure read called from drivability
# checks too, and a reader that exited non-zero on a sub-floor mission would break every
# one of them. The seams read `meets_floor` and refuse; see each seam for its refusal
# text, which must name the alternative artifact (a feedback record for a bare
# direction, a plain ticket for a single unit of work).
#
# `total`, NOT `todo`: a mission whose tickets are all driven still satisfies the floor.
# The floor is about how the mission was created, not about what is left to do.
#
# WHY THIS EXISTS. Both drivability floors used to count `## Acceptance` ITEMS
# (`progress.sh`'s `total`), and `/specificate` writes a provisional acceptance sketch into
# exactly that section -- so a proposal satisfied every floor with zero tickets. On
# 2026-07-30 an approved mission carrying `merge_policy: auto`, `tickets: []` and an
# acceptance block whose own first line read "PROPOSED sketch for discussion -- not a
# plan" was offered to `/drive` as a claimable PR-unit. Claiming it would have created a
# branch and a worktree for an empty queue, under a policy authorizing the run to merge.
#
# THE TWO CONSUMERS ASK DIFFERENT QUESTIONS, WHICH IS WHY BOTH NUMBERS ARE REPORTED:
#   * a planning reader asks "does a plan exist?" -> `total` (a fully-driven mission
#     still has one; only a plan-less proposal is empty). This was approve.sh's
#     question before that step was retired (K1); the /mission replan session and
#     list.sh's `no_plan` verdict ask it now.
#   * plan-units.sh asks "is there work to do?"  -> `todo` (a mission whose tickets are
#     all archived has nothing to offer a runner right now).
# Counting acceptance items answers neither.
#
# The relation is read through read-relation.sh -- the single reader of the many-valued
# `mission:` field -- never by grepping frontmatter here.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
slug="${1:-}"
root="${2:-}"

if [ -z "$slug" ]; then
  echo '{"error": "slug is required"}' >&2
  exit 1
fi

if [ -z "$root" ]; then
  if repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    root="${repo_root}/.workaholic"
  else
    root=".workaholic"
  fi
fi

count_area() {
  _ca_dir="$1"
  _ca_n=0
  [ -d "$_ca_dir" ] || { printf '%s' 0; return 0; }
  # -type f over the whole area: todo/ is flat (a legacy todo/<user>/ may survive until
  # the living migration converges it) and archive/ is
  # keyed by branch (archive/<branch>/), so neither depth is assumed here.
  for _ca_f in $(find "$_ca_dir" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort); do
    if sh "${SCRIPT_DIR}/read-relation.sh" "$_ca_f" 2>/dev/null | grep -qxF -- "$slug"; then
      _ca_n=$((_ca_n + 1))
    fi
  done
  printf '%s' "$_ca_n"
}

todo=$(count_area "${root}/tickets/todo")
archive=$(count_area "${root}/tickets/archive")

total=$((todo + archive))

# The floor is a named constant rather than a literal at each comparison: the number is
# a proxy for the artifact partition (feedback / ticket / mission stay distinguishable),
# and a future argument about it should change one line here.
FLOOR=2
if [ "$total" -ge "$FLOOR" ]; then meets=true; else meets=false; fi

printf '{"slug": "%s", "todo": %s, "archive": %s, "total": %s, "floor": %s, "meets_floor": %s}\n' \
  "$slug" "$todo" "$archive" "$total" "$FLOOR" "$meets"
