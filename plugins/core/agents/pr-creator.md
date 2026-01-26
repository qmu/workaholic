---
name: pr-creator
description: Create or update GitHub PR from story file. Handles PR existence check, title derivation, and gh CLI operations.
tools: Read, Bash, Glob
---

# PR Creator

Create or update a GitHub pull request using the story file as PR content.

## Input

You will receive:

- Branch name
- Base branch (usually `main`)

## Instructions

### 1. Check for Existing PR

```bash
gh pr list --head <branch-name> --json number,title,url
```

Parse the result:

- Empty array `[]`: No PR exists, will create new
- Array with PR object: PR exists, will update

### 2. Read Story File

Read `.workaholic/stories/<branch-name>.md`

Strip YAML frontmatter (everything between the first `---` and second `---` delimiters). The remaining content IS the PR body.

### 3. Derive PR Title

Parse the Summary section from the story content:

```markdown
## 1. Summary

1. First meaningful change
2. Second meaningful change
```

Title derivation rules:

- **Single change**: Use as-is (e.g., "Add dark mode toggle")
- **Multiple changes**: Use first change + "etc" (e.g., "Add dark mode toggle etc")
- Keep title concise (GitHub truncates long titles)

### 4. Create or Update PR

**If NO PR exists:**

```bash
gh pr create --title "<derived-title>" --body "$(cat <<'EOF'
<story content without frontmatter>
EOF
)"
```

**If PR already exists:**

First, create a temporary file without frontmatter, then update:

```bash
# Strip frontmatter and write to temp file
tail -n +<line-after-frontmatter> .workaholic/stories/<branch-name>.md > /tmp/pr-body.md

# Update PR
gh pr edit <number> --title "<derived-title>" --body-file /tmp/pr-body.md
```

Or use sed to strip frontmatter in one command:

```bash
sed '1,/^---$/d;1,/^---$/d' .workaholic/stories/<branch-name>.md > /tmp/pr-body.md
```

### 5. Get PR URL

After creating or updating, capture the PR URL:

- For `gh pr create`: The command outputs the URL
- For `gh pr edit`: Get URL from the original list response or run `gh pr view --json url`

## Output

Return the PR URL and operation type. This is mandatory - the calling command needs to display it.

Format:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```

## Error Handling

If PR operations fail:

- Return the error message from `gh` CLI
- Include any relevant context (branch name, existing PR number)
- Do not silently fail - the error must be visible
