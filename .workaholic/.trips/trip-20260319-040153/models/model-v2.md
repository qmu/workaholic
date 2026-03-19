# Model v2

**Author**: Architect
**Status**: under-review
**Reviewed-by**: Planner, Constructor

## Content

### 1. System Coherence: Mapping Business Demands to Structural Changes

The four demands are not independent. They form an interlocking system where efficiency changes enable better records, symmetry enables autonomous operation, and records enable post-hoc traceability. This model maps each demand to the structural units it affects and identifies the dependencies between them.

#### Demand Dependency Graph

```
EFFICIENCY (D1) ───────────────────────────────────────────────┐
  reduces review file count                                    │
  changes: trip-protocol SKILL.md, trip.md, agent files        │
                                                               │
TRIP RECORDS (D2) ─────────────────────────────────────────────┤
  adds event logging across all workflow steps                 │──> These four
  changes: trip-protocol SKILL.md, trip-commit.sh,             │    converge on
           init-trip.sh, write-trip-report SKILL.md,           │    the same
           gather-artifacts.sh, trip.md                        │    component set
                                                               │
AGENT SYMMETRY (D3) ───────────────────────────────────────────┤
  restructures agent files to identical schema                 │
  changes: planner.md, architect.md, constructor.md            │
                                                               │
OVERNIGHT POLISH (D4) ─────────────────────────────────────────┘
  improves autonomous operation of all above
  changes: trip-protocol SKILL.md, trip.md, agent files
```

**Key insight**: D1 (efficiency) and D2 (records) are structurally coupled. Reducing review rounds changes the events that get logged. The consolidated review model must be designed jointly with the event log schema to ensure no traceability is lost when review rounds shrink.

#### Priority Ordering and Structural Tension

The Direction defines a specific priority ordering: D4 (Overnight Polish) first as the existential requirement, D1 (Efficiency) second, D2 (Trip Records) third, D3 (Agent Symmetry) fourth. This model acknowledges that ordering and notes the following tension.

The Direction's priority ordering is based on business impact: D4 first because autonomous operation is the product's raison d'etre. The structural dependency analysis, however, reveals that D1 and D2 are tightly coupled at the file level -- they modify the same components (trip-protocol SKILL.md, trip-commit.sh, init-trip.sh, gather-artifacts.sh) and their designs interact (the event log schema must account for the consolidated review model). Implementing D4 in isolation before D1/D2 is structurally possible but would require rework, since the convergence cap and deadlock detection mechanisms reference review rounds and event logging that have not yet been defined.

**Resolution for implementation sequencing**: The Constructor should implement D1 and D2 together as a structurally coupled unit, then layer D4's autonomous operation mechanisms on top of that foundation, and finally apply D3's schema restructuring. This deviates from the Direction's priority sequence (D4 -> D1 -> D2 -> D3) by moving to (D1+D2 -> D4 -> D3), but it respects the Direction's priority intent: D4 depends on D1+D2 being in place, so implementing them first is a prerequisite, not a demotion. The business priority of D4 is honored by treating D1+D2 as its structural foundation rather than as independent work items.

This tension should be confirmed during convergence. If the Planner considers the D4-first ordering to be a hard constraint (e.g., the convergence cap must be the very first change committed), the Constructor will need to implement D4's protocol-level rules first with placeholder references to "consolidated review" and "event log" concepts, then backfill D1+D2 and update the references. This is feasible but adds implementation friction.

### 2. Domain Model: Key Abstractions

#### 2.1 TripEvent (new abstraction for D2)

Every inter-agent interaction is a discrete event. The event log is the canonical record of the trip's collaborative process, replacing the implicit record currently embedded in git commits and plan.md progress entries.

