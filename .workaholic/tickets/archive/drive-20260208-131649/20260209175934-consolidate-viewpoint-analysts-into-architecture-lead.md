---
created_at: 2026-02-09T17:59:34+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.5h
commit_hash: ca27130
category: Changed
---

# Consolidate Four Viewpoint Analysts into Architecture Lead

## Overview

Consolidate the `application-analyst`, `component-analyst`, `feature-analyst`, and `usecase-analyst` into a single `architecture-lead` agent that owns all four viewpoints and produces all four spec documents. Create a `lead-architecture` skill that encodes the combined domain knowledge from all four viewpoints in the define-lead schema format (Role, Responsibility, Goal, Default Policies). Replace the four separate agent files with one thin `architecture-lead.md` orchestrator. Update `scan.md` and `select-scan-agents/sh/select.sh` to replace all 4 agent references with the single `architecture-lead`.

## Key Files

- `plugins/core/agents/application-analyst.md` - Current agent to be deleted (application viewpoint: runtime behavior, agent orchestration, data flow)
- `plugins/core/agents/component-analyst.md` - Current agent to be deleted (component viewpoint: internal structure, module boundaries, skill/agent/command decomposition)
- `plugins/core/agents/feature-analyst.md` - Current agent to be deleted (feature viewpoint: feature inventory, capability matrix, configuration options)
- `plugins/core/agents/usecase-analyst.md` - Current agent to be deleted (usecase viewpoint: user workflows, command sequences, input/output contracts)
- `plugins/core/skills/define-lead/SKILL.md` - Schema template and guidelines for the new lead skill
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Existing viewpoint analysis framework (still needed by the lead)
- `plugins/core/skills/write-spec/SKILL.md` - Spec writing guidelines (still needed by the lead)
- `plugins/core/commands/scan.md` - Invokes all 4 analysts as separate subagent_types; must collapse to single `architecture-lead`
- `plugins/core/skills/select-scan-agents/sh/select.sh` - References all 4 analysts in ALL_AGENTS list and in partial scan mapping; must replace all with `architecture-lead`
- `plugins/core/skills/select-scan-agents/SKILL.md` - Documents partial scan mapping table with all 4 analyst references
- `plugins/core/agents/infra-lead.md` - Reference implementation of a viewpoint lead agent
- `plugins/core/skills/lead-infra/SKILL.md` - Reference implementation of a viewpoint lead skill

## Related History

The define-lead skill and prior lead conversions established the pattern for transforming analysts into leads. All policy analysts and some viewpoint analysts (infrastructure, data, stakeholder, communication) have already been migrated on this branch. This ticket completes the remaining four viewpoint analysts by consolidating them into a single lead rather than creating four separate leads.

- [20260209173043-transform-infra-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209173043-transform-infra-analyst-to-lead-architecture.md) - Transformed infrastructure-analyst to infra-lead (closest reference pattern: viewpoint lead with analyze-viewpoint skill)
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration: established the define-lead agent template pattern
- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill (prerequisite schema)
- [20260208131751-migrate-scanner-into-scan-command.md](.workaholic/tickets/archive/drive-20260208-131649/20260208131751-migrate-scanner-into-scan-command.md) - Established the current scan.md agent table structure

## Implementation Steps

