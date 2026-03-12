---
created_at: 2026-03-11T21:55:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 0.25h
commit_hash: acee2a2
category: Changed
---

# Enforce Planner Business Focus in Planning Phase

## Overview

Add explicit behavioral guardrails to the Planner agent to prevent codebase discovery during the Planning Phase and redirect the Planner toward business-side analysis. The Planner's role was recently redefined as a business visionary (see redefine-trippin-agent-personality-spectrum), but the personality rewrite alone is insufficient to prevent the behavioral pattern where the Planner reads source files, explores directory structures, and performs technical analysis when writing Direction artifacts. The Planner needs explicit instructions about what it must NOT do (codebase exploration, file reading, code pattern analysis) and what it MUST do instead (business value articulation, risk assessment, stakeholder analysis, user persona definition, market positioning).

The core problem: despite being told the Planner "does NOT set technical direction," the Planner still gravitates toward codebase discovery as its first action when writing a Direction. This happens because LLM agents naturally want to "understand the system" before making recommendations, and the available tools (Glob, Grep, Read, Bash) make codebase exploration the path of least resistance. The Planner needs to be explicitly told that understanding the codebase is the Architect's job, and that the Planner's job is to articulate the business context that the Architect and Constructor will then translate into technical decisions.

The Direction artifact should contain:
1. How the project creates value (business model, value proposition)
2. What the risks are (market risk, adoption risk, dependency risk, not technical risk)
3. Who the expected users are (personas, use cases, stakeholder map)
4. What kind of software component this is in the larger system (positioning, ecosystem role)
5. Why this trip matters from a business perspective

The Direction artifact should NOT contain:
- File paths or code references
- Existing implementation analysis
- Technical architecture observations
- Codebase pattern descriptions

## Key Files

- `plugins/trippin/agents/planner.md` - Planner agent definition; needs explicit behavioral restrictions in Planning Phase section and a new "Planning Phase Focus" or similar section that defines what the Direction artifact should contain
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill; the Direction artifact description and Planning Phase Step 1 should reinforce that Direction is a business vision document, not a technical analysis
- `plugins/trippin/commands/trip.md` - Trip command; the Planner description in Agent Teams should reinforce the business-only focus and the prohibition on codebase exploration

## Related History

The Planner role has evolved through two significant iterations: first adding opinion-domain framing (non-tech perspective) and then a full personality rewrite repositioning the Planner as a business visionary. Both changes strengthened the role description but did not add explicit behavioral prohibitions against codebase discovery, which is the behavioral pattern this ticket addresses.

Past tickets that touched similar areas:

- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Rewrote the Planner as a business visionary with "Business Vision" and "Stakeholder Advocacy" responsibilities; established the framing this ticket enforces behaviorally
- [20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md](.workaholic/tickets/archive/drive-20260310-220224/20260311015142-enhance-trip-agent-critical-thinking-and-role-opinions.md) - Added Opinion Domain and Review Approach sections; introduced the non-tech perspective framing that preceded the business visionary rewrite
- [20260310234932-add-e2e-assurance-policy-to-planner.md](.workaholic/tickets/archive/drive-20260310-220224/20260310234932-add-e2e-assurance-policy-to-planner.md) - Added E2E testing to Planner's Coding Phase; demonstrates that the Planner's Coding Phase role (testing) is distinct from Planning Phase role (direction setting)
- [20260311215034-concurrent-coding-phase-agents.md](.workaholic/tickets/todo/20260311215034-concurrent-coding-phase-agents.md) - Proposes Architect doing codebase discovery during Coding Phase; reinforces that codebase discovery belongs to the Architect, not the Planner

## Implementation Steps

1. **Add a "Planning Phase Focus" section to the Planner agent** (`plugins/trippin/agents/planner.md`): Insert a new section between "Responsibilities" and "Planning Phase" that explicitly defines the Planner's behavioral boundaries. This section should contain:
   - A clear statement that the Planner must NOT use Glob, Grep, or Read to explore the codebase during the Planning Phase. Codebase discovery is the Architect's responsibility.
   - A definition of what the Direction artifact must contain: business value proposition, risk assessment (business risks, not technical risks), user personas and stakeholder analysis, positioning within the larger system or ecosystem, and the business rationale for why this trip matters.
   - A definition of what the Direction artifact must NOT contain: file paths, code references, implementation analysis, technical architecture observations, or codebase pattern descriptions.
   - The Planner may reference the user instruction and general domain knowledge but should not attempt to "understand the codebase" before writing a Direction.

2. **Update the Planner's Planning Phase section** (`plugins/trippin/agents/planner.md`): Revise item 1 to reinforce that the Direction artifact is a business vision document. Change from the current generic "writes `directions/direction-v1.md` based on the user instruction" to explicitly state that the Planner articulates the business context, stakeholder value, and risk landscape without exploring the codebase.

3. **Update the Direction artifact guidance in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): In the Planning Phase Step 1 description, add clarification that the Direction is a business vision document authored by the Planner from a non-technical perspective. The technical decomposition of the Direction happens when the Architect writes the Model. This reinforces the artifact dependency chain: Direction (business) -> Model (structural translation) -> Design (technical).

4. **Update the Planner description in the trip command** (`plugins/trippin/commands/trip.md`): In the Agent Teams instruction block, add a behavioral note to the Planner description: "Does NOT explore the codebase -- codebase discovery is the Architect's responsibility. Writes Direction artifacts based on business analysis of the user instruction."

## Patches

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -35,6 +35,25 @@
 - **Stakeholder Advocacy**: Actively represent stakeholder interests throughout the process
 - **Explanatory Accountability**: Ensure decisions are justified and traceable

