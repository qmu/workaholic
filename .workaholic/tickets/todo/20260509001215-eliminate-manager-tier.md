---
created_at: 2026-05-09T00:12:15+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Eliminate Manager Tier from Standards Plugin

## Overview

Remove the entire "manager" tier from the standards plugin: three `manage-*` skills, three `*-manager` agents, the cross-cutting `managers-principle` skill, the `define-manager` schema rule, the `/scan` command, the `select-scan-agents` skill, and all language in leading skills that says leads "consume" manager outputs. After this change the standards plugin contains only `leading-*` skills, `leaders-principle`, `analyze-*` skills, `write-*` skills, and writer agents — managers are gone entirely. The constraint-setting workflow and `.workaholic/constraints/<scope>.md` artifact format also disappear with the manager tier; the project no longer ships explicit constraint files. Specs under `.workaholic/specs/` lose their automated owner (architecture-manager produced them via the scan flow); they become hand-maintained reference docs touched alongside structural changes through the `/ticket` workflow.

This is a refactoring that simplifies the agent hierarchy. The original motivation for managers — "establish authoritative strategic context that leaders consume" — has not paid off: the constraint files are not consulted by the rest of the workflow, the scan command is unused in practice, and the indirection makes leading skills harder to read. Leads are perfectly capable of deriving their viewpoint directly from the codebase, which is what they already do in the trip and ticket flows.

## Key Files

### To delete

- `plugins/standards/skills/manage-architecture/` - Architecture manager skill (entire directory)
- `plugins/standards/skills/manage-project/` - Project manager skill (entire directory)
- `plugins/standards/skills/manage-quality/` - Quality manager skill (entire directory)
- `plugins/standards/skills/managers-principle/` - Cross-cutting manager principles (entire directory)
- `plugins/standards/skills/select-scan-agents/` - Scan agent selection skill (entire directory)
- `plugins/standards/agents/architecture-manager.md` - Architecture manager agent
- `plugins/standards/agents/project-manager.md` - Project manager agent
- `plugins/standards/agents/quality-manager.md` - Quality manager agent
- `plugins/core/commands/scan.md` - /scan command (sole consumer of the manager tier)
- `.claude/rules/define-manager.md` - Manager schema enforcement rule

### To audit and rewrite

- `plugins/standards/skills/leading-validity/SKILL.md` - Strip any "consume manager outputs" language; lead derives viewpoint directly
- `plugins/standards/skills/leading-availability/SKILL.md` - Same
- `plugins/standards/skills/leading-security/SKILL.md` - Same
- `plugins/standards/skills/leading-accessibility/SKILL.md` - Same

### Reference (not modified by this ticket)

- `.claude/rules/define-lead.md` - Lead schema; leading skills must continue to satisfy it after edits
- `plugins/standards/skills/leaders-principle/SKILL.md` - Cross-cutting lead principles; remains in place
- `plugins/core/commands/report.md` - Verify it does not reference scan or managers
- `plugins/core/commands/ship.md` - Verify it does not reference scan or managers

## Related History

The manager tier was introduced in February 2026 to provide strategic context that leads would consume; subsequent work formalized the constraint-setting workflow and produced `.workaholic/constraints/` artifacts. None of those artifacts are consulted by the active `/ticket`, `/drive`, or `/trip` flows today, which is the motivation for removing the tier entirely.

Past tickets that touched similar areas:

- [20260211170401-define-manager-tier-and-skills.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170401-define-manager-tier-and-skills.md) - Created the manager tier this ticket dismantles (define-manager schema, three manage-* skills, managers-principle, three manager agents)
- [20260211170402-wire-leaders-to-manager-outputs.md](.workaholic/tickets/archive/drive-20260210-121635/20260211170402-wire-leaders-to-manager-outputs.md) - Wired leads to consume manager outputs and added the two-phase scan; this ticket undoes that wiring
- [20260211183439-add-constraint-setting-workflow-to-managers.md](.workaholic/tickets/archive/drive-20260210-121635/20260211183439-add-constraint-setting-workflow-to-managers.md) - Added the constraint-setting workflow; that workflow goes away with the manager tier
- [20260212165728-manager-constraint-files.md](.workaholic/tickets/archive/drive-20260212-122906/20260212165728-manager-constraint-files.md) - Defined `.workaholic/constraints/<scope>.md` output format; that format goes away
- [20260212173856-rename-policy-skills-to-principle.md](.workaholic/tickets/archive/drive-20260212-122906/20260212173856-rename-policy-skills-to-principle.md) - Renamed `*-policy` skills to `*-principle`; informs naming for any residual references

## Implementation Steps

1. **Delete manager skill directories.**

   ```bash
   git rm -r plugins/standards/skills/manage-architecture
   git rm -r plugins/standards/skills/manage-project
   git rm -r plugins/standards/skills/manage-quality
   git rm -r plugins/standards/skills/managers-principle
   ```

2. **Delete manager agent files.**

   ```bash
   git rm plugins/standards/agents/architecture-manager.md
   git rm plugins/standards/agents/project-manager.md
   git rm plugins/standards/agents/quality-manager.md
   ```

