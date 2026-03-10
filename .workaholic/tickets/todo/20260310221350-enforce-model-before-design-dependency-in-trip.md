---
created_at: 2026-03-10T22:13:50+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Enforce Model-before-Design Dependency in Trip Workflow

## Overview

Fix a workflow ordering bug in the Trippin plugin where the Constructor begins generating its design artifact concurrently with the Architect's model artifact after a direction is approved (or re-approved following revision). The Constructor's design should be derived from the Architect's model, not just from the direction alone. The current workflow treats model and design generation as concurrent (Step 2 in Phase 1), but the design has a data dependency on the model: the Constructor needs to read the completed model to produce a structurally aligned design. A stricter sequential flow is required: Architect writes model first, then Constructor writes design after reading the model.

## Key Files

- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining Phase 1 Step 2 as concurrent model and design generation; needs to be made sequential with model preceding design
- `plugins/trippin/commands/trip.md` - Trip command orchestration; the Agent Teams instruction block lists model and design generation as sequential steps 6-7 but the protocol skill and agent definitions do not enforce this ordering
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; Phase 1 responsibilities list "Review Model artifacts from Architect" before "Write Design artifacts" but do not state that the model must exist before design generation begins
- `plugins/trippin/agents/architect.md` - Architect agent definition; no mention that its model output is a prerequisite for the Constructor's design

## Related History

The trip command was recently implemented with the three-agent Implosive Structure workflow. A sibling ticket already addresses general phase gate synchronization (agents should not autonomously advance after completing reviews), and another addresses deterministic review file conventions. This ticket addresses a more specific dependency: the Constructor's design artifact has a data dependency on the Architect's model artifact, making truly concurrent generation incorrect even with proper synchronization gates.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command, agents, and protocol (direct predecessor)
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/todo/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Sibling ticket for general phase gate synchronization; proposes concurrent model and design with a gate after both complete, which this ticket supersedes with a stricter sequential requirement
- [20260310220221-deterministic-artifact-review-convention.md](.workaholic/tickets/todo/20260310220221-deterministic-artifact-review-convention.md) - Sibling ticket for review file conventions (related workflow area)

## Implementation Steps

1. **Rewrite Phase 1 Step 2 in trip-protocol to enforce sequential ordering** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Change Step 2 from concurrent to sequential. Split into Step 2a (Architect writes model) and Step 2b (Constructor writes design after reading the model). Add a GATE between them: the leader must confirm the model is complete before requesting the design from the Constructor.

2. **Update the Agent Teams instruction block in trip.md** (`plugins/trippin/commands/trip.md`): Rewrite Phase 1 steps 6-7 (lines 71-72) to make the dependency explicit. After step 6 (Architect writes model), add a synchronization point where the leader confirms the model is committed and complete. Only then does step 7 (Constructor writes design) begin. Add an explicit instruction that the Constructor must READ the completed model before writing the design.

3. **Update the Constructor agent definition** (`plugins/trippin/agents/constructor.md`): In the Phase 1 section, make the model dependency explicit. Change from listing "Review Model" and "Write Design" as separate responsibilities to stating: "Read the approved Model from Architect, then write Design artifacts derived from both the approved Direction and the approved Model." This makes the input dependency clear.

4. **Update the Architect agent definition** (`plugins/trippin/agents/architect.md`): Add a note in the Phase 1 section that the Architect's model is a blocking prerequisite for the Constructor's design. This reinforces that the Architect should prioritize model completion.

5. **Add an Artifact Dependency section to trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Document the data flow between artifacts explicitly:
   - Direction (Planner) feeds into Model (Architect) and Design (Constructor)
   - Model (Architect) feeds into Design (Constructor)
   - This creates a strict ordering: Direction -> Model -> Design
   - Cross-reviews happen after both Model and Design exist

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -98,11 +98,19 @@
 ### Step 2: Model and Design

