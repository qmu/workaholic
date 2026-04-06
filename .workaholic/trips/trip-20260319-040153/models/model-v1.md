# Model v1

**Author**: Architect
**Status**: draft
**Reviewed-by**: (none)

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
  impact      : description of downstream effect on other agents
```

**Storage**: A single append-only file `activity-log.md` in the trip directory, formatted as a markdown table. Each row is one event. This file is machine-parseable (pipe-delimited table) and human-readable.

**Location**: `.workaholic/.trips/<trip-name>/activity-log.md`

**Writer**: The `trip-commit.sh` script appends a row to the activity log on every commit. This is the single point of truth -- agents do not manually write to the log. The commit script already knows the agent, phase, step, and description; it needs only the additional fields (target, event_type, impact) passed as optional parameters.

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
    - Synchronization rule
    - Protocol reference
```

**Current state**: All three agents already follow this schema approximately, but with inconsistencies:
- Planner has extra constraints ("Direction artifacts must NOT contain...") that the others lack equivalent constraints for
- Constructor has an extra skill reference (system-safety) that is asymmetric
- Section ordering is already consistent; the gap is in content depth and constraint specificity

**Proposed resolution**: Each agent's Planning Phase section gains a "must contain" and "must NOT contain" constraint pair, specific to their artifact type. The Constructor's system-safety reference stays (it is a genuine asymmetry in responsibility, not a schema problem). The schema enforces identical structure; content asymmetry reflecting genuine role differences is correct.

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
  activity-log.md       # Event log (NEW)