3. **Delete the define-manager schema rule.**

   ```bash
   git rm .claude/rules/define-manager.md
   ```

4. **Delete the /scan command and select-scan-agents skill.**

   The /scan command is the only consumer of the manager tier and the select-scan-agents skill exists to feed it. With managers gone, the command has no purpose and there is no demand for partial-vs-full scan selection. Delete both.

   ```bash
   git rm plugins/core/commands/scan.md
   git rm -r plugins/standards/skills/select-scan-agents
   ```

5. **Audit and rewrite the four leading skills.**

   For each of `plugins/standards/skills/leading-validity/SKILL.md`, `leading-availability/SKILL.md`, `leading-security/SKILL.md`, `leading-accessibility/SKILL.md`:

   - Read the current content end-to-end.
   - Remove any sentence in Role/Goal/Responsibility/Policies/Practices that references managers, manager outputs, "consume", "receive", "strategic context", or `.workaholic/constraints/`.
   - Where a sentence said the lead derives viewpoint from manager outputs, rewrite it to say the lead derives its viewpoint directly from the codebase (existing implementation, configuration, tests, and documentation).
   - Keep Role/Goal/Responsibility narrative consistent with `.claude/rules/define-lead.md` four-tier structure (Role → Policies → Practices → Standards).
   - The current files (as of this ticket) do not contain explicit "consumes manager output" language — but they do contain Role descriptions like "analyzes the repository's [...] then produces policy documentation". Verify and tighten that wording if needed; the intent is clearly "lead reads codebase directly and produces its own documentation".

6. **Verify no orphan references remain.**

   ```bash
   grep -rn "manage-\|managers-principle\|architecture-manager\|project-manager\|quality-manager\|select-scan-agents\|/scan\b\|define-manager\|\.workaholic/constraints" \
     plugins/ .claude/ CLAUDE.md 2>/dev/null \
     | grep -v "manage-branch"
   ```

   Expected: no matches (the documentation/spec sweep that lives in the dependent ticket handles `.workaholic/specs/` and CLAUDE.md). If any unexpected matches surface in code/skill/agent files, remove them.

   The `manage-branch` exclusion preserves the unrelated branching utility (no longer present under that name in the current tree, but the grep is defensive).

7. **Confirm the standards plugin inventory after deletion.**

   The standards plugin must contain exactly:

   - `skills/leading-{validity,availability,security,accessibility}/`
   - `skills/leaders-principle/`
   - `skills/analyze-{performance,policy,viewpoint}/`
   - `skills/write-{changelog,overview,release-note,spec,terms}/`
   - `skills/review-sections/`
   - `skills/validate-writer-output/`
   - `agents/lead.md`
   - `agents/changelog-writer.md`, `release-note-writer.md`, `terms-writer.md`, `overview-writer.md`, `model-analyst.md`, `performance-analyst.md`, `section-reviewer.md`
   - `rules/`
   - `.claude-plugin/plugin.json`

   Verify with:

   ```bash
   find plugins/standards -type f | sort
   ```

## Patches

### `plugins/standards/skills/leading-availability/SKILL.md`

```diff
--- a/plugins/standards/skills/leading-availability/SKILL.md
+++ b/plugins/standards/skills/leading-availability/SKILL.md
@@ -8,7 +8,7 @@

 ## Role

-This leading skill owns the project's delivery pipelines, infrastructure, observability, and recovery domains. It analyzes the repository's CI/CD automation, external dependencies, environment requirements, provisioning practices, logging and metrics instrumentation, backup strategies, and recovery procedures, then produces documentation that accurately reflects what is implemented.
+This leading skill owns the project's delivery pipelines, infrastructure, observability, and recovery domains. It derives its viewpoint directly from the repository's CI/CD automation, external dependencies, environment requirements, provisioning practices, logging and metrics instrumentation, backup strategies, and recovery procedures, then produces documentation that accurately reflects what is implemented.
```

### `plugins/standards/skills/leading-validity/SKILL.md`

```diff
--- a/plugins/standards/skills/leading-validity/SKILL.md
+++ b/plugins/standards/skills/leading-validity/SKILL.md
@@ -16,7 +16,7 @@

 ## Role

-This leading skill owns the project's logical-validity policy domain. It analyzes the repository's type safety enforcement, linting and formatting tools, code review processes, layer segregation, data persistence strategy, testing frameworks, coverage targets, and test organization, then produces policy documentation that accurately reflects what is implemented.
+This leading skill owns the project's logical-validity policy domain. It derives its viewpoint directly from the repository's type safety enforcement, linting and formatting tools, code review processes, layer segregation, data persistence strategy, testing frameworks, coverage targets, and test organization, then produces policy documentation that accurately reflects what is implemented.
```

### `plugins/standards/skills/leading-security/SKILL.md`

```diff
--- a/plugins/standards/skills/leading-security/SKILL.md
+++ b/plugins/standards/skills/leading-security/SKILL.md
@@ -8,7 +8,7 @@

 ## Role

-This leading skill owns the project's security policy domain. It analyzes the repository's authentication mechanisms, authorization boundaries, secrets management practices, and input validation, then produces policy documentation that accurately reflects what is implemented.
+This leading skill owns the project's security policy domain. It derives its viewpoint directly from the repository's authentication mechanisms, authorization boundaries, secrets management practices, and input validation, then produces policy documentation that accurately reflects what is implemented.
```