+## Planning Phase Focus
+
+When writing Direction artifacts, focus exclusively on the business side:
+
+**Direction artifacts MUST contain:**
+- **Value Proposition**: How the project creates value, what business problem it solves
+- **Risk Assessment**: Market risk, adoption risk, dependency risk, competitive risk (NOT technical risk -- that is the Constructor's domain)
+- **User Personas**: Who the expected users are, their needs, their context, their pain points
+- **System Positioning**: What kind of software component this is in the larger ecosystem, how it relates to adjacent systems
+- **Business Rationale**: Why this trip matters from a stakeholder perspective
+
+**Direction artifacts must NOT contain:**
+- File paths or code references
+- Existing codebase analysis or implementation observations
+- Technical architecture descriptions
+- Code pattern analysis
+
+**Codebase discovery is the Architect's job.** Do NOT use Glob, Grep, or Read to explore source files during the Planning Phase. Base the Direction on the user instruction and domain knowledge, not on codebase exploration. The Architect will translate your business vision into structural terms in the Model.
+
 ## Planning Phase

```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -73,7 +73,7 @@
 > Create three teammates:
-> 1. **Planner** (Progressive) - Represents the business vision side: business phenomena, stakeholder advocacy, and explanatory accountability. Evaluates from the perspective of business outcomes and stakeholder value. Does NOT set technical direction. Writes direction artifacts to `<trip_path>/directions/`.
+> 1. **Planner** (Progressive) - Represents the business vision side: business phenomena, stakeholder advocacy, and explanatory accountability. Evaluates from the perspective of business outcomes and stakeholder value. Does NOT set technical direction. Does NOT explore the codebase -- codebase discovery is the Architect's responsibility. Writes Direction artifacts based on business analysis of the user instruction to `<trip_path>/directions/`.
 > 2. **Architect** (Neutral) - Represents the structural bridge between business vision and technical implementation: system coherence, translation fidelity, and boundary integrity. Evaluates whether business intent is faithfully represented in technical structure. Writes model artifacts to `<trip_path>/models/`.
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -198,7 +198,7 @@
 ### Step 1: Direction

-1. **Planner** writes `directions/direction-v1.md` based on the user instruction
+1. **Planner** writes `directions/direction-v1.md` based on the user instruction. The Direction is a business vision document: it defines the value proposition, risk landscape, user personas, and system positioning from a non-technical perspective. The Planner does NOT explore the codebase -- the technical decomposition happens when the Architect translates the Direction into the Model.
 2. **Architect** reviews and writes `directions/reviews/direction-v1-architect.md`
 3. **Constructor** reviews and writes `directions/reviews/direction-v1-constructor.md`
```

## Considerations

- The Planner agent definition currently has tools `Read, Write, Edit, Glob, Grep, Bash` in the frontmatter. Removing Glob, Grep, and Read from the Planner's tool list would be the most enforceable approach, but the Planner needs these tools during the Coding Phase for test planning and E2E test execution. The behavioral restriction must be scoped to the Planning Phase only, enforced through instructions rather than tool removal. (`plugins/trippin/agents/planner.md` line 4)
- The user instruction passed to the Planner may contain technical references (e.g., "refactor the authentication module"). The Planner should still process these references from a business perspective ("why does authentication matter to users?") rather than exploring the referenced code. The behavioral guardrail should not prevent the Planner from understanding the user's intent, only from exploring the codebase to inform the Direction. (`plugins/trippin/commands/trip.md` lines 64-70)
- The Architect's Planning Phase role is to "Review Direction artifacts from Planner" and then "Write Model artifacts." The Architect's review of the Direction is where codebase knowledge enters the workflow -- the Architect can identify if the business vision conflicts with technical reality when translating Direction into Model. This separation is already structurally supported by the artifact dependency chain (Direction -> Model -> Design). (`plugins/trippin/agents/architect.md` lines 47-50)
- The concurrent coding phase ticket (`20260311215034`) proposes having the Architect perform codebase discovery during the Coding Phase. If both tickets are implemented, the Architect becomes the sole agent responsible for codebase understanding in both phases, while the Planner remains focused on business analysis (Planning Phase) and testing (Coding Phase). This creates a clean separation. (`.workaholic/tickets/todo/20260311215034-concurrent-coding-phase-agents.md`)
- The "Direction artifacts must NOT contain file paths" rule may feel overly strict for cases where the user instruction explicitly references specific files. A softer version would be "Direction artifacts should not contain file paths discovered through codebase exploration" -- allowing the Planner to mention files that the user explicitly named. The implementation should use language that prohibits exploration-derived references, not user-provided references. (`plugins/trippin/agents/planner.md`)
- The Critical Review Policy requires reviewers to "identify at least one concern or trade-off per review." When the Architect reviews a Direction that contains no technical content, the Architect's review naturally becomes the point where technical reality enters the conversation -- the Architect translates business vision into structural implications and identifies where the vision may conflict with codebase reality. This is the intended workflow. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 39-55)

## Final Report

### Changes
- Added "Planning Phase Focus" section to `plugins/trippin/agents/planner.md` with MUST/must-NOT guardrails for Direction artifacts
- Updated Planning Phase item 1 in `plugins/trippin/agents/planner.md` to emphasize business analysis without codebase exploration
- Updated Direction step description in `plugins/trippin/skills/trip-protocol/SKILL.md` to clarify it is a business vision document
- Added "Does NOT explore the codebase" to the Planner description in `plugins/trippin/commands/trip.md`

### Test Plan
- Verify planner.md contains the new "Planning Phase Focus" section between Responsibilities and Planning Phase
- Verify trip-protocol SKILL.md Step 1 Direction description includes business vision language
- Verify trip.md Planner description includes codebase exploration prohibition