1. **Create the `lead-architecture` skill directory and SKILL.md**

   Create `plugins/core/skills/lead-architecture/SKILL.md` following the define-lead schema. This skill encodes the combined domain knowledge of all four viewpoints:

   - Frontmatter with `name: architecture-lead`, `description`, `skills: [define-lead]`, `user-invocable: false`
   - `## Role` - The architecture lead owns the project's architectural viewpoints. It analyzes the repository from four perspectives -- application (runtime behavior, agent orchestration, data flow), component (internal structure, module boundaries, decomposition), feature (feature inventory, capability matrix, configuration options), and usecase (user workflows, command sequences, input/output contracts) -- then produces spec documentation for each.
   - `## Responsibility` - Minimum duties:
     - Every scan produces all four spec documents (`application.md`, `component.md`, `feature.md`, `usecase.md`) reflecting only observable, implemented aspects
     - Application viewpoint covers orchestration model, data flow, execution lifecycle, and concurrency patterns
     - Component viewpoint covers module boundaries, responsibility distribution, dependency graph, and design patterns
     - Feature viewpoint covers feature inventory, capability matrix, configuration options, and feature status
     - Usecase viewpoint covers primary workflows, command contracts, step-by-step sequences, and error handling
     - Gaps where no evidence is found are marked as "not observed"
   - `## Goal` - All four spec documents in `.workaholic/specs/` accurately reflect the repository's architecture. No fabricated claims, every statement grounded in codebase evidence, gaps marked as "not observed". Translations produced only when user's root CLAUDE.md declares translation requirements.
   - `## Default Policies` with all four subsections:
     - `### Implementation` - Rules for writing spec documents: only document observable aspects, cite evidence, follow analyze-viewpoint output template, produce translations per user policy. For each viewpoint, use the corresponding analysis prompts and suggested Mermaid diagram types from the viewpoint definitions.
     - `### Review` - Rules for reviewing architecture artifacts: verify codebase citations, flag aspirational claims, check all output sections per viewpoint, verify Assumptions sections with `[Explicit]`/`[Inferred]` prefixes.
     - `### Documentation` - Rules for documentation output: follow analyze-viewpoint template structure, use viewpoint slugs for filenames (`application.md`, `component.md`, `feature.md`, `usecase.md`), write full paragraphs, include multiple inline Mermaid diagrams, mark absent areas as "not observed".
     - `### Execution` - Rules for execution: for each viewpoint, gather context via `bash .claude/skills/analyze-viewpoint/sh/gather.sh <slug> main` and check overrides via `bash .claude/skills/analyze-viewpoint/sh/read-overrides.sh`. Analyze codebase using each viewpoint's analysis prompts. Write all four English specs, then produce translations per user's root CLAUDE.md. The lead must include the four viewpoint definitions (slug, description, analysis prompts, Mermaid diagram suggestions, output sections) so it can produce all four documents.

2. **Delete the four analyst agents and create `architecture-lead.md`**

   Delete:
   - `plugins/core/agents/application-analyst.md`
   - `plugins/core/agents/component-analyst.md`
   - `plugins/core/agents/feature-analyst.md`
   - `plugins/core/agents/usecase-analyst.md`

   Create `plugins/core/agents/architecture-lead.md` as a thin, multi-purpose orchestrator:
   - Frontmatter: `name: architecture-lead`, `description: Owns application, component, feature, and usecase viewpoints for the project.`, `tools: Read, Write, Edit, Bash, Glob, Grep`, `skills: [lead-architecture, analyze-viewpoint, write-spec, translate]`
   - Follow the agent template pattern from define-lead skill
   - Instructions: read caller's prompt, apply corresponding Default Policy from lead-architecture skill, execute task, return JSON result

3. **Update scan command agent references**

   In `plugins/core/commands/scan.md`:
   - Remove the four separate table rows for `usecase-analyst`, `application-analyst`, `component-analyst`, and `feature-analyst`
   - Add a single row for `architecture-lead` / `core:architecture-lead` with "Pass base branch"
   - Update the agent count from 17 to 14 (4 agents removed, 1 added = net -3)
   - Update Phase 4 validation: the spec file list remains the same (application.md, component.md, feature.md, usecase.md are still produced)

4. **Update select-scan-agents shell script**

   In `plugins/core/skills/select-scan-agents/sh/select.sh`:
   - Replace `usecase-analyst`, `application-analyst`, `component-analyst`, and `feature-analyst` in the `ALL_AGENTS` variable with a single `architecture-lead`
   - Update the partial scan mapping: everywhere that touches `application-analyst`, `usecase-analyst`, `component-analyst`, or `feature-analyst`, replace with `architecture-lead`

