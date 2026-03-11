---
created_at: 2026-03-11T19:45:19+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: d5711dc
category: Changed
---

# Rename Trip Phases to Descriptive Names

## Overview

Rename "Phase 1" and "Phase 2" to "Planning Phase" and "Coding Phase" across all Trippin plugin files. The current numbered names do not convey the purpose of each phase. Descriptive names make the two-phase workflow self-documenting: "Planning Phase" (specification through collaborative artifacts) and "Coding Phase" (implementation through test-plan-code-review-test loop).

## Key Files

- `plugins/trippin/skills/trip-protocol/SKILL.md` - Primary protocol definition; contains the canonical phase headings, commit point lists, and phase references throughout
- `plugins/trippin/commands/trip.md` - Trip command with Agent Teams instruction block; contains phase labels in the workflow description and environment warning
- `plugins/trippin/agents/architect.md` - Architect agent; contains "Phase 1: Specification" and "Phase 2: Implementation" section headings
- `plugins/trippin/agents/planner.md` - Planner agent; contains "Phase 1: Specification" and "Phase 2: Implementation" section headings
- `plugins/trippin/agents/constructor.md` - Constructor agent; contains "Phase 1: Specification" and "Phase 2: Implementation" section headings
- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` - Commit script; the `<phase>` parameter is free-form and used in commit message body, so the example should be updated

## Related History

The Trippin plugin's phase structure was established during the initial trip command implementation and has been refined through several iterations including artifact dependency enforcement and agent personality redefinition. The phase names have remained as "Phase 1" and "Phase 2" since inception, even as the content they represent became more clearly defined.

Past tickets that touched similar areas:

- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Rewrote agent personality spectrum; touched the same Phase 1/Phase 2 sections in all three agents and trip-protocol (same files, same sections)
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Initial implementation of trip command establishing the two-phase workflow structure
- [20260310221350-enforce-model-before-design-dependency-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221350-enforce-model-before-design-dependency-in-trip.md) - Enforced Direction -> Model -> Design ordering within what is now being renamed to Planning Phase
- [20260212173856-rename-policy-skills-to-principle.md](.workaholic/tickets/archive/drive-20260212-122906/20260212173856-rename-policy-skills-to-principle.md) - Similar terminology rename across multiple files for clarity (same pattern: Config layer rename)

## Implementation Steps

1. **Rename phase headings and references in `trip-protocol/SKILL.md`**:
   - Rename `## Phase 1: Specification (Inner Loop)` to `## Planning Phase: Specification (Inner Loop)`
   - Rename `## Phase 2: Implementation (Outer Loop)` to `## Coding Phase: Implementation (Outer Loop)`
   - Update "Phase 1 completes when" to "Planning Phase completes when"
   - Update "Commit points in Phase 1 (Specification)" to "Commit points in Planning Phase (Specification)"
   - Update "Commit points in Phase 2 (Implementation)" to "Commit points in Coding Phase (Implementation)"
   - Update "during Phase 2" in System Safety section to "during Coding Phase"

2. **Rename phase references in `trip.md` command**:
   - Update "Phase 2 implementation may encounter" to "Coding Phase implementation may encounter"
   - Update "**Phase 1 - Specification (Inner Loop)**" to "**Planning Phase - Specification (Inner Loop)**"
   - Update "**Phase 2 - Implementation (Outer Loop)**" to "**Coding Phase - Implementation (Outer Loop)**"
   - Update "implementation results from Phase 2" to "implementation results from Coding Phase"

3. **Rename phase section headings in all three agent files**:
   - In `architect.md`: Rename `## Phase 1: Specification` to `## Planning Phase` and `## Phase 2: Implementation` to `## Coding Phase`
   - In `planner.md`: Rename `## Phase 1: Specification` to `## Planning Phase` and `## Phase 2: Implementation` to `## Coding Phase`
   - In `constructor.md`: Rename `## Phase 1: Specification` to `## Planning Phase` and `## Phase 2: Implementation` to `## Coding Phase`