```
TripEvent:
  timestamp   : ISO 8601 datetime
  agent       : "planner" | "architect" | "constructor" | "leader"
  target      : "planner" | "architect" | "constructor" | "all" | null
  event_type  : "artifact_created" | "review_submitted" | "revision_requested"
                | "consensus_reached" | "phase_transition" | "implementation_complete"
                | "test_passed" | "test_failed" | "rollback_proposed" | "rollback_voted"
                | "moderation_initiated" | "gate_passed"
  artifact    : file path or null
  description : human-readable summary
  impact      : description of downstream effect on other agents (see Impact Policy below)
```

##### Impact Field Policy

The "impact" field serves stakeholder traceability by answering "so what?" for every event. However, not all event authors have equal visibility into downstream effects. The policy distinguishes two authorship contexts:

- **Leader-authored events** (event types: `gate_passed`, `consensus_reached`, `phase_transition`, `moderation_initiated`): The impact field is **mandatory**. The leader has full visibility into workflow state and can provide accurate downstream impact descriptions. Example: "All three artifacts approved; proceeding to Coding Phase."

- **Agent-authored events** (event types: `artifact_created`, `review_submitted`, `revision_requested`, `implementation_complete`, `test_passed`, `test_failed`, `rollback_proposed`, `rollback_voted`): The impact field is **best-effort**. Agents express their understanding of downstream effects but are not penalized for imprecision. If an agent cannot determine the impact, the field may contain a generic statement such as "Ready for review" or be left as "-". Example: "Planner and Constructor can begin review of the model."

This distinction preserves the narrative value of the activity log for leader events (which define the process arc) without imposing unrealistic knowledge requirements on individual agents (who see only their local context).

##### Workflow Step to Event Type Mapping

To prevent divergent usage of the event_type field, the following table maps common workflow steps to their canonical event types. This is not exhaustive but covers the standard path through both phases.

| Workflow Step | event_type | Notes |
| ------------- | ---------- | ----- |
| Agent writes initial artifact (direction-v1, model-v1, design-v1) | `artifact_created` | |
| Agent writes revised artifact (direction-v2, model-v2, etc.) | `artifact_created` | Same type; version is in the artifact field |
| Agent writes consolidated review (round-N-agent.md) | `review_submitted` | |
| Leader confirms all reviews received | `gate_passed` | |
| Author revises artifact after review feedback | `revision_requested` | Logged when the leader requests the revision, not when the author starts |
| All three agents approve all three artifacts | `consensus_reached` | |
| Leader transitions from Planning to Coding | `phase_transition` | |
| Constructor reports implementation complete | `implementation_complete` | |
| Planner reports E2E tests passed | `test_passed` | |
| Planner reports E2E tests failed | `test_failed` | |
| Architect completes analytical review | `review_submitted` | Same type as planning reviews |
| Agent proposes rollback | `rollback_proposed` | |
| Agent votes on rollback proposal | `rollback_voted` | |
| Leader invokes moderation between two agents | `moderation_initiated` | |
| Leader transitions to complete | `phase_transition` | |

**Storage**: A single append-only file `event-log.md` in the trip directory, formatted as a markdown table. Each row is one event. This file is machine-parseable (pipe-delimited table) and human-readable.

**Location**: `.workaholic/.trips/<trip-name>/event-log.md`

**Writer**: The `trip-commit.sh` script appends a row to the event log on every commit. This is the single point of truth -- agents do not manually write to the log. The commit script already knows the agent, phase, step, and description; it needs only the additional fields (target, event_type, impact) passed as optional parameters.

#### 2.2 Agent Schema (canonical structure for D3)

All three agent files must follow an identical section schema. The current files are asymmetric in section ordering, depth of description, and which concerns they address. The canonical schema:

```
Agent File Schema:
  Frontmatter:
    name, description, tools, model, color, skills
  H1: Agent Name
  H2: Role
    - One paragraph defining the agent's perspective
  H2: Domain
    - Domain protection statement
    - 4 diagnostic questions (bulleted)
  H2: Review Policy
    - How this agent reviews others' work
  H2: Responsibilities
    - 3 named responsibilities with one-line descriptions
  H2: Planning Phase
    - Numbered list: 3 items (write, review, moderate)
  H2: Coding Phase
    - QA role declaration (bold)
    - Numbered list: 4 items (concurrent task, post-implementation task, rollback trigger, rollback vote)
  H2: Rules
    - Commit rule with script invocation
    - Progress tracking rule
    - Review output rule
    - Event logging rule
    - Synchronization rule
    - Protocol reference
```

