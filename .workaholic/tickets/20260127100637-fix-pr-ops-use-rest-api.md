---
created_at: 2026-01-27T10:06:37+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
---

# Fix pr-ops script to use REST API instead of gh pr edit

## Overview

The `gh pr edit` command fails with a GraphQL error when the repository has Projects (classic) enabled:

```
GraphQL: Projects (classic) is being deprecated in favor of the new Projects experience
```

Replace `gh pr edit` with `gh api` REST endpoint which bypasses the GraphQL layer entirely.

## Key Files

- `plugins/core/skills/pr-ops/scripts/create-or-update.sh` - The script that creates/updates PRs

## Implementation Steps

1. Replace line 37 (`gh pr edit "$NUMBER" --title "$TITLE" --body-file /tmp/pr-body.md`) with REST API call:
   ```bash
   REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
   gh api "repos/${REPO}/pulls/${NUMBER}" --method PATCH \
     -f title="$TITLE" \
     -f body="$(cat /tmp/pr-body.md)" > /dev/null
   ```

2. The REST API endpoint `PATCH /repos/{owner}/{repo}/pulls/{pull_number}` accepts:
   - `title`: PR title (string)
   - `body`: PR body content (string)

## Considerations

- REST API requires reading body content into command argument via `$(cat ...)` instead of `--body-file`
- The `gh repo view` call adds one extra API request but is reliable for getting owner/repo
- Redirect output to `/dev/null` since we already have the URL from `PR_INFO`
