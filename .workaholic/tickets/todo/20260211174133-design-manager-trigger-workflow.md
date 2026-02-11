---
created_at: 2026-02-11T17:41:33+08:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Design Manager Trigger Workflow and Constraint-Setting Process

## Overview

Define when and how manager agents are triggered, what their constraint-setting workflow looks like, and what artifact types they produce. Managers exist to stabilize the project backbone by setting constraints -- policies, guidelines, roadmaps, and other directional materials that leaders and human developers follow. This ticket designs the operational workflow: the triggers that activate managers, the interactive process they follow (analyze, question, propose), and the output artifact lifecycle.

The manager tier (project-manager, architecture-manager, quality-manager) was introduced in the previous ticket but currently only runs during `/scan`. The core question this ticket answers is: beyond scan, when should managers activate, and how should they interact with users to establish constraints?

## Key Files

- `plugins/core/commands/scan.md` - Currently the only entry point for all agents; managers need additional trigger points
- `plugins/core/commands/drive.md` - Drive workflow; potential trigger point when manager outputs are stale or missing
- `plugins/core/commands/ticket.md` - Ticket creation; potential trigger point when manager context would improve ticket quality
- `plugins/core/agents/project-manager.md` - Thin orchestrator for project management
- `plugins/core/agents/architecture-manager.md` - Thin orchestrator for architecture management
- `plugins/core/agents/quality-manager.md` - Thin orchestrator for quality management
- `plugins/core/skills/manage-project/SKILL.md` - Project manager skill; Execution section defines current workflow
- `plugins/core/skills/manage-architecture/SKILL.md` - Architecture manager skill; Execution section defines current workflow
- `plugins/core/skills/manage-quality/SKILL.md` - Quality manager skill; Execution section defines current workflow
- `plugins/core/skills/managers-policy/SKILL.md` - Cross-cutting manager policies; Strategic Focus rule governs output quality
- `.claude/rules/define-manager.md` - Manager schema; Outputs section defines artifact contract
- `plugins/core/skills/select-scan-agents/SKILL.md` - Agent selection logic; needs manager-specific selection criteria

## Related History

The project recently created the manager tier with three manager agents and skills, and has one pending ticket to wire leaders to consume manager outputs. This ticket extends the manager concept from passive scan-time execution to an active, trigger-driven constraint-setting workflow.

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created manager tier foundation: define-manager schema, 3 manager skills, managers-policy, 3 manager agents (same domain: manager tier)
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/todo/20260211170402-wire-leaders-to-manager-outputs.md) - Pending: wires leaders to consume manager outputs and adds two-phase scan execution (directly dependent: defines how leaders consume what managers produce)
- [20260210124953-add-leaders-policy-skill.md](.workaholic/tickets/archive/drive-20260210-121635/20260210124953-add-leaders-policy-skill.md) - Added leaders-policy cross-cutting skill; established the pattern that managers-policy follows (same pattern: policy layer)

## Implementation Steps

1. **Define the trigger taxonomy**

   Identify and document all situations where managers should activate. Proposed trigger categories:

   - **Explicit invocation**: A new `/manage` command that users run to initiate a constraint-setting session. This is the primary trigger for intentional strategic work.
   - **Scan-time execution**: Already planned in the wire-leaders ticket. Managers run before leaders during `/scan` to provide fresh context.
   - **Staleness detection**: During `/drive`, check if manager outputs exist and are reasonably current. If outputs are missing or significantly stale (e.g., many commits since last run), suggest running managers before proceeding.
   - **On-demand from ticket**: During `/ticket` creation, optionally invoke a manager to provide strategic context for the ticket being written.

   Write a design document at `plugins/core/skills/manage-workflow/SKILL.md` that captures this taxonomy.

2. **Design the `/manage` command**

   Create `plugins/core/commands/manage.md` as the primary user-facing entry point for manager work. The command should:

   - Accept an optional domain argument: `/manage`, `/manage project`, `/manage architecture`, `/manage quality`
   - Without argument: run all three managers sequentially with user interaction between each
   - With argument: run only the specified manager
   - The workflow for each manager:
     1. **Analyze**: Manager reads the current codebase and existing constraints
     2. **Question**: Manager asks the user clarifying questions about intent, priorities, and boundaries using `AskUserQuestion`
     3. **Propose**: Manager presents proposed constraints as draft documents
     4. **Confirm**: User reviews and approves, requests changes, or rejects
     5. **Commit**: Approved constraints are written to `.workaholic/` and committed