**Current state**: All three agents already follow this schema approximately, but with inconsistencies:
- Planner has extra constraints ("Direction artifacts must NOT contain...") that the others lack equivalent constraints for
- Constructor has an extra skill reference (system-safety) that is asymmetric
- Section ordering is already consistent; the gap is in content depth and constraint specificity
- No agent currently has an event logging rule

**Proposed resolution**: Each agent's Planning Phase section gains a "must contain" and "must NOT contain" constraint pair, specific to their artifact type. The Constructor's system-safety reference stays (it is a genuine asymmetry in responsibility, not a schema problem). The schema enforces identical structure; content asymmetry reflecting genuine role differences is correct. A new "Event logging" rule is added to the Rules section of all three agents, instructing them to include event_type and impact parameters in their trip-commit.sh invocations.

#### 2.3 ReviewRound (restructured abstraction for D1)

The current model produces 6 review files per mutual review round (each of 3 agents reviews 2 artifacts). This is the primary efficiency bottleneck.

**Current structure (6 files per round)**:
```
directions/reviews/direction-v1-architect.md
directions/reviews/direction-v1-constructor.md
models/reviews/model-v1-planner.md
models/reviews/model-v1-constructor.md
designs/reviews/design-v1-planner.md
designs/reviews/design-v1-constructor.md
```

**Proposed structure (3 files per round)**:
Each agent writes a single consolidated review covering both artifacts they review:

```
reviews/round-N-planner.md     (reviews Model + Design together)
reviews/round-N-architect.md   (reviews Direction + Design together)
reviews/round-N-constructor.md (reviews Direction + Model together)
```

**Structural trade-off**: The current per-artifact review model provides precise traceability (each review maps to exactly one artifact). The consolidated model trades per-artifact precision for cross-artifact coherence (an agent can express how Direction and Design interact, not just assess each in isolation). This is actually a structural improvement: the most valuable review insights come from cross-artifact tension, not single-artifact critique.

**New storage layout**:
```
.workaholic/.trips/<trip-name>/
  directions/           # Planner's artifacts (unchanged)
  models/               # Architect's artifacts (unchanged)
  designs/              # Constructor's artifacts (unchanged)
  reviews/              # Consolidated reviews (NEW - replaces per-artifact reviews/)
    round-1-planner.md
    round-1-architect.md
    round-1-constructor.md
    round-2-planner.md   (if revision needed)
    ...
  rollbacks/            # Rollback proposals (unchanged)
    reviews/            # Votes on rollbacks (unchanged)
  event-log.md          # Event log (NEW)
```

**Impact on review subdirectories**: The `reviews/` subdirectory inside each artifact directory (`directions/reviews/`, `models/reviews/`, `designs/reviews/`) becomes unused. These directories can be removed from `init-trip.sh` and the protocol SKILL.md. A single top-level `reviews/` directory replaces them.

#### 2.4 EventLog (PR-facing artifact for D2)

The `event-log.md` is the source-of-truth inside the trip directory. For PR presentation, the write-trip-report skill extracts this log and formats it as the "Trip Activity Log" table in the PR body.

**Table format in PR**:
```markdown
## Trip Activity Log

| When | Who | What | Impact |
| ---- | --- | ---- | ------ |
| 2026-03-19T04:05:00+00:00 | Planner | Created direction-v1.md | Architect and Constructor can begin review |
| 2026-03-19T04:05:30+00:00 | Architect | Created model-v1.md | Planner and Constructor can begin review |
| ... | ... | ... | ... |
```

### 3. Translation Fidelity: Business Intent to Component Boundaries

