---
created_at: 2026-03-10T22:11:31+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Domain]
effort: 0.25h
commit_hash: daf86e8
category: Changed
---

# Enforce Phase Gate Synchronization in Trip Command

## Overview

Fix a workflow ordering violation in the Trippin plugin's trip command where sub-agents autonomously advance to artifact generation after completing their own review, without waiting for all reviewers to finish. Observed behavior: the Architect approved the Planner's direction artifact and immediately began generating its own model artifact, even though the Constructor's review was still pending. The correct behavior requires the trip command orchestrator (leader agent) to be the sole entity that advances the workflow to the next phase step. No sub-agent may proceed to generate its own artifact until ALL reviews for the current step are approved.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command orchestration; the Agent Teams instruction block defines the Phase 1 workflow steps but lacks explicit synchronization gates between review completion and artifact generation
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining the Phase 1 specification workflow; the Consensus Gate section exists but is only defined at the phase boundary (Phase 1 to Phase 2), not between sub-steps within Phase 1
- `plugins/trippin/agents/architect.md` - Architect agent definition; Phase 1 section lists "Review Direction" and "Write Model" as sequential responsibilities without a synchronization constraint between them
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; same pattern as architect
- `plugins/trippin/agents/planner.md` - Planner agent definition; same pattern as architect

## Related History

The trip command was recently implemented with a focus on establishing the basic workflow, worktree isolation, and commit-per-step conventions. The Phase 1 workflow described sequential steps but did not enforce synchronization between them. Two sibling tickets in the todo queue address related but distinct concerns: deterministic review file conventions (where reviews are written) and commit message formatting (how commits are labeled). This ticket addresses a third gap: when agents are allowed to advance to the next step.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command, agents, protocol, and workflow steps (direct predecessor; the source of the underspecified synchronization)
- [20260310220221-deterministic-artifact-review-convention.md](.workaholic/tickets/todo/20260310220221-deterministic-artifact-review-convention.md) - Sibling ticket addressing review artifact file conventions (related: also addresses concurrent agent behavior in the review step)
- [20260310220756-trip-commit-message-rules.md](.workaholic/tickets/todo/20260310220756-trip-commit-message-rules.md) - Sibling ticket addressing commit message format (same workflow, different concern)

## Implementation Steps

1. **Add a Phase Gate Policy section to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Define a universal synchronization rule that applies to every sub-step within both phases. The rule: when a sub-agent finishes a task (review, artifact creation, etc.), it must STOP and report completion to the leader. Only the leader agent may issue the next work request. No sub-agent may autonomously advance to the next step. Place this section prominently, before the Phase 1 details, so it applies globally.

2. **Add intra-phase consensus gates to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): The existing "Consensus Gate" section only covers the Phase 1 to Phase 2 transition. Add explicit gates within Phase 1:
   - After Step 1 (Direction): ALL reviewers (Architect AND Constructor) must approve before the leader requests Model and Design generation
   - After Step 2 (Model and Design): ALL cross-reviews must approve before declaring Phase 1 complete
   - Make it clear these are synchronization points, not just quality checks

3. **Rewrite the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): The current Phase 1 steps (lines 65-74) list actions sequentially but do not enforce waiting. Rewrite to make the leader's gating role explicit:
   - After requesting reviews from Architect and Constructor, the leader must WAIT for BOTH to complete and approve
   - Only after both approvals does the leader send requests to Architect (write model) and Constructor (write design)
   - Add explicit "WAIT FOR ALL REVIEWS" markers in the instruction text
   - Emphasize that the leader is the only entity that can advance the workflow

4. **Add a synchronization constraint to each agent definition** (`plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`, `plugins/trippin/agents/planner.md`): Add a "Synchronization Rule" section to each agent that states: "After completing any task (review, artifact creation, moderation), STOP and wait for the next instruction from the team lead. Do NOT proceed to your next responsibility autonomously." This reinforces the gate from the agent's own perspective.

