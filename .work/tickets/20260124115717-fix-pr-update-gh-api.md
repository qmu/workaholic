# Fix PR Update to Avoid gh pr edit GraphQL Error

## Overview

When updating an existing PR via `/pull-request`, the agent uses `gh pr edit` which triggers a GraphQL error about deprecated Projects (classic). The command documentation already specifies using `gh api` for updates, but the instructions need to be more explicit to prevent the agent from defaulting to `gh pr edit`.

The error occurs because `gh pr edit` queries `repository.pullRequest.projectCards` which is part of the deprecated Projects (classic) feature. Using `gh api` directly with the REST API avoids this issue.

## Key Files

- `plugins/core/commands/pull-request.md` - The command needs clearer instructions to enforce `gh api` usage

## Implementation Steps

1. Add an explicit warning before the "Creating vs Updating" section (around line 181):

   ```markdown
   ## Important: API Choice

   **NEVER use `gh pr edit`** - it triggers GraphQL errors related to deprecated Projects (classic).
   Always use `gh api` with the REST endpoint for updating PRs.
   ```

2. Update the "If PR already exists" section to be more explicit:

   ```markdown
   ### If PR already exists:

   **Use `gh api` (NOT `gh pr edit`)** to update the PR title and body:

   ```sh
   # Get owner/repo from remote
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

   gh api repos/${REPO}/pulls/<number> -X PATCH \
     -f title="<derived-title>" \
     -f body="$(cat <<'EOF'
   <story content without frontmatter>
   EOF
   )"
   ```

   Do NOT use `gh pr edit` as it causes GraphQL errors with Projects (classic) deprecation.
   ```

3. Add to the Critical Rules or Notes section at the end:

   ```markdown
   ## Notes

   - **gh api vs gh pr edit**: Always use `gh api` for PR updates. The `gh pr edit` command queries deprecated GraphQL fields (projectCards) that cause errors on repositories that ever used Projects (classic).
   ```

## Considerations

- The `gh api` approach requires extracting the owner/repo from the remote, which adds a step but is more reliable
- This is a GitHub CLI issue that may be fixed in future versions, but the workaround is stable
- The REST API approach also returns more detailed response data which could be useful for verification