4. **Update `trip-commit.sh` example comment**:
   - Change the example from `planner specification "write-direction-v1"` to `planner planning "write-direction-v1"` to reflect the new phase naming convention

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -140,10 +140,10 @@
 | `[Planner] Create integration test plan covering authentication edge cases` | `[Planner] test plan` |
 | `[Constructor] Implement login endpoint with JWT token generation` | `[Constructor] impl` |

-Commit points in Phase 1 (Specification):
+Commit points in Planning Phase (Specification):
 - Planner writes direction → commit
 - Architect reviews direction → commit
 - Constructor reviews direction → commit
@@ -152,7 +152,7 @@
 - Each cross-review → commit
 - Each revision → commit
 - Consensus confirmation → commit

-Commit points in Phase 2 (Implementation):
+Commit points in Coding Phase (Implementation):
 - Test plan created → commit
 - Code implemented → commit
 - Structural review → commit
@@ -179,7 +179,7 @@

 ## Initialize Trip

-## Phase 1: Specification (Inner Loop)
+## Planning Phase: Specification (Inner Loop)

 Agents produce and mutually review artifacts until full consensus.

@@ -213,7 +213,7 @@

 ### Consensus Gate

-Phase 1 completes when all agents confirm:
+Planning Phase completes when all agents confirm:
 - Direction, Model, and Design are internally consistent
 - No unresolved disagreements remain
 - Artifacts are sufficient to begin implementation

-## Phase 2: Implementation (Outer Loop)
+## Coding Phase: Implementation (Outer Loop)

 With approved specification artifacts, agents transition to building.
```

### `plugins/trippin/skills/trip-protocol/SKILL.md` (System Safety section)

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -279,7 +279,7 @@
 ## System Safety

-Agents must not modify system-wide configuration (shell profiles, global packages, system services, `/etc/` files, `sudo` commands) unless the repository is a provisioning repository. The Constructor is the primary agent executing commands during Phase 2, so this constraint is especially critical for implementation work.
+Agents must not modify system-wide configuration (shell profiles, global packages, system services, `/etc/` files, `sudo` commands) unless the repository is a provisioning repository. The Constructor is the primary agent executing commands during Coding Phase, so this constraint is especially critical for implementation work.
```

### `plugins/trippin/commands/trip.md`

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -55,7 +55,7 @@

-If validation cannot be resolved (e.g., no `.env` file exists anywhere to copy), warn the user and proceed with the caveat that Phase 2 implementation may encounter environment issues.
+If validation cannot be resolved (e.g., no `.env` file exists anywhere to copy), warn the user and proceed with the caveat that Coding Phase implementation may encounter environment issues.

@@ -82,7 +82,7 @@
 >
-> **Phase 1 - Specification (Inner Loop)**:
+> **Planning Phase - Specification (Inner Loop)**:
 > 1. Ask Planner to write `directions/direction-v1.md` based on the user instruction → **commit**
@@ -96,7 +96,7 @@
 >
-> **Phase 2 - Implementation (Outer Loop)**:
+> **Coding Phase - Implementation (Outer Loop)**:
 > 1. Ask Planner to create a test plan (including E2E scenarios if the project has a user-facing interface) → **commit**
@@ -112,7 +112,7 @@
 1. List all artifacts created in `<trip_path>/`
 2. Summarize the agreed direction, model, and design
-3. Report any implementation results from Phase 2
+3. Report any implementation results from Coding Phase
 4. Show the worktree branch name for the user to merge or inspect
```

### `plugins/trippin/agents/architect.md`

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -42,11 +42,11 @@
 - **Translation Fidelity**: Ensure business intent is accurately represented in technical structure
 - **Boundary Integrity**: Ensure boundaries accommodate both business evolution and technical quality

-## Phase 1: Specification
+## Planning Phase

 1. Review Direction artifacts from Planner
 2. Write Model artifacts in `.workaholic/.trips/<trip-name>/models/` (blocking prerequisite for Constructor's design)
 3. Review Design artifacts from Constructor
 4. Moderate disagreements between Planner and Constructor when called upon

-## Phase 2: Implementation
+## Coding Phase

 1. Review the Constructor's implementation for structural integrity against the Model
```

