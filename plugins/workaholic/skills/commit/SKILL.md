---
name: commit
description: Safe commit workflow with multi-contributor awareness and structured message format.
user-invocable: false
metadata:
  internal: true
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
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>" [files...]
```

### Parameters

Each section (except title) should be a short paragraph of 3-5 sentences. See the Message Format section below for detailed guidance on what to cover in each section. The body keys are chosen to feed `/report`: `Why` → Motivation, `Changes` → Changes/Outcome, `Concerns` → Concerns, `Insights` → Successful Development Patterns.

- `title` - Commit title (present-tense verb, 50 chars max)
- `why` - Why this change was needed: the problem, what triggered it, the chosen approach and rationale (from ticket Overview). Feeds `/report` Motivation. Omitted from the message when empty.
- `changes` - What users will experience differently: concrete before-and-after differences, or "None" with brief explanation
- `concerns` - Risks, trade-offs, deferred work, or forward-looking follow-ups this change surfaced (from ticket Considerations). Feeds `/report` Concerns. Pass "None" or empty to omit the section.
- `insights` - Non-obvious patterns, gotchas, or institutional knowledge worth preserving (from ticket Discovered Insights). Feeds `/report` Successful Development Patterns. Pass "None" or empty to omit the section.
- `verify` - What verification was done or should be done: manual checks, automated tests, edge cases considered
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

Each section should be a short paragraph (3-5 sentences). The keys map onto the report's narrative sections so `git log` alone gives a reviewer — and the `/report` overview-writer — enough signal without reading the diff. `Why`, `Concerns`, and `Insights` are omitted when empty or "None"; `Changes` and `Verify` always render.

```
<title>

Why: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Concerns: <risks, trade-offs, deferred work, or forward-looking follow-ups>

Insights: <non-obvious patterns or gotchas worth preserving>

Verify: <what verification was done or should be done>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Title

Present-tense verb, what changed (50 chars max). No prefixes like `feat:` or `[fix]`.

Examples:
- Add session-based authentication
- Fix Mermaid slash character in labels
- Remove unused RegisterTool type

### Why

Why this change was needed, including the motivation and rationale. Start with the problem or gap that existed before this change. Explain what triggered the work -- a user report, a downstream dependency, a missing capability, or a design decision. State the chosen approach and why it was preferred over alternatives. Extract context from the ticket Overview. Target 3-5 sentences. `/report` synthesizes the branch's Motivation section from these. Omitted from the message when empty (e.g. a trivial archive commit).

### Changes

What users will experience differently after this change. Describe each observable difference concretely -- new commands, altered output format, changed error messages, new options, or modified default behavior. Explain the before-and-after for each difference so that a reader who has never seen the code can understand the impact. `/report` draws the Changes and Outcome sections from these. If the change is internal only, write "None" and briefly explain why there is no user-facing impact (e.g., "None -- this is a refactor of internal shell scripts with no change to CLI behavior").

### Concerns

Risks, trade-offs, limitations, deferred work, or forward-looking follow-ups this change surfaced. Each should be a concrete, actionable observation -- what the risk is and, where possible, how to address it. Extract from the ticket Considerations and anything you discovered while implementing. `/report` feeds these into its Concerns section (and `/ship` can carry unresolved ones forward), so a concern recorded here is not lost if the ticket is later pruned. Pass "None" or leave empty when there is nothing to flag; the section is then omitted from the message.

### Insights

Non-obvious patterns, gotchas, hidden coupling, or institutional knowledge worth preserving for whoever touches this area next. Focus on what *worked* and why, or a surprising constraint that shaped the implementation -- not a restatement of the change. Extract from the ticket Discovered Insights. `/report` uses these for its Successful Development Patterns section. Pass "None" or leave empty when nothing noteworthy emerged; the section is then omitted.

### Verify

What verification was done or should be done to confirm this change works correctly. Describe manual checks that were performed and their results. List automated tests that were added, modified, or run. Identify edge cases that were considered and whether they were covered or deferred. If the change interacts with external systems, note how those interactions were validated. Write "None" only if the change is trivial (e.g., typo fix, comment update) and requires no special verification.

## Examples

### Implementation commit (with specific files)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Add session-based authentication" \
  "Users needed persistent login state across browser sessions. Previously, every page refresh required re-authentication, causing friction for returning users. Added cookie-based session management with configurable TTL, chosen over JWT tokens for simplicity and server-side revocation support." \
  "New 'Remember me' checkbox on the login form that persists sessions for 30 days. When unchecked, sessions expire when the browser closes. Session expiry now shows a friendly redirect to login instead of a raw 401 error." \
  "Session fixation was considered and mitigated by regenerating the session id on login; CSRF protection for the new cookie path is deferred to a follow-up and should be tracked before this ships externally." \
  "Server-side revocation via a session store turned out simpler to reason about than JWT blacklisting for this codebase -- prefer it whenever sessions must be invalidated mid-life." \
  "Manual login/logout flow tested across Chrome and Firefox. Verified session persistence across page refreshes and browser restarts. Tested session expiry by setting TTL to 5 seconds and confirming redirect behavior. Cookie security flags (HttpOnly, Secure, SameSite) verified in browser dev tools." \
  src/auth/session.ts src/middleware/auth.ts
```

### Archive commit (stage all changes)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Archive ticket: add-authentication" \
  "" \
  "None" \
  "None" \
  "None" \
  "None"
```

### Abandonment commit

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Abandon: add-authentication" \
  "Implementation proved unworkable due to API limitations" \
  "None" \
  "The provider's API has no idempotency key, so retries double-charge; revisit only if they ship one." \
  "None" \
  "None"
```
