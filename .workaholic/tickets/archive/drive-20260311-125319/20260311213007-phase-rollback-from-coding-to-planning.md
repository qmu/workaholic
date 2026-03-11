---
created_at: 2026-03-11T21:30:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 0.5h
commit_hash: 5b4feda
category: Added
---

# Phase Rollback from Coding Phase to Planning Phase

## Overview

Add a phase rollback mechanism to the trip command that allows agents to return from the Coding Phase back to the Planning Phase when they determine the current implementation approach is fundamentally flawed. Currently the workflow is strictly one-directional: once the Planning Phase consensus gate is passed and the Coding Phase begins, there is no mechanism to revisit the direction, model, or design artifacts. This creates a situation where the Constructor may struggle with an implementation that was poorly specified, or the Architect may discover during code review that the structural model needs redesign, but neither can trigger a return to planning.

The rollback requires a two-out-of-three consensus vote. Any agent can propose a rollback, but the process only moves back to the Planning Phase when at least two of the three agents agree. This prevents a single agent from disrupting progress while still allowing the team to self-correct when the majority recognizes a fundamental problem.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command orchestration; the Agent Teams instruction block defines the Coding Phase workflow and must be extended with rollback rules and the consensus voting mechanism
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining phase structure, phase gate policy, and consensus gates; needs a new Rollback Protocol section and modifications to the Coding Phase workflow
- `plugins/trippin/agents/planner.md` - Planner agent definition; needs rollback proposal and voting capability documented in its Coding Phase responsibilities
- `plugins/trippin/agents/architect.md` - Architect agent definition; needs rollback proposal and voting capability documented in its Coding Phase responsibilities
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; needs rollback proposal and voting capability documented in its Coding Phase responsibilities
- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` - Commit script; the phase parameter must support a `rollback` value for rollback-related commits

## Related History

The trip workflow was built with a strictly forward-moving phase model: Planning Phase produces artifacts, consensus gate approves them, then Coding Phase implements them. The Phase Gate Policy added synchronization enforcement but only for forward transitions between sub-steps. The phase rename from numbered phases to "Planning Phase" and "Coding Phase" made the workflow more readable but did not change the unidirectional flow. No previous ticket has addressed backward phase transitions.

Past tickets that touched similar areas:

- [20260311194519-rename-trip-phases-to-descriptive-names.md](.workaholic/tickets/archive/drive-20260311-125319/20260311194519-rename-trip-phases-to-descriptive-names.md) - Renamed phases to Planning Phase and Coding Phase (same files, same phase structure being extended)
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Added Phase Gate Policy and synchronization enforcement (same coordination mechanism being extended with rollback gates)
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Original trip command implementation establishing the two-phase workflow (the foundation being extended)

## Implementation Steps

1. **Add a Rollback Protocol section to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Place this new section after the Coding Phase section and before E2E Assurance Policy. Define the rollback mechanism:
   - Any agent (Planner, Architect, or Constructor) can propose a rollback to the Planning Phase at any point during the Coding Phase
   - The proposing agent writes a rollback proposal artifact to `.workaholic/.trips/<trip-name>/rollbacks/rollback-v<N>.md` explaining why the Planning Phase artifacts are insufficient
   - The other two agents each vote by writing a response artifact to `rollbacks/reviews/rollback-v<N>-<agent>.md` with either "support" or "oppose" and their reasoning
   - If at least two out of three agents support the rollback (the proposer counts as one supporter), the rollback proceeds
   - The leader agent coordinates the vote: after a proposal is committed, it requests votes from the other two agents, waits for both, then tallies
   - On rollback: the workflow returns to the appropriate Planning Phase step (Direction revision, Model revision, or Design revision) based on the rollback proposal's recommendation
   - After rollback, all Planning Phase consensus gates apply again -- the team must re-achieve consensus before returning to the Coding Phase
   - Rollback increments the version counters for any revised artifacts (e.g., `direction-v3.md` if two versions existed before)

2. **Add rollback artifact format to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): In the Artifact Storage section, add the `rollbacks/` directory and `rollbacks/reviews/` subdirectory to the directory tree. Define the rollback proposal artifact format:
   - Title: `Rollback Proposal v<N>`
   - Author: the proposing agent
   - Reason: what went wrong during Coding Phase
   - Target: which Planning Phase step to return to (Direction, Model, or Design)
   - Evidence: specific implementation issues that motivated the proposal

3. **Update the Coding Phase section in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): After the Iteration subsection, add a Rollback subsection that references the Rollback Protocol. State that at any point during Coding Phase steps (test planning, implementation, review, testing, or iteration), an agent may propose a rollback instead of continuing iteration.

4. **Update the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): Add rollback rules to the Coding Phase section of the instruction text. After the iteration step (step 5), add:
   - If any agent proposes a rollback, the leader pauses Coding Phase work
   - The leader requests votes from the other two agents
   - The leader waits for both votes (GATE)
   - If two or more agents support rollback: return to Planning Phase at the specified step, re-run the specification loop from that point
   - If rollback is rejected (only one supporter): continue Coding Phase iteration
   - Each rollback proposal and vote produces a commit

5. **Add rollback capability to each agent definition** (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`): In the Coding Phase section of each agent, add a rollback paragraph:
   - The agent may propose a rollback if it determines the Planning Phase artifacts are fundamentally insufficient for successful implementation
   - Scenarios: Planner finds test plan reveals missing requirements; Architect finds structural model cannot support the implementation; Constructor finds the design is not implementable at the required quality level
   - When another agent proposes a rollback, this agent must evaluate the proposal from its own domain perspective and vote support or oppose

