---
name: ship
description: Ship workflow - merge PR, deploy via cloud.md, and verify production.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
---

# Ship

Merge a pull request, deploy to production, and verify the deployment. Claude Code acts as the deployment agent, following instructions from a user-provided `cloud.md` file.

## 1. Cloud.md Convention

`cloud.md` is a project-level file authored by the user (not part of Workaholic). It tells the ship command how to deploy and verify.

### 1-1. Search Order

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/find-cloud-md.sh
```

Searches: `./cloud.md`, `./.workaholic/cloud.md`

### 1-2. Expected Sections

```markdown
## Deploy
Step-by-step deployment instructions for Claude Code to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

### 1-3. Confirmation

Before executing deploy instructions, the ship command displays the Deploy section and asks for user confirmation via AskUserQuestion. If the user declines, deployment is skipped.

### 1-4. Fallback

If no `cloud.md` is found, skip deploy and verify steps. Inform the user that deployment was skipped because no `cloud.md` was found.

## 2. Shell Scripts

### 2-1. Pre-check

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/pre-check.sh "<branch>"
```

Verifies a PR exists for the branch. Returns JSON with PR number, URL, and merge status.

### 2-2. Merge PR

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/merge-pr.sh "<pr-number>"
```

Merges the PR, checks out main, and pulls to sync. Returns JSON with merge status and commit hash.

### 2-3. Find cloud.md

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/ship/sh/find-cloud-md.sh
```

Searches for cloud.md in standard locations. Returns JSON with path or `{"found": false}`.
