#!/bin/sh -eu
# Collect commit information for overview generation
# Outputs JSON with commit subjects, bodies, and timestamps

set -eu

BASE_BRANCH="${1:-main}"

# Get commit count
COUNT=$(git rev-list --count "${BASE_BRANCH}..HEAD")

if [ "$COUNT" -eq 0 ]; then
    echo '{"commits":[],"count":0,"base_branch":"'"${BASE_BRANCH}"'"}'
    exit 0
fi

# Collect commits as JSON array
# Format: hash, subject, body, timestamp
COMMITS=$(git log "${BASE_BRANCH}..HEAD" --reverse --format='{
  "hash": "%h",
  "subject": "%s",
  "body": "%b",
  "timestamp": "%cI"
},' | sed 's/"/\\"/g; s/\\"{/{/g; s/\\"}$/}/g' | sed '$ s/,$//')

# Escape special characters in body for valid JSON
COMMITS_CLEANED=$(git log "${BASE_BRANCH}..HEAD" --reverse --pretty=format:'%h|%s|%cI' | while IFS='|' read -r hash subject timestamp; do
    # Escape quotes and newlines
    subject_escaped=$(echo "$subject" | sed 's/"/\\"/g')
    cat <<ENTRY
    {
      "hash": "$hash",
      "subject": "$subject_escaped",
      "timestamp": "$timestamp"
    },
ENTRY
done | sed '$ s/,$//')

# Output JSON
cat <<EOF
{
  "commits": [
$COMMITS_CLEANED
  ],
  "count": ${COUNT},
  "base_branch": "${BASE_BRANCH}"
}
EOF
