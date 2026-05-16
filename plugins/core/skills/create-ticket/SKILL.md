---
name: create-ticket
description: Create implementation tickets with proper format and conventions.
skills:
  - gather
  - standards:leading-validity
  - standards:leading-accessibility
  - standards:leading-security
  - standards:leading-availability
user-invocable: false
---

# Create Ticket

Guidelines for creating implementation tickets in `.workaholic/tickets/`.

## Step 1: Capture Dynamic Values

**Run the ticket-metadata script:**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
```

Parse the JSON output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546"
}
```

Use these values for frontmatter fields and filename.

## Frontmatter Template

Use the captured values from Step 1:

```yaml
---
created_at: $(date -Iseconds)      # REPLACE with actual output
author: $(git config user.email)   # REPLACE with actual output
type: <enhancement | bugfix | refactoring | housekeeping>
layer: [<UX | Domain | Infrastructure | DB | Config>]
effort:
commit_hash:
category:
depends_on:
---
```

### Field Requirements

- **Lines 1-4**: Fill with actual values (never placeholders)
- **Lines 5-8**: Must be present but leave empty (filled after implementation or by ticket-organizer)

### Concrete Example

```yaml
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
type: enhancement
layer: [UX, Domain]
effort:
commit_hash:
category:
depends_on:
---
```

## Common Mistakes

These cause validation failures:

| Mistake | Example | Fix |
|---------|---------|-----|
| Missing empty fields | Omitting `effort:` line | Include all 8 fields, even if empty |
| Placeholder values | `author: user@example.com` | Run `git config user.email` and use actual output |
| Wrong date format | `2026-01-31` or `2026/01/31T...` | Use `date -Iseconds` output (includes timezone) |
| Scalar layer | `layer: Config` | Use array format: `layer: [Config]` |
| Scalar depends_on | `depends_on: file.md` | Use array format: `depends_on: [file.md]` |

## Filename Convention

Format: `YYYYMMDDHHmmss-<short-description>.md`

Use current timestamp: `date +%Y%m%d%H%M%S`

Example: `20260114153042-add-dark-mode.md`

## Workflow

Followed by `work:ticket-organizer`. Skills cannot invoke subagents or AskUserQuestion directly; the steps below describe what the loading agent must do.

