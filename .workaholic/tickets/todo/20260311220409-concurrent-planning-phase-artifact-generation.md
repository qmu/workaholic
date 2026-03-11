---
created_at: 2026-03-11T22:04:09+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Concurrent Planning Phase Artifact Generation with Mutual Review

## Overview

Restructure the Planning Phase so that all three agents (Planner, Architect, Constructor) generate their artifacts concurrently rather than following the current sequential dependency chain (Direction -> Model -> Design). The current workflow enforces strict ordering: the Planner writes the Direction first, then the Architect reads the Direction and writes the Model, then the Constructor reads both the Direction and Model and writes the Design. Each step also includes review gates where the other two agents review the artifact before the next generation step begins. This creates a long serial pipeline where two agents are idle at any given time.

The new workflow has three stages:

1. **Concurrent Artifact Generation**: When the Planning Phase begins, all three agents start writing their artifacts simultaneously. The Planner writes the Direction (business vision), the Architect writes the Model (structural translation), and the Constructor writes the Design (technical implementation plan). Each agent works from the user instruction and their own domain perspective without waiting for the other agents' artifacts.

2. **Mutual Review Session**: Once all three artifacts are complete, the agents enter a structured mutual review session. Each agent reviews the other two agents' artifacts, producing six review files total. This is a well-organized round where every perspective evaluates every artifact.

3. **Convergence**: The team discusses the reviews and reaches consensus. If revisions are needed, the relevant agents revise their artifacts and another review round occurs. The team iterates until all three agents approve all three artifacts as mutually consistent.

This eliminates the sequential bottleneck where Direction must exist before Model, and Model must exist before Design. Instead of three sequential generation-review cycles, there is one concurrent generation followed by mutual review and convergence.

## Key Files

- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining the Planning Phase workflow (lines 194-231); the Artifact Dependencies section (lines 58-69) explicitly declares `Direction -> Model -> Design` as strict ordering that must be replaced with concurrent generation; the Planning Phase Step 1 (Direction) and Step 2 (Model and Design) must be merged into a single concurrent generation step followed by mutual review
- `plugins/trippin/commands/trip.md` - Trip command orchestration; the Agent Teams instruction block (lines 85-97) defines the sequential Planning Phase steps that must be rewritten for concurrent launch and mutual review
- `plugins/trippin/agents/planner.md` - Planner agent; Planning Phase section (lines 39-43) describes writing Direction first then reviewing Model and Design; must be updated to describe concurrent generation
- `plugins/trippin/agents/architect.md` - Architect agent; Planning Phase section (lines 47-50) describes reviewing Direction first then writing Model; must be updated to describe concurrent generation with Model written from user instruction and domain expertise rather than from the approved Direction
- `plugins/trippin/agents/constructor.md` - Constructor agent; Planning Phase section (lines 41-44) explicitly states "Wait for and read Model artifacts from Architect (the model is a prerequisite for the design)"; this dependency must be removed in favor of concurrent generation from the user instruction

## Related History

The Planning Phase sequential ordering was established intentionally through the model-before-design dependency enforcement ticket, which determined that the Constructor's Design has a data dependency on the Architect's Model. The Phase Gate Policy added synchronization gates to prevent agents from racing ahead. The personality spectrum rewrite repositioned the Planner as a business visionary and the Constructor as technically accountable, which actually strengthens the case for concurrent generation: each agent has a distinct domain perspective that can produce its artifact independently from the user instruction without needing the other agents' artifacts as input.

Past tickets that touched similar areas:

- [20260310221350-enforce-model-before-design-dependency-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221350-enforce-model-before-design-dependency-in-trip.md) - Established the Direction -> Model -> Design sequential ordering; this is the exact constraint being reversed by concurrent generation
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Added Phase Gate Policy and GATE markers; the gates within Planning Phase steps must be restructured for concurrent dispatch
- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Repositioned agents along business-vision/structural-bridge/technical-accountability spectrum; strengthens the rationale for concurrent generation since each agent has a self-contained domain perspective
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Initial trip command implementation establishing the three-agent workflow
- [20260311215034-concurrent-coding-phase-agents.md](.workaholic/tickets/todo/20260311215034-concurrent-coding-phase-agents.md) - Complementary ticket making the Coding Phase concurrent (different phase, same concurrency pattern)
- [20260311215505-enforce-planner-business-focus-in-planning-phase.md](.workaholic/tickets/todo/20260311215505-enforce-planner-business-focus-in-planning-phase.md) - Complementary ticket enforcing Planner's business focus; the Planner still writes business-focused Direction, just concurrently now

