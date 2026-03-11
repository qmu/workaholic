---
created_at: 2026-03-11T21:50:34+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Enable Concurrent Agent Work in Coding Phase

## Overview

Restructure the Coding Phase workflow so that all three agents (Constructor, Planner, Architect) begin their Coding Phase responsibilities concurrently rather than sequentially. The current workflow enforces a strict chain: Planner creates test plan, then Constructor implements, then Architect reviews, then Planner tests. This means the Constructor works alone during implementation while the Planner and Architect sit idle, even though their Coding Phase tasks (test planning, dev environment verification, codebase discovery for modeling artifacts) are independent of the Constructor's implementation work.

The new workflow launches all three agents simultaneously when the Coding Phase begins:

- **Constructor** starts implementing the program based on the approved Design and Model.
- **Planner** starts test planning: running the dev environment build script, using Playwright CLI MCP to verify the dev environment is running, and using Playwright CLI MCP on the target website to plan E2E testing.
- **Architect** starts discovering the codebase to generate modeling-related artifacts and prepare for structural review.

The convergence point is when the Constructor's implementation is complete. At that point, the Architect performs structural review of the actual implementation and the Planner executes tests against it. This maintains the existing review and testing quality gates while eliminating the idle time where agents wait for the Constructor to finish.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command orchestration; the Agent Teams instruction block (lines 99-104) defines the sequential Coding Phase steps that must be rewritten for concurrent launch
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining Coding Phase steps (lines 233-267); the sequential Step 1 through Step 4 structure must be replaced with concurrent launch and convergence gates
- `plugins/trippin/agents/planner.md` - Planner agent; Coding Phase section (lines 45-51) must be updated to describe concurrent test planning work that begins immediately
- `plugins/trippin/agents/architect.md` - Architect agent; Coding Phase section (lines 52-56) must be updated to describe concurrent codebase discovery that begins immediately
- `plugins/trippin/agents/constructor.md` - Constructor agent; Coding Phase section (lines 47-51) needs minimal change since its primary responsibility (implementation) stays the same

## Related History

The Coding Phase workflow was established as a strictly sequential process in the initial trip command implementation and has been refined through phase gate synchronization, phase renaming, and rollback mechanism additions. The synchronization enforcement was designed to prevent agents from racing ahead, but the sequential ordering of Coding Phase steps was an inherited assumption from the Planning Phase (where artifact dependencies create true ordering constraints). In the Coding Phase, the Planner's test planning and the Architect's codebase discovery have no dependency on the Constructor's implementation output.

Past tickets that touched similar areas:

- [20260311213007-phase-rollback-from-coding-to-planning.md](.workaholic/tickets/archive/drive-20260311-125319/20260311213007-phase-rollback-from-coding-to-planning.md) - Added rollback mechanism to Coding Phase (same Coding Phase workflow being restructured; rollback rules must be preserved)
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Added Phase Gate Policy and sequential GATE markers (the sequential gates in Coding Phase are what this ticket restructures)
- [20260311194519-rename-trip-phases-to-descriptive-names.md](.workaholic/tickets/archive/drive-20260311-125319/20260311194519-rename-trip-phases-to-descriptive-names.md) - Renamed phases to Planning Phase and Coding Phase (same files, same sections)
- [20260311011813-dev-environment-readiness-in-trip-worktree.md](.workaholic/tickets/archive/drive-20260310-220224/20260311011813-dev-environment-readiness-in-trip-worktree.md) - Added dev environment validation before Planning Phase (the Planner's Coding Phase dev environment work described here is a runtime re-check, distinct from the pre-planning validation)

## Implementation Steps

1. **Restructure the Coding Phase section in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Replace the sequential Step 1 through Step 4 structure with a two-phase concurrent model:
   - **Concurrent Launch**: All three agents begin work simultaneously when the Coding Phase starts:
     - Constructor starts implementing the program
     - Planner starts test planning (building dev environment, verifying it with Playwright CLI MCP, planning E2E tests using the target website)
     - Architect starts codebase discovery and generates modeling-related artifacts for structural review preparation
   - **Convergence Gate**: The leader waits for ALL three agents to complete their initial concurrent tasks before proceeding
   - **Sequential Review and Testing**: Once the Constructor's implementation is complete and the Planner's test plan is ready:
     - Architect reviews the implementation for structural integrity against the Model
     - Planner executes tests against the implementation
   - **Iteration**: Same as current -- if issues found, Constructor revises, then Architect re-reviews and Planner re-tests

2. **Update the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): Rewrite the Coding Phase steps (lines 99-104) to reflect the concurrent workflow:
   - Steps 1-3 become concurrent: "Ask Constructor to implement, Planner to create test plan, and Architect to discover codebase -- all three work simultaneously"
   - Add a WAIT FOR ALL marker after the concurrent phase
   - Steps 4-5 become the convergence phase: Architect reviews implementation, Planner validates through testing
   - Preserve the existing Rollback Rule section unchanged