### `plugins/standards/skills/leading-accessibility/SKILL.md`

```diff
--- a/plugins/standards/skills/leading-accessibility/SKILL.md
+++ b/plugins/standards/skills/leading-accessibility/SKILL.md
@@ -8,7 +8,7 @@

 ## Role

-This leading skill owns the project's user experience viewpoint. It analyzes the repository to understand how users interact with the system, what journeys they follow, what interaction patterns exist, and what onboarding paths are available, then produces spec documentation that accurately reflects these relationships.
+This leading skill owns the project's user experience viewpoint. It derives its viewpoint directly from the repository to understand how users interact with the system, what journeys they follow, what interaction patterns exist, and what onboarding paths are available, then produces spec documentation that accurately reflects these relationships.
```

> **Note**: These patches are speculative — verify the current Role wording before applying. The intent is to replace any verb suggesting indirection ("analyzes", "consumes manager output") with a verb that anchors the lead in the codebase ("derives its viewpoint directly from"). Adjust additional sentences in Goal/Responsibility/Policies if they imply manager dependence.

## Considerations

- **Cross-plugin dependency**: After this change the work plugin's `ticket-organizer`, `planner`, `architect`, and `constructor` agents continue to preload `standards:leading-*` skills via the soft cross-plugin reference pattern. Those preloads are unaffected by this ticket. The dependent ticket `20260509001216-wire-leads-into-work-flows.md` extends the same pattern to `/drive` and the `discover`/`create-ticket` skills. (`plugins/work/agents/ticket-organizer.md`, `plugins/work/agents/planner.md`, `plugins/work/agents/architect.md`, `plugins/work/agents/constructor.md`)
- **Documentation drift**: After this ticket, `CLAUDE.md`, `plugins/core/README.md`, and `.workaholic/specs/{application,component,data,infrastructure,ux}.md` will contain stale references to managers, the scan command, and the two-phase execution model. The dependent ticket `20260509001217-update-stale-manager-documentation.md` cleans those up. Defer the doc sweep until both refactor tickets are merged so the documentation reflects the final structure in one pass. (`CLAUDE.md`, `plugins/core/README.md`, `.workaholic/specs/`)
- **Existing constraint files**: `.workaholic/constraints/project.md` was produced by the manager tier under the previous workflow. With managers gone, no agent owns or updates this file. Leaving it in place is harmless (it is just a markdown file), but the directory will not be regenerated. Decide during implementation whether to delete `.workaholic/constraints/` outright or leave it as historical residue. The scope explicitly says to remove the constraint workflow and artifact format; deletion is consistent. Recommendation: `git rm -r .workaholic/constraints/`. (`.workaholic/constraints/`)
- **Existing spec files**: `.workaholic/specs/{application,component,feature,usecase}.md` were produced by `architecture-manager` via the scan flow. They lose their automated owner but remain useful as hand-maintained reference docs. The scope says do NOT delete them. The dependent doc-sweep ticket updates their content to reflect the new structure. (`.workaholic/specs/`)
- **`select-scan-agents` referenced by `/scan`**: Only `/scan` consumes `select-scan-agents`. Both must be removed together to avoid leaving an orphan skill. The grep audit in step 6 catches any other references. (`plugins/standards/skills/select-scan-agents/`, `plugins/core/commands/scan.md`)
- **`define-manager.md` schema**: The schema rule is path-scoped to `plugins/standards/skills/manage-*/SKILL.md` and `plugins/standards/agents/*-manager.md`. With both globs emptied, the rule has no targets and can be safely deleted. (`.claude/rules/define-manager.md`)
- **Trip and ticket agents already preload leads**: `ticket-organizer`, `planner`, `architect`, and `constructor` already declare `standards:leading-*` skills in their frontmatter. This ticket does not need to touch those preloads. The dependent wiring ticket extends the pattern to `/drive` and the `discover`/`create-ticket` skills. (`plugins/work/agents/`)
- **No backward compatibility needed**: Private marketplace, no external consumers. No deprecation period, no shims, no version-coupling concerns beyond the standard `/release` flow that runs after `/drive`. (CLAUDE.md "Important" section)
- **Plugin version bump deferred**: Per scope, version bumps and `/release` happen after `/drive` finishes implementing the queued tickets. Do not modify any `plugin.json` `version` fields in this ticket. (`plugins/standards/.claude-plugin/plugin.json`, `plugins/core/.claude-plugin/plugin.json`)
- **Leaders-principle stays**: The `leaders-principle` skill (Prior Term Consistency, Vendor Neutrality) is not affected. Only `managers-principle` is removed. (`plugins/standards/skills/leaders-principle/SKILL.md`)
- **Single commit, narrow blast radius**: This ticket is a deletion-heavy refactor. Use the `Removed` commit category. The dependent tickets handle wiring and documentation separately to keep each commit focused.
