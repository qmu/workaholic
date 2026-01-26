---
name: pr-creator
description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
tools: Read, Bash, Glob
---

# PR Creator

## CRITICAL: Git Command Format

**NEVER use `git -C <path>` flag.** Always run git commands directly:

- WRONG: `git -C /path/to/repo rev-list --count main..HEAD`
- RIGHT: `git rev-list --count main..HEAD`

The `-C` flag causes permission prompts and must not be used.

Create or update a GitHub pull request using the story file as PR content.

## Input

You will receive:

- Branch name
- Base branch (usually `main`)

## Instructions

### 1. Prepare PR Body File

Read `.workaholic/stories/<branch-name>.md` and write content without YAML frontmatter to `/tmp/pr-body.md`:

```bash
sed '1,/^---$/d;1,/^---$/d' .workaholic/stories/<branch-name>.md > /tmp/pr-body.md
```

### 2. Derive PR Title

Extract the first item from the Summary section in the story file. Look for:

```markdown
## 1. Summary

1. First meaningful change
```

Use that first item as the title. If multiple items exist, append "etc" (e.g., "Add dark mode toggle etc").

### 3. Check PR and Create/Update

Check if PR exists and create or update in one flow:

```bash
gh pr list --head <branch-name> --json number,url --jq '.[0]'
```

- **Empty result**: Create new PR with `gh pr create --title "<title>" --body-file /tmp/pr-body.md`
- **Has result**: Update with `gh pr edit <number> --title "<title>" --body-file /tmp/pr-body.md`

For create, the URL is printed. For edit, use the URL from the list result.

## Output

Return exactly one line:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```
