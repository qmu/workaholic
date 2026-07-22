#!/bin/sh -eu
# List OPEN pull requests that reference a mission slug, so a /mission replan
# sees a sibling already implementing the same acceptance before it emits
# duplicate delta tickets. A PR "touches" the mission when the slug appears in
# its title or body — a mission-linked branch story names the mission it
# advances, so the slug is the durable cross-branch signal (work-* branch names
# carry no slug). This complements the fetch-first base resolution in
# create-mission-worktree.sh: the fetch keeps a new worktree off a stale base;
# this keeps a replan from duplicating a sibling's in-flight, not-yet-merged work.
#
# Best-effort by construction: degrades to an empty, unavailable list whenever
# gh is missing/unauthenticated or the repo has no usable remote, so a replan is
# never blocked by tooling (workaholic:implementation — degrade, don't break the
# flow, but surface that the check did not run via "available": false).
#
# Usage: list-related-prs.sh <slug>
# Output: {"slug":"...","available":true|false,"prs":[{number,title,url,headRefName}]}

set -eu

slug="${1:-}"
if [ -z "$slug" ]; then
  echo '{"error": "slug is required"}' >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  printf '{"slug": "%s", "available": false, "prs": []}\n' "$slug"
  exit 0
fi

# Search open PRs' title AND body for the slug. `|| true` keeps a gh failure
# (no auth, no remote, network) from aborting the caller under `set -e`.
prs="$(gh pr list --state open --search "${slug} in:title,body" \
  --json number,title,url,headRefName 2>/dev/null || true)"

if [ -z "$prs" ]; then
  printf '{"slug": "%s", "available": false, "prs": []}\n' "$slug"
  exit 0
fi

printf '{"slug": "%s", "available": true, "prs": %s}\n' "$slug" "$prs"