-Once Direction is agreed:
-1. **Architect** writes `models/model-v1.md` derived from the approved Direction
-2. **Constructor** writes `designs/design-v1.md` derived from the approved Direction
-3. Each agent reviews the other's artifact
-4. **Planner** reviews both for alignment with the Direction
-5. Revisions continue until all three artifacts are mutually consistent
+Once Direction is approved by all three agents:
+
+**Step 2a: Model**
+1. **Architect** writes `models/model-v1.md` derived from the approved Direction
+2. **GATE**: Leader confirms model is committed and complete
+
+**Step 2b: Design**
+3. **Constructor** reads the completed Model, then writes `designs/design-v1.md` derived from both the approved Direction AND the approved Model
+4. **GATE**: Leader confirms design is committed and complete
+
+**Step 2c: Cross-Review**
+5. Each agent reviews the other's artifact (Architect reviews design, Constructor reviews model)
+6. **Planner** reviews both for alignment with the Direction
+7. Revisions continue until all three artifacts are mutually consistent
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -65,9 +65,11 @@
 > **Phase 1 - Specification (Inner Loop)**:
 > 1. Ask Planner to write `directions/direction-v1.md` based on the user instruction → **commit**
 > 2. Ask Architect to review the direction and add review notes → **commit**
 > 3. Ask Constructor to review the direction and add review notes → **commit**
 > 4. If disagreements arise, the third agent moderates and writes resolution → **commit**
 > 5. Iterate revisions until all three approve the direction → **commit each revision**
-> 6. Ask Architect to write `models/model-v1.md` → **commit**
-> 7. Ask Constructor to write `designs/design-v1.md` → **commit**
+> 6. Ask Architect to write `models/model-v1.md` → **commit** → WAIT for completion
+> 7. After the model is complete, ask Constructor to READ the model, then write `designs/design-v1.md` based on both the direction AND the model → **commit** → WAIT for completion
 > 8. Each agent reviews the other's artifacts → **commit each review**
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -27,8 +27,8 @@
 ## Phase 1: Specification

 1. Review Direction artifacts from Planner
-2. Review Model artifacts from Architect
-3. Write Design artifacts in `.workaholic/.trips/<trip-name>/designs/`
+2. Wait for and read Model artifacts from Architect (the model is a prerequisite for the design)
+3. Write Design artifacts in `.workaholic/.trips/<trip-name>/designs/` derived from BOTH the approved Direction AND the completed Model
 4. Moderate disagreements between Planner and Architect when called upon
```

## Considerations

- The sibling phase-gate synchronization ticket (`20260310221131-enforce-phase-gate-synchronization-in-trip.md`) proposes concurrent model and design generation with a gate after both complete. This ticket supersedes that portion of the phase-gate ticket by requiring sequential generation. The two tickets should be coordinated: the phase-gate ticket's general synchronization rules (agents stop after each task, leader advances workflow) are still needed, but its Step 2 patch should adopt sequential ordering instead of concurrent. (`.workaholic/tickets/todo/20260310221131-enforce-phase-gate-synchronization-in-trip.md`)
- The dependency Direction -> Model -> Design mirrors the philosophical structure: Extrinsic Idealism (vision) feeds Structural Idealism (form) feeds Intrinsic Idealism (substance). Making this data flow explicit in the protocol reinforces the Implosive Structure's design intent. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- After direction revisions (regeneration), the same sequential ordering must apply: if a direction is revised and re-approved, the Architect must regenerate the model first, and only then does the Constructor regenerate the design. The protocol must state this explicitly for revision cycles, not just initial generation. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 85-106)
- Agent Teams agents operate in separate context windows. Even with explicit ordering instructions, an agent may not see the model if it was written after the agent's context was initialized. The leader must explicitly tell the Constructor the path to the completed model file so it can read it. (`plugins/trippin/commands/trip.md`)
- Phase 2 has a similar implicit dependency: the Constructor implements based on both Model and Design. Since it authored the Design, this is less risky, but the test plan (Planner) should also reference the Model. Consider whether Phase 2 needs similar explicit dependency documentation. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 114-140)
