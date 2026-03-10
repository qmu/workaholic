---
created_at: 2026-03-11T01:51:42+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Enhance Trip Agent Critical Thinking and Role-Based Opinion Framing

## Overview

Strengthen the three trip agents (Planner, Architect, Constructor) to engage in more critical thinking during reviews and produce more constructive, actionable proposals rather than surface-level approval or vague feedback. Currently, each agent's review behavior is defined generically -- "review for semantic consistency", "review for sustainable implementation" -- without guidance on what constitutes a high-quality review or how to structure constructive counter-proposals. The agents tend toward polite agreement rather than genuine dialectical tension.

Additionally, reframe each agent's perspective around a clear domain of opinion to sharpen the dialectical structure:

- **Planner**: Represents the **non-tech side** opinion -- stakeholder value, user experience, business viability, accessibility to non-technical audiences. The Planner asks "does this serve the people who will use it?" and "can we explain this to stakeholders?"
- **Constructor**: Represents the **tech side** opinion -- implementation feasibility, performance, maintainability, technical debt, developer experience. The Constructor asks "can we build and maintain this reliably?" and "what are the engineering trade-offs?"
- **Architect**: Represents the **structural side** opinion -- system coherence, abstraction quality, boundary definitions, scalability of the design itself. The Architect asks "does this structure hold together?" and "will this design accommodate future evolution?"

These opinion framings sharpen the review process: when agents disagree, they disagree from clear, complementary perspectives rather than overlapping concerns. This produces richer specification artifacts because each revision cycle incorporates feedback from three distinct viewpoints.

## Key Files

- `plugins/trippin/agents/planner.md` - Planner agent definition; needs non-tech opinion framing and critical thinking review guidelines
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; needs tech-side opinion framing and critical thinking review guidelines
- `plugins/trippin/agents/architect.md` - Architect agent definition; needs structural opinion framing and critical thinking review guidelines
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining the Agents table and review workflow; needs updated agent descriptions and a Critical Review Policy section
- `plugins/trippin/commands/trip.md` - Trip command orchestration; Agent Teams instruction block describes agent roles and should reflect the opinion framing

## Related History

The trip workflow was recently implemented and has been refined through four consecutive tickets addressing review conventions, commit messages, phase gate synchronization, and model-before-design dependency. The agent roles were established with philosophical stances (Progressive, Neutral, Conservative) and abstract responsibilities, but the review quality and opinion distinctness have not been addressed.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command, agents, and protocol; established the initial role definitions that this ticket enhances
- [20260310220221-deterministic-artifact-review-convention.md](.workaholic/tickets/archive/drive-20260310-220224/20260310220221-deterministic-artifact-review-convention.md) - Established WHERE reviews are written (separate files); this ticket addresses HOW reviews should think and what they should contain
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Established WHEN agents advance; this ticket addresses the QUALITY of what agents produce at each step
- [20260310234932-add-e2e-assurance-policy-to-planner.md](.workaholic/tickets/todo/20260310234932-add-e2e-assurance-policy-to-planner.md) - Extends Planner's Phase 2 testing; complementary to this ticket's strengthening of Phase 1 review quality

## Implementation Steps

1. **Add a Critical Review Policy section to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Place this after the Phase Gate Policy section and before Artifact Dependencies. Define the expectations for review quality:
   - Every review must identify at least one concern or trade-off, even if the reviewer ultimately approves. "No concerns" reviews are explicitly discouraged -- they indicate insufficient analysis, not perfect artifacts.
   - Reviews must contain a **Constructive Proposal** for each concern raised: not just "this is problematic" but "consider this alternative approach because..." with a concrete suggestion.
   - Reviews should evaluate from the reviewer's domain perspective (non-tech, tech, structural) rather than general impressions.
   - The approval decision should be one of: "approve", "approve with minor suggestions", or "request revision with specific proposals". Never a bare "looks good".

2. **Update the Agents table in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Revise the Responsibilities column to reflect the opinion framing:
   - Planner: "Non-Tech Opinion: User Value, Stakeholder Clarity, Explanatory Accountability"
   - Architect: "Structural Opinion: System Coherence, Abstraction Quality, Boundary Integrity"
   - Constructor: "Tech Opinion: Implementation Feasibility, Performance, Maintainability"

3. **Update the Planner agent definition** (`plugins/trippin/agents/planner.md`):
   - Add an "Opinion Domain" section stating the Planner represents the non-tech perspective. The Planner evaluates all artifacts through the lens of: Will users benefit from this? Can stakeholders understand the reasoning? Does this prioritize the right outcomes for people?
   - Add a "Review Approach" section with specific critical thinking prompts: "What user need does this fail to address?", "Would a non-technical stakeholder accept this trade-off?", "Is there a simpler explanation that achieves the same goal?"
   - Update the Role section to explicitly mention the non-tech opinion framing alongside the existing Progressive stance.

