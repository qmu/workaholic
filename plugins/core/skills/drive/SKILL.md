---
name: drive
description: Implementation workflow, approval flow, final report, archive, and frontmatter update for drive sessions.
skills:
  - commit
  - system-safety
  - standards:leading-validity
  - standards:leading-accessibility
  - standards:leading-security
  - standards:leading-availability
allowed-tools: Bash
user-invocable: false
---

# Drive

Complete drive session skill covering the `/drive` command workflow, the drive-navigator subagent, per-ticket implementation, approval, reporting, archiving, and frontmatter updates.

## Command Workflow

End-to-end orchestration for `/drive`. The thin `/drive` command preloads this skill and follows this section.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop.

### Phase 0: Worktree Guard

Check if trip worktrees exist before proceeding:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh
```

If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
- **"Continue here"** - Proceed with drive on the current branch
- **"Switch to worktree"** - Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/drive` there

If `has_worktrees` is `false`, proceed silently to Phase 1.

**Rationale**: Prevents accidental development on a drive branch when trip worktrees with in-progress work may be the intended target.

**Trip branch compatibility**: The drive workflow operates on any non-main topic branch, including `trip/*` branches. When running on a trip branch after a trip session completes, tickets are read from `.workaholic/tickets/todo/` and archived normally. Use `/ticket` to add refinement tickets, then `/drive` to implement them.

### Phase 1: Navigate Tickets

Invoke the drive-navigator subagent via Task tool:

```
Task tool with subagent_type: "work:drive-navigator", model: "opus"
prompt: "Navigate tickets. mode: <normal|icebox>"
```

Pass mode based on `$ARGUMENT`:
- If `$ARGUMENT` contains "icebox": mode = "icebox"
- Otherwise: mode = "normal"

Handle the response:
- `status: "empty"` - Inform user: "No tickets in queue or icebox."
- `status: "stopped"` - End the drive session
- `status: "icebox"` - Re-invoke with mode = "icebox"
- `status: "ready"` - Proceed to Phase 2 with the ordered ticket list

### Phase 2: Implement Tickets

For each ticket in the ordered list:

#### Step 2.1: Implement Ticket

Follow the **Workflow** section below. Implementation context is preserved in the main conversation, providing full visibility of changes made. Apply the policies, practices, and standards from the relevant preloaded leading skill(s) — see the Lead Lens table in the `create-ticket` skill for the layer-to-lead mapping.

#### Step 2.2: Request Approval

Follow the **Approval** section below to present the approval dialog. **CRITICAL**: You MUST use the `title` and `overview` fields from the Step 2.1 workflow result to populate the approval prompt header and question. If these fields are unavailable, re-read the ticket file to obtain them. Never present an approval prompt without the ticket title and summary.

**CRITICAL**: Use `AskUserQuestion` with selectable `options`. NEVER proceed without explicit user approval.

#### Step 2.3: Handle User Response

**"Approve" or "Approve and stop"**:
1. Follow the **Final Report** section below to update ticket effort and append the Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit by calling the archive script directly:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
     <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
   ```
   Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
   and `<repo-url>` comes from the gather skill's `git-context.sh` output.
   **NEVER manually move tickets** with `mv` + `git add` -- always use the archive script.
4. If "Approve and stop": break loop, skip Phase 3, go directly to Phase 4
5. Otherwise: continue to next ticket

**Free-form feedback** (user selects "Other" and provides text):

> **CRITICAL**: Update the ticket file FIRST. Do NOT re-implement until the ticket reflects the user's feedback.

1. Follow the **Approval** section below (Handle Feedback) — this updates the ticket
2. **Verify** the ticket file was updated (re-read it)
3. Re-implement changes based on the updated ticket
4. Return to Step 2.2

**"Abandon"**:
1. Follow the **Approval** section below (Handle Abandonment)
2. Break loop, skip Phase 3, go directly to Phase 4 (same as "Approve and stop")

### Phase 3: Re-check and Continue

After all tickets from the navigator's list are processed:

1. **Re-check todo directory**:
   ```bash
   ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
   ```

2. **If new tickets found**:
   - Inform user: "Found N new ticket(s) added during this session."
   - Re-invoke drive-navigator with mode = "normal"
   - Continue to Phase 2 with the new ticket list

3. **If no new tickets**:
   - Check icebox (existing behavior from navigator)
   - If user declines icebox or icebox empty, proceed to Phase 4

### Phase 4: Completion

After todo is truly empty (and user declines icebox):
- Summarize what was done across all batches
- List all commits created during the session

**Session-wide tracking**: Maintain counters across multiple navigator batches:
- Total tickets implemented
- Total commits created
- List of all commit hashes

### Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented (out of scope, too complex, blocked, or any other reason):

1. **Stop and ask the developer** using `AskUserQuestion` with selectable `options`
2. Explain why implementation cannot proceed
3. Use selectable options (NEVER open-ended text questions):
   - "Move to icebox" - Move ticket to `.workaholic/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**