## Implementation Steps

1. **Replace the Artifact Dependencies section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Remove the strict sequential ordering declaration. Replace with a concurrent generation model:
   - All three artifacts (Direction, Model, Design) are generated concurrently from the user instruction
   - Each agent writes from their own domain perspective without reading the other agents' artifacts
   - The Direction is still business-focused (Planner), the Model is still structural (Architect), the Design is still technical (Constructor)
   - The mutual review session after generation is where cross-pollination and alignment happen
   - On revision cycles: if an artifact is revised, only the author revises it (incorporating review feedback from the other two agents), and another mutual review round follows

2. **Restructure the Planning Phase section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Merge the current Step 1 (Direction) and Step 2 (Model and Design) into a new three-step structure:
   - **Step 1: Concurrent Artifact Generation** - All three agents begin writing simultaneously: Planner writes `directions/direction-v1.md`, Architect writes `models/model-v1.md`, Constructor writes `designs/design-v1.md`. Each agent works from the user instruction and their own domain expertise. GATE: Leader waits for ALL three artifacts to be committed.
   - **Step 2: Mutual Review Session** - Each agent reviews the other two agents' artifacts, producing six review files: Architect reviews Direction, Constructor reviews Direction, Planner reviews Model, Constructor reviews Model, Planner reviews Design, Architect reviews Design. GATE: Leader waits for ALL six reviews to complete.
   - **Step 3: Convergence** - The team discusses reviews and reaches consensus. If revisions are needed, affected agents revise their artifacts (incrementing version numbers), then another mutual review round occurs (Step 2). GATE: All three agents approve all three artifacts before proceeding to Coding Phase.

3. **Rewrite the Planning Phase steps in the trip command** (`plugins/trippin/commands/trip.md`): Replace the current 13-step sequential Planning Phase (lines 85-97) with:
   - Concurrent launch: Ask all three agents to write their artifacts simultaneously
   - WAIT FOR ALL THREE artifacts to be complete
   - Mutual review: Ask each agent to review the other two agents' artifacts
   - WAIT FOR ALL SIX reviews to complete
   - If disagreements arise, the relevant agents revise and another review round occurs
   - Iterate until full consensus on all three artifacts

4. **Update the Planner agent Planning Phase section** (`plugins/trippin/agents/planner.md`): Change from "Write Direction first, then review Model and Design" to "Write Direction concurrently with Model and Design based on the user instruction, then participate in mutual review of all artifacts."

5. **Update the Architect agent Planning Phase section** (`plugins/trippin/agents/architect.md`): Remove the statement that Model is a "blocking prerequisite for Constructor's design." Change to "Write Model concurrently with Direction and Design based on the user instruction and domain expertise, then participate in mutual review of all artifacts." The Architect no longer waits for the approved Direction before writing the Model.

6. **Update the Constructor agent Planning Phase section** (`plugins/trippin/agents/constructor.md`): Remove the "Wait for and read Model artifacts from Architect" dependency. Change to "Write Design concurrently with Direction and Model based on the user instruction and domain expertise, then participate in mutual review of all artifacts." The Constructor no longer depends on either Direction or Model as input.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -57,13 +57,12 @@
 ## Artifact Dependencies

-Artifacts have strict data flow dependencies that determine generation order:
+Artifacts are generated concurrently, then aligned through mutual review:

 ```
-Direction (Planner) ──→ Model (Architect) ──→ Design (Constructor)
+Direction (Planner) ──┐
+Model (Architect)   ──┼──→ Mutual Review ──→ Convergence
+Design (Constructor) ─┘
 ```

