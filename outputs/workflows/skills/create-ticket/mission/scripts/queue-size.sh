#!/bin/sh -eu
# How many TICKETS name this mission -- the single answer to "does this mission have a
# plan, and is any of it still drivable".
#
#   queue-size.sh <mission-slug> [workaholic-root]
#
# Output: {"slug": "...", "todo": N, "archive": N, "total": N}
#   todo    -- tickets in tickets/todo/**  naming the slug: what is left to drive
#   archive -- tickets in tickets/archive/** naming the slug: what has been driven
#   total   -- todo + archive: whether a plan exists at all
#
# WHY THIS EXISTS. Both drivability floors used to count `## Acceptance` ITEMS
# (`progress.sh`'s `total`), and `/propose` writes a provisional acceptance sketch into
# exactly that section -- so a proposal satisfied every floor with zero tickets. On
# 2026-07-30 an approved mission carrying `merge_policy: auto`, `tickets: []` and an
# acceptance block whose own first line read "PROPOSED sketch for discussion -- not a
# plan" was offered to `/drive` as a claimable PR-unit. Claiming it would have created a
# branch and a worktree for an empty queue, under a policy authorizing the run to merge.
#
# THE TWO CONSUMERS ASK DIFFERENT QUESTIONS, WHICH IS WHY BOTH NUMBERS ARE REPORTED:
#   * approve.sh asks "does a plan exist?"       -> `total` (a fully-driven mission still
#     has one, so approving it stays possible; only a plan-less proposal is refused).
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
  # -type f over the whole area: todo/ is one level deep (todo/<user>/) and archive/ is
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

printf '{"slug": "%s", "todo": %s, "archive": %s, "total": %s}\n' \
  "$slug" "$todo" "$archive" "$((todo + archive))"