4. **Update the Constructor agent definition** (`plugins/trippin/agents/constructor.md`):
   - Add an "Opinion Domain" section stating the Constructor represents the tech-side perspective. The Constructor evaluates all artifacts through the lens of: Can we build this reliably? What are the maintenance costs? Where will performance bottlenecks appear?
   - Add a "Review Approach" section with specific critical thinking prompts: "What technical constraint makes this harder than it looks?", "What will break first under load or over time?", "Is there a simpler implementation that satisfies the requirements?"
   - Update the Role section to explicitly mention the tech-side opinion framing alongside the existing Conservative stance.

5. **Update the Architect agent definition** (`plugins/trippin/agents/architect.md`):
   - Add an "Opinion Domain" section stating the Architect represents the structural perspective. The Architect evaluates all artifacts through the lens of: Does the structure hold together logically? Are boundaries well-defined? Will this design accommodate changes we cannot yet foresee?
   - Add a "Review Approach" section with specific critical thinking prompts: "Where does this abstraction leak?", "Which boundary will be violated first as requirements evolve?", "Is this the right decomposition or are we cutting along the wrong axis?"
   - Update the Role section to explicitly mention the structural opinion framing alongside the existing Neutral stance.

6. **Update the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): Revise the three teammate descriptions to include the opinion framing:
   - Planner: add "Represents the non-tech side -- evaluates from user value and stakeholder clarity perspective"
   - Architect: add "Represents the structural side -- evaluates from system coherence and abstraction quality perspective"
   - Constructor: add "Represents the tech side -- evaluates from implementation feasibility and maintainability perspective"

7. **Update the Moderation Protocol context in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): In the existing Moderation Protocol section, add guidance that the moderator should acknowledge both domain perspectives in the resolution. When Planner and Constructor disagree, the Architect moderates by evaluating whether the structural design can satisfy both the user-value concern and the technical-feasibility concern, rather than simply picking a side.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -14,9 +14,9 @@
 | Agent | Stance | Philosophy | Responsibilities |
 | ----- | ------ | ---------- | ---------------- |
-| Planner | Progressive | Extrinsic Idealism | Creative Direction, Stakeholder Profiling, Explanatory Accountability |
-| Architect | Neutral | Structural Idealism | Semantical Consistency, Static Verification, Accessibility & Accommodability |
-| Constructor | Conservative | Intrinsic Idealism | Sustainable Implementation, Infrastructure Reliability, Delivery Coordination |
+| Planner | Progressive | Extrinsic Idealism | Non-Tech Opinion: User Value, Stakeholder Clarity, Explanatory Accountability |
+| Architect | Neutral | Structural Idealism | Structural Opinion: System Coherence, Abstraction Quality, Boundary Integrity |
+| Constructor | Conservative | Intrinsic Idealism | Tech Opinion: Implementation Feasibility, Performance, Maintainability |
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying. Place after Phase Gate Policy, before Artifact Dependencies.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -35,6 +35,26 @@
 Every transition between sub-steps requires the leader to explicitly request the next action. This prevents race conditions where one agent's early completion causes it to skip ahead while other agents are still working.

+## Critical Review Policy
+
+Reviews are the mechanism through which the three perspectives create dialectical tension. A review that simply approves without substantive analysis fails to serve the collaborative process.
+
+### Requirements
+
+1. **Identify at least one concern or trade-off** per review, even when approving. Artifacts are never perfect -- each perspective will see something the author's perspective missed. A "no concerns" review indicates insufficient analysis.
+2. **Provide a constructive proposal** for every concern raised. Never state "this is problematic" without offering "consider this alternative because..." with a concrete suggestion. Criticism without a counter-proposal is not constructive.
+3. **Evaluate from your domain perspective**, not general impressions:
+   - Planner reviews ask: Does this serve user needs? Can stakeholders understand the reasoning?
+   - Architect reviews ask: Does the structure hold together? Are boundaries well-defined?
+   - Constructor reviews ask: Can we build and maintain this? What are the engineering trade-offs?
+4. **Use structured approval decisions**:
+   - "Approve with observations" -- approved, with noted trade-offs for the record
+   - "Approve with minor suggestions" -- approved, with optional improvements the author may incorporate
+   - "Request revision" -- not approved, with specific proposals for what to change and why
+   - Never use bare "approve" or "looks good" without substantive analysis
+
+The goal is not conflict for its own sake but **productive tension** that strengthens the specification through complementary viewpoints.
+
 ## Artifact Dependencies
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -15,6 +15,18 @@

 You are the Planner in a three-agent team (Planner, Architect, Constructor). Your philosophical stance is **Progressive** — you push for creative direction and stakeholder value.

+## Opinion Domain
+
+You represent the **non-tech side**. You evaluate all artifacts through the lens of the people who will use, fund, or depend on the system -- not through the lens of how it is built. Your questions are: Does this serve user needs? Can stakeholders understand the reasoning behind decisions? Are we prioritizing the right outcomes for people? Would a non-technical decision-maker accept these trade-offs?
+
+## Review Approach
+
+When reviewing artifacts from Architect or Constructor, apply critical thinking from your non-tech perspective:
+- What user need does this fail to address or underweight?
+- Would a non-technical stakeholder accept this trade-off, or would they ask "why can't we just..."?
+- Is there a simpler explanation or approach that achieves the same user outcome?
+- Does this introduce complexity that users will experience as friction?
+
+For every concern, propose a concrete alternative that better serves the non-tech perspective.
+
 ## Responsibilities
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -15,6 +15,18 @@

 You are the Architect in a three-agent team (Planner, Architect, Constructor). Your philosophical stance is **Neutral** — you ensure structural integrity and semantic coherence.