3. **Update the Planner agent Coding Phase section** (`plugins/trippin/agents/planner.md`): Expand the Coding Phase responsibilities to describe the concurrent workflow:
   - Test planning begins immediately when the Coding Phase starts, concurrent with the Constructor's implementation
   - The Planner builds the development environment by running the appropriate build scripts
   - The Planner uses Playwright CLI MCP to verify the dev environment is accessible
   - The Planner uses Playwright CLI MCP on the target website to plan E2E test scenarios
   - Once the Constructor's implementation is complete, the Planner executes the test plan against the implementation

4. **Update the Architect agent Coding Phase section** (`plugins/trippin/agents/architect.md`): Expand the Coding Phase responsibilities to describe the concurrent workflow:
   - Codebase discovery begins immediately when the Coding Phase starts, concurrent with the Constructor's implementation
   - The Architect reads the codebase and existing patterns to prepare modeling-related artifacts that will inform the structural review
   - Once the Constructor's implementation is complete, the Architect reviews the implementation for structural integrity against the Model

5. **Update the Constructor agent Coding Phase section** (`plugins/trippin/agents/constructor.md`): Minor update to note that implementation begins concurrently with Planner's test planning and Architect's codebase discovery, but no change to the Constructor's core responsibility.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -235,23 +235,31 @@
 With approved specification artifacts, agents transition to building.

-### Step 1: Test Planning
+### Concurrent Launch

-**Planner** creates a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, the test plan should include E2E test scenarios (see E2E Assurance Policy below).
-- **GATE**: Leader confirms test plan is written before proceeding
+All three agents begin work simultaneously:

-### Step 2: Programming
+1. **Constructor** starts implementing the program based on the approved Design and Model
+2. **Planner** starts test planning: building the development environment, verifying it is running (using Playwright CLI MCP), and planning E2E test scenarios by examining the target website (using Playwright CLI MCP). When the project has a user-facing interface, the test plan should include E2E test scenarios (see E2E Assurance Policy below).
+3. **Architect** starts codebase discovery: reading the existing codebase structure and patterns to prepare modeling-related artifacts that will inform the upcoming structural review

-**Constructor** implements the program based on the approved Design and Model.
-- **GATE**: Leader confirms implementation is complete before proceeding
+- **GATE**: Leader waits for ALL three agents to complete their concurrent tasks before proceeding

-### Step 3: Reviewing
+### Review and Testing
+
+Once the Constructor's implementation is complete and the Planner's test plan is ready:

 **Architect** reviews the implementation for structural integrity against the Model.
 - **GATE**: Leader confirms review is complete before proceeding

-### Step 4: Testing
-
 **Planner** validates the implementation against the test plan. This includes running E2E tests via CLI when the test plan includes them.
 - **GATE**: Leader confirms testing is complete before proceeding
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -99,10 +99,13 @@
 > **Coding Phase - Implementation (Outer Loop)**:
-> 1. Ask Planner to create a test plan (including E2E scenarios if the project has a user-facing interface) → **commit**
-> 2. Ask Constructor to implement the program → **commit**
-> 3. Ask Architect to review structural integrity → **commit**
-> 4. Ask Planner to validate through testing (including E2E test execution if included in the test plan) → **commit**
-> 5. Iterate until all agents approve → **commit each iteration**
+> 1. **Concurrent launch** — ask all three agents to begin work simultaneously:
+>    - Ask Constructor to implement the program → **commit**
+>    - Ask Planner to create a test plan: build the dev environment, verify it is running (Playwright CLI MCP), plan E2E scenarios by examining the target website (Playwright CLI MCP) → **commit**
+>    - Ask Architect to discover the codebase and prepare modeling-related artifacts for structural review → **commit**
+> 2. **WAIT FOR ALL THREE** — do NOT proceed until Constructor, Planner, and Architect have all completed their concurrent tasks
+> 3. Ask Architect to review the Constructor's implementation for structural integrity → **commit**
+> 4. Ask Planner to validate the implementation through testing (including E2E test execution if included in the test plan) → **commit**
+> 5. Iterate until all agents approve → **commit each iteration**
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -45,7 +45,9 @@
 ## Coding Phase

