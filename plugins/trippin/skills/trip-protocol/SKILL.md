---
name: trip-protocol
description: Two-phase collaborative workflow protocol and artifact conventions.
allowed-tools: Bash, Read, Write, Glob
user-invocable: false
---

# Trip Protocol

Defines the Implosive Structure workflow for three-agent collaboration: Planner, Architect, and Constructor.

## Agents

| Agent | Stance | Philosophy | Responsibilities |
| ----- | ------ | ---------- | ---------------- |
| Planner | Progressive | Extrinsic Idealism | Creative Direction, Stakeholder Profiling, Explanatory Accountability |
| Architect | Neutral | Structural Idealism | Semantical Consistency, Static Verification, Accessibility & Accommodability |
| Constructor | Conservative | Intrinsic Idealism | Sustainable Implementation, Infrastructure Reliability, Delivery Coordination |

## Dual Objectives

- **Goal**: Maximize benefit / Minimize loss (Optimization Problem)
- **Responsibility**: Prevent what shouldn't happen (Constraint Satisfaction)

## Phase Gate Policy

**CRITICAL: The leader agent is the sole workflow coordinator. No sub-agent may autonomously advance to the next step.**

Rules:
1. When a sub-agent finishes a task (review, artifact creation, moderation), it STOPS and reports completion
2. The leader waits for ALL concurrent tasks to complete before issuing the next round of work
3. Review approval by all reviewers is a prerequisite before any agent begins artifact generation
4. No agent may interpret its own approval as permission to proceed to its next responsibility

Every transition between sub-steps requires the leader to explicitly request the next action. This prevents race conditions where one agent's early completion causes it to skip ahead while other agents are still working.

## Artifact Dependencies

Artifacts have strict data flow dependencies that determine generation order:

```
Direction (Planner) ──→ Model (Architect) ──→ Design (Constructor)
```

- **Direction** feeds into both Model and Design
- **Model** feeds into Design (the Constructor must read the completed Model before writing Design)
- This creates strict ordering: Direction → Model → Design (never concurrent)
- Cross-reviews happen only after both Model and Design exist

On revision cycles: if a Direction is revised and re-approved, the Architect must regenerate the Model first, and only then does the Constructor regenerate the Design.

## Worktree Isolation

Each trip session runs in a dedicated git worktree for isolation. The worktree is created before any artifacts.

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh <trip-name>
```

This creates:
- Branch: `trip/<trip-name>`
- Worktree: `.worktrees/<trip-name>/`

All agent work happens inside the worktree directory. After completion, the user can merge the trip branch or inspect changes independently.

## Commit-per-Step Rule

**Every discrete workflow step produces a git commit.** The trip branch's commit history is the complete trace of the collaborative process.

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh <agent> <phase> <step> <description>
```

### Commit Message Format

```
[Agent] Descriptive summary of what was done

Phase: <phase>
Step: <step>
```

- **Agent prefix**: Capitalized name in square brackets: `[Planner]`, `[Architect]`, `[Constructor]`
- **Description**: A clear, intuitive English sentence summarizing what was accomplished. Must describe *what was done*, not just name a file or use a symbol.
- **Language**: All commit messages must be written in English.

### Good and Bad Examples

| Good | Bad |
| ---- | --- |
| `[Planner] Define user authentication flow and stakeholder priorities` | `[Planner] direction-v1.md` |
| `[Architect] Review direction for semantic consistency and identify type safety gaps` | `[Architect] review` |
| `[Constructor] Design database schema with migration strategy for user accounts` | `[Constructor] design` |
| `[Planner] Create integration test plan covering authentication edge cases` | `[Planner] test plan` |
| `[Constructor] Implement login endpoint with JWT token generation` | `[Constructor] impl` |

Commit points in Phase 1 (Specification):
- Planner writes direction → commit
- Architect reviews direction → commit
- Constructor reviews direction → commit
- Moderation resolution → commit
- Direction revision → commit
- Architect writes model → commit
- Constructor writes design → commit
- Each cross-review → commit
- Each revision → commit
- Consensus confirmation → commit

Commit points in Phase 2 (Implementation):
- Test plan created → commit
- Code implemented → commit
- Structural review → commit
- Test validation → commit
- Each iteration fix → commit

## Artifact Storage

```
.workaholic/.trips/<trip-name>/
  directions/           # Planner's artifacts
    reviews/            # Review feedback on directions
  models/               # Architect's artifacts
    reviews/            # Review feedback on models
  designs/              # Constructor's artifacts
    reviews/            # Review feedback on designs
```