### 1. Check Branch

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh`. If `on_main` is true, create a topic branch via `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh` and record the returned branch name as `branch_created` for the output JSON. Trip branches (`trip/*`) return `on_main: false` and skip branch creation; tickets go to `.workaholic/tickets/todo/` regardless of branch type.

### 2. Parallel Discovery

Invoke `work:discoverer` three times in parallel via the Task tool (single message with three Task calls), `model: "opus"`, one per mode:

- **history** (`subagent_type: "work:discoverer"`, mode: `history`): Returns JSON with summary, tickets list, match reasons, and `moderation` field (status/matches/recommendation).
- **source** (`subagent_type: "work:discoverer"`, mode: `source`): Returns JSON with summary, files list, code_flow, and optional snippets.
- **policy** (`subagent_type: "work:discoverer"`, mode: `policy`): Returns JSON with summary, policies list, and architecture (principles, dependency_rules).

Wait for all three to complete before proceeding.

### 3. Handle Moderation Result

Based on the history discoverer's `moderation` field:

- `moderation.status: "duplicate"` — Return `status: "duplicate"` with existing ticket path.
- `moderation.status: "needs_decision"` — Return `status: "needs_decision"` with merge/split options.
- `moderation.status: "clear"` — Proceed to step 4.

### 4. Evaluate Complexity

- **Split when**: multiple independent features, unrelated layers, multiple commits needed.
- **Keep single when**: tightly coupled, shared context, small enough for one commit.
- If splitting: 2-4 discrete tickets, each independently implementable.

### 5. Write Ticket(s)

Follow the rest of this skill for format and content. Apply the Lead Lens table (below) to map the ticket's `layer` field to the relevant `standards:leading-*` skill — its policies, practices, and standards govern the ticket's Implementation Steps, Considerations, and Patches.

Populate sections from the three discovery JSONs:

- **history → Related History**: `summary` field provides the synthesis sentence; `tickets` array provides the bullet list with paths and match reasons.
- **source → Key Files**: `files` array provides paths and relevance descriptions.
- **source → Implementation Steps**: reference `code_flow`.
- **source.snippets → Patches**: generate unified diffs from snippets. Follow the patch guidelines in this skill. Mark patches as speculative if based on interpretation rather than explicit requirements. Omit the Patches section if changes cannot be expressed as concrete diffs.
- **policy → Considerations**: reference relevant `policies` that the implementation must follow; note `architecture.principles` and `architecture.dependency_rules` that constrain the design.

**If splitting**:
- Unique timestamp per ticket (add 1 second between).
- First ticket is foundation.
- Populate `depends_on` in dependent tickets:
  - Determine dependency order among the split tickets.
  - The first ticket (foundation) has no `depends_on` (leave empty).
  - Subsequent tickets that depend on earlier ones list the prerequisite filenames in `depends_on` (e.g., `depends_on: [20260410002111-foundation.md]`).
  - Only add dependencies where there is a genuine implementation ordering requirement (shared files, API contracts, schema changes needed first).
- Cross-reference in the Considerations section.

### 6. Handle Ambiguity

If the request is ambiguous, return `status: "needs_clarification"` with a `questions` array.

## Output Contract

Return one of:

```json
{
  "status": "success",
  "branch_created": "work-20260202-181910",
  "tickets": [
    {
      "path": ".workaholic/tickets/todo/20260131-feature.md",
      "title": "Ticket Title",
      "summary": "Brief one-line summary"
    }
  ]
}
```

Note: `branch_created` is optional — only included if a new branch was created in step 1.

Or if duplicate:

```json
{
  "status": "duplicate",
  "existing_ticket": ".workaholic/tickets/todo/20260130-existing.md",
  "reason": "Existing ticket already covers this functionality"
}
```

Or if decision needed:

```json
{
  "status": "needs_decision",
  "decision_type": "merge|split",
  "details": "Description of the situation",
  "options": [
    {"label": "Option 1", "description": "What this does"},
    {"label": "Option 2", "description": "What this does"}
  ]
}
```

Or if clarification needed:

```json
{
  "status": "needs_clarification",
  "questions": ["Question 1?", "Question 2?"]
}
```

**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use AskUserQuestion (the command relays decisions/clarifications). Return JSON only.

## File Structure

```markdown
---
created_at: 2026-01-31T19:25:46+09:00
author: developer@company.com
type: enhancement
layer: [UX, Domain]
effort:
commit_hash:
category:
depends_on:
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Key Files

- `path/to/file.ts` - <why this file is relevant>

## Related History

<1-2 sentence summary synthesizing what historical tickets reveal about this area>

Past tickets that touched similar areas:

- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/<branch>/20260127010716-rename-terminology-to-terms.md) - Renamed terminology directory (same layer: Config)
- [20260125113858-auto-commit-ticket-on-creation.md](.workaholic/tickets/archive/<branch>/20260125113858-auto-commit-ticket-on-creation.md) - Modified ticket.md (same file)

## Implementation Steps

1. <Step 1>
2. <Step 2>
   ...

## Patches

<Optional unified diff patches for key changes - omit if no concrete code changes can be specified>

### `path/to/file.ext`

```diff
--- a/path/to/file.ext
+++ b/path/to/file.ext
@@ -10,6 +10,8 @@ existing context line
 unchanged line
-removed line
+added line
 more context
```

## Considerations

- <Concern description> (`path/to/relevant-file.ext`)
- <Concern about behavior change> (`path/to/file.ext` lines 45-60)
- <Future technical debt> (affects `path/to/module/`)
```

**Considerations Guidelines:**
- Each concern SHOULD reference a specific file path
- Use parentheses to indicate the relevant location: `(path/to/file.ext)`
- For line-specific concerns, include line ranges: `(path/to/file.ext lines 10-25)`
- If a concern is conceptual without a specific file, omit the reference

## Frontmatter Fields

### Required at Creation

- **created_at**: Creation timestamp in ISO 8601 format. Run `date -Iseconds` and use the actual output.
- **author**: Git email. Run `git config user.email` and use the actual output. Never use hardcoded values.
- **type**: Infer from request context:
  - `enhancement` - New features or capabilities (keywords: add, create, implement, new)
  - `bugfix` - Fixing broken behavior (keywords: fix, bug, broken, error)
  - `refactoring` - Restructuring without changing behavior (keywords: refactor, restructure, reorganize)
  - `housekeeping` - Maintenance, cleanup, documentation (keywords: clean, update, remove, deprecate)
- **layer**: Architectural layers affected (YAML array, can specify multiple):
  - `UX` - User interface, components, styling
  - `Domain` - Business logic, models, services
  - `Infrastructure` - External integrations, APIs, networking
  - `DB` - Database, storage, migrations
  - `Config` - Configuration, build, tooling

### Filled After Implementation

These fields are updated by the `drive` skill (Update Frontmatter section) during archiving:

- **effort**: Time spent in numeric hours (leave empty when creating)
- **commit_hash**: Short git commit hash (set by archive script)
- **category**: Added, Changed, or Removed (set by archive script)

### Optional

- **depends_on**: List of ticket filenames that must be implemented before this ticket. Populated automatically when the ticket-organizer splits a request. Format: YAML list of filenames (e.g., `[20260410002111-foundation.md]`). Leave empty for standalone tickets.

## Lead Lens

Each ticket should respect the relevant leading skills based on its `layer` field. Map layer to lead:

| Layer | Leading skill | Lens |
| ----- | ------------- | ---- |
| UX | `standards:leading-accessibility` | Reach, modeless design, WCAG conformance |
| Domain | `standards:leading-validity` | Type-driven design, layer segregation, functional style |
| Infrastructure | `standards:leading-availability` | CI/CD, vendor neutrality, IaC, observability |
| DB | `standards:leading-validity` | Relational-first persistence, domain–persistence segregation |
| Config | (whichever lead governs the affected behavior) | Apply the lead whose policies the config touches |

Anything touching authentication, authorization, secrets management, or input validation also engages `standards:leading-security` regardless of layer.

When writing Implementation Steps, Considerations, and Patches, ensure they respect the policies, practices, and standards of every applicable lead. The `ticket-organizer` agent has these skills preloaded and applies them automatically; this section documents the mapping for human readers and future agents.

## Exploring the Codebase

Before writing a ticket:

- Use Glob, Grep, and Read tools to find relevant files
- Understand existing patterns, architecture, and conventions
- Identify files that will need to be modified or created

## Related History

The Related History section is populated by the `discoverer` agent in history mode (invoked by `/ticket` command).

**Link format**: Use markdown links with repository-relative paths:
```markdown
- [filename.md](.workaholic/tickets/archive/<branch>/filename.md) - Description (match reason)
```

The full path includes the branch directory from the search results (e.g., `feat-20260126-214833`).

If the subagent returns no matches, omit the Related History section entirely.

## Patch Guidelines

Patches are optional but valuable for concrete, well-understood changes.

**When to include patches:**
- Clear code changes that can be expressed precisely
- Modifications to existing files (not new files)
- Changes where exact placement matters

**When to omit patches:**
- New file creation (no existing code to diff against)
- Complex refactoring where exploration is needed
- Changes that depend on runtime behavior

**Patch format rules:**
- Use standard unified diff format compatible with `git apply`
- Include 3 lines of context before/after each hunk
- Keep patches small and focused (max 50 lines per file)
- Use repository-relative paths (not absolute)
- One `### path/to/file` subsection per file

**Mark uncertain patches:**
```markdown
> **Note**: This patch is speculative - verify before applying.
```

## Writing Guidelines

- Focus on the "why" and "what", not just "how"
- Keep implementation steps actionable and specific
- Reference existing code patterns when applicable
- Use the Write tool directly - it creates parent directories automatically