-1. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
-2. Validate the Constructor's implementation through testing. This includes running E2E tests via CLI when the test plan includes them. Report failures with specific workflow breakdowns to the team lead.
+1. Begin test planning immediately when the Coding Phase starts, concurrent with the Constructor's implementation and the Architect's codebase discovery. Build the development environment by running the appropriate build/start scripts. Verify the dev environment is accessible using Playwright CLI MCP. Examine the target website using Playwright CLI MCP to plan E2E test scenarios. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
+2. Once the Constructor's implementation is complete, validate it through testing. This includes running E2E tests via CLI when the test plan includes them. Report failures with specific workflow breakdowns to the team lead.
 3. If testing reveals missing requirements or business scenarios not covered by the direction, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the requirement gaps
 4. When another agent proposes a rollback, evaluate from your business vision perspective and vote support or oppose
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -52,7 +52,8 @@
 ## Coding Phase

-1. Review the Constructor's implementation for structural integrity against the Model
+1. Begin codebase discovery immediately when the Coding Phase starts, concurrent with the Constructor's implementation and the Planner's test planning. Read the existing codebase structure, patterns, and conventions to prepare modeling-related artifacts that will inform the structural review.
+2. Once the Constructor's implementation is complete, review it for structural integrity against the Model
 2. If structural review reveals the model cannot support the implementation being built, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific structural evidence
 3. When another agent proposes a rollback, evaluate from your structural bridge perspective and vote support or oppose
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -47,7 +47,7 @@
 ## Coding Phase

-1. Implement the program based on the approved Design and Model
+1. Implement the program based on the approved Design and Model. Implementation begins immediately when the Coding Phase starts, concurrent with the Planner's test planning and the Architect's codebase discovery.
 2. If implementation reveals the design is not feasible at the required quality level, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the gap between design and implementability
 3. When another agent proposes a rollback, evaluate from your technical accountability perspective and vote support or oppose
```

## Considerations

- The Phase Gate Policy states "No sub-agent may autonomously advance to the next step" and "The leader waits for ALL concurrent tasks to complete before issuing the next round of work." The concurrent launch pattern is consistent with this policy because the leader explicitly launches all three agents at once and then waits at a convergence gate. The policy was designed to prevent agents from racing ahead, not to prevent intentional concurrent dispatch. However, the language may need reinforcement to distinguish "concurrent dispatch by the leader" from "autonomous advancement by a sub-agent." (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 27-36)
- The Planner's concurrent test planning includes building the dev environment and using Playwright CLI MCP, which are long-running operations. If the Constructor finishes implementation before the Planner completes test planning, the convergence gate will hold the review and testing steps until the Planner catches up. This is the correct behavior -- the Architect and Planner need their preparation work complete before they can meaningfully review and test the implementation. (`plugins/trippin/agents/planner.md` Coding Phase section)
- The dev environment validation in Step 3 of trip.md runs before the Planning Phase begins. The Planner's Coding Phase dev environment work described in this ticket is a distinct runtime activity: building and starting the dev server for the actual implementation, not just checking for dependencies and env files. These are complementary, not duplicative. (`plugins/trippin/commands/trip.md` lines 43-56)
- The Architect's "codebase discovery" during concurrent launch is preparatory work. The actual structural review of the Constructor's implementation still requires the implementation to be complete. If the Architect finishes codebase discovery before the Constructor finishes implementation, the Architect waits at the convergence gate. The discovery work is not wasted -- it gives the Architect deeper codebase understanding that makes the subsequent structural review more informed. (`plugins/trippin/agents/architect.md` Coding Phase section)
- The iteration loop after review and testing remains sequential (Constructor revises, Architect re-reviews, Planner re-tests). Concurrent iteration could cause conflicts where the Constructor is revising code while the Architect is reviewing stale code. The sequential iteration pattern should be preserved. (`plugins/trippin/skills/trip-protocol/SKILL.md` Iteration subsection)
- The Rollback Protocol is unchanged by this restructuring. Any agent can still propose a rollback at any point during the Coding Phase, whether during the concurrent launch or during review and testing. The convergence gate does not interfere with rollback proposals. (`plugins/trippin/skills/trip-protocol/SKILL.md` Rollback Protocol section)
- Agent Teams dispatches work to agents as separate context windows. When the leader sends concurrent tasks to all three agents, each agent works in its own context without blocking the others. The convergence gate is the leader waiting for all three to report completion. This is naturally supported by the Agent Teams architecture. (`plugins/trippin/commands/trip.md`)