5. **Update select-scan-agents SKILL.md**

   In `plugins/core/skills/select-scan-agents/SKILL.md`:
   - Update the agent count from 17 to 14
   - Update the partial scan mapping table: replace analyst names with `architecture-lead`

## Patches

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -11,7 +11,7 @@

-Run a full documentation scan by invoking all 17 documentation agents directly, providing real-time progress visibility for each agent.
+Run a full documentation scan by invoking all 14 documentation agents directly, providing real-time progress visibility for each agent.

 ## Instructions
```

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -31,7 +31,7 @@

-Parse the JSON output to get the list of all 17 agents.
+Parse the JSON output to get the list of all 14 agents.

-### Phase 3: Invoke All Agents in Parallel
+### Phase 3: Invoke All Agents in Parallel

-Invoke all 17 agents in a single message with parallel Task tool calls (each `model: "sonnet"`):
+Invoke all 14 agents in a single message with parallel Task tool calls (each `model: "sonnet"`):
```

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -40,11 +40,8 @@
 | `communication-lead` | `core:communication-lead` | Pass base branch |
 | `model-analyst` | `core:model-analyst` | Pass base branch |
-| `usecase-analyst` | `core:usecase-analyst` | Pass base branch |
 | `infra-lead` | `core:infra-lead` | Pass base branch |
-| `application-analyst` | `core:application-analyst` | Pass base branch |
-| `component-analyst` | `core:component-analyst` | Pass base branch |
 | `db-lead` | `core:db-lead` | Pass base branch |
-| `feature-analyst` | `core:feature-analyst` | Pass base branch |
+| `architecture-lead` | `core:architecture-lead` | Pass base branch |
 | `test-lead` | `core:test-lead` | Pass base branch |
```

### `plugins/core/skills/select-scan-agents/sh/select.sh`

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -14,7 +14,7 @@
 BASE_BRANCH="${2:-}"

-ALL_AGENTS="communication-lead model-analyst usecase-analyst infra-lead application-analyst component-analyst db-lead feature-analyst test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
+ALL_AGENTS="communication-lead model-analyst infra-lead architecture-lead db-lead test-lead security-lead quality-lead a11y-lead observability-lead delivery-lead recovery-lead changelog-writer terms-writer"
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -70,16 +70,12 @@
   case "$path" in
     plugins/core/commands/*|plugins/core/agents/*)
-      touch "$TMPDIR_SEL/application-analyst"
-      touch "$TMPDIR_SEL/usecase-analyst"
-      touch "$TMPDIR_SEL/component-analyst"
+      touch "$TMPDIR_SEL/architecture-lead"
       ;;
   esac

   case "$path" in
     plugins/core/skills/*)
-      touch "$TMPDIR_SEL/component-analyst"
-      touch "$TMPDIR_SEL/feature-analyst"
+      touch "$TMPDIR_SEL/architecture-lead"
       ;;
   esac
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -86,7 +82,7 @@
   case "$path" in
     plugins/core/rules/*)
       touch "$TMPDIR_SEL/quality-lead"
-      touch "$TMPDIR_SEL/component-analyst"
+      touch "$TMPDIR_SEL/architecture-lead"
       ;;
   esac
```

```diff
--- a/plugins/core/skills/select-scan-agents/sh/select.sh
+++ b/plugins/core/skills/select-scan-agents/sh/select.sh
@@ -112,7 +108,7 @@
   case "$path" in
     README.md|CLAUDE.md)
       touch "$TMPDIR_SEL/communication-lead"
-      touch "$TMPDIR_SEL/feature-analyst"
+      touch "$TMPDIR_SEL/architecture-lead"
       ;;
   esac
```

### `plugins/core/skills/select-scan-agents/SKILL.md`

```diff
--- a/plugins/core/skills/select-scan-agents/SKILL.md
+++ b/plugins/core/skills/select-scan-agents/SKILL.md
@@ -10,7 +10,7 @@

-- **full**: Returns all 17 agents (8 viewpoint analysts, 7 policy analysts, 2 documentation writers)
+- **full**: Returns all 14 agents (5 viewpoint leads, 7 policy leads, 2 documentation writers)
 - **partial**: Analyzes `git diff --stat` against the base branch to select only relevant agents
```