-- **Direction** feeds into both Model and Design
-- **Model** feeds into Design (the Constructor must read the completed Model before writing Design)
-- This creates strict ordering: Direction → Model → Design (never concurrent)
-- Cross-reviews happen only after both Model and Design exist
-
-On revision cycles: if a Direction is revised and re-approved, the Architect must regenerate the Model first, and only then does the Constructor regenerate the Design.
+- All three artifacts are generated concurrently from the user instruction
+- Each agent writes from their own domain perspective without reading the other agents' artifacts
+- **Mutual Review** aligns the three artifacts: each agent reviews the other two agents' work
+- On revision cycles: the artifact author incorporates review feedback and writes the next version; another mutual review round follows until consensus
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying. This replaces the Planning Phase Step 1 and Step 2 sections.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -196,33 +196,32 @@
 Agents produce and mutually review artifacts until full consensus.

-### Step 1: Direction
+### Step 1: Concurrent Artifact Generation

-1. **Planner** writes `directions/direction-v1.md` based on the user instruction
-2. **Architect** reviews and writes `directions/reviews/direction-v1-architect.md`
-3. **Constructor** reviews and writes `directions/reviews/direction-v1-constructor.md`
-4. **GATE**: Leader waits for BOTH Architect AND Constructor reviews to complete
-5. If disagreements arise, the third party moderates (see Moderation Protocol)
-6. Revisions produce `direction-v2.md`, `direction-v3.md`, etc.
-7. **GATE**: All three agents approve the direction before proceeding
+All three agents begin writing their artifacts simultaneously from the user instruction:

-### Step 2: Model and Design
+1. **Planner** writes `directions/direction-v1.md` (business vision, stakeholder value, risk landscape)
+2. **Architect** writes `models/model-v1.md` (structural translation, system coherence, boundary integrity)
+3. **Constructor** writes `designs/design-v1.md` (technical implementation plan, engineering approach, quality strategy)

-Once Direction is approved and the leader has confirmed consensus:
+- **GATE**: Leader waits for ALL THREE artifacts to be committed and complete

-**Step 2a: Model**
-1. **Architect** writes `models/model-v1.md` derived from the approved Direction
-2. **GATE**: Leader confirms model is committed and complete
+### Step 2: Mutual Review Session

-**Step 2b: Design**
-3. **Constructor** reads the completed Model, then writes `designs/design-v1.md` derived from BOTH the approved Direction AND the completed Model
-4. **GATE**: Leader confirms design is committed and complete
+Each agent reviews the other two agents' artifacts:

-**Step 2c: Cross-Review**
-5. **Architect** reviews design and writes `designs/reviews/design-v1-architect.md`; **Constructor** reviews model and writes `models/reviews/model-v1-constructor.md`
-6. **Planner** reviews both and writes `models/reviews/model-v1-planner.md` and `designs/reviews/design-v1-planner.md`
-7. **GATE**: Leader waits for ALL cross-reviews to complete
-8. Revisions continue until all three artifacts are mutually consistent
+1. **Planner** reviews Model and Design: writes `models/reviews/model-v1-planner.md` and `designs/reviews/design-v1-planner.md`
+2. **Architect** reviews Direction and Design: writes `directions/reviews/direction-v1-architect.md` and `designs/reviews/design-v1-architect.md`
+3. **Constructor** reviews Direction and Model: writes `directions/reviews/direction-v1-constructor.md` and `models/reviews/model-v1-constructor.md`
+
+- **GATE**: Leader waits for ALL SIX reviews to complete
+
+### Step 3: Convergence
+
+1. If disagreements arise, the relevant agents revise their artifacts incorporating review feedback (e.g., `direction-v2.md`, `model-v2.md`, `design-v2.md`)
+2. After revisions, another mutual review round occurs (return to Step 2)
+3. If disagreements between two agents persist, the third agent moderates (see Moderation Protocol)
+4. **GATE**: All three agents approve all three artifacts before proceeding to Coding Phase

 ### Consensus Gate
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -85,13 +85,16 @@
 > **Planning Phase - Specification (Inner Loop)**:
-> 1. Ask Planner to write `directions/direction-v1.md` based on the user instruction → **commit**
-> 2. Ask Architect to review the direction and write `directions/reviews/direction-v1-architect.md` → **commit**
-> 3. Ask Constructor to review the direction and write `directions/reviews/direction-v1-constructor.md` → **commit**
-> 4. **WAIT FOR ALL REVIEWS** — do NOT proceed until both Architect and Constructor have completed their reviews
-> 5. If disagreements arise, the third agent moderates and writes resolution → **commit**
-> 6. Iterate revisions until all three approve the direction → **commit each revision**
-> 7. **GATE: Direction approved** — only after all three agents approve, proceed to Model and Design
-> 8. Ask Architect to write `models/model-v1.md` → **commit** → **WAIT** for model to be complete
-> 9. After the model is complete, ask Constructor to READ the model, then write `designs/design-v1.md` based on BOTH the direction AND the model → **commit** → **WAIT** for design to be complete
-> 10. Each agent reviews the other's artifact by writing to `reviews/` subdirectories (e.g., `designs/reviews/design-v1-architect.md`) → **commit each review**
-> 12. **WAIT FOR ALL CROSS-REVIEWS** — do NOT proceed until all reviews are complete
-> 13. Iterate until full consensus on direction, model, and design → **commit each revision**
+> 1. **Concurrent artifact generation** — ask all three agents to begin writing their artifacts simultaneously:
+>    - Ask Planner to write `directions/direction-v1.md` (business vision) → **commit**
+>    - Ask Architect to write `models/model-v1.md` (structural translation) → **commit**
+>    - Ask Constructor to write `designs/design-v1.md` (technical implementation plan) → **commit**
+> 2. **WAIT FOR ALL THREE ARTIFACTS** — do NOT proceed until Planner, Architect, and Constructor have all completed their artifacts
+> 3. **Mutual review session** — ask each agent to review the other two agents' artifacts:
+>    - Ask Planner to review Model and Design → **commit each review**
+>    - Ask Architect to review Direction and Design → **commit each review**
+>    - Ask Constructor to review Direction and Model → **commit each review**
+> 4. **WAIT FOR ALL SIX REVIEWS** — do NOT proceed until all agents have completed all reviews
+> 5. If disagreements arise, the relevant agents revise their artifacts incorporating review feedback → **commit each revision**
+> 6. After revisions, repeat mutual review (step 3) until full consensus on all three artifacts → **commit each revision**
+> 7. If disagreements between two agents persist, the third agent moderates and writes resolution → **commit**
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -39,8 +39,8 @@
 ## Planning Phase

-1. Write Direction artifacts in `.workaholic/.trips/<trip-name>/directions/`
-2. Review Model artifacts from Architect and Design artifacts from Constructor
-3. Moderate disagreements between Architect and Constructor when called upon
+1. Write Direction artifacts in `.workaholic/.trips/<trip-name>/directions/` concurrently with the Architect's Model and Constructor's Design, based on the user instruction and business domain expertise
+2. After all three artifacts are complete, review Model artifacts from Architect and Design artifacts from Constructor in the mutual review session
+3. Moderate disagreements between Architect and Constructor when called upon
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -47,8 +47,8 @@
 ## Planning Phase