Versioning: `direction-v1.md`, `direction-v2.md`, etc. Each revision is a new file, preserving history for review.

## Initialize Trip

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/init-trip.sh <trip-name>
```

## Phase 1: Specification (Inner Loop)

Agents produce and mutually review artifacts until full consensus.

### Step 1: Direction

1. **Planner** writes `directions/direction-v1.md` based on the user instruction
2. **Architect** reviews and writes `directions/reviews/direction-v1-architect.md`
3. **Constructor** reviews and writes `directions/reviews/direction-v1-constructor.md`
4. **GATE**: Leader waits for BOTH Architect AND Constructor reviews to complete
5. If disagreements arise, the third party moderates (see Moderation Protocol)
6. Revisions produce `direction-v2.md`, `direction-v3.md`, etc.
7. **GATE**: All three agents approve the direction before proceeding

### Step 2: Model and Design

Once Direction is approved and the leader has confirmed consensus:

**Step 2a: Model**
1. **Architect** writes `models/model-v1.md` derived from the approved Direction
2. **GATE**: Leader confirms model is committed and complete

**Step 2b: Design**
3. **Constructor** reads the completed Model, then writes `designs/design-v1.md` derived from BOTH the approved Direction AND the completed Model
4. **GATE**: Leader confirms design is committed and complete

**Step 2c: Cross-Review**
5. **Architect** reviews design and writes `designs/reviews/design-v1-architect.md`; **Constructor** reviews model and writes `models/reviews/model-v1-constructor.md`
6. **Planner** reviews both and writes `models/reviews/model-v1-planner.md` and `designs/reviews/design-v1-planner.md`
7. **GATE**: Leader waits for ALL cross-reviews to complete
8. Revisions continue until all three artifacts are mutually consistent

### Consensus Gate

Phase 1 completes when all agents confirm:
- Direction, Model, and Design are internally consistent
- No unresolved disagreements remain
- Artifacts are sufficient to begin implementation

## Phase 2: Implementation (Outer Loop)

With approved specification artifacts, agents transition to building.

### Step 1: Test Planning

**Planner** creates a test plan aligned with the approved Direction, Model, and Design.
- **GATE**: Leader confirms test plan is written before proceeding

### Step 2: Programming

**Constructor** implements the program based on the approved Design and Model.
- **GATE**: Leader confirms implementation is complete before proceeding

### Step 3: Reviewing

**Architect** reviews the implementation for structural integrity against the Model.
- **GATE**: Leader confirms review is complete before proceeding

### Step 4: Testing

**Planner** validates the implementation against the test plan.
- **GATE**: Leader confirms testing is complete before proceeding

### Iteration

If review or testing reveals issues, the team iterates:
- Constructor revises implementation → **GATE**: Leader confirms revision complete
- Architect re-reviews → **GATE**: Leader confirms re-review complete
- Planner re-tests → **GATE**: Leader confirms re-test complete
- Continue until all pass

## Moderation Protocol

When two agents disagree, the third agent serves as moderator:

| Disagreement | Moderator |
| ------------ | --------- |
| Planner vs Architect | Constructor |
| Architect vs Constructor | Planner |
| Planner vs Constructor | Architect |

The moderator:
1. Reads both positions from the artifact files
2. Evaluates against the dual objectives (optimization + constraint satisfaction)
3. Proposes a resolution or requests specific revisions from one or both parties
4. The resolution is written as the next version of the contested artifact

## Artifact Format

Each artifact markdown file follows this structure:

```markdown
# <Artifact Type> v<N>

**Author**: <Agent Name>
**Status**: draft | under-review | approved
**Reviewed-by**: <comma-separated agent names>

## Content

<artifact content here>

## Review Notes

<feedback from reviewing agents, added during review>
```

## Review Convention

**Rule**: Only the artifact's author may modify the original artifact file. All other agents express feedback through separate review files.

### Review File Convention

When reviewing an artifact, write feedback to a dedicated file in the `reviews/` subdirectory:

```
<artifact-dir>/reviews/<artifact-basename>-<reviewer-agent>.md
```

Examples:
- Architect reviewing direction-v1: `directions/reviews/direction-v1-architect.md`
- Constructor reviewing direction-v1: `directions/reviews/direction-v1-constructor.md`
- Planner reviewing model-v1: `models/reviews/model-v1-planner.md`

This ensures:
- No concurrent write conflicts (each agent writes to a unique path)
- Clear attribution of feedback
- Original artifacts remain clean for the author to revise

After reviews are committed, the artifact author reads all review files and incorporates feedback into the next version (e.g., `direction-v2.md`).