```diff
--- a/plugins/core/skills/select-scan-agents/SKILL.md
+++ b/plugins/core/skills/select-scan-agents/SKILL.md
@@ -29,10 +29,10 @@
 | Changed path | Agents triggered |
 | --- | --- |
-| `plugins/core/commands/`, `plugins/core/agents/` | application-analyst, usecase-analyst, component-analyst |
-| `plugins/core/skills/` | component-analyst, feature-analyst |
-| `plugins/core/rules/` | quality-policy-analyst, component-analyst |
+| `plugins/core/commands/`, `plugins/core/agents/` | architecture-lead |
+| `plugins/core/skills/` | architecture-lead |
+| `plugins/core/rules/` | quality-lead, architecture-lead |
 | `.workaholic/tickets/` | data-analyst, model-analyst |
 | `.workaholic/terms/` | terms-writer |
-| `.claude-plugin/`, plugin config files | infrastructure-analyst, delivery-policy-analyst |
-| `README.md`, `CLAUDE.md` | stakeholder-analyst, feature-analyst |
-| `.github/` | delivery-policy-analyst, security-policy-analyst |
+| `.claude-plugin/`, plugin config files | infra-lead, delivery-lead |
+| `README.md`, `CLAUDE.md` | communication-lead, architecture-lead |
+| `.github/` | delivery-lead, security-lead |
```

## Considerations

- This is a many-to-one consolidation (4 agents to 1), unlike prior 1-to-1 lead migrations. The `lead-architecture` skill must encode all four viewpoint definitions (slugs, analysis prompts, diagram suggestions, output sections) so the single agent can produce all four spec documents (`plugins/core/skills/lead-architecture/SKILL.md`)
- The agent count in scan.md drops from 17 to 14. All prose references to "17 agents" must be updated to "14" (`plugins/core/commands/scan.md` lines 11, 31, 36)
- The scan Phase 4 validation lists remain unchanged since the four spec files (`application.md`, `component.md`, `feature.md`, `usecase.md`) are still produced by the consolidated lead (`plugins/core/commands/scan.md` line 67)
- The partial scan mapping in `select.sh` currently triggers different subsets of the 4 analysts for different path changes. After consolidation, all these trigger `architecture-lead`, which means `architecture-lead` gets triggered more broadly -- this is acceptable because it owns all four viewpoints (`plugins/core/skills/select-scan-agents/sh/select.sh` lines 70-118)
- The `select-scan-agents/SKILL.md` documentation table still references old agent names (`quality-policy-analyst`, `data-analyst`, `stakeholder-analyst`, `infrastructure-analyst`, `delivery-policy-analyst`, `security-policy-analyst`); these should also be updated to their current lead names for consistency (`plugins/core/skills/select-scan-agents/SKILL.md` lines 29-39)
- The `architecture-lead` agent will need to invoke `analyze-viewpoint/sh/gather.sh` four times (once per viewpoint slug) during a documentation scan. This is different from other leads that gather context once (`plugins/core/skills/analyze-viewpoint/sh/gather.sh`)

## Final Report

Consolidated four viewpoint analysts (application, component, feature, usecase) into a single `architecture-lead` agent with a `lead-architecture` skill. Created the skill with all four viewpoint definitions embedded (slugs, analysis prompts, Mermaid suggestions, output sections) and Default Policies following the define-lead schema. Deleted the four analyst agent files, created the thin architecture-lead orchestrator. Updated scan.md agent count from 17 to 14 and collapsed four table rows into one. Updated select-scan-agents shell script (ALL_AGENTS list and all partial scan case mappings) and SKILL.md (agent counts, category labels, mapping table, output example). Also fixed stale agent names in SKILL.md documentation that predated earlier lead migrations.