This section maps each business intent to the specific files that must change and explains how the structural change faithfully represents the business demand.

#### 3.1 Efficiency --> Consolidated Review Model

**Business intent**: Reduce redundant review rounds. Fewer cycles, more substantive feedback.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `trip-protocol/SKILL.md` | Replace "Mutual Review Session" (6 files) with "Consolidated Review Round" (3 files). Update Artifact Storage diagram. Update Review File Convention. | The protocol is the canonical definition of the review process |
| `trip.md` (command) | Update Step 4 leader instructions: "WAIT FOR ALL THREE REVIEWS" instead of "WAIT FOR ALL SIX REVIEWS" | The command orchestrates the protocol |
| `init-trip.sh` | Create `reviews/` at top level instead of `directions/reviews/`, `models/reviews/`, `designs/reviews/` | Directory structure reflects the new model |
| Agent files (all 3) | Update review output rule to reference `reviews/round-N-<agent>.md` | Agents must know where to write reviews |
| `gather-artifacts.sh` | Collect reviews from top-level `reviews/` directory. **Dual-path scanning**: check both old-style per-artifact review directories (`directions/reviews/`, `models/reviews/`, `designs/reviews/`) and new-style top-level `reviews/` directory. Old-style paths are checked first for backward compatibility. Merge results from both paths into a single artifact collection. | Report generation must work for both pre-change trips (old layout) and post-change trips (new layout) |

**Fidelity check**: The business intent "fewer, more substantive reviews" is faithfully represented by reducing from 6 files to 3 files per round. Each agent still reviews both non-own artifacts, but expresses feedback holistically. The per-round numbering (`round-N`) preserves the iteration history that the per-artifact model provided through versioned filenames.

#### 3.2 Trip Records --> Event Log System

**Business intent**: Traceable event log capturing every inter-agent interaction.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `trip-protocol/SKILL.md` | Add "Trip Event Log" section defining event schema, storage, append rules, Impact Field Policy, and Workflow Step Mapping Table | Protocol is the canonical definition |
| `trip-commit.sh` | Extend to accept optional event metadata (target, event_type, impact) and append to `event-log.md` | Single point of event recording, co-located with commit |
| `init-trip.sh` | Create empty `event-log.md` with table header | Initialization must set up the log |
| `write-trip-report/SKILL.md` | Add "Trip Activity Log" section to report template | PR must include the log |
| `gather-artifacts.sh` | Include `event-log.md` in gathered output | Report skill needs access to the log |
| `trip.md` (command) | Leader instructions must include event_type and impact in commit calls | Leader orchestrates event recording |

**Fidelity check**: The business intent "When, Who, What, Impact" maps directly to the TripEvent fields (timestamp, agent, description, impact). The event log is append-only and machine-parseable, satisfying traceability. Placing the append logic in `trip-commit.sh` ensures no event is missed -- every step that produces a commit also produces a log entry. The Impact Field Policy (mandatory for leader, best-effort for agents) ensures the log narrative is reliable where it matters most (process arc events) without burdening individual agents.

#### 3.3 Agent Symmetry --> Canonical Schema Enforcement

**Business intent**: Identical schema, different content. Same structure, different opinions.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `planner.md` | Rewrite to match canonical Agent Schema. Add "must NOT contain" constraint for Model/Design concerns. Add "Event logging" rule. | Schema conformance |
| `architect.md` | Rewrite to match canonical Agent Schema. Add "must contain"/"must NOT contain" for Direction/Design boundaries. Add "Event logging" rule. | Schema conformance |
| `constructor.md` | Rewrite to match canonical Agent Schema. Add "must contain"/"must NOT contain" for Direction/Model boundaries. Add "Event logging" rule. | Schema conformance |

**Fidelity check**: "Same sections, different content" is structurally simple -- the schema is the invariant, the content is the variant. The key design decision is that genuine asymmetries (Constructor's system-safety dependency, Planner's codebase prohibition) must be expressed within the schema, not as schema deviations. Each agent's "must NOT contain" constraint pair captures what the agent is explicitly forbidden from doing, which is the structural counterpart to "different opinions." The new "Event logging" rule in every agent's Rules section ensures all agents participate in event recording uniformly.

