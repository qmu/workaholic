# Model v1 Review

**Reviewer**: Constructor
**Artifact**: Model v1
**Decision**: Approve with minor suggestions

## Implementability Assessment

The Model provides a clean structural translation from the four business demands to concrete file changes. The Demand Dependency Graph, Component Taxonomy matrix, and Translation Fidelity tables give me exactly what I need to plan implementation order and verify coverage. The boundary integrity analysis (Section 4) correctly identifies which files change and which stay unchanged, and I agree with both lists after cross-referencing against my own Design.

The domain abstractions (TripEvent, Agent Schema, ReviewRound, ActivityLog) are well-defined and map cleanly to the file-level changes I will implement.

## Concerns

### 1. The consolidated reviews directory relocation creates a backward compatibility gap in gather-artifacts.sh that is acknowledged but underspecified

The Model proposes moving from per-artifact `reviews/` subdirectories to a single top-level `reviews/` directory (Section 2.3). This is the correct structural decision, and my Design agrees. However, the Model's description of the impact on `gather-artifacts.sh` (Section 3.1) says "Collect reviews from top-level `reviews/` directory" without specifying backward compatibility behavior for existing trips that use the old directory layout.

Looking at the current `gather-artifacts.sh` (lines 33-35), it hard-codes paths to `directions/reviews/`, `models/reviews/`, and `designs/reviews/`. Existing completed trips created before this change will have review files in those old locations. The `write-trip-report` skill calls `gather-artifacts.sh` both for new and old trips (e.g., when generating a PR for a resumed trip).

**Proposal**: The Model's File Change table for `gather-artifacts.sh` should explicitly state: "Check both old-style per-artifact review directories and new-style top-level `reviews/` directory. Merge results. Old-style paths are checked first for backward compatibility." My Design already includes this (Section "Backward Compatibility"), but the Model should reflect this constraint since it affects the structural boundary between old and new trip layouts. This is not a major revision request -- it is a clarification that strengthens the Model's translation fidelity for this specific component.

### 2. The TripEvent schema defines event_type as a union but does not specify the mapping from agent workflow steps to event types

The TripEvent abstraction (Section 2.1) defines 12 event types. The Model specifies that `trip-commit.sh` is the single writer, with event metadata passed as optional parameters. However, the mapping from "what the agent just did" to "which event_type to use" is left implicit. For example, when the Constructor writes `design-v1.md`, should the event_type be `artifact_created`? When the Constructor revises to `design-v2.md`, is that still `artifact_created` or something else?

During implementation, agents and the leader will need to select the correct event_type string for each call to the logging mechanism. If this mapping is ambiguous, different callers will use different event types for equivalent actions, degrading the log's consistency.

**Proposal**: Add a brief mapping table to Section 2.1 that connects workflow steps to event types. For example: "Artifact initial creation -> `artifact_created`; Artifact revision after review -> `artifact_created` (new version); Review submission -> `review_submitted`; Gate confirmation -> `gate_passed`." This does not need to be exhaustive -- it should cover the common cases to prevent divergent usage. Alternatively, my Design's approach of a separate `log-event.sh` script with documented usage examples achieves the same goal through example rather than specification.

### 3. The event log naming differs between Model and Design -- this needs alignment

The Model calls the event log file `activity-log.md` (Section 2.1), while my Design calls it `event-log.md`. This is a trivial naming discrepancy but it will cause implementation confusion if not resolved before coding. The PR-facing table in Section 2.4 is labeled "Trip Activity Log" which aligns with the Direction's "Trip Activity Log table" terminology.

**Proposal**: Adopt `event-log.md` as the file name (describing what it is: a log of events) and "Trip Activity Log" as the PR display label (describing what stakeholders see). The file name should be a technical identifier; the display label should be a business-facing name. This is a minor naming convention decision that should be settled during convergence rather than left for the implementation to discover as a conflict.

### 4. Quality Guardrails (Section 3.4) propose minimum artifact length and review substance checks -- these are not enforceable in this architecture

The Model proposes "minimum artifact length, required sections check, review substance check (reject reviews under N words)" as Quality Guardrails for overnight operation. In the current architecture, agents are Claude Code subagents executing markdown instructions. There is no runtime validation layer that can reject an agent's output before it is committed. The agent writes a file, calls `trip-commit.sh`, and the commit happens. There is no hook to validate content quality between writing and committing.

The only enforcement mechanism available is textual: instructions in the agent markdown files and SKILL.md that tell agents what quality bar to meet. This is already how the Critical Review Policy works -- it instructs agents to include substantive analysis, but it cannot programmatically reject shallow reviews.

**Proposal**: Reframe "Quality Guardrails" from a runtime enforcement mechanism to a textual policy with post-hoc verification. The guardrails should be expressed as: (a) agent instructions that set minimum quality expectations, and (b) a validation checklist the leader can run after receiving artifacts to flag potential quality issues. This is more honest about what the architecture can enforce and avoids promising automated rejection that cannot be delivered.

## Strengths

The Component Taxonomy matrix (Section 5) is excellent. It provides a complete cross-reference of which demands touch which files, and I used it to validate my own Design's file inventory. Both artifacts agree on the affected file set with no gaps.

The risk assessment is pragmatic. Risk 6.3 (trip-commit.sh backward compatibility) correctly identifies the most dangerous implementation detail -- extending the script's interface without breaking existing callers. The mitigation (strictly optional parameters with sensible defaults) is the right engineering approach and matches my Design.

The structural trade-off analysis in Section 2.3 (per-artifact precision vs. cross-artifact coherence) demonstrates genuine architectural reasoning rather than arbitrary restructuring. The insight that "the most valuable review insights come from cross-artifact tension" provides a structural justification that I can reference during implementation.
