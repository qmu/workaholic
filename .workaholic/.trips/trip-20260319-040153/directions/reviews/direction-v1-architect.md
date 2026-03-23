# Review of Direction v1

**Reviewer**: Architect
**Artifact**: directions/direction-v1.md
**Decision**: Approve with observations

## Structural Perspective

The Direction provides a clear, well-prioritized business vision that translates faithfully into the structural abstractions defined in Model v1. Each of the four demands maps cleanly to identifiable structural changes: Efficiency maps to the ReviewRound abstraction, Trip Records maps to TripEvent/ActivityLog, Agent Symmetry maps to the Agent Schema, and Overnight Polish maps to convergence bounds and guardrails. Stakeholders can trace their requirements through the combined Direction+Model without ambiguity.

The prioritization rationale (Overnight Polish first, then Efficiency, then Trip Records, then Agent Symmetry) is structurally sound. Overnight Polish is indeed a cross-cutting concern that constrains the design of all other demands. Efficiency must precede Trip Records because the consolidated review model changes the event taxonomy. Agent Symmetry being last is correct because the final agent schema depends on what new rules (event logging, error recovery, autonomous behavior) are introduced by the other demands.

## Concerns

### 1. Consolidated Review Feedback Routing Is Not Addressed

The Direction calls for "at most three focused review documents (one per agent)" per round, reducing from six to three. This is a clear structural improvement. However, the Direction does not address the downstream question: when an author receives a consolidated review covering two artifacts simultaneously, how do they identify which feedback applies to their artifact versus the other? The current per-artifact model provides implicit routing -- feedback in `direction-v1-architect.md` is obviously for the Planner. The consolidated model loses this clarity.

**Proposal**: The Direction should acknowledge that consolidated reviews require explicit internal structure to preserve feedback routing. A brief addition to the "What success looks like" section for Demand 1 could state: "Each consolidated review contains clearly labeled sub-sections per artifact so that artifact authors can extract feedback relevant to their work without parsing the entire document." This keeps it at the business-outcome level (legibility, actionability) without prescribing technical structure.

### 2. Event Log Completeness Versus PR Readability Tension

The Direction envisions a Trip Activity Log table with "When, Who, What, and Impact" that allows stakeholders to "understand the collaborative process without opening a single artifact file." For short trips this works well. For multi-iteration trips (which the overnight polish demand aims to support), the activity log could grow to 50-100 rows, making the PR body unwieldy. The Direction does not acknowledge this tension between completeness (every event logged) and readability (PR should be scannable).

**Proposal**: The Direction could add a brief qualification under Demand 2: "For longer trips, the activity log in the PR should surface phase-transition events prominently while preserving the full log in an expandable section. The goal is a scannable narrative, not an exhaustive table." This aligns the business expectation with the reality that autonomous overnight runs produce substantial event histories.

### 3. Overnight Polish Success Criteria Are Aspirational Without Measurable Bounds

The Direction states success as "a trip launched at 11 PM completes by 6 AM with zero human intervention" and "morning review takes 15 minutes, not 45." These are useful orienting statements but lack structural anchor points. The Model translates "overnight" into convergence bounds (max 3 review rounds) and deadlock detection, but the Direction does not establish what convergence bounds are acceptable from the business perspective. For instance: is it acceptable for the system to force consensus after 3 rounds even if genuine disagreement remains? Is a forced consensus better or worse than an incomplete trip with a clear "here is where we got stuck" diagnostic?

**Proposal**: The Direction should state the business preference explicitly: "A completed trip with noted disagreements is preferable to a stalled trip with unresolved process. When autonomous convergence mechanisms activate, the output should clearly mark where forced convergence occurred so the user can evaluate those decisions during morning review." This gives the Model and Design a clear business constraint to optimize against.

## Cross-Artifact Coherence

The Direction and Model are well-aligned. The four demands in the Direction map one-to-one with the four structural translation sections in the Model. The demand dependency ordering (Direction section "Business Rationale for Prioritization") matches the Model's demand dependency graph. No business requirements in the Direction are missing from the Model's structural coverage.

One minor gap: the Direction's Persona 3 (Plugin Maintainer) mentions "no structured observability into runtime agent interactions" as a pain point. The Model addresses this through the TripEvent abstraction, but the Model does not explicitly connect the activity log to the maintainer persona's debugging use case. This is a traceability gap -- a maintainer reading the Model would not immediately see that the activity log is also intended to serve their debugging needs, not just the solo developer's morning review needs. This is a minor observation, not a revision request.

## Summary

The Direction is a strong business vision document. Its four demands are well-defined, the risk assessment is realistic, and the prioritization logic is sound. The three concerns above are observations about completeness and precision, not structural flaws. Each has a lightweight proposal that can be incorporated if the Planner agrees they add clarity without bloating the document.
