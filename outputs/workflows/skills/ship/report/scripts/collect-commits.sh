#!/bin/sh -eu
# Collect commit information for overview generation
# Outputs JSON with commit hash, subject, body, and timestamp.
#
# The body is emitted (not dropped): /report's overview-writer reads the
# structured commit body (Why/Changes/Concerns/Insights/Verify) from it. Fields
# are delimited with ASCII unit separator (0x1f) and records with record
# separator (0x1e) so multi-line bodies survive, and jq does the JSON escaping.

set -eu

BASE_BRANCH="${1:-main}"

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
