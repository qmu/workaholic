---
name: ship
description: Ship workflow - merge PR, deploy via cloud.md, and verify production.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
metadata:
  internal: true
---

# Ship

Merge a pull request, deploy to production, and verify the deployment. The agent acts as the deployment agent, following instructions from a user-provided `cloud.md` file.

This skill is the **trip-independent ship essence**: it operates on the current branch's PR. Worktree handling and drive/trip context routing are not part of this skill — they live in `core:trip-protocol` (Trip Ship) and are orchestrated by the Claude-Code `/ship` command. Any agent can run this skill directly to ship the current branch.

## 1. Cloud.md Convention

`cloud.md` is a project-level file authored by the user (not part of Workaholic). It tells the ship workflow how to deploy and verify.

### 1-1. Search Order

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh
```

Searches: `./cloud.md`, `./.workaholic/cloud.md`

### 1-2. Expected Sections

```markdown
## Deploy
Step-by-step deployment instructions for the agent to execute.

## Verify
Health checks, smoke tests, and expected outcomes.
```

### 1-3. Confirmation

Before executing deploy instructions, display the Deploy section and ask the user to confirm via AskUserQuestion. If the user declines, deployment is skipped.

### 1-4. Fallback

If no `cloud.md` is found, skip deploy and verify steps. Inform the user that deployment was skipped because no `cloud.md` was found.

## 2. Shell Scripts

### 2-1. Pre-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"
```

Verifies a PR exists for the branch. Returns JSON with PR number, URL, and merge status.

### 2-2. Merge PR

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"
```

Merges the PR, checks out main, and pulls to sync. Returns JSON with merge status and commit hash.

### 2-3. Find cloud.md

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh
```

Searches for cloud.md in standard locations. Returns JSON with path or `{"found": false}`.

### 2-4. Check Todo

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Checks if `.workaholic/tickets/todo/` has remaining tickets. Returns JSON with cleanliness status, count, and ticket list. Used as a pre-merge guard to prevent shipping with unfinished work.

### 2-5. Extract Carry-Overs

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"
```

Reads the just-shipped story (`.workaholic/stories/<branch>.md`), parses each `###` concern block in section 6 (Concerns), and writes one file per concern under `.workaholic/concerns/` as `<pr-number>-<slug>.md` (with `severity` and a Title/Description/How-to-Fix body). Returns JSON:

```json
{"status":"ok","extracted":10,"files":["..."]}
```

Commits the new files with message `Carry over concerns from PR #<pr-number>` so the corpus stays under version control. Skips silently when no story file exists or section 6 is empty.

## 3. Workspace Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ticket Guard.

If `clean` is `false`, display the `summary` to the user and ask via AskUserQuestion with selectable options:
- **"Ignore and proceed"** - Continue with the ship workflow. The unrelated changes will remain in the workspace after the command completes.
- **"Stop"** - Halt the workflow so you can handle the changes first.

If the user selects "Stop", end the workflow immediately.

## 4. Ticket Guard

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/check-todo.sh
```

Parse the JSON output. If `clean` is `true`, proceed silently to the Ship Flow.

If `clean` is `false`, display the ticket list to the user: "Cannot ship: N ticket(s) remaining in `.workaholic/tickets/todo/`:" followed by the ticket filenames. Then ask via AskUserQuestion with selectable options:
- **"Move all to icebox"** - Move all remaining tickets to `.workaholic/tickets/icebox/`, stage and commit "Move remaining tickets to icebox", then proceed to the Ship Flow.
- **"Stop"** - Halt the workflow so you can handle tickets first (run `/drive`, manually reorganize, etc.)

If the user selects "Stop", end the workflow immediately.

## 5. Ship Flow

Ship the current branch's PR. (Worktree sync/cleanup and drive/trip routing are not here — see `core:trip-protocol` Trip Ship.)

1. **Pre-check**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/pre-check.sh "<branch>"`. If `found` is `false`: inform user "No PR found for this branch. Run `/report` first." and stop. If `merged` is `true`: skip to Deploy.
2. **Merge PR**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/merge-pr.sh "<pr-number>"`. On failure, inform user and stop.
3. **Extract carry-overs**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/extract-carryover.sh "<branch>" "<pr-number>" "<pr-url>"`. Persists active Concerns from the just-shipped story's section 6 into `.workaholic/concerns/`. Commits the new files. Skips silently when no story file exists or section 6 is empty. Report `extracted` count from the JSON output.
4. **Deploy**: Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/find-cloud-md.sh`. If `found` is `false`: inform user "No cloud.md found. Deployment skipped." and skip to summary. If `found` is `true`: read the file, find `## Deploy` section, ask confirmation via AskUserQuestion, execute if confirmed.
5. **Verify**: If cloud.md found, read `## Verify` section and execute. Report results.
6. **Summarize**: PR merge status (number, URL), carry-over extraction count, deployment status, verification results.