6. **Update the init-trip.sh script** (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`): Add `rollbacks/` and `rollbacks/reviews/` to the directory structure created during trip initialization.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -174,6 +174,7 @@
 .workaholic/.trips/<trip-name>/
   directions/           # Planner's artifacts
     reviews/            # Review feedback on directions
+  rollbacks/            # Rollback proposals
+    reviews/            # Votes on rollback proposals
   models/               # Architect's artifacts
     reviews/            # Review feedback on models
   designs/              # Constructor's artifacts
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch adds the Rollback Protocol section after the Coding Phase Iteration subsection.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -258,6 +258,52 @@
 - Planner re-tests → **GATE**: Leader confirms re-test complete
 - Continue until all pass

+## Rollback Protocol
+
+During the Coding Phase, any agent may propose returning to the Planning Phase when they determine the specification artifacts are fundamentally insufficient for successful implementation.
+
+### Trigger Scenarios
+
+- **Constructor**: Implementation is not feasible at the required quality level given the current design
+- **Architect**: Structural review reveals the model cannot support the implementation being built
+- **Planner**: Testing reveals missing requirements or business scenarios not covered by the direction
+
+### Consensus Requirement
+
+Rollback requires a **two-out-of-three majority**. The proposing agent counts as one supporter.
+
+1. Proposing agent writes `rollbacks/rollback-v<N>.md` with reason, target step, and evidence → **commit**
+2. **GATE**: Leader requests votes from the other two agents
+3. Each voting agent writes `rollbacks/reviews/rollback-v<N>-<agent>.md` with "support" or "oppose" and reasoning → **commit each**
+4. **GATE**: Leader waits for both votes
+5. Leader tallies: if 2+ agents support → rollback proceeds; if only 1 → Coding Phase continues
+
+### On Rollback Approval
+
+- The workflow returns to the Planning Phase at the step specified in the proposal (Direction, Model, or Design revision)
+- Revised artifacts use incremented version numbers (e.g., if `direction-v2.md` was the last approved version, the revision is `direction-v3.md`)
+- All Planning Phase consensus gates apply again — the team must re-achieve full consensus before returning to the Coding Phase
+- The rollback and its resolution are preserved in the `rollbacks/` directory as part of the process trace
+
+### Rollback Proposal Artifact Format
+
+```markdown
+# Rollback Proposal v<N>
+
+**Author**: <Agent Name>
+**Status**: proposed | approved | rejected
+**Target**: <Direction | Model | Design>
+
+## Reason
+
+<Why the current specification is insufficient>
+
+## Evidence
+
+<Specific implementation issues encountered during Coding Phase>
+
+## Votes
+
+- <Agent 1>: <support | oppose> — <reasoning>
+- <Agent 2>: <support | oppose> — <reasoning>
+```
+
 ## E2E Assurance Policy
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch adds rollback rules to the Coding Phase in the Agent Teams instruction block.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -103,6 +103,14 @@
 > 4. Ask Planner to validate through testing (including E2E test execution if included in the test plan) → **commit**
 > 5. Iterate until all agents approve → **commit each iteration**
 >
+> **Rollback Rule**:
+> If any agent proposes a rollback to the Planning Phase during Coding Phase:
+> 1. Pause all Coding Phase work
+> 2. The proposing agent writes a rollback proposal artifact → **commit**
+> 3. Request votes from the other two agents → **commit each vote**
+> 4. **WAIT FOR BOTH VOTES** before proceeding
+> 5. If 2+ agents support: return to Planning Phase at the specified step, re-run specification loop from that point
+> 6. If only 1 supports: continue Coding Phase iteration
+>
 > **Artifact format**: Each artifact uses the structure defined in the trip-protocol skill (title, author, status, reviewed-by, content, review notes).
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch adds rollback capability to the Constructor's Coding Phase section.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -49,6 +49,8 @@
 ## Coding Phase

 1. Implement the program based on the approved Design and Model
+2. If implementation reveals the design is not feasible at the required quality level, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the gap between design and implementability
+3. When another agent proposes a rollback, evaluate from your technical accountability perspective and vote support or oppose
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch adds rollback capability to the Architect's Coding Phase section.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -53,6 +53,8 @@
 ## Coding Phase

 1. Review the Constructor's implementation for structural integrity against the Model
+2. If structural review reveals the model cannot support the implementation being built, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific structural evidence
+3. When another agent proposes a rollback, evaluate from your structural bridge perspective and vote support or oppose
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch adds rollback capability to the Planner's Coding Phase section.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -47,6 +47,8 @@
 ## Coding Phase

 1. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
 2. Validate the Constructor's implementation through testing. This includes running E2E tests via CLI when the test plan includes them. Report failures with specific workflow breakdowns to the team lead.
+3. If testing reveals missing requirements or business scenarios not covered by the direction, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the requirement gaps
+4. When another agent proposes a rollback, evaluate from your business vision perspective and vote support or oppose
```

### `plugins/trippin/skills/trip-protocol/sh/init-trip.sh`

> **Note**: This patch adds the rollbacks directory to trip initialization.

```diff
--- a/plugins/trippin/skills/trip-protocol/sh/init-trip.sh
+++ b/plugins/trippin/skills/trip-protocol/sh/init-trip.sh
@@ -30,6 +30,7 @@
 mkdir -p "${trip_path}/directions/reviews"
 mkdir -p "${trip_path}/models/reviews"
 mkdir -p "${trip_path}/designs/reviews"
+mkdir -p "${trip_path}/rollbacks/reviews"
```

## Considerations

- The rollback mechanism relies entirely on instruction text enforcement, the same as the Phase Gate Policy. There is no mechanical barrier preventing an agent from ignoring a rejected rollback vote and continuing to propose rollbacks repeatedly. The two-out-of-three consensus requirement mitigates this by requiring majority agreement, but a determined agent could theoretically spam proposals. Consider adding a cooldown or maximum rollback count if this becomes a problem in practice. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- When a rollback returns to the Planning Phase, the scope of revision needs to be clear. If the rollback targets the Direction, then the Model and Design must also be revised (per the existing artifact dependency chain: Direction -> Model -> Design). If it targets only the Design, the Direction and Model remain approved. The rollback proposal's "Target" field determines the re-entry point. (`plugins/trippin/skills/trip-protocol/SKILL.md` Artifact Dependencies section)
- The Coding Phase may have already produced partial implementation commits on the trip branch before a rollback occurs. These commits remain in the git history as part of the process trace. After rollback, the revised Planning Phase may produce different specification artifacts, and the subsequent Coding Phase will build on top of the existing commits (not revert them). This means the Constructor will need to reconcile any prior implementation work with the revised specification. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
- The commit message for rollback-related steps uses the existing `trip-commit.sh` with phase set to `rollback`. This introduces a third phase value alongside `planning` and `coding`. Consumers of commit history (such as `write-trip-report`) should be aware of this new phase value. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` lines 26-27)
- Agent Teams context window limitations may cause agents to lose track of the rollback protocol details during long sessions. The defense-in-depth approach (protocol skill + command instruction + agent definition) used for Phase Gate Policy should be replicated for rollback rules. (`plugins/trippin/commands/trip.md`, `plugins/trippin/skills/trip-protocol/SKILL.md`, `plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)

## Final Report

### Changes Made

- Updated `plugins/trippin/skills/trip-protocol/SKILL.md` — added Rollback Protocol section (trigger scenarios, 2/3 consensus requirement, approval workflow, artifact format), Rollback subsection under Coding Phase, and `rollbacks/` to Artifact Storage
- Updated `plugins/trippin/commands/trip.md` — added Rollback Rule to Agent Teams instruction block
- Updated `plugins/trippin/agents/constructor.md` — added rollback proposal and voting to Coding Phase
- Updated `plugins/trippin/agents/architect.md` — added rollback proposal and voting to Coding Phase
- Updated `plugins/trippin/agents/planner.md` — added rollback proposal and voting to Coding Phase
- Updated `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` — added `rollbacks/reviews` to directory creation

### Test Plan

- Verify trip-protocol SKILL.md has Rollback Protocol section between Iteration and E2E Assurance Policy
- Verify all 3 agent files have rollback capability in Coding Phase
- Verify trip.md Agent Teams instruction includes Rollback Rule
- Verify init-trip.sh creates rollbacks/reviews directory
