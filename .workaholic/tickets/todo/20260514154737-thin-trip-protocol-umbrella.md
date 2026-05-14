---
created_at: 2026-05-14T15:47:37+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Thin Trip Protocol Umbrella into a Single Skill

## Overview

The work side of the trip workflow currently carries the bulk of its instructional content across four files: `plugins/work/agents/planner.md`, `plugins/work/agents/architect.md`, `plugins/work/agents/constructor.md`, and `plugins/work/commands/trip.md`. The shared skill `plugins/core/skills/trip-protocol/SKILL.md` (145 lines) already documents the protocol's policies and conventions, but the agents and command still contain procedural prose, role philosophy, orchestration steps, and per-agent rules that duplicate or complement skill content.

The user is migrating toward an agents-and-commands-as-thin-aliases-of-skills model so that Codex-spec compatibility is achievable: each agent/command becomes a frontmatter-with-stub-body alias, and skills hold all instructional content. This ticket performs that thinning for the trip-protocol umbrella by moving procedural content into `plugins/core/skills/trip-protocol/SKILL.md` while preserving exact runtime behavior.

This is a **refactoring**, not a rewrite. Content moves verbatim where possible; the Agent Teams launch, the three-member composition, the Progressive/Neutral/Conservative stances and dialectic, every script invocation, and the order of operations all remain unchanged after the migration.

A critical architectural constraint applies: today the three role agents preload `standards:leading-*` directly. Once the agents are thinned, those soft preloads belong on `core:trip-protocol` itself, in accordance with the project's dependency policy (core may soft-depend on standards via skill preloads; core may not hard-depend on standards or work).

## Key Files

- `plugins/core/skills/trip-protocol/SKILL.md` (145 lines) — Destination for all migrated procedural content. Already contains policies (Phase Gate, Critical Review), workflow overview, shell-scripts table, artifact storage, plan/event-log conventions, phase-by-phase steps, post-completion protocol, and commit/written-language policies. Will gain: `## Roles` (with Planner / Architect / Constructor subsections), `## Agent Rules` (the per-agent Rules currently duplicated across three files), `## Trip Command Procedure` (the orchestration body of `/trip`), and `## Leading Standards` (soft preload registry, supplanting the per-agent preload lists).
- `plugins/work/agents/planner.md` (40 lines) — Thinned to ~10 lines plus frontmatter. Body becomes: identity statement ("Planner — Progressive stance, business outcomes"), reference to `core:trip-protocol` `## Roles → Planner` for full role contract, and the I/O contract sentence (inputs: lead instruction; outputs: directions/, review files, dev env, E2E results).
- `plugins/work/agents/architect.md` (40 lines) — Thinned identically; body references `core:trip-protocol` `## Roles → Architect`. I/O contract: inputs lead instruction; outputs models/, review files, analytical review notes.
- `plugins/work/agents/constructor.md` (42 lines) — Thinned identically; body references `core:trip-protocol` `## Roles → Constructor`. I/O contract: inputs lead instruction; outputs designs/, review files, code, internal test results. Retains `core:system-safety` skill preload because the system-safety detection call is a Constructor-specific obligation, not a protocol-wide one.
- `plugins/work/commands/trip.md` (100 lines) — Thinned to ~10 lines plus frontmatter. Body becomes: a one-line entry sentence describing `/trip` as the launch verb, and a directive pointing at `core:trip-protocol` `## Trip Command Procedure` (which holds the migrated five-step orchestration including the pre-check, worktree-or-branch choice, init, validation, Agent Teams launch text, and results presentation).
- `plugins/core/skills/branching/SKILL.md` — Referenced indirectly; the trip command's script calls into branching scripts already use the `${CLAUDE_PLUGIN_ROOT}/../core/...` form. After migration, those calls move into the skill body which is itself in `core`, so the relative reference becomes `${CLAUDE_PLUGIN_ROOT}/../core/...` from the perspective of work-side callers... but since the migration target is **inside core**, references from inside `core:trip-protocol` to other core scripts should use `${CLAUDE_PLUGIN_ROOT}/skills/branching/...` (same-plugin form). Audit and rewrite all script paths during migration (see Implementation Step 6).
- `plugins/core/skills/check-deps/scripts/check.sh` — Called in the trip command's pre-check. From inside `core:trip-protocol`, becomes `${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh`... no — once inside core, becomes `${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh`. Verify the actual location of `check-deps` (it is in `plugins/core/skills/check-deps/`) so the same-plugin form is correct.
- `plugins/work/skills/create-ticket/SKILL.md` — Not modified; referenced here only because the discovered file inventory shows that this kind of "thin alias" pattern has been applied to other commands (`ticket-command-alias-refactor` in history).

