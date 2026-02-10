---
name: commit
description: Safe commit workflow with multi-contributor awareness and structured message format.
skills:
  - format-commit-message
user-invocable: false
---

# Commit

Safe commit workflow with multi-contributor awareness. All commits in the Workaholic workflow should use this skill.

## Multi-Contributor Awareness

**Context**: You are not the only one working in this repository. Multiple developers and agents may have uncommitted changes in the working directory.

Before committing:

1. **Run pre-flight check** to understand what will be committed
2. **Review staged changes** to ensure only intended files are included
3. **Identify unintended changes** that may belong to other contributors
4. **Ask user if uncertain** about whether to include changes

## Usage

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "<title>" "<description>" "<changes>" "<test-plan>" "<release-prep>" [files...]
```

### Parameters

Each section (except title) should be a short paragraph of 3-5 sentences. See **format-commit-message** skill for detailed guidance on what to cover in each section.

- `title` - Commit title (present-tense verb, 50 chars max)
- `description` - Why this change was needed: the problem, what triggered it, the chosen approach and rationale (from ticket Overview)
- `changes` - What users will experience differently: concrete before-and-after differences, or "None" with brief explanation
- `test-plan` - What verification was done or should be done: manual checks, automated tests, edge cases considered
- `release-prep` - What is needed to ship and support: migration steps, config changes, documentation updates, or "None" with brief explanation
- `files...` - Optional: specific files to stage (if omitted, stages all tracked changes)

### Staging Behavior

- If files are specified: stages only those files
- If no files specified: stages all modified tracked files (`git add -u`)
- **Never uses `git add -A`** to avoid accidentally staging untracked files from other contributors

## Pre-Commit Checks

The commit script performs safety checks:

1. **Verify branch exists** - Cannot commit in detached HEAD state
2. **Check for staged changes** - Warns if nothing to commit
3. **Review what will be committed** - Shows diff summary before proceeding

## Message Format

Follow the preloaded **format-commit-message** skill:

```
<title>

Description: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Test Planning: <what verification was done or should be done>

Release Preparation: <what is needed to ship and support afterward>

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Examples

### Implementation commit (with specific files)

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Add session-based authentication" \
  "Users needed persistent login state across browser sessions. Previously, every page refresh required re-authentication, causing friction for returning users. Added cookie-based session management with configurable TTL, chosen over JWT tokens for simplicity and server-side revocation support." \
  "New 'Remember me' checkbox on the login form that persists sessions for 30 days. When unchecked, sessions expire when the browser closes. Session expiry now shows a friendly redirect to login instead of a raw 401 error." \
  "Manual login/logout flow tested across Chrome and Firefox. Verified session persistence across page refreshes and browser restarts. Tested session expiry by setting TTL to 5 seconds and confirming redirect behavior. Cookie security flags (HttpOnly, Secure, SameSite) verified in browser dev tools." \
  "None -- backward-compatible addition. No existing auth flows are affected since session support is opt-in via the checkbox." \
  src/auth/session.ts src/middleware/auth.ts
```

### Archive commit (stage all changes)

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Archive ticket: add-authentication" \
  "" \
  "None" \
  "None" \
  "None"
```

### Abandonment commit

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/commit/sh/commit.sh \
  "Abandon: add-authentication" \
  "Implementation proved unworkable due to API limitations" \
  "None" \
  "None" \
  "Ticket moved to abandoned with failure analysis"
```
