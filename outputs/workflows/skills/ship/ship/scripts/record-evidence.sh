#!/bin/sh -eu
# Append a "## Deployment Evidence" block to a branch story, capturing the
# production-confirmation proof BEFORE the PR is merged. Reviewers see the
# evidence on the PR; the merged story carries it permanently.
#
# Usage: bash record-evidence.sh <branch> <target> <method> <result> <status>
#   <result> = a short, NON-SECRET observed result (status/version/hash/response).
#              Never pass credentials, tokens, or cookies — the story is public.
#   <status> = pass | fail
# Output: JSON {"recorded": bool, "story"?: path, "status"?: status, "reason"?: ...}

set -eu

branch="$1"
target="$2"
method="$3"
result="$4"
status="$5"

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
story="${root}/.workaholic/stories/${branch}.md"

if [ ! -f "$story" ]; then
  printf '{"recorded": false, "reason": "no_story"}\n'
  exit 0
fi

ts=$(date -Iseconds)

{
  printf '\n## Deployment Evidence\n\n'
  printf -- '- **When:** %s\n' "$ts"
  printf -- '- **Target:** %s\n' "$target"
  printf -- '- **Method:** %s\n' "$method"
  printf -- '- **Status:** %s\n' "$status"
  printf -- '- **Observed:** %s\n' "$result"
} >> "$story"

printf '{"recorded": true, "story": ".workaholic/stories/%s.md", "status": "%s"}\n' "$branch" "$status"