## Related History

The work plugin has gone through three prior thinning/refactoring waves that establish the pattern this ticket follows: an early `thin-ticket-command` refactor extracted command logic into skills; the recent manager-tier elimination and lead-wiring sequence (work-20260417-092936 archive) restructured leading-skill plumbing across agents; and the in-flight may-2026 series moved skills across plugin boundaries to land the current core/standards/work topology. This ticket continues the same trajectory for the trip-protocol surface.

Past tickets that touched similar areas:

- [20260128004252-thin-ticket-command.md](.workaholic/tickets/archive/feat-20260128-001720/20260128004252-thin-ticket-command.md) — Original pattern of thinning a command body and pushing content into a skill; same refactor shape applied to a different command.
- [20260202125814-ticket-command-alias-refactor.md](.workaholic/tickets/archive/drive-20260201-112920/20260202125814-ticket-command-alias-refactor.md) — Follow-up that established the command-as-alias convention now applied to `/trip`.
- [20260509001216-wire-leads-into-work-flows.md](.workaholic/tickets/archive/work-20260417-092936/20260509001216-wire-leads-into-work-flows.md) — Wired `standards:leading-*` skills into work-side agents (the preloads this ticket now moves onto `core:trip-protocol`).
- [20260509001215-eliminate-manager-tier.md](.workaholic/tickets/archive/work-20260417-092936/20260509001215-eliminate-manager-tier.md) — Most recent agent-tier restructure; same care for behavior preservation while restructuring agent layout applies here.
- [20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md](.workaholic/tickets/archive/drive-20260310-220224/20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md) — Established the role-philosophy prose (Progressive/Neutral/Conservative, Extrinsic/Structural/Intrinsic Idealism) that this ticket migrates to the skill verbatim.
- [20260311103508-add-report-trip-command.md](.workaholic/tickets/archive/drive-20260310-220224/20260311103508-add-report-trip-command.md) — Created the original heavy `/trip` command body now being thinned.
- [20260219165413-restructure-role-responsibility-goal-headings.md](.workaholic/tickets/archive/drive-20260213-131416/20260219165413-restructure-role-responsibility-goal-headings.md) — Sets the precedent for the `## Roles` heading shape this ticket adopts inside the skill.

## Implementation Steps

1. **Read all five files end-to-end** and inventory the migratable content:
   - From each role agent: the role-philosophy line (e.g., "Progressive stance, Extrinsic Idealism"), the `## Domain` paragraph, the `## Planning Phase` paragraph, the `## Coding Phase` paragraph, and the `## Rules` list.
   - From `/trip`: the prerequisites note, the Pre-check, Step 1 (Create or Resume), Step 2 (Initialize), Step 3 (Validate Dev Environment), Step 4 (Launch Agent Teams — including the verbatim team-lead instruction block), Step 5 (Present Results).