5. **Restructure the Phase 1 workflow in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Rewrite the Phase 1 section to make synchronization gates visually distinct. Use a format like:
   - Step 1a: Planner writes direction
   - Step 1b: Architect reviews direction, Constructor reviews direction (concurrent, leader waits for both)
   - GATE: All reviews approved
   - Step 1c: Architect writes model, Constructor writes design (concurrent, leader waits for both)
   - Step 1d: Cross-reviews (each reviews the other's artifact, plus Planner reviews both)
   - GATE: All cross-reviews approved
   - Phase 1 complete

6. **Add gate enforcement language to the Agent Teams instruction** (`plugins/trippin/commands/trip.md`): In the instruction text passed to the Agent Teams session, add a top-level policy statement before the phase descriptions: "CRITICAL: You are the sole workflow coordinator. No agent may autonomously advance to the next step. After assigning a task to an agent, wait for its completion before issuing the next task. After assigning reviews to multiple agents, wait for ALL reviews to complete before advancing."

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -24,6 +24,18 @@
 - **Goal**: Maximize benefit / Minimize loss (Optimization Problem)
 - **Responsibility**: Prevent what shouldn't happen (Constraint Satisfaction)

+## Phase Gate Policy
+
+**CRITICAL: The leader agent is the sole workflow coordinator. No sub-agent may autonomously advance to the next step.**
+
+Rules:
+1. When a sub-agent finishes a task (review, artifact creation, moderation), it STOPS and reports completion
+2. The leader waits for ALL concurrent tasks to complete before issuing the next round of work
+3. Review approval by all reviewers is a prerequisite before any agent begins artifact generation
+4. No agent may interpret its own approval as permission to proceed to its next responsibility
+
+Every transition between sub-steps requires the leader to explicitly request the next action. This prevents race conditions where one agent's early completion causes it to skip ahead while other agents are still working.
+
 ## Worktree Isolation
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -85,17 +97,23 @@
 ## Phase 1: Specification (Inner Loop)

 Agents produce and mutually review artifacts until full consensus.

 ### Step 1: Direction

 1. **Planner** writes `directions/direction-v1.md` based on the user instruction
 2. **Architect** reviews for semantical consistency and static verification
 3. **Constructor** reviews for sustainable implementation and infrastructure reliability
-4. If disagreements arise, the third party moderates (see Moderation Protocol)
-5. Revisions produce `direction-v2.md`, `direction-v3.md`, etc.
-6. Consensus required from all three agents before proceeding
+4. **GATE**: Leader waits for BOTH Architect AND Constructor reviews to complete
+5. If disagreements arise, the third party moderates (see Moderation Protocol)
+6. Revisions produce `direction-v2.md`, `direction-v3.md`, etc.
+7. **GATE**: All three agents approve the direction before proceeding

 ### Step 2: Model and Design

-Once Direction is agreed:
+Once Direction is approved and the leader has confirmed consensus:
 1. **Architect** writes `models/model-v1.md` derived from the approved Direction
 2. **Constructor** writes `designs/design-v1.md` derived from the approved Direction
-3. Each agent reviews the other's artifact
-4. **Planner** reviews both for alignment with the Direction
-5. Revisions continue until all three artifacts are mutually consistent
+3. **GATE**: Leader waits for BOTH model and design to be written
+4. Each agent reviews the other's artifact
+5. **Planner** reviews both for alignment with the Direction
+6. **GATE**: Leader waits for ALL cross-reviews to complete
+7. Revisions continue until all three artifacts are mutually consistent
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -44,4 +44,10 @@
 ## Protocol

 Follow the preloaded **trip-protocol** skill for artifact format, versioning, consensus gates, and moderation rules.
+
+## Synchronization Rule
+
+After completing any task (review, artifact creation, moderation), **STOP and wait** for the next instruction from the team lead. Do NOT proceed to your next responsibility autonomously. The team lead coordinates all workflow transitions.
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -44,4 +44,10 @@
 ## Protocol

 Follow the preloaded **trip-protocol** skill for artifact format, versioning, consensus gates, and moderation rules.
+
+## Synchronization Rule
+
+After completing any task (review, artifact creation, moderation, implementation), **STOP and wait** for the next instruction from the team lead. Do NOT proceed to your next responsibility autonomously. The team lead coordinates all workflow transitions.
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -44,4 +44,10 @@
 ## Protocol

 Follow the preloaded **trip-protocol** skill for artifact format, versioning, consensus gates, and moderation rules.
+
+## Synchronization Rule
+
+After completing any task (review, artifact creation, moderation, testing), **STOP and wait** for the next instruction from the team lead. Do NOT proceed to your next responsibility autonomously. The team lead coordinates all workflow transitions.
```

## Considerations

- The Agent Teams feature runs agents in separate context windows with independent execution. The synchronization enforcement is purely through instruction text -- there is no mechanical lock or barrier. If an agent's context window does not retain the synchronization rule prominently enough, it may still proceed autonomously. Repeating the rule in multiple locations (protocol skill, agent definition, and command instruction) provides defense-in-depth. (`plugins/trippin/commands/trip.md`, `plugins/trippin/skills/trip-protocol/SKILL.md`)
- The sibling ticket for deterministic artifact review conventions (`20260310220221-deterministic-artifact-review-convention.md`) is complementary: that ticket defines WHERE reviews are written (separate files), while this ticket defines WHEN the next step begins (after all reviews complete). Both should be implemented together for a coherent workflow. (`.workaholic/tickets/todo/20260310220221-deterministic-artifact-review-convention.md`)
- The current trip command instruction block in `trip.md` uses a numbered list (lines 65-82) that implies sequential execution, but Agent Teams agents may interpret these as a full roadmap and work ahead. The rewrite must use language that makes the leader's gating role impossible to misinterpret -- consider using ALL CAPS markers like "WAIT" and "GATE" in the instruction text. (`plugins/trippin/commands/trip.md` lines 65-82)
- The Phase 2 workflow also needs synchronization gates (between implementation, review, and testing), though the problem was observed in Phase 1. The Phase Gate Policy should apply universally to both phases. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 114-140)
- Agent Teams communication model limitations: agents communicate by reading filesystem artifacts, not through a message queue. The leader agent must poll or be notified when an agent's task is complete. The current design assumes the leader can observe commits; if this is unreliable, consider adding a completion signal mechanism (e.g., a status file the agent writes when done). (`plugins/trippin/commands/trip.md`)

## Final Report

### Changes Made

- **`plugins/trippin/skills/trip-protocol/SKILL.md`**: Added Phase Gate Policy section before Worktree Isolation defining the universal synchronization rule. Added intra-phase GATE markers to Phase 1 Steps 1 and 2. Added per-step GATE markers to Phase 2 steps and iteration loop.
- **`plugins/trippin/commands/trip.md`**: Added CRITICAL coordinator policy to Agent Teams instruction block. Rewrote Phase 1 steps with explicit WAIT FOR ALL REVIEWS, GATE, and WAIT FOR ALL ARTIFACTS/CROSS-REVIEWS markers.
- **`plugins/trippin/agents/architect.md`**: Added Synchronization Rule section.
- **`plugins/trippin/agents/constructor.md`**: Added Synchronization Rule section.
- **`plugins/trippin/agents/planner.md`**: Added Synchronization Rule section.

### Approach

Defense-in-depth: the synchronization rule is enforced at three layers (protocol skill, command instruction, agent definition) so that even if one layer is lost from an agent's context, the others reinforce it.