#### 3.4 Overnight Polish --> Autonomous Operation Improvements

**Business intent**: Run unattended, produce excellent results by morning.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `trip-protocol/SKILL.md` | Add "Autonomous Operation" section: convergence heuristics (max 3 review rounds before forced convergence), deadlock detection (same concerns raised twice without resolution triggers moderation), progress checkpoints | Overnight runs cannot prompt for human input |
| `trip.md` (command) | Add convergence limits to leader instructions: "If round 3 reviews still show disagreement, invoke moderation automatically" | Leader must enforce limits |
| `trip-protocol/SKILL.md` | Add "Quality Expectations" section: minimum quality standards expressed as agent instructions and a post-hoc verification checklist the leader runs after receiving artifacts (see Quality Expectations Policy below) | Prevent degenerate artifacts in unsupervised mode |
| Agent files (all 3) | Add "Autonomous Behavior" subsection under Rules: what to do when uncertain (prefer conservative choice, log reasoning to event log, do not block) | Agents need explicit guidance for unsupervised operation |

##### Quality Expectations Policy

Quality guardrails for overnight operation are expressed as textual policy, not runtime enforcement. The architecture has no validation layer between an agent writing a file and the commit happening -- agents are Claude Code subagents executing markdown instructions, and `trip-commit.sh` cannot programmatically reject content.

The quality mechanism operates at two levels:

1. **Agent instructions** (preventive): Each agent's markdown file includes minimum quality expectations in its Rules section. Examples: "Reviews must identify at least one concern or trade-off," "Artifacts must include all sections defined in the canonical schema," "Review substance must go beyond surface-level approval." These instructions set expectations that the agent follows during generation.

2. **Leader post-hoc checklist** (detective): After receiving artifacts or reviews, the leader applies a verification checklist before advancing to the next gate. The checklist includes: (a) artifact contains all required sections, (b) review identifies at least one substantive concern, (c) revision addresses feedback from the previous round. If the checklist fails, the leader requests revision with specific deficiencies identified. This is a manual (leader-driven) check, not an automated script.

This design is honest about what the architecture can enforce. It avoids promising automated rejection that cannot be delivered while still providing meaningful quality assurance through the combination of good instructions and diligent gate-keeping.

##### Forced Convergence Behavior

When the revision cap (3 review rounds) is reached without full consensus, the following forced convergence procedure applies:

1. **Mandatory moderation**: The leader identifies the unresolved disagreement(s) and invokes the Moderation Protocol. The third agent (the one not party to the disagreement) serves as moderator per the existing Moderation Protocol rules.

2. **Moderator resolution**: The moderator reads both positions, evaluates against the dual objectives, and writes the next version of the contested artifact as a resolution. This resolution is not subject to another review round -- it is the final version for the purposes of this planning cycle.

3. **Plan Amendment entry**: The leader appends an entry to the Plan Amendments section of `plan.md` documenting: (a) which artifacts could not reach natural consensus, (b) which agent moderated, (c) what the resolution was, and (d) that forced convergence was invoked. This provides traceability for the exceptional path.

4. **Event log entry**: A `moderation_initiated` event is logged, followed by an `artifact_created` event for the moderator's resolution, followed by a `consensus_reached` event with a description noting it was reached through forced convergence.

5. **Proceed to Coding Phase**: After forced convergence, the team proceeds as if normal consensus had been reached. If the specification proves inadequate during implementation, the Rollback Protocol remains available.

**Fidelity check**: "Autonomous overnight operation" is a constraint-satisfaction problem (the system must not deadlock, must not degenerate, must eventually converge). The structural response is convergence bounds, deadlock detection, quality expectations, and forced convergence procedure. These are the structural mechanisms that translate "works overnight" into enforceable protocol rules. The quality mechanism is a two-level policy (preventive instructions + detective checklist) rather than a runtime enforcement layer, which accurately reflects the architecture's capabilities.