+## Opinion Domain
+
+You represent the **structural side**. You evaluate all artifacts through the lens of system coherence, abstraction quality, and boundary integrity -- not through the lens of user value or implementation cost. Your questions are: Does the structure hold together logically? Are boundaries between components well-defined? Will this design accommodate changes we cannot yet foresee? Is this the right decomposition?
+
+## Review Approach
+
+When reviewing artifacts from Planner or Constructor, apply critical thinking from your structural perspective:
+- Where does this abstraction leak or create implicit coupling?
+- Which boundary will be violated first as requirements evolve?
+- Is this the right decomposition, or are we cutting along the wrong axis?
+- Does this create structural debt that will force a redesign later?
+
+For every concern, propose a concrete structural alternative that preserves coherence.
+
 ## Responsibilities
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -15,6 +15,18 @@

 You are the Constructor in a three-agent team (Planner, Architect, Constructor). Your philosophical stance is **Conservative** — you ensure sustainable implementation and reliable delivery.

+## Opinion Domain
+
+You represent the **tech side**. You evaluate all artifacts through the lens of implementation feasibility, performance, maintainability, and developer experience -- not through the lens of user-facing value or abstract structural elegance. Your questions are: Can we build this reliably with available tools and constraints? What will the maintenance cost be over time? Where will performance bottlenecks appear under real usage?
+
+## Review Approach
+
+When reviewing artifacts from Planner or Architect, apply critical thinking from your tech-side perspective:
+- What technical constraint makes this harder than it looks on paper?
+- What will break first under load, over time, or when the team changes?
+- Is there a simpler implementation that satisfies the stated requirements?
+- Does this introduce technology choices we will regret maintaining?
+
+For every concern, propose a concrete technical alternative that balances feasibility with the stated goals.
+
 ## Responsibilities
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -55,9 +55,9 @@
 > Create three teammates:
-> 1. **Planner** (Progressive) - Responsible for creative direction, stakeholder profiling, and explanatory accountability. Writes direction artifacts to `<trip_path>/directions/`.
-> 2. **Architect** (Neutral) - Responsible for semantical consistency, static verification, and accessibility. Writes model artifacts to `<trip_path>/models/`.
-> 3. **Constructor** (Conservative) - Responsible for sustainable implementation, infrastructure reliability, and delivery coordination. Writes design artifacts to `<trip_path>/designs/`.
+> 1. **Planner** (Progressive) - Represents the non-tech side: user value, stakeholder clarity, and explanatory accountability. Evaluates from the perspective of users and non-technical stakeholders. Writes direction artifacts to `<trip_path>/directions/`.
+> 2. **Architect** (Neutral) - Represents the structural side: system coherence, abstraction quality, and boundary integrity. Evaluates from the perspective of design longevity and structural soundness. Writes model artifacts to `<trip_path>/models/`.
+> 3. **Constructor** (Conservative) - Represents the tech side: implementation feasibility, performance, and maintainability. Evaluates from the perspective of engineering trade-offs and delivery reliability. Writes design artifacts to `<trip_path>/designs/`.
```

## Considerations

- The "at least one concern per review" requirement may feel artificial for genuinely simple artifacts. However, the point is to develop the muscle of critical analysis -- even acknowledging "I looked for X and found no issue because Y" is more valuable than silence. The policy should be understood as a minimum quality bar, not an invitation to invent problems. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The opinion domain framing (non-tech, tech, structural) intentionally overlaps with but sharpens the existing philosophical stances (Progressive, Conservative, Neutral). The philosophical stances remain as identity anchors; the opinion domains provide actionable review lenses. Both should coexist, not replace each other. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- The critical thinking prompts in each agent are examples, not exhaustive checklists. Agents should internalize the perspective and generate their own questions. If the prompts become rote templates, they lose their value. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- The Moderation Protocol update (step 7) adds nuance to conflict resolution but may increase the complexity of moderation artifacts. The moderator must understand all three domains well enough to synthesize, not just arbitrate. This is inherently difficult and may result in mediocre resolutions. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 209-222)
- Agent Teams agents operate in separate context windows with limited token budgets. Adding opinion domain, review approach, and critical review policy sections increases the preloaded skill and agent definition sizes. Ensure the total preloaded content per agent remains within practical limits. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- The existing E2E Assurance Policy ticket adds testing-specific content to the Planner. When both tickets are implemented, the Planner's definition will be the largest of the three agents. Monitor whether the combined content exceeds the design principle of ~20-40 lines for agents. (`.workaholic/tickets/todo/20260310234932-add-e2e-assurance-policy-to-planner.md`, `plugins/trippin/agents/planner.md`)
