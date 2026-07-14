---
name: create-ticket
description: Use when the user runs `/ticket <description>` or asks to "write a ticket", "spec out a feature", or "draft an implementation plan". Discovers historical context, source code, and standards for the request, then writes an implementation ticket to `.workaholic/tickets/todo/` with frontmatter, key files, related history, implementation steps, and considerations.
---

# Create Ticket

Guidelines for creating implementation tickets in `.workaholic/tickets/`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. The two Claude-Code mechanisms used below are **enhancements, not requirements**:

- **Parallel fan-out** — where a step spawns parallel workers to run parts concurrently (e.g. the three discovery modes), that is the Claude Code optimization. On other agents, perform those parts **sequentially** in the same session; the inputs and outputs are identical.
- **User interaction** — where a step uses the agent's selection prompt, use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The decision points are mandatory; only the prompt mechanism varies. Prefix each interactive prompt's (the agent's selection prompt) `question` body with `[<project label>]` — run `bash gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## Summary Mode

`/ticket` has a read-only **summary** mode, triggered by a bare invocation (empty `$ARGUMENT`) or the explicit argument `summary`. It reports the current user's assigned todo tickets and creates nothing — the discovery workflow, worktree guard, and every the agent's selection prompt are skipped.

```bash
bash create-ticket/scripts/summary.sh
```

`summary.sh` reuses `drive/list-todo.sh` for the current-user scoping (`todo/<user-slug>/`, from `git config user.email`), so "assigned to me" stays defined in one place, then enriches each ticket with its H1 title and frontmatter `type`/`layer`/`depends_on`. Output is a JSON array `[{path, title, type, layer, depends_on}]` (sorted by path), or `[]` when the queue is empty. This is the create-only guardrail's one read-only exception: it lists work, it never writes.

## Allowed Locations

Tickets are written to ONE of these two directories — never anywhere else:

- `.workaholic/tickets/todo/<user>/` — Active queue (default for new tickets). `<user>` is the filesystem-safe slug of `git config user.email` (the `user_slug` from Step 1). Partitioning the queue per developer stops one developer's unarchived tickets from leaking onto another's branch and being re-driven. The flat `todo/` root is never a write target for new tickets; any strays already sitting there are swept into a user subdirectory (see Step 1.5).
- `.workaholic/tickets/icebox/` — Deferred, and stays flat (only when the request explicitly targets the icebox).

Archive paths (`.workaholic/tickets/archive/<branch>/`) are written by the drive archive script, never by this skill.

**PROHIBITED**: Do NOT write tickets into any other directory under `.workaholic/`, including but not limited to: `RFDs/`, `policies/`, `specs/`, `guides/`, `stories/`, `terms/`, `release-notes/`, `trips/`, `constraints/`, `concerns/`. Even if the user's request sounds like a design discussion, RFD, spec, policy, or deferred concern, the artifact produced by this skill is a ticket and must live under `.workaholic/tickets/`. Other artifact types (including deferred concerns/ideas — those are written by `ship` and updated by `report`) are out of scope for this skill.

**Rationale**: The drive workflow, archive script, navigator, report skill, and validation hook all scan `.workaholic/tickets/` exclusively. A ticket placed in a sibling directory becomes invisible to the rest of the pipeline. The `plugins/workaholic/hooks/validate-ticket.sh` hook enforces this and rejects ticket-shaped files (filename matching `YYYYMMDDHHmmss-*.md`) written outside `.workaholic/tickets/`.

### Trip Origin (trip-emitted tickets)

A `/trip` produces its tickets through the trip-protocol **Decomposition gate** (Planning Phase Step 5), where the Constructor decomposes the agreed `designs/design-v<N>.md` into implementation tickets. Those tickets follow this skill's File Structure and the same location rule above — they are written under `.workaholic/tickets/todo/<user>/`, **never** under `.workaholic/trips/`. The only addition is a **Trip Origin** reference: a line linking the ticket back to the section of `.workaholic/trips/<trip-name>/designs/design-v<N>.md` that justifies it, so the rationale (in `trips/`) stays one link from the contract (the ticket). Add it as a short note under the `## Overview`, e.g. `**Trip Origin:** .workaholic/trips/<name>/designs/design-v2.md § "Data layer"`. Drive-created tickets (via `/ticket`) omit it.

## Step 1: Capture Dynamic Values

**Run the ticket-metadata script:**

```bash
bash gather/scripts/ticket-metadata.sh
```

Parse the JSON output:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546",
  "user_slug": "developer-company-com"
}
```

Use `created_at`/`author` for frontmatter fields, `filename_timestamp` for the filename, and `user_slug` for the `todo/<user>/` write path.

## Step 1.5: Sweep Stray Tickets

Before writing the new ticket, route any leftover tickets sitting directly at the `todo/` root into per-user subdirectories:

```bash
bash create-ticket/scripts/sweep-todo.sh
```

The sweep moves each root-level `todo/*.md` into `todo/<author-slug>/`, routing by the stray ticket's own `author:` frontmatter (falling back to the current user's slug when missing). It git-stages every move and **never** moves a ticket to the icebox. Report the `moved` count from its JSON output if any tickets were relocated.

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
mission:                           # optional: the slug of the mission this ticket advances (empty when none)
---
```

### Field Requirements

- **Lines 1-4**: Fill with actual values (never placeholders)
- **Lines 5-8** (`effort`/`commit_hash`/`category`/`depends_on`): Must be present but leave empty (filled after implementation, or during creation when a request is split)
- **`mission`**: Optional. Present but empty unless the developer associates the ticket with an existing mission at `/ticket` time (see Workflow Step 4c) — then it holds that mission's `slug`. Machine-readable, never required; the pipeline tolerates its absence.

## Common Mistakes

These cause validation failures:

| Mistake | Example | Fix |
|---------|---------|-----|
| Missing empty fields | Omitting `effort:` line | Include all 8 fields, even if empty |
| Placeholder values | `author: user@example.com` | Run `git config user.email` and use actual output |
| Wrong date format | `2026-01-31` or `2026/01/31T...` | Use `date -Iseconds` output (includes timezone) |
| Invalid layer value | `layer: [Frontend]` | Use only `UX`, `Domain`, `Infrastructure`, `DB`, `Config` (the array form is the house style) |
| Invalid depends_on entry | `depends_on: [notes.md]` | List real ticket filenames: `depends_on: [20260131192546-foo.md]` |

## Filename Convention

Format: `YYYYMMDDHHmmss-<short-description>.md`

Use current timestamp: `date +%Y%m%d%H%M%S`

Example: `20260114153042-add-dark-mode.md`

## Workflow

The `/ticket` command (main agent) drives this Workflow directly. Skills cannot invoke subagents or the agent's selection prompt directly; the steps below describe what the loading agent (the command) must do. The command issues every the agent's selection prompt (moderation decisions, clarifications) and spawns every discovery subagent itself — no `ticket-organizer` subagent sits in between.

### 0. Load the Policy Lens (first)

Before scoping the request or writing any ticket content, load the project's engineering policies as your judging lens: `planning`, `design`, `implementation`, and `operation`. On Claude Code these arrive automatically (this skill preloads them via its `skills:` frontmatter and the `/ticket` command's `policy-lens.sh` hook injects the reminder); on other agents, open each index skill yourself. Read those indexes, then open the specific policy hard copies they link (`policies/<slug>.md`) for the layer(s) the request touches — use the **Policy Lens** table below to pick which skill(s) apply.

These policies are the lens you judge the work against. Every proposal you put in the ticket — its **planning** (business/market/legal grounding), its **design** (interaction and behavior), its **implementation** (code structure and correctness), and its **operation** (delivery, runtime, and recovery) — must be defensible against the relevant policy's Goal (目標), Responsibility (責務), and Practices (実践). `implementation/directory-structure` and `implementation/coding-standards` always apply to code work, especially when scaffolding a new project. Carry the applicable policies forward into Implementation Steps, Considerations, and Patches.

If a policy index is somehow not in context, load it with the Skill tool and proceed; the rest of the workflow does not depend on the hook having fired.

### 1. Check Branch

Run `bash branching/scripts/check.sh`. If `on_main` is true, create a topic branch **only** by running `bash branching/scripts/create.sh`, and record the returned branch name as `branch_created` for the output JSON.

**Branch-name rule (mandatory):** the branch name is **always** exactly `work-<YYYYMMDD-HHMMSS>`, produced by `create.sh`. Do **not** name a branch yourself, do **not** append a feature/description suffix, and do **not** use any other prefix (`drive-`, `trip/`, a feature name, etc.). `create.sh` is the only branch-creation path.

Already-on-a-topic-branch returns `on_main: false` and skips creation (including legacy `drive-*`/`trip/*` branches, which are still recognized but never created anew); tickets go to `.workaholic/tickets/todo/` regardless of branch type.

### 2. Parallel Discovery

The command spawns three parallel workers in parallel (single message with three Task calls), one per discovery mode. Each prompt instructs the subagent to preload `discover`, run the section matching its mode, and return that mode's output schema:

- **history** (`mode: history` → `discover` Discover History): Returns JSON with summary, tickets list, match reasons, and `moderation` field (status/matches/recommendation).
- **source** (`mode: source` → `discover` Discover Source): Returns JSON with summary, files list, code_flow, and optional snippets.
- **policy** (`mode: policy` → `discover` Discover Policy): Returns JSON with summary, policies list, and architecture (principles, dependency_rules).

These are leaf subagents — they do non-interactive discovery only and MUST NOT call the agent's selection prompt. Wait for all three to complete before proceeding.

### 3. Handle Moderation Result

Based on the history discovery subagent's `moderation` field:

- `moderation.status: "duplicate"` — Return `status: "duplicate"` with existing ticket path.
- `moderation.status: "needs_decision"` — Return `status: "needs_decision"` with merge/split options.
- `moderation.status: "clear"` — Proceed to step 4.

### 4. Evaluate Complexity

- **Split when**: multiple independent features, unrelated layers, multiple commits needed.
- **Keep single when**: tightly coupled, shared context, small enough for one commit.
- If splitting: 2-4 discrete tickets, each independently implementable.

### 4b. Quality Gate Interrogation (mandatory — always run)

Before writing the ticket, **interrogate the developer about how the outcome's quality will be assured**, and record the answers as the ticket's mandatory `## Quality Gate` section. This step **always runs** — it is not skippable and is not gated on the request "seeming obvious." The point is to make the eventual `/drive` approval concrete: the developer should approve the implementation against a gate they pre-agreed, not a vague description.

**Grill, don't tick a box.** Ask enough focused questions (one or several the agent's selection prompt rounds, issued by the command/main agent — leaves cannot ask) to pin down a gate that is **objective and checkable**, converting vague intent ("make it robust") into verifiable criteria ("`node scripts/test-workflow-scripts.mjs` green; returns 422 on a missing email"). Cover:

- **Verification method** — which automated tests, type-checks, CI checks, manual steps, or production probes will prove the outcome.
- **Acceptance criteria** — the specific, checkable conditions that must hold for the work to be correct (each phrased as a verifiable statement, per `implementation` / `objective-documentation`).
- **The gate** — exactly which checks/commands must be green before the developer approves at `/drive`.
- **Edge cases / failure modes** — what must be covered, not just the happy path.
- **Division of assurance** — what Claude verifies during implementation vs. what the developer confirms at the approval gate.

Keep asking until the gate is concrete enough to drive an approval prompt. Seed proposals from discovery's `source.test_coverage` and any existing CI checks so the questions are specific, but the developer's answers are authoritative. Prefer machine-checkable substance (tests / type-checks / CI gates) over manual sign-off (`implementation` / `test`, `operation` / `ci-cd`).

> **Do not soften this step.** A "minimal-friction / skip if it seems obvious" escape hatch is explicitly **not** wanted here — thorough interrogation is the goal, not a cost. Issue these questions through the same `needs_clarification` channel the command relays via the agent's selection prompt.

### 4c. Offer Mission Association (optional)

Before writing, offer to associate the ticket(s) with an existing **mission** — a long-lived goal spanning many tickets (see `mission`). List the missions:

```bash
bash mission/scripts/list.sh
```

If the array contains missions with `status: active`, the command issues one the agent's selection prompt offering each **active** mission (by `title` + `slug`) plus a **"None"** option, and writes the chosen mission's `slug` into each written ticket's `mission:` frontmatter field (ended — `achieved`/`abandoned` — missions live in the archive area and are never offered: new work does not advance a closed mission). If no active mission exists, or the developer picks "None", leave `mission:` empty. Because the choice is drawn from the list of existing missions, the written slug is valid by construction — no separate slug validation is applied (the field is optional and the pipeline tolerates its absence). Skip this step silently when there are no missions.

### 5. Write Ticket(s)

Follow the rest of this skill for format and content. Apply the Policy Lens table (below) to map the ticket's `layer` field to the relevant `workaholic:` policy skill — its policies and practices govern the ticket's Implementation Steps, Considerations, and Patches.

Populate sections from the three discovery JSONs:

- **history → Related History**: `summary` provides the 1-2 sentence synthesis; `tickets` provides a bullet list, one markdown link each — `[filename.md](.workaholic/tickets/archive/<branch>/filename.md) - description (match reason)` — with `<branch>` taken from the search result (e.g. `feat-20260126-214833`). Omit the Related History section entirely if there are no matches.
- **source → Key Files**: `files` array provides paths and relevance descriptions.
- **source → Implementation Steps**: reference `code_flow`.
- **source.snippets → Patches**: generate unified diffs from snippets. Follow the patch guidelines in this skill. Mark patches as speculative if based on interpretation rather than explicit requirements. Omit the Patches section if changes cannot be expressed as concrete diffs.
- **policy → Policies**: write the mandatory `## Policies` section. Always list the two universal implementation policies (`directory-structure`, `coding-standards`), then add the pillar policies the ticket's `layer` selects via the Policy Lens table, plus any specific policy the policy-mode discovery surfaced. Each entry is `workaholic:<pillar>` / `policies/<slug>.md` followed by one line on why it applies. This is the recorded list `/drive` and `/trip` read before implementing — never leave it empty for a code-touching ticket.
- **interrogation → Quality Gate**: write the mandatory `## Quality Gate` section from the Step 4b interrogation answers (unlike the other sections, this content is **developer-elicited**, not discovery-fed). Structure it as **Acceptance Criteria** (checkable bullets), **Verification Method** (the commands/tests/probes that prove them), and **Gate** (what must pass before approval). Keep every line objective and verifiable. This is the recorded gate `/drive` surfaces in its approval prompt and forwards into the commit `Verify:` key — never leave it empty.
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
      "path": ".workaholic/tickets/todo/developer-company-com/20260131-feature.md",
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
  "existing_ticket": ".workaholic/tickets/todo/developer-company-com/20260130-existing.md",
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

Or if clarification needed — this is also the channel for the **mandatory Quality Gate interrogation** (Workflow Step 4b): return the QA questions here so the command relays them via the agent's selection prompt, then incorporate the answers into the `## Quality Gate` section:

```json
{
  "status": "needs_clarification",
  "questions": ["Question 1?", "Question 2?"]
}
```

**CRITICAL**: Never implement code changes — only discover context and write tickets. Never commit. Never use the agent's selection prompt (the command relays decisions/clarifications). Return JSON only.

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
mission:
---

# <Title>

## Overview

<Brief description of what will be implemented>

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践). `/drive` and `/trip` both consume this section verbatim — it is the recorded, confirmable list of which standard policies the implementation answers to.

This section is **mandatory and never empty**. A code-touching ticket always lists at least the two universal implementation policies; add the pillar policies the `layer` field selects (see the Policy Lens table) plus any specific policy the policy-mode discovery surfaced.

- `implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `implementation` / `policies/coding-standards.md` — TypeScript/style conventions (applies to all code work)
- `design` / `policies/modeless-design.md` — <why this policy applies to this ticket>

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

## Quality Gate

How the outcome's quality is assured, captured from the developer at ticket time (Workflow Step 4b). `/drive` surfaces this in its approval prompt and forwards it into the commit `Verify:` key, so the approval is concrete: the implementation is approved against a pre-agreed, checkable gate. **Mandatory and never empty** for a code-touching ticket; every line must be objective and verifiable (`implementation` / `objective-documentation`).

**Acceptance criteria** — the checkable conditions that must hold:

- <e.g. `git branch | grep` exits 0 (allow); `git branch foo` exits 2 (block)>

**Verification method** — the commands/tests/probes that prove them:

- <e.g. `node scripts/test-workflow-scripts.mjs` is green; the new assertions cover the criteria>

**Gate** — what must pass before approval:

- <e.g. the suite is green, posix-lint conforming, and the change verified live in-session>

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

- **depends_on**: List of ticket filenames that must be implemented before this ticket. Populated automatically when the `/ticket` command splits a request. Format: YAML list of filenames (e.g., `[20260410002111-foundation.md]`). Leave empty for standalone tickets.
- **mission**: The `slug` of an existing mission this ticket advances (see `mission`). Chosen at `/ticket` time from the list of existing missions (Workflow Step 4c), or left empty. This is the machine-readable ticket→mission relation a mission rolls up from; it is never required and the whole pipeline works with it absent.

## Policy Lens

Each ticket should respect the relevant policies in the `workaholic` policy skills based on its `layer` field. Map layer to skill:

| Layer | Policy skill | Lens |
| ----- | ------------ | ---- |
| UX | `design`, plus `implementation` | Modeless design, reach, WCAG conformance, emergent design system |
| Domain | `implementation` | Type-driven design, layer segregation, functional style |
| Infrastructure | `implementation`, plus `operation` | Vendor neutrality, IaC, observability; CI/CD automation |
| DB | `implementation` | Relational-first persistence, domain–persistence segregation |
| Config | (whichever skill governs the affected behavior) | Apply the skill whose policies the config touches |

Two implementation policies apply across **every** layer when a ticket touches code — `implementation/directory-structure` (conventional project layout) and `implementation/coding-standards` (TypeScript/style conventions) — and matter most when a ticket initiates a new project or a new top-level area. When a ticket initiates new work at all (a new feature or project), also apply `planning` (企画 — business, market, and legal grounding) before the design/implementation pillars.

When writing Implementation Steps, Considerations, and Patches, ensure they respect the policies and practices of every applicable skill. The four policy indexes (`planning`, `design`, `implementation`, `operation`) are the lens — on Claude Code they are preloaded and the `policy-lens.sh` hook injects the reminder on every `/ticket` run; this section documents the layer→pillar mapping for human readers and future agents.

Use this mapping to fill the ticket's mandatory **`## Policies`** section. That section is the durable, in-ticket record of which standard policies (synced from qmu.co.jp) the work answers to: the policy lens is preloaded *while the ticket is written*, but `/drive` and `/trip` implement the ticket later — they read the recorded `## Policies` list to know exactly which policy hard copies to open before writing code. Keeping the list explicit in the ticket is what lets a developer confirm, after the fact, that the implementation referred to the corporate standard policies.

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