### 4. Boundary Integrity: Change Classification

#### 4.1 Files That Change

| File | Demands Served | Change Magnitude |
| ---- | -------------- | ---------------- |
| `plugins/trippin/skills/trip-protocol/SKILL.md` | D1, D2, D4 | Major: new sections, restructured review model, event log schema, autonomous operation rules |
| `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` | D2 | Moderate: extend to append event log entries |
| `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` | D1, D2 | Moderate: new directory layout, initialize event log |
| `plugins/trippin/commands/trip.md` | D1, D2, D4 | Moderate: updated leader instructions for consolidated reviews, event logging, convergence limits, forced convergence procedure |
| `plugins/trippin/agents/planner.md` | D1, D3, D4 | Moderate: schema conformance, review path update, event logging rule, autonomous behavior |
| `plugins/trippin/agents/architect.md` | D1, D3, D4 | Moderate: schema conformance, review path update, event logging rule, autonomous behavior |
| `plugins/trippin/agents/constructor.md` | D1, D3, D4 | Moderate: schema conformance, review path update, event logging rule, autonomous behavior |
| `plugins/trippin/skills/write-trip-report/SKILL.md` | D2 | Moderate: add activity log section to report template |
| `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` | D1, D2 | Moderate: dual-path scanning for old and new review locations, include event log |

#### 4.2 Files That Stay Unchanged

| File | Reason |
| ---- | ------ |
| `plugins/trippin/skills/ship/SKILL.md` | Ship workflow is downstream of trip; unaffected by planning/coding protocol changes |
| `plugins/trippin/skills/ship/sh/*.sh` | No interaction with review model or event log |
| `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` | Worktree creation is orthogonal to review/logging changes |
| `plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh` | Worktree listing is orthogonal |
| `plugins/trippin/skills/trip-protocol/sh/cleanup-worktree.sh` | Cleanup is orthogonal |
| `plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh` | Dev environment validation is orthogonal |
| `plugins/trippin/skills/trip-protocol/sh/read-plan.sh` | Plan reading is orthogonal (plan.md schema does not change) |
| `plugins/trippin/.claude-plugin/` | Plugin configuration is unchanged |

#### 4.3 New Components

| Component | Type | Purpose |
| --------- | ---- | ------- |
| `event-log.md` (runtime artifact) | File template | Append-only event log, created by init-trip.sh per trip |
| Top-level `reviews/` (runtime artifact) | Directory | Replaces per-artifact review subdirectories |

No new skill scripts are needed. The `trip-commit.sh` extension handles event logging. No new skills or commands are introduced.

### 5. Component Taxonomy: Demand-to-File Matrix

```
                    trip-     trip-      init-    trip.md   planner  architect  constructor  write-trip  gather-
                    protocol  commit.sh  trip.sh  (cmd)     .md      .md        .md          report      artifacts.sh
                    SKILL.md
D1 EFFICIENCY       X                    X        X         X        X          X                        X
D2 TRIP RECORDS     X         X          X        X                                          X           X
D3 AGENT SYMMETRY                                           X        X          X
D4 OVERNIGHT        X                             X         X        X          X
```

### 6. Risk Assessment

#### 6.1 Consolidated Reviews May Lose Granularity

**Risk**: Moving from per-artifact reviews to consolidated reviews could make it harder to trace which feedback applies to which artifact during revision.

**Mitigation**: The consolidated review file format must include explicit sub-sections per artifact (e.g., "### On Direction v1" and "### On Design v1" within the same file). This preserves per-artifact traceability within the consolidated structure.

#### 6.2 Event Log Bloat

**Risk**: Long-running trips with many iterations could produce very large event logs that clutter the PR.

**Mitigation**: The write-trip-report skill should include a summarization heuristic: if the event log exceeds 30 rows, include a collapsed `<details>` block for the full log and show only phase-transition events in the main table.