-1. Review Direction artifacts from Planner
-2. Write Model artifacts in `.workaholic/.trips/<trip-name>/models/` (blocking prerequisite for Constructor's design)
-3. Review Design artifacts from Constructor
-4. Moderate disagreements between Planner and Constructor when called upon
+1. Write Model artifacts in `.workaholic/.trips/<trip-name>/models/` concurrently with the Planner's Direction and Constructor's Design, based on the user instruction and structural domain expertise
+2. After all three artifacts are complete, review Direction artifacts from Planner and Design artifacts from Constructor in the mutual review session
+3. Moderate disagreements between Planner and Constructor when called upon
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -41,8 +41,8 @@
 ## Planning Phase

-1. Review Direction artifacts from Planner
-2. Wait for and read Model artifacts from Architect (the model is a prerequisite for the design)
-3. Write Design artifacts in `.workaholic/.trips/<trip-name>/designs/` derived from BOTH the approved Direction AND the completed Model
-4. Moderate disagreements between Planner and Architect when called upon
+1. Write Design artifacts in `.workaholic/.trips/<trip-name>/designs/` concurrently with the Planner's Direction and Architect's Model, based on the user instruction and technical domain expertise
+2. After all three artifacts are complete, review Direction artifacts from Planner and Model artifacts from Architect in the mutual review session
+3. Moderate disagreements between Planner and Architect when called upon
```

## Considerations

- The Artifact Dependencies section (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 58-69) currently declares `Direction -> Model -> Design` as a strict ordering with the philosophical justification that "Direction feeds into both Model and Design" and "Model feeds into Design." This sequential dependency was established by the enforce-model-before-design ticket (`20260310221350`) as a deliberate design choice. Removing it is a significant workflow change that inverts the previous decision. The justification for concurrent generation is that each agent's domain perspective (business vision, structural bridge, technical accountability) is sufficiently self-contained to produce a meaningful first draft from the user instruction alone, with the mutual review session serving as the alignment mechanism instead of sequential input chaining.
- The mutual review session produces six review files per round (each of three agents reviews two artifacts). This is more review volume than the current sequential approach, which produces reviews incrementally across three separate generation-review cycles. The total review work is comparable, but it is compressed into a single concentrated round. The GATE requiring all six reviews to complete before proceeding prevents partial advancement. (`plugins/trippin/skills/trip-protocol/SKILL.md` Planning Phase section)
- Without the sequential dependency chain, the Architect's Model is no longer derived from the approved Direction, and the Constructor's Design is no longer derived from the approved Model. Instead, all three artifacts are independently authored and then aligned through review. This means the first-draft artifacts may have more divergence than in the sequential approach, requiring more revision iterations to converge. The trade-off is faster initial generation (parallel) versus potentially more revision rounds (alignment cost). (`plugins/trippin/skills/trip-protocol/SKILL.md` Artifact Dependencies section)
- The Planner business focus enforcement ticket (`20260311215505`) adds behavioral guardrails preventing the Planner from exploring the codebase during the Planning Phase. This is complementary: the Planner still writes a business-focused Direction artifact, just concurrently with the other agents. Both tickets should be implemented together for the intended workflow. (`.workaholic/tickets/todo/20260311215505-enforce-planner-business-focus-in-planning-phase.md`)
- The Coding Phase concurrency ticket (`20260311215034`) applies the same concurrency pattern to the Coding Phase. If both are implemented, both phases use concurrent-then-converge patterns, creating a consistent workflow structure. The two tickets are independent and can be implemented in either order. (`.workaholic/tickets/todo/20260311215034-concurrent-coding-phase-agents.md`)
- The Phase Gate Policy (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 27-36) states the leader waits for ALL concurrent tasks to complete before issuing the next round. This policy already supports concurrent dispatch by the leader -- it was designed to prevent agents from autonomously advancing, not to prevent intentional parallel work assignment. The concurrent generation step is consistent with the policy because the leader explicitly dispatches all three agents and waits at the GATE.
- The Moderation Protocol (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 361-376) still applies during the Convergence step. If two agents disagree about artifact alignment, the third agent moderates. The moderation trigger may be more common in the concurrent model because artifacts are independently authored and may have conflicting assumptions that the sequential model would have resolved through input chaining.
- The commit-per-step rule (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 122-170) remains unchanged. Each artifact generation produces a commit, each review produces a commit, and each revision produces a commit. The concurrent model does not change the commit granularity -- it changes when the commits happen (three generation commits in parallel instead of sequentially).
- The revision cycle workflow changes: currently, if a Direction is revised, the Architect must regenerate the Model, and then the Constructor must regenerate the Design (cascading sequential revision). In the concurrent model, only the artifact that received revision requests needs to be updated by its author, and then a new mutual review round determines if the other artifacts also need revision. This is more efficient for localized changes but could lead to more iteration rounds if changes in one artifact cascade to the others through review. (`plugins/trippin/skills/trip-protocol/SKILL.md` Artifact Dependencies section)