2. **Add `## Roles` section to `core:trip-protocol`** with three subsections — `### Planner (Progressive)`, `### Architect (Neutral)`, `### Constructor (Conservative)`. Each subsection contains: the philosophy line, the Domain paragraph, the Planning Phase paragraph, and the Coding Phase paragraph from the corresponding agent. Move text verbatim where the prose is self-contained; lightly rephrase only the cross-references (e.g., "Follow the preloaded **trip-protocol** skill" becomes "Follow this protocol" since the reader is already inside it).
3. **Add `## Agent Rules` section** capturing the rules currently duplicated as the `## Rules` list across the three agent files. Express the shared rules once, with role-specific exceptions called out inline (Constructor's `system-safety` rule is the only role-specific entry). The shared rules: STOP after each task, English-only output, never modify another agent's artifact, retain role boundaries on re-invocation, apply preloaded lead standards.
4. **Add `## Trip Command Procedure` section** containing the verbatim five steps from the current `/trip` command body, including the team-lead instruction quoted block. Audit script-path references — see step 6.
5. **Add `## Leading Standards` (soft preloads) section** listing the four leading skills currently preloaded by each agent (`standards:leading-validity`, `standards:leading-accessibility`, `standards:leading-security`, `standards:leading-availability`) and noting that the protocol soft-depends on them per the project's plugin-dependency rules. Add the same four entries to the `core:trip-protocol` frontmatter as `skills:` preloads if the plugin format supports skill preloading on a skill itself; otherwise document them as preload guidance for callers. (Investigation note: check whether `core:trip-protocol` already has a `skills:` frontmatter field; the current SKILL.md frontmatter is `allowed-tools` and `user-invocable` — no `skills:` field. The migration must add one **only if** Claude Code supports skill-to-skill preloads. If unsupported, the preloads stay on the agent/command frontmatter, which means this section becomes a documentation-only registry.)
6. **Rewrite script paths inside `core:trip-protocol`** to use same-plugin form `${CLAUDE_PLUGIN_ROOT}/skills/.../scripts/...` for core-local scripts (branching, check-deps, system-safety, trip-protocol). Verify each path resolves; the current `/trip` command uses `${CLAUDE_PLUGIN_ROOT}/../core/...` form because it sits in `plugins/work/`. Once migrated into `plugins/core/skills/trip-protocol/SKILL.md`, the relative pivot changes.
7. **Thin `plugins/work/agents/planner.md`** to: keep frontmatter (`name`, `description`, `tools`, `model`, `color`, `skills`), narrow `skills:` to `[core:trip-protocol]` (removing the four `standards:leading-*` entries that now belong to the skill), and replace the body with ~5-10 lines: identity sentence, "See `core:trip-protocol` `## Roles → Planner` for the full role contract.", and a one-line I/O contract.
8. **Thin `plugins/work/agents/architect.md`** the same way; `skills: [core:trip-protocol]`; body references `## Roles → Architect`.
9. **Thin `plugins/work/agents/constructor.md`** the same way; `skills: [core:trip-protocol, core:system-safety]` (keeping `system-safety` because it is Constructor-specific); body references `## Roles → Constructor`.
10. **Tool-list narrowing**: review each agent's `tools:` list. Planner needs `Read, Write, Edit, Glob, Grep, Bash` (writes artifacts, runs E2E via Bash, reads files). Architect arguably does not need `Write`/`Edit` outside its own artifact directory but currently has them; for safety preservation, keep the existing tool lists unchanged in this refactor unless investigation shows a tool is wholly unused. (Refactor scope discipline: do not narrow tools speculatively.)
11. **Thin `plugins/work/commands/trip.md`** to: keep frontmatter (`name`, `description`, `skills`), keep the user-input notice line ("When user input contains `/trip`..."), and replace the body with a single directive: "Follow `core:trip-protocol` `## Trip Command Procedure`." plus the prerequisites one-liner.
12. **Verify the Agent Teams launch directive** in the migrated skill is byte-identical to the current `/trip` Step 4 quoted block — the team-lead instruction is the contract the lead reads, and changing it changes behavior.
13. **Run the verification checklist** in the Considerations section below: every script path resolves, the launch directive matches, the three role contracts match, the role colors (red/green/blue) are preserved.

## Patches

> **Note**: These patches are speculative — they illustrate the target shape of each file. The author of this refactor should re-derive the exact content during migration, especially for the role sections inside `core:trip-protocol/SKILL.md`, which are appended verbatim from the agent files.

### `plugins/work/agents/planner.md`

```diff
--- a/plugins/work/agents/planner.md
+++ b/plugins/work/agents/planner.md
@@ -1,41 +1,15 @@
 ---
 name: planner
 description: Progressive agent for business vision, stakeholder advocacy, and explanatory accountability.
 tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: red
 skills:
   - core:trip-protocol
-  - standards:leading-validity
-  - standards:leading-accessibility
-  - standards:leading-security
-  - standards:leading-availability
 ---
 
 # Planner
 
-Business visionary agent -- Progressive stance, Extrinsic Idealism.
-
-## Domain
-
-You protect **business outcomes and stakeholder value**. Review through the lens of business value: Does this deliver the business outcome? Can stakeholders trace the reasoning? For every concern, propose a concrete alternative framed in business outcomes.
-
-## Planning Phase
-
-Write `directions/direction-v1.md` containing: value proposition, business risk assessment, user personas, system positioning, business rationale. Do NOT include file paths, code references, or codebase analysis -- codebase discovery is the Architect's job.
-
-Review Model and Design in `reviews/round-1-planner.md`. Respond to feedback in `reviews/response-planner-to-<reviewer>.md`. Moderate Architect-Constructor disagreements when called upon.
-
-## Coding Phase
-
-**QA Role: E2E and external interface testing.** Validate the system from the outside. Build dev environment, plan E2E scenarios (browser via Playwright for web apps, CLI execution for CLI tools). Do NOT run unit tests, compiler checks, or perform code review.
-
-## Rules
-
-- Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
-- All output must be in English (artifacts, reviews, code, commit descriptions)
-- After completing any task, STOP and wait for the team lead's next instruction
-- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (E2E/external testing) apply
-- Apply preloaded **lead standards** — ensure planning artifacts, E2E test plans, and review feedback respect the team's policies, practices, and standards across all domains
-- Never modify another agent's artifact
+Progressive trip teammate — business vision, stakeholder advocacy, E2E testing.
+
+Follow `core:trip-protocol` `## Roles → Planner` for the full role contract, `## Agent Rules` for the shared rules, and `## Phase` sections for procedural steps.
+
+**I/O**: Receives lead instructions; produces `directions/direction-v*.md`, review files under `reviews/`, dev-environment setup, and E2E test results.
```

### `plugins/work/agents/architect.md`

```diff
--- a/plugins/work/agents/architect.md
+++ b/plugins/work/agents/architect.md
@@ -1,41 +1,15 @@
 ---
 name: architect
 description: Neutral agent bridging business vision and technical implementation through structural coherence and translation fidelity.
 tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: green
 skills:
   - core:trip-protocol
-  - standards:leading-validity
-  - standards:leading-accessibility
-  - standards:leading-security
-  - standards:leading-availability
 ---
 
 # Architect
 
-Structural bridge agent -- Neutral stance, Structural Idealism.
-
-## Domain
-
-You protect **structural integrity and translation fidelity**. Review as the bridge between perspectives: Does the structure faithfully represent the business intent? Can stakeholders trace their requirements? For every concern, propose a concrete structural alternative preserving translation fidelity.
-
-## Planning Phase
-
-Write `models/model-v1.md` containing: system coherence mapping, domain model, translation fidelity analysis, boundary integrity assessment, component taxonomy. The model bridges business and technical but is neither alone.
-
-Review Direction and Design in `reviews/round-1-architect.md`. Respond to feedback in `reviews/response-architect-to-<reviewer>.md`. Moderate Planner-Constructor disagreements when called upon.
-
-## Coding Phase
-
-**QA Role: Analytical review only.** Discover codebase changes and perform code review, architectural review, and model checking. Do NOT execute any tests -- testing belongs to the Planner (E2E) and Constructor (internal).
-
-## Rules
-
-- Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
-- All output must be in English (artifacts, reviews, code, commit descriptions)
-- After completing any task, STOP and wait for the team lead's next instruction
-- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (analytical review only) apply
-- Apply preloaded **lead standards** — ensure model artifacts, structural analysis, and review feedback respect the team's policies, practices, and standards across all domains
-- Never modify another agent's artifact
+Neutral trip teammate — structural bridge, translation fidelity, analytical review.
+
+Follow `core:trip-protocol` `## Roles → Architect` for the full role contract, `## Agent Rules` for the shared rules, and `## Phase` sections for procedural steps.
+
+**I/O**: Receives lead instructions; produces `models/model-v*.md`, review files under `reviews/`, and analytical review notes.
```

### `plugins/work/agents/constructor.md`

```diff
--- a/plugins/work/agents/constructor.md
+++ b/plugins/work/agents/constructor.md
@@ -1,43 +1,16 @@
 ---
 name: constructor
 description: Conservative agent for technical ownership, quality assurance, and delivery accountability.
 tools: Read, Write, Edit, Glob, Grep, Bash
 model: opus
 color: blue
 skills:
   - core:trip-protocol
   - core:system-safety
-  - standards:leading-validity
-  - standards:leading-accessibility
-  - standards:leading-security
-  - standards:leading-availability
 ---
 
 # Constructor
 
-Technically accountable agent -- Conservative stance, Intrinsic Idealism.
-
-## Domain
-
-You protect **engineering quality and production readiness**. Review with technical ownership: Is this the right technical approach? What quality bar must this meet? For every concern, propose a concrete technical alternative that maintains the quality bar.
-
-## Planning Phase
-
-Write `designs/design-v1.md` containing: scope and inventory, implementation approach, quality strategy, delivery plan, risk assessment. The design translates structure into buildable, testable components.
-
-Review Direction and Model in `reviews/round-1-constructor.md`. Respond to feedback in `reviews/response-constructor-to-<reviewer>.md`. Moderate Planner-Architect disagreements when called upon.
-
-## Coding Phase
-
-**QA Role: Internal testing.** Implement the program, then verify with compiler/type checks, unit tests, linters. Fix failures before reporting completion. Do NOT run E2E tests or perform analytical code review.
-
-## Rules
-
-- Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
-- All output must be in English (artifacts, reviews, code, commit descriptions)
-- Run system-safety detection before any implementation that may touch system configuration
-- After completing any task, STOP and wait for the team lead's next instruction
-- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (internal testing) apply
-- Apply preloaded **lead standards** — ensure design artifacts, implementation, and testing respect the team's policies, practices, and standards across all domains
-- Never modify another agent's artifact
+Conservative trip teammate — technical ownership, implementation, internal testing.
+
+Follow `core:trip-protocol` `## Roles → Constructor` for the full role contract, `## Agent Rules` for the shared rules, and `## Phase` sections for procedural steps. Run `core:system-safety` detection before implementation that may touch system configuration.
+
+**I/O**: Receives lead instructions; produces `designs/design-v*.md`, review files under `reviews/`, source-code commits, and internal test results.
```

### `plugins/work/commands/trip.md`

```diff
--- a/plugins/work/commands/trip.md
+++ b/plugins/work/commands/trip.md
@@ -1,101 +1,12 @@
 ---
 name: trip
 description: Launch Agent Teams session with Planner, Architect, and Constructor
 skills:
   - core:trip-protocol
 ---
 
 # Trip
 
 **Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.
 
-Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs either in an isolated git worktree or on a trip branch in the main working tree.
-
-**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.
-
-## Pre-check: Dependencies
-
-```bash
-bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
-```
-
-If `ok` is `false`, display the `message` to the user and stop.
-
-## Step 1: Create or Resume Trip
-
-...
-
-## Step 5: Present Results
-
-...
+Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. Follow `core:trip-protocol` `## Trip Command Procedure` for the full five-step orchestration (pre-check, create-or-resume, initialize, validate dev environment, launch Agent Teams, present results).
+
+**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.
```

### `plugins/core/skills/trip-protocol/SKILL.md` (additions only)

```diff
--- a/plugins/core/skills/trip-protocol/SKILL.md
+++ b/plugins/core/skills/trip-protocol/SKILL.md
@@ -143,3 +143,140 @@ Format: `[Agent] Descriptive summary of what was accomplished`. Description must
 ## Artifact Format
 
 Each artifact file: `# <Type> v<N>`, then metadata fields (Author, Status: draft/under-review/approved, Reviewed-by), then Content section, then Review Notes section.
+
+## Roles
+
+### Planner (Progressive)
+
+Business visionary agent — Progressive stance, Extrinsic Idealism. **Domain**: protect business outcomes and stakeholder value. Review through the lens of business value: Does this deliver the business outcome? Can stakeholders trace the reasoning? For every concern, propose a concrete alternative framed in business outcomes.
+
+- **Planning Phase**: Write `directions/direction-v1.md` (value proposition, business risk, user personas, system positioning, business rationale). Do NOT include file paths or codebase analysis — discovery is the Architect's job. Review Model and Design in `reviews/round-1-planner.md`. Respond in `reviews/response-planner-to-<reviewer>.md`. Moderate Architect-Constructor disagreements when called upon.
+- **Coding Phase QA Role**: E2E and external interface testing. Build dev environment, plan and run E2E scenarios (Playwright for web, CLI execution for CLI tools). Do NOT run unit tests, compiler checks, or code review.
+
+### Architect (Neutral)
+
+Structural bridge agent — Neutral stance, Structural Idealism. **Domain**: protect structural integrity and translation fidelity. Review as the bridge: Does the structure faithfully represent the business intent? Can stakeholders trace their requirements? For every concern, propose a concrete structural alternative preserving translation fidelity.
+
+- **Planning Phase**: Write `models/model-v1.md` (system coherence mapping, domain model, translation fidelity analysis, boundary integrity, component taxonomy). Review Direction and Design in `reviews/round-1-architect.md`. Respond in `reviews/response-architect-to-<reviewer>.md`. Moderate Planner-Constructor disagreements when called upon.
+- **Coding Phase QA Role**: Analytical review only. Discover codebase changes and perform code review, architectural review, model checking. Do NOT execute any tests.
+
+### Constructor (Conservative)
+
+Technically accountable agent — Conservative stance, Intrinsic Idealism. **Domain**: protect engineering quality and production readiness. Review with technical ownership: Is this the right technical approach? What quality bar must this meet? For every concern, propose a concrete technical alternative.
+
+- **Planning Phase**: Write `designs/design-v1.md` (scope and inventory, implementation approach, quality strategy, delivery plan, risk assessment). Review Direction and Model in `reviews/round-1-constructor.md`. Respond in `reviews/response-constructor-to-<reviewer>.md`. Moderate Planner-Architect disagreements when called upon.
+- **Coding Phase QA Role**: Internal testing. Implement, then verify with compiler/type checks, unit tests, linters. Fix failures before reporting completion. Do NOT run E2E tests or perform analytical code review.
+
+## Agent Rules
+
+- Follow this protocol for commit/log-event commands, artifact format, and all workflow procedures.
+- All output must be in English (artifacts, reviews, code, commit descriptions).
+- After completing any task, STOP and wait for the team lead's next instruction.
+- When re-invoked for post-completion follow-up, the same role boundaries and QA domain apply.
+- Apply preloaded lead standards (validity, accessibility, security, availability) — ensure artifacts, implementation, and testing respect the team's policies, practices, and standards across all domains.
+- Never modify another agent's artifact.
+- **Constructor only**: Run `core:system-safety` detection before any implementation that may touch system configuration.
+
+## Leading Standards (Soft Preloads)
+
+The trip protocol soft-depends on the following leading skills. Agents that participate in a trip must preload them at the call site (commands or agent frontmatter); this protocol exercises their policies during planning, design, implementation, review, and testing.
+
+- `standards:leading-validity`
+- `standards:leading-accessibility`
+- `standards:leading-security`
+- `standards:leading-availability`
+
+## Trip Command Procedure
+
+(Verbatim five-step procedure migrated from `plugins/work/commands/trip.md`. Note: when invoked from a work-side command, script paths use `${CLAUDE_PLUGIN_ROOT}/../core/...`; when documented inside this skill, paths are shown in the same form because the caller's `${CLAUDE_PLUGIN_ROOT}` resolves to the work plugin. Audit during migration.)
+
+### Pre-check: Dependencies
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
+```
+
+If `ok` is `false`, display the `message` to the user and stop.
+
+### Step 1: Create or Resume Trip
+
+[verbatim content from current /trip Step 1]
+
+### Step 2: Initialize Trip Artifacts
+
+[verbatim content from current /trip Step 2]
+
+### Step 3: Validate Dev Environment
+
+[verbatim content from current /trip Step 3]
+
+### Step 4: Launch Agent Teams
+
+[verbatim content from current /trip Step 4, including the full team-lead instruction quoted block]
+
+### Step 5: Present Results
+
+[verbatim content from current /trip Step 5]
```

## Considerations

- **Behavior preservation is the highest-priority invariant**. The team-lead instruction inside Step 4 is the operational contract that drives every Agent Teams session; any rewording during migration changes behavior. Migrate that block verbatim (`plugins/work/commands/trip.md` lines 70-90).
- **Script-path pivot when content moves between plugins**. `${CLAUDE_PLUGIN_ROOT}` resolves to the *caller's* plugin root. When the command body moves into `core:trip-protocol`, the relative path from the skill to core scripts is `${CLAUDE_PLUGIN_ROOT}/skills/...` (same plugin). But because skills are invoked from callers in other plugins, the `${CLAUDE_PLUGIN_ROOT}` expansion happens at the caller's plugin context — meaning a script path written inside the skill could resolve differently depending on who invokes it. **Verify Claude Code's `${CLAUDE_PLUGIN_ROOT}` semantics during preloaded-skill invocation before committing path changes.** Test by invoking `/trip` after migration and confirming `check-deps`, `branching`, `trip-protocol` scripts all execute. (Affects all bash blocks in `plugins/core/skills/trip-protocol/SKILL.md`.)
- **Skill-to-skill preloads may not be supported**. The current `core:trip-protocol/SKILL.md` frontmatter uses `name`, `description`, `allowed-tools`, `user-invocable` — no `skills:` field. If Claude Code does not honor a `skills:` field on skills themselves, the `standards:leading-*` preloads cannot move onto `core:trip-protocol` and must stay on agent/command frontmatter. The `## Leading Standards` documentation section then becomes the registry of *expected* preloads that callers must wire in. (Affects `plugins/core/skills/trip-protocol/SKILL.md` frontmatter.)
- **Dependency policy compliance** (`CLAUDE.md` lines 35-49). Core cannot hard-depend on standards or work. Soft references (preloads) are permitted. After migration, the four `standards:leading-*` entries appear in `core:trip-protocol` only as documented soft references, never as hard `dependencies` in `plugin.json`. Verify `plugins/core/.claude-plugin/plugin.json` is untouched by this refactor.
- **Tool-list discipline**. Each agent's `tools:` list is unchanged in this refactor (`Read, Write, Edit, Glob, Grep, Bash`). Narrowing tools is a separate concern — premature narrowing risks breaking behavior. (Affects each agent file frontmatter.)
- **Color preservation**. Planner=red, Architect=green, Constructor=blue. These visible cues distinguish agents during Agent Teams sessions and must remain on each agent's frontmatter (since color is an agent-level concern, not a skill-level one).
- **Lead lens for Config layer**: this ticket touches no application policies directly, but the migrated content carries leads in tow. Verify that the rewritten skill still names all four leading standards and that `## Agent Rules` continues to require "apply preloaded lead standards" — preserves the policy linkage established by `20260509001216-wire-leads-into-work-flows.md`.
- **Verification checklist** (must be exercised post-migration):
  - Every script invocation in the original four files appears, byte-identical in content, in the migrated skill: `check-deps/scripts/check.sh`, `branching/scripts/list-worktrees.sh`, `branching/scripts/create.sh`, `branching/scripts/adopt-worktree.sh`, `trip-protocol/scripts/init-trip.sh`, `trip-protocol/scripts/validate-dev-env.sh`, `trip-protocol/scripts/read-plan.sh`.
  - The Agent Teams launch directive (the quoted team-lead instruction) appears verbatim in `## Trip Command Procedure → Step 4`.
  - The three role contracts in `## Roles` carry the exact stance labels and idealism labels: Progressive/Extrinsic, Neutral/Structural, Conservative/Intrinsic.
  - The QA differentiation policy (Constructor=internal, Planner=E2E, Architect=analytical) appears in both `## Coding Phase` (already present) and the individual role subsections.
  - Running `/trip` end-to-end yields the same artifact directory shape (`directions/`, `models/`, `designs/`, `reviews/`, `rollbacks/`, `event-log.md`, `plan.md`) and same commit format `[Agent] description`.
- **Line-budget targets** (`plugins/work/agents/*`, `plugins/work/commands/trip.md`):
  - Each agent: ~10-15 lines total (frontmatter included). Current sizes are 40-42 lines; target reduction ~70%.
  - `/trip` command: ~10-15 lines total. Current size 100 lines; target reduction ~85%.
  - `core:trip-protocol/SKILL.md` will grow from 145 to ~280-320 lines as it absorbs the migrated content.
