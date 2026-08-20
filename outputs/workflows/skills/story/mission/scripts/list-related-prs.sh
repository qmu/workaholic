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

# REST, NOT `gh pr list --search` (2026-08-12, FB 20260812172522): the subcommand is
# GraphQL-backed and a web session may 403 it.
#
# AND NOT `search/issues` EITHER, which is the obvious REST translation of
# `--search "<slug> in:title,body"` and was tried first. Measured in this repository's own
# session, the endpoint is refused one layer further out than GraphQL was:
#
#   This GitHub API path is not available: sessions are bound to their configured
#   repositories. Use repository-scoped endpoints (repos/{owner}/{repo}/...).
#
# So the query moves to the **repository-scoped** list endpoint and the matching happens
# here. `GET repos/{slug}/pulls?state=open` returns each PR's `title`, `body` and
# `head.ref`, so `<slug> in:title,body` becomes a `jq` test on exactly those two fields —
# the same question, asked locally. `headRefName` is preserved as a real value rather
# than being lost, which the search translation could not have done without a second
# request per hit.
#
# WHAT CHANGED: the server-side search paginated over every open PR; this reads one page
# of 100. A repository with more than 100 open pull requests would see only the newest —
# reported honestly here rather than silently, since the caller uses this to avoid
# duplicating a sibling's work. Also, search is 30 requests/minute where the core API is
# 5,000/hour, so this direction is the cheaper one too.
#
# `|| true` keeps a gh failure (no auth, no remote, network) from aborting the caller
# under `set -e`.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"
repo_slug="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>/dev/null || true)"

# The filter runs through a real `jq`, not `gh api --jq`: the slug is data and belongs in
# a `--arg` binding, which `gh api`'s built-in filter flag does not accept. Interpolating
# it into the filter text instead would break on any slug containing a quote.
prs=""
if [ -n "$repo_slug" ]; then
  raw="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
    "repos/${repo_slug}/pulls?state=open&per_page=100" 2>/dev/null || true)"
  if [ -n "$raw" ]; then
    prs="$(printf '%s' "$raw" | jq -c --arg slug "$slug" '
      [ .[]? | select(((.title // "") + " " + (.body // "")) | contains($slug))
             | {number, title, url: .html_url, headRefName: (.head.ref // "")} ]' \
      2>/dev/null || true)"
  fi
fi

# THE ANSWER MUST BE AN ARRAY BEFORE IT IS CALLED AVAILABLE. `gh api` prints an error
# BODY to stdout on a refused path, so a non-empty string is not evidence of a successful
# read — reporting one as `available: true` would hand the caller an error object where
# it expects a PR list, which is exactly the mistake this conversion nearly shipped.
if [ -n "$prs" ] && ! printf '%s' "$prs" | jq -e 'type == "array"' >/dev/null 2>&1; then
  prs=""
fi

if [ -z "$prs" ]; then
  printf '{"slug": "%s", "available": false, "prs": []}\n' "$slug"
  exit 0
fi

printf '{"slug": "%s", "available": true, "prs": %s}\n' "$slug" "$prs"
