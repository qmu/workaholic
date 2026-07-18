#!/bin/sh -eu
# Collect commit information for overview generation
# Outputs JSON with commit hash, subject, body, and timestamp.
#
# The body is emitted (not dropped): /report's overview-writer reads the
# structured commit body (Why/Changes/Concerns/Insights/Verify) from it. Fields
# are delimited with ASCII unit separator (0x1f) and records with record
# separator (0x1e) so multi-line bodies survive, and jq does the JSON escaping.

set -eu

# Base ref: an explicit arg wins; otherwise the single resolver decides it (prefers
# origin/<default>, immune to a stale local `main`). We never re-derive an in-script
# default that silently falls back to `main` — that stale fallback is the bug this closes.
SCRIPT_DIR=$(dirname "$0")
if [ "$#" -ge 1 ] && [ -n "$1" ]; then
    BASE_BRANCH="$1"
elif ! BASE_BRANCH=$("${SCRIPT_DIR}/../../gather/scripts/base-ref.sh"); then
    echo "collect-commits: could not resolve a base ref" >&2
    exit 1
fi

# Get commit count
COUNT=$(git rev-list --count "${BASE_BRANCH}..HEAD")

if [ "$COUNT" -eq 0 ]; then
    echo '{"commits":[],"count":0,"base_branch":"'"${BASE_BRANCH}"'"}'
    exit 0
fi

git log "${BASE_BRANCH}..HEAD" --reverse \
    --format='%h%x1f%s%x1f%cI%x1f%b%x1f%(trailers:key=Category,valueonly)%x1e' \
  | jq -Rs --arg base "$BASE_BRANCH" '
      split("")
      | map(ltrimstr("\n"))
      | map(select(length > 0))
      | map(split(""))
      | map({
          hash: .[0],
          subject: .[1],
          timestamp: .[2],
          body: ((.[3] // "") | sub("\n+$"; "")),
          category: ((.[4] // "") | gsub("\\s"; ""))
        })
      | {commits: ., count: length, base_branch: $base}'