```

**Impact on review subdirectories**: The `reviews/` subdirectory inside each artifact directory (`directions/reviews/`, `models/reviews/`, `designs/reviews/`) becomes unused. These directories can be removed from `init-trip.sh` and the protocol SKILL.md. A single top-level `reviews/` directory replaces them.

#### 2.4 ActivityLog (PR-facing artifact for D2)

The `activity-log.md` is the source-of-truth inside the trip directory. For PR presentation, the write-trip-report skill extracts this log and formats it as the "Trip Activity Log" table in the PR body.

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
| `gather-artifacts.sh` | Collect reviews from top-level `reviews/` directory | Report generation reads from the new location |

**Fidelity check**: The business intent "fewer, more substantive reviews" is faithfully represented by reducing from 6 files to 3 files per round. Each agent still reviews both non-own artifacts, but expresses feedback holistically. The per-round numbering (`round-N`) preserves the iteration history that the per-artifact model provided through versioned filenames.

#### 3.2 Trip Records --> Event Log System

**Business intent**: Traceable event log capturing every inter-agent interaction.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `trip-protocol/SKILL.md` | Add "Trip Activity Log" section defining event schema, storage, and append rules | Protocol is the canonical definition |
| `trip-commit.sh` | Extend to accept optional event metadata (target, event_type, impact) and append to `activity-log.md` | Single point of event recording, co-located with commit |
| `init-trip.sh` | Create empty `activity-log.md` with table header | Initialization must set up the log |
| `write-trip-report/SKILL.md` | Add "Trip Activity Log" section to report template | PR must include the log |
| `gather-artifacts.sh` | Include `activity-log.md` in gathered output | Report skill needs access to the log |
| `trip.md` (command) | Leader instructions must include event_type and impact in commit calls | Leader orchestrates event recording |

**Fidelity check**: The business intent "When, Who, What, Impact" maps directly to the TripEvent fields (timestamp, agent, description, impact). The event log is append-only and machine-parseable, satisfying traceability. Placing the append logic in `trip-commit.sh` ensures no event is missed -- every step that produces a commit also produces a log entry.

#### 3.3 Agent Symmetry --> Canonical Schema Enforcement

**Business intent**: Identical schema, different content. Same structure, different opinions.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `planner.md` | Rewrite to match canonical Agent Schema. Add "must NOT contain" constraint for Model/Design concerns | Schema conformance |
| `architect.md` | Rewrite to match canonical Agent Schema. Add "must contain"/"must NOT contain" for Direction/Design boundaries | Schema conformance |
| `constructor.md` | Rewrite to match canonical Agent Schema. Add "must contain"/"must NOT contain" for Direction/Model boundaries | Schema conformance |

**Fidelity check**: "Same sections, different content" is structurally simple -- the schema is the invariant, the content is the variant. The key design decision is that genuine asymmetries (Constructor's system-safety dependency, Planner's codebase prohibition) must be expressed within the schema, not as schema deviations. Each agent's "must NOT contain" constraint pair captures what the agent is explicitly forbidden from doing, which is the structural counterpart to "different opinions."

#### 3.4 Overnight Polish --> Autonomous Operation Improvements

**Business intent**: Run unattended, produce excellent results by morning.

**Structural translation**:

| Component | Change | Rationale |
| --------- | ------ | --------- |
| `trip-protocol/SKILL.md` | Add "Autonomous Operation" section: convergence heuristics (max 3 review rounds before forced convergence), deadlock detection (same concerns raised twice without resolution triggers moderation), progress checkpoints | Overnight runs cannot prompt for human input |
| `trip.md` (command) | Add convergence limits to leader instructions: "If round 3 reviews still show disagreement, invoke moderation automatically" | Leader must enforce limits |
| `trip-protocol/SKILL.md` | Add "Quality Guardrails" section: minimum artifact length, required sections check, review substance check (reject reviews under N words) | Prevent degenerate artifacts in unsupervised mode |
| Agent files (all 3) | Add "Autonomous Behavior" subsection under Rules: what to do when uncertain (prefer conservative choice, log reasoning to activity log, do not block) | Agents need explicit guidance for unsupervised operation |

**Fidelity check**: "Autonomous overnight operation" is a constraint-satisfaction problem (the system must not deadlock, must not degenerate, must eventually converge). The structural response is convergence bounds, deadlock detection, and quality guardrails. These are the structural mechanisms that translate "works overnight" into enforceable protocol rules.

### 4. Boundary Integrity: Change Classification

#### 4.1 Files That Change

| File | Demands Served | Change Magnitude |
| ---- | -------------- | ---------------- |
| `plugins/trippin/skills/trip-protocol/SKILL.md` | D1, D2, D4 | Major: new sections, restructured review model, event log schema |
| `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` | D2 | Moderate: extend to append activity log entries |
| `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` | D1, D2 | Moderate: new directory layout, initialize activity log |
| `plugins/trippin/commands/trip.md` | D1, D2, D4 | Moderate: updated leader instructions for consolidated reviews, event logging, convergence limits |
| `plugins/trippin/agents/planner.md` | D1, D3, D4 | Moderate: schema conformance, review path update, autonomous behavior |
| `plugins/trippin/agents/architect.md` | D1, D3, D4 | Moderate: schema conformance, review path update, autonomous behavior |
| `plugins/trippin/agents/constructor.md` | D1, D3, D4 | Moderate: schema conformance, review path update, autonomous behavior |
| `plugins/trippin/skills/write-trip-report/SKILL.md` | D2 | Moderate: add activity log section to report template |
| `plugins/trippin/skills/write-trip-report/sh/gather-artifacts.sh` | D1, D2 | Moderate: read from new review/log locations |

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
| `activity-log.md` (runtime artifact) | File template | Append-only event log, created by init-trip.sh per trip |
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

**Risk**: Long-running trips with many iterations could produce very large activity logs that clutter the PR.

**Mitigation**: The write-trip-report skill should include a summarization heuristic: if the activity log exceeds 30 rows, include a collapsed `<details>` block for the full log and show only phase-transition events in the main table.

#### 6.3 trip-commit.sh Backward Compatibility

**Risk**: Extending trip-commit.sh with new optional parameters could break existing invocations.

**Mitigation**: New parameters must be strictly optional with sensible defaults. If no event metadata is provided, the script appends a generic event row derived from the existing parameters (agent, phase, step, description). Existing callers continue to work unchanged.

#### 6.4 Schema Enforcement Without Tooling

**Risk**: Agent file schema conformance is a one-time refactor, but drift can reoccur on future edits.

**Mitigation**: The canonical schema is documented in trip-protocol SKILL.md as a normative reference. Future agent file edits can be validated by comparing section headings against the schema. No automated tooling is proposed (this is a documentation/configuration project, not a compiled codebase).

## Review Notes

(Awaiting review from Planner and Constructor)