### `plugins/trippin/agents/planner.md`

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -36,12 +36,12 @@
 - **Stakeholder Advocacy**: Actively represent stakeholder interests throughout the process
 - **Explanatory Accountability**: Ensure decisions are justified and traceable

-## Phase 1: Specification
+## Planning Phase

 1. Write Direction artifacts in `.workaholic/.trips/<trip-name>/directions/`
 2. Review Model artifacts from Architect and Design artifacts from Constructor
 3. Moderate disagreements between Architect and Constructor when called upon

-## Phase 2: Implementation
+## Coding Phase

 1. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
```

### `plugins/trippin/agents/constructor.md`

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -37,13 +37,13 @@
 - **Quality Assurance**: Ensure the output meets production standards and engineering excellence
 - **Delivery Accountability**: Own the technical delivery pipeline and what ships

-## Phase 1: Specification
+## Planning Phase

 1. Review Direction artifacts from Planner
 2. Wait for and read Model artifacts from Architect (the model is a prerequisite for the design)
 3. Write Design artifacts in `.workaholic/.trips/<trip-name>/designs/` derived from BOTH the approved Direction AND the completed Model
 4. Moderate disagreements between Planner and Architect when called upon

-## Phase 2: Implementation
+## Coding Phase

 1. Implement the program based on the approved Design and Model
```

### `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`

```diff
--- a/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
+++ b/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
@@ -1,7 +1,7 @@
 #!/bin/bash
 # Commit a trip workflow step with standardized message format.
 # Usage: bash trip-commit.sh <agent> <phase> <step> <description>
-# Example: bash trip-commit.sh planner specification "write-direction-v1" "Define initial creative direction based on user requirements"
+# Example: bash trip-commit.sh planner planning "write-direction-v1" "Define initial creative direction based on user requirements"
 # Commit message format: [Agent] <description>
 # Body: Phase: <phase>\nStep: <step>
```

## Considerations

- The `<phase>` parameter in `trip-commit.sh` is a free-form string written into the commit message body as `Phase: <phase>`. Existing trip branches that were created before this rename will have commits with `Phase: specification` or `Phase: implementation`. This is historical data and does not need migration, but consumers of git log output (such as `write-trip-report`) should be aware that both old and new phase names may appear in commit history. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` lines 26-27)
- The `trip-protocol/SKILL.md` description in the frontmatter says "Two-phase collaborative workflow protocol" which is still accurate with the rename since "two-phase" is a structural descriptor, not a name. No change needed there. (`plugins/trippin/skills/trip-protocol/SKILL.md` line 3)
- The README.md for Trippin describes the skill as "Two-phase collaborative workflow protocol and artifact conventions" which similarly does not use the numbered phase names and needs no update. (`plugins/trippin/README.md` line 18)
- The Commit Message Format section in trip-protocol uses `<phase>` as a generic placeholder. The agents and trip command will need to pass `planning` or `coding` as the phase value instead of `specification` or `implementation`. This is a convention change that the agent instructions must convey clearly. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 122-127)

## Final Report

### Changes Made

- Updated `plugins/trippin/skills/trip-protocol/SKILL.md` — renamed 6 references: phase headings, commit point labels, consensus gate, and System Safety section
- Updated `plugins/trippin/commands/trip.md` — renamed 4 references: environment warning, Agent Teams instruction block phase labels, and results summary
- Updated `plugins/trippin/agents/architect.md` — renamed phase section headings
- Updated `plugins/trippin/agents/planner.md` — renamed phase section headings
- Updated `plugins/trippin/agents/constructor.md` — renamed phase section headings
- Updated `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` — updated example comment

### Test Plan

- Grep for "Phase 1" and "Phase 2" in trippin plugin — should return zero matches
- Verify all files parse correctly as markdown with new headings