#### 6.3 trip-commit.sh Backward Compatibility

**Risk**: Extending trip-commit.sh with new optional parameters could break existing invocations.

**Mitigation**: New parameters must be strictly optional with sensible defaults. If no event metadata is provided, the script appends a generic event row derived from the existing parameters (agent, phase, step, description). Existing callers continue to work unchanged.

#### 6.4 Schema Enforcement Without Tooling

**Risk**: Agent file schema conformance is a one-time refactor, but drift can reoccur on future edits.

**Mitigation**: The canonical schema is documented in trip-protocol SKILL.md as a normative reference. Future agent file edits can be validated by comparing section headings against the schema. No automated tooling is proposed (this is a documentation/configuration project, not a compiled codebase).

#### 6.5 gather-artifacts.sh Backward Compatibility for Review Directory Migration

**Risk**: Existing completed trips use per-artifact review directories (`directions/reviews/`, `models/reviews/`, `designs/reviews/`). New trips use the top-level `reviews/` directory. If `gather-artifacts.sh` only scans the new location, PR generation for resumed or old trips will silently omit review artifacts.

**Mitigation**: `gather-artifacts.sh` must implement dual-path scanning. The script checks old-style per-artifact review directories first, then checks the new-style top-level `reviews/` directory. Results from both paths are merged. This ensures the report skill works correctly for trips created before and after this change. The dual-path logic should be documented inline in the script so future maintainers understand why both paths are scanned.

#### 6.6 Event Type Divergence Across Callers

**Risk**: Without a canonical mapping from workflow steps to event_type values, different callers (leader instructions, agent behavior) may use different event types for equivalent actions, degrading log consistency.

**Mitigation**: The Workflow Step to Event Type Mapping table (Section 2.1) provides a normative reference. The leader's instructions in `trip.md` should reference this table. Agent instructions should include the event_type to use for their standard actions (e.g., "When creating an artifact, use event_type `artifact_created`").

## Review Notes

v2 incorporates feedback from Planner and Constructor reviews of v1:

- **Planner Concern 1 (Priority Ordering)**: Added Section 1 "Priority Ordering and Structural Tension" acknowledging the Direction's priority sequence and explicitly surfacing the tension between structural dependencies and business priorities, with a proposed resolution for implementation sequencing.

- **Planner Concern 2 (Impact Field)**: Added "Impact Field Policy" in Section 2.1 distinguishing mandatory (leader-authored) vs best-effort (agent-authored) impact entries, with specific event type classification.

- **Constructor Concern 1 (Backward Compatibility)**: Added explicit dual-path scanning requirement to the gather-artifacts.sh entry in Section 3.1 and a dedicated risk entry (6.5) specifying that old-style and new-style review directories must both be scanned with merged results.

- **Constructor Concern 2 (Event Type Mapping)**: Added "Workflow Step to Event Type Mapping" table in Section 2.1 mapping common workflow steps to their canonical event_type values, with a dedicated risk entry (6.6).

- **Constructor Concern 3 (Event Log Naming)**: Adopted `event-log.md` as the file name (replacing `activity-log.md`). The PR display label remains "Trip Activity Log" per Direction terminology.

- **Constructor Concern 4 (Quality Guardrails)**: Replaced runtime enforcement framing with "Quality Expectations Policy" in Section 3.4, expressing guardrails as two-level textual policy (preventive agent instructions + detective leader checklist) with post-hoc verification, not automated rejection.

- **Cross-Artifact Naming Convergence**: Standardized on `event-log.md` throughout all references.

- **Agent Schema Update**: Added "Event logging" rule to the Canonical Agent Schema (Section 2.2).

- **Forced Convergence Specification**: Added explicit "Forced Convergence Behavior" subsection in Section 3.4 specifying what happens at revision cap: mandatory moderation, moderator resolution as final version, Plan Amendment entry for traceability, and event log recording.