## Navigator

Navigate tickets for the `/drive` command. The `work:drive-navigator` subagent runs this section. Lists, analyzes, prioritizes, and confirms execution order with user.

### Input

You will receive:

- `mode`: Either "normal" or "icebox"

### Icebox Mode (mode = "icebox")

1. List tickets in `.workaholic/tickets/icebox/`:
   ```bash
   ls -1 .workaholic/tickets/icebox/*.md 2>/dev/null
   ```
2. If no tickets, return: `{"status": "empty", "tickets": []}`
3. If tickets found, use `AskUserQuestion` with selectable options listing each ticket
4. Move selected ticket to `.workaholic/tickets/todo/`:
   ```bash
   mv .workaholic/tickets/icebox/<selected>.md .workaholic/tickets/todo/
   git add .workaholic/tickets/icebox/<selected>.md .workaholic/tickets/todo/<selected>.md
   ```
5. Return the moved ticket for implementation

### Normal Mode (mode = "normal")

#### 1. List and Analyze Tickets

List all tickets in `.workaholic/tickets/todo/`:

```bash
ls -1 .workaholic/tickets/todo/*.md 2>/dev/null
```

**If no tickets found:**

1. Check if `.workaholic/tickets/icebox/` has tickets:
   ```bash
   ls -1 .workaholic/tickets/icebox/*.md 2>/dev/null
   ```
2. If icebox has tickets, use `AskUserQuestion` with selectable options:
   - "Work on icebox" - Return with icebox mode request
   - "Stop" - Return empty result
3. If icebox is also empty, return: `{"status": "empty", "tickets": []}`

**If tickets found:**

For each ticket, read and extract YAML frontmatter to get:
- `type`: bugfix > enhancement > refactoring > housekeeping (priority ranking)
- `layer`: Group related layers for context efficiency
- `depends_on`: List of ticket filenames this ticket depends on (optional)

#### 2. Determine Priority Order

Consider these factors (in order of precedence):

1. **Dependency ordering**: Build a dependency graph from `depends_on` fields and perform topological sort. Tickets with no dependencies come first, then tickets whose dependencies are satisfied. If a cycle is detected, warn in the output and fall back to type-based priority for the cycled tickets.
2. **Severity**: Within the same dependency tier, bugfixes take precedence over enhancements
3. **Context grouping**: Process tickets affecting same layer/files together
4. **Implicit dependencies**: If ticket A modifies files that ticket B reads, process A first

Handle missing metadata gracefully - default to normal priority when fields are absent. Treat empty or missing `depends_on` as no dependencies.

Priority ranking by type (used within same dependency tier):
1. `bugfix` - High priority
2. `enhancement` - Normal priority
3. `refactoring` - Normal priority
4. `housekeeping` - Low priority

#### 3. Present Prioritized List

Show tickets grouped by priority tier:

```
Found 4 tickets to implement:

**High Priority (bugfix)**
1. 20260131-fix-login-error.md

**Normal Priority (enhancement)**
2. 20260131-add-dark-mode.md [layer: UX]
3. 20260131-add-api-endpoint.md [layer: Infrastructure]

**Low Priority (housekeeping)**
4. 20260131-cleanup-unused-imports.md [depends on: 20260131-add-api-endpoint.md]

Proposed order considers dependencies, severity, and context grouping.
```