3. **Design the constraint output format**

   Define where manager-produced constraints live and what form they take:

   - **Policies**: Written to `.workaholic/policies/` (already exists as output location for leader-produced policy docs; managers would produce higher-level strategic policies)
   - **Guidelines**: Written to `.workaholic/guidelines/` (new directory for actionable guidelines that leaders follow)
   - **Roadmap**: Written to `.workaholic/roadmap.md` (project-manager output: timeline, milestones, priorities)
   - **Architecture decisions**: Written to `.workaholic/decisions/` (architecture-manager output: ADR-style records)

   Each constraint document should have frontmatter indicating which manager produced it, when, and which leaders consume it.

4. **Design the staleness detection mechanism**

   Create a skill `plugins/core/skills/check-manager-staleness/SKILL.md` with a bundled shell script that:

   - Checks if manager output files exist in `.workaholic/`
   - Compares the `modified_at` timestamp in output frontmatter against the current HEAD commit date
   - Counts commits since the output was last produced
   - Returns a JSON status: `{"stale": true/false, "managers": ["project", "architecture"], "commits_since": 15}`

   This skill is consumed by `/drive` to optionally suggest running managers.

5. **Design the interactive constraint-setting protocol**

   Define the interaction pattern that all three managers follow when proposing constraints:

   - **Read existing constraints**: Check `.workaholic/` for existing policy/guideline/decision documents
   - **Analyze delta**: Compare codebase state against existing constraints to identify gaps or stale constraints
   - **Formulate questions**: Prepare 2-5 targeted questions for the user about areas where the manager cannot infer intent from the codebase alone
   - **Present questions**: Use `AskUserQuestion` to gather user input
   - **Draft proposal**: Generate constraint documents incorporating user answers and codebase evidence
   - **Present for review**: Show the draft to the user with a summary of what changes and why
   - **Handle feedback**: If user requests changes, iterate; if user approves, write files

   Document this protocol in `plugins/core/skills/manage-workflow/SKILL.md`.

6. **Update manager skills with interactive capabilities**

   Update the Execution section of each manager skill (`manage-project`, `manage-architecture`, `manage-quality`) to reference the manage-workflow protocol. Add a new execution mode: "interactive" (used by `/manage`) vs "autonomous" (used by `/scan`).

   - In interactive mode: follow the full analyze-question-propose-confirm cycle
   - In autonomous mode: produce outputs without user interaction (current behavior)

7. **Update the define-manager schema**

   Add guidance in `.claude/rules/define-manager.md` for the dual execution modes (interactive vs autonomous) and the constraint output locations. The schema's `## Outputs` section should document both the scan-time structured analysis output and the interactive constraint documents.

## Considerations

- The `/manage` command introduces a new user-facing workflow that is fundamentally different from `/scan`. Scan is a batch documentation update; `/manage` is an interactive strategic session. The command should feel deliberate and focused, not automated. Users invoke `/manage` when they want to think about project direction with AI assistance. (`plugins/core/commands/manage.md`)
- Staleness detection is a soft suggestion, not a blocker. `/drive` should never refuse to proceed because manager outputs are stale. It should inform the user: "Manager outputs are N commits behind. Consider running /manage for fresh context." The user decides. (`plugins/core/skills/check-manager-staleness/SKILL.md`)
- The constraint output directories (`.workaholic/guidelines/`, `.workaholic/decisions/`) are new filesystem locations. The existing `.workaholic/` structure has `tickets/`, `stories/`, `specs/`, `terms/`, and `policies/`. Adding `guidelines/` and `decisions/` should follow the same conventions (README.md index, i18n support). (`plugins/core/rules/workaholic.md`)
- Manager questions to the user should be concrete and grounded. Instead of "What is your quality strategy?", managers should ask "The codebase has no test framework configured. Should testing be a priority for the next phase?" This follows the Strategic Focus policy in managers-policy. (`plugins/core/skills/managers-policy/SKILL.md`)
- The architecture-manager already produces viewpoint specs during scan (absorbed from the former architecture-lead). In interactive mode, it would additionally produce architecture decision records. These are complementary outputs -- specs describe what IS, decisions describe what was DECIDED and WHY. (`plugins/core/skills/manage-architecture/SKILL.md`)
- Cross-reference: This ticket depends on [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/todo/20260211170402-wire-leaders-to-manager-outputs.md) for the scan-time execution phase. The interactive `/manage` workflow can be implemented independently.
- The nesting rules in CLAUDE.md state that commands can invoke subagents and skills. The `/manage` command would invoke manager subagents (project-manager, architecture-manager, quality-manager), which aligns with the architecture policy. However, managers using `AskUserQuestion` during interactive mode requires that they run with prompt access (not background), similar to the critical note in scan.md about `run_in_background: false`. (`plugins/core/commands/manage.md`, `plugins/core/commands/scan.md` lines 55-57)