#### 4. Confirm Order with User

**ALWAYS use `AskUserQuestion` with selectable `options` parameter. NEVER ask open-ended text questions.**

Use selectable options:
- **Proceed** - Execute in proposed order
- **Pick one** - Let user select a specific ticket to start with
- **Original order** - Use chronological/alphabetical order instead

If user selects "Pick one", present a follow-up question with each ticket as an option.

### Navigator Output

Return a JSON object:

```json
{
  "status": "ready",
  "tickets": [
    ".workaholic/tickets/todo/20260131-fix-login-error.md",
    ".workaholic/tickets/todo/20260131-add-dark-mode.md"
  ]
}
```

Possible status values:
- `"ready"` - Tickets are ready for implementation in the returned order
- `"empty"` - No tickets to process
- `"stopped"` - User chose to stop
- `"icebox"` - User wants to switch to icebox mode (re-invoke with mode="icebox")

## Workflow

Step-by-step workflow for implementing a single ticket during `/drive`. This skill is preloaded directly by the drive command.

**IMPORTANT**: This workflow implements changes only. Approval and commit are handled by the `/drive` command after implementation.

### Steps

#### 1. Read and Understand the Ticket

- Read the ticket file to understand requirements
- Identify key files mentioned in the ticket
- Understand the implementation steps outlined

#### 2. Apply Patches (if present)

If the ticket has a "## Patches" section:

1. For each patch in the section:
   - Write patch content to a temporary file
   - Validate with `git apply --check <patch-file>`
   - If valid, apply with `git apply <patch-file>`
   - Clean up temporary file
2. Report which patches applied successfully
3. For failed patches, note them and proceed with manual implementation

If no Patches section exists, skip to step 3.

#### 3. Implement the Ticket

- Read the ticket's `layer` field. For each layer, apply the policies, practices, and standards from the matching leading skill: UX → `standards:leading-accessibility`, Domain → `standards:leading-validity`, Infrastructure → `standards:leading-availability`, DB → `standards:leading-validity`, Config → the lead whose policies the config touches. Anything touching authentication, authorization, secrets, or input validation also engages `standards:leading-security`.
- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- For areas where patches applied, verify and adjust as needed
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

#### 4. Return Summary (DO NOT COMMIT)

After implementation is complete, return a summary to the parent command:

```json
{
  "status": "pending_approval",
  "ticket_path": "<path to ticket>",
  "title": "<Title from H1>",
  "overview": "<Summary from Overview section>",
  "changes": ["<Change 1>", "<Change 2>", "..."],
  "repo_url": "<repository URL>"
}
```

### Critical Rules

- **NEVER commit** - drive command handles commit after user approval
- **NEVER use AskUserQuestion** - drive command handles approval dialog
- **NEVER archive tickets** - drive command handles archiving
- After implementation, proceed to approval flow

### Prohibited Operations

**Context**: This repository may have multiple contributors (developers, other agents) working concurrently. Uncommitted changes in the working directory may not belong to you.

The following destructive git commands are **NEVER** allowed during implementation:

| Command | Risk | Alternative |
|---------|------|-------------|
| `git clean` | Deletes untracked files that may belong to other contributors | Do not use |
| `git checkout .` | Discards all uncommitted changes including others' work | Use targeted checkout for specific files |
| `git restore .` | Discards all uncommitted changes including others' work | Reserved for abandonment flow only |
| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |

**Rationale**: You are not the only one working in this repository. Destructive operations affect everyone's uncommitted work, not just your own implementation. Always check `git status` before any operation that discards changes, and be considerate of work that may not be yours.

If an implementation requires discarding changes, use targeted commands that affect only specific files you modified, or request user approval first.

### System Safety

Before implementation, check whether the repository authorizes system-wide configuration changes by following the preloaded **system-safety** skill. Run the detection script and respect the result:

- If `system_changes_authorized` is `false`: the prohibited operations list in the system-safety skill applies unconditionally. Do not install global packages, edit shell profiles, modify `/etc/` files, manage system services, or use `sudo`.
- If `system_changes_authorized` is `true`: system-wide changes are permitted because the repository is a provisioning repository.

When an implementation step requires a prohibited operation, propose a safe project-local alternative (see the system-safety skill's Safe Alternatives table). If no alternative exists, report the blocker to the user.

## Approval

User approval flow for `/drive` implementation review.

### 1. Request Approval

Present approval dialog after implementing a ticket.

#### Format

```
**Ticket: <title from ticket H1>**
<overview from ticket Overview section>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

#### Options

**CRITICAL**: The `header` and `question` fields below are templates that MUST be replaced with actual values before presenting to the user. Use `title` and `overview` from the workflow result JSON. If those values are not available in context, re-read the ticket file to obtain the H1 title and Overview section. Presenting an approval prompt with missing, empty, or literal angle-bracket placeholder values is a failure condition -- the user cannot make an informed decision without knowing what ticket was implemented.

```json
{
  "questions": [{
    "question": "<overview from ticket Overview section>\n\nApprove this implementation?",
    "header": "<title from ticket H1>",
    "options": [
      {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
      {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
      {"label": "Abandon", "description": "Write failure analysis, discard changes, stop session"}
    ],
    "multiSelect": false
  }]
}
```

Users can also select "Other" to provide free-form feedback.

### 2. Handle Approval

When user selects "Approve" or "Approve and stop":

1. Update ticket with effort and Final Report (see **Final Report** section below)
2. Archive and commit (see **Archive** section below)
3. For "Approve": continue to next ticket
4. For "Approve and stop": end drive session

### 3. Handle Feedback

When user selects "Other" and provides feedback:

**CRITICAL: Update the ticket file BEFORE making ANY code changes. Do NOT skip this step. Do NOT write code until steps 1-2 are verified complete.**

1. **Update Implementation Steps** in the ticket file:
   - Add new steps for requested functionality
   - Modify existing steps that need adjustment

2. **Append Discussion section** (before Final Report if exists):

```markdown
## Discussion

### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

**User feedback**: <verbatim feedback>

**Ticket updates**: <list of Implementation Steps added/modified>

**Direction change**: <interpretation of how to change approach>
```

For subsequent revisions, append as "### Revision 2", etc.

3. **Verify ticket update**: Re-read the ticket file to confirm both Implementation Steps and Discussion section were written successfully. If the update failed, retry before proceeding.

4. **Re-implement** following the updated ticket's Implementation Steps
5. Return to approval flow (Section 1). **CRITICAL**: Before presenting the approval prompt again, ensure you have the ticket title (H1 heading) and overview available. Re-read the ticket file if needed -- the feedback loop must not lose ticket context.

### 4. Handle Abandonment

When user selects "Abandon":

#### Discard Changes

Check for other contributors' work before discarding:

```bash
git status --porcelain
```

Discard only your implementation changes:

```bash
git restore <file1> <file2> ...
```

#### Record Failure

Append to ticket:

```markdown
## Failure Analysis

### What Was Attempted
- <implementation approach>

### Why It Failed
- <reason abandoned>

### Insights for Future Attempts
- <learnings>
```

#### Archive Abandoned Ticket

```bash
mkdir -p .workaholic/tickets/abandoned
mv <ticket-path> .workaholic/tickets/abandoned/
```

Commit using **commit** skill:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "None" \
  "None" \
  "Ticket moved to abandoned with failure analysis" \
  .workaholic/tickets/
```

Stop the drive session. Return control to the drive command to present the completion summary.

## Final Report

After user approves implementation, update the ticket with effort and final report.

### Update Effort Field

Estimate the actual time this implementation took, then round to the nearest valid value.

**The ONLY valid values are:** `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Do NOT use t-shirt sizes (S/M/L/XS/XL), minutes (10m/30m), or any other format. The `update.sh` script will reject invalid values.

**Valid values (hour-based only):**

| Value | Use For |
|-------|---------|
| `0.1h` | Trivial changes (typo fix, config tweak) |
| `0.25h` | Simple changes (add field, update text) |
| `0.5h` | Small feature or fix (new function, bug fix) |
| `1h` | Medium feature (new component, refactor) |
| `2h` | Large feature (new workflow, significant refactor) |
| `4h` | Very large feature (new system, major rewrite) |

ALWAYS use one of these exact values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

#### How to Update

**MUST use update.sh** -- NEVER use the Edit tool to modify the effort field directly.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh <ticket-path> effort <value>
```

Example:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh .workaholic/tickets/todo/20260212-example.md effort 0.5h
```

### Final Report Section

Append `## Final Report` section to the ticket file.

**If no insights discovered:**

```markdown
## Final Report

Development completed as planned.
```

**If meaningful insights were discovered:**

```markdown
## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: <what was discovered>
  **Context**: <why this matters for understanding the codebase>
```

### What Makes a Good Insight

Include insights that fall into these categories:

- **Architectural patterns**: Hidden design decisions or conventions not documented elsewhere
- **Code relationships**: Non-obvious dependencies or coupling between components
- **Historical context**: Why something exists in its current form
- **Edge cases**: Gotchas or surprising behaviors future developers should know

### Insight Guidelines

- Keep insights actionable and specific, not vague observations
- Insights should benefit someone reading the ticket months later
- Don't duplicate information already in Overview or Implementation Steps
- If no meaningful insights, omit the subsection entirely

## Archive

Complete commit workflow after user approves implementation. Always use this script - never manually move tickets.

> **CRITICAL: NEVER manually archive tickets.** Do not use `mv` + `git add` + `git commit` to move
> tickets from `todo/` to `archive/`. The `archive.sh` script is the ONLY authorized method.
> Manual moves cause unstaged deletions because agents forget to stage the old path.

### Prerequisites

**CRITICAL**: Before calling the archive script, verify that all required frontmatter fields have been successfully updated:

1. **Verify effort field**: The ticket MUST have a valid `effort:` value (e.g., `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
2. **Abort on failure**: If frontmatter update failed (e.g., Edit tool error), **DO NOT proceed with archiving**
3. **Report the error**: Inform the user that frontmatter update failed and the ticket cannot be archived

**Never archive a ticket without all required frontmatter fields.**

### Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
  <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
```

Follow the **commit** skill's Message Format section for message format.

### Archive Example

```
Add structured commit message format

Description: Commit messages lacked structured sections for downstream lead agents, making it harder to generate documentation and understand impact at a glance. Lead agents (leading-validity, leading-availability, leading-security) need to judge what is required to ship each change without reading the full diff. Restructured the format from three sections (Motivation, UX Change, Arch Change) to five well-scoped sections that give each lead enough signal to act.

Changes: None -- this is an internal change to commit message format templates. The CLI behavior, command interfaces, and user-facing output remain identical.

Test Planning: Verified commit.sh produces correctly labeled sections with all five parameters by running the script with sample inputs. Confirmed empty description fields are handled gracefully (Description section omitted when empty). Checked that archive.sh passes all seven positional arguments correctly to commit.sh.

Release Preparation: None -- backward-compatible change to message format. Existing lead agents consume commit messages as free text and will parse the new section labels automatically.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Update Frontmatter

Update ticket YAML frontmatter fields after implementation.

### Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh <ticket-path> <field> <value>
```

### Fields

#### effort

Time spent in numeric hours.

Valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Invalid: `XS`, `S`, `M`, `10m` (t-shirt sizes and minutes are not allowed)

Update when: After implementation, before archiving.

#### commit_hash

Short git commit hash (7 characters).

Update when: After creating the commit, set automatically by archive script.

#### category

Change category based on commit message verb.

Values:
- **Added**: Add, Create, Implement, Introduce
- **Changed**: Update, Fix, Refactor (default)
- **Removed**: Remove, Delete

Update when: After creating the commit, set automatically by archive script.

### Field Insertion Order

When a field doesn't exist, it's inserted in this order:
1. After `layer:` -> `effort:`
2. After `effort:` -> `commit_hash:`
3. After `commit_hash:` -> `category:`
