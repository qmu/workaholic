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
| Planner | Progressive | Extrinsic Idealism | Business Vision: Business Phenomena, Stakeholder Advocacy, Explanatory Accountability |
| Architect | Neutral | Structural Idealism | Structural Bridge: System Coherence, Translation Fidelity, Boundary Integrity |
| Constructor | Conservative | Intrinsic Idealism | Technical Accountability: Engineering Quality, Quality Assurance, Delivery Ownership |

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

## Critical Review Policy

Reviews are the mechanism through which the three perspectives create dialectical tension. A review that simply approves without substantive analysis fails to serve the collaborative process.

### Requirements

1. **Identify at least one concern or trade-off** per review, even when approving. Artifacts are never perfect -- each perspective will see something the author's perspective missed. A "no concerns" review indicates insufficient analysis.
2. **Provide a constructive proposal** for every concern raised. Never state "this is problematic" without offering "consider this alternative because..." with a concrete suggestion. Criticism without a counter-proposal is not constructive.
3. **Evaluate from your domain perspective**, not general impressions:
   - Planner reviews ask: Does this deliver the business outcome? Can stakeholders trace the reasoning?
   - Architect reviews ask: Does the structure faithfully bridge business intent and technical implementation?
   - Constructor reviews ask: Does this meet the quality bar I am accountable for? What engineering risks exist?
4. **Use structured approval decisions**:
   - "Approve with observations" -- approved, with noted trade-offs for the record
   - "Approve with minor suggestions" -- approved, with optional improvements the author may incorporate
   - "Request revision" -- not approved, with specific proposals for what to change and why
   - Never use bare "approve" or "looks good" without substantive analysis

The goal is not conflict for its own sake but **productive tension** that strengthens the specification through complementary viewpoints.

## Artifact Dependencies

Artifacts are generated concurrently, then aligned through mutual review:

```
Direction (Planner) ──┐
Model (Architect)   ──┼──→ Mutual Review ──→ Convergence
Design (Constructor) ─┘
```

- All three artifacts are generated concurrently from the user instruction
- Each agent writes from their own domain perspective without reading the other agents' artifacts
- **Mutual Review** aligns the three artifacts: each agent reviews the other two agents' work
- On revision cycles: the artifact author incorporates review feedback and writes the next version; another mutual review round follows until consensus

## Worktree Isolation

Each trip session runs in a dedicated git worktree for isolation. The worktree is created before any artifacts.

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh <trip-name>
```

This creates:
- Branch: `trip/<trip-name>`
- Worktree: `.worktrees/<trip-name>/`

All agent work happens inside the worktree directory. After completion, the user can merge the trip branch or inspect changes independently.

### Resume or Create

Before creating a new worktree, the trip command checks for existing trip worktrees using `list-trip-worktrees.sh`. If active worktrees are found, the user is prompted to either resume an existing trip or create a new one. This prevents worktree proliferation and allows returning to interrupted sessions.

When resuming, the existing worktree path and branch are reused. Trip artifact initialization is skipped if the artifacts directory already exists inside the worktree.

### Listing Trip Worktrees

To discover active trip worktrees with their metadata (branch, path, PR status):

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
```

Output: JSON with `count` and `worktrees` array. Each entry contains `trip_name`, `branch`, `worktree_path`, `has_pr`, and optionally `pr_number` and `pr_url`. Used by `report-trip` and `ship-trip` as a fallback when not on a trip branch.

**Note**: Worktree creation is only the first part of preparation. The development environment inside the worktree must also be validated and configured before planning begins (see Dev Environment Readiness below).

## Dev Environment Readiness

After creating the worktree and initializing trip artifacts, the development environment inside the worktree must be validated and prepared **before** the Planner begins writing any direction artifacts.

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh <worktree_path>
```

### Concurrent Isolation

Multiple trip sessions may run simultaneously in separate worktrees. Each worktree must be fully independent:
- **No shared network ports**: If the project uses specific ports (dev server, database), each worktree must use unique ports
- **No shared lock files**: Build tools, package managers, and databases may use lock files that conflict across worktrees
- **No shared state directories**: Caches, temp files, and runtime state must be worktree-local

### Validation-Feedback-Action Loop

The validation script outputs structured JSON indicating what is missing or misconfigured. The leader agent reads this feedback and takes corrective action:
1. Run validation script
2. Parse results: if `ready` is true, proceed to planning
3. If `ready` is false, address each failing check (copy env files, install dependencies, configure ports)
4. Re-run validation
5. Repeat until ready or report unresolvable issues to the user

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

Commit points in Planning Phase (Specification):
- Planner writes direction → commit
- Architect writes model → commit
- Constructor writes design → commit
- Each mutual review → commit
- Moderation resolution → commit
- Each revision → commit
- Consensus confirmation → commit

Commit points in Coding Phase (Implementation):
- Code implemented and internal tests passed (Constructor) → commit
- Test plan created (Planner) → commit
- Codebase discovery (Architect) → commit
- Analytical review: code review, architectural review, model checking (Architect) → commit
- E2E / external interface test validation (Planner) → commit
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
  rollbacks/            # Rollback proposals
    reviews/            # Votes on rollback proposals
```

Versioning: `direction-v1.md`, `direction-v2.md`, etc. Each revision is a new file, preserving history for review.

## Initialize Trip

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/init-trip.sh <trip-name> [instruction]
```

## Trip Plan Document

Each trip maintains a `plan.md` file in the trip directory that serves as the persistent state record for the trip lifecycle. It captures the original instruction, tracks workflow progress, and enables automated resume after shutdown.

### Location

```
.workaholic/.trips/<trip-name>/plan.md
```

### Format

```markdown
---
instruction: "<user's original trip instruction>"
phase: planning | coding | complete
step: <current step identifier>
iteration: <revision cycle count>
updated_at: <ISO 8601 timestamp>
---

# Trip Plan

## Initial Idea

<user's original instruction, preserved verbatim>

## Plan Amendments

<append-only log of changes with timestamps>

## Progress

<checklist of completed steps with agent attribution>
```

### Step Identifiers

| Phase | Step | Description |
| ----- | ---- | ----------- |
| planning | not-started | Trip initialized, no work begun |
| planning | artifact-generation | Agents creating initial artifacts |
| planning | mutual-review-N | Mutual review round N |
| planning | convergence | Revisions and consensus |
| coding | concurrent-launch | Constructor implementing, Planner test planning, Architect discovering |
| coding | review-and-testing | Architect reviewing, Planner E2E testing |
| coding | iteration-N | Fix iteration N |
| complete | done | Trip finished |

### Update Rules

- The **team lead** (trip command) updates plan.md frontmatter at phase transitions and commits via `trip-commit.sh`
- **Agents** append progress entries to the Progress section after completing major steps
- Progress entry format: `- [x] <phase>/<step> (<agent>) - <brief description> (<timestamp>)`
- Plan updates are bundled with the agent's artifact commit (not separate commits)

### Reading Plan State

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/read-plan.sh <trip-path>
```

Output: JSON with `phase`, `step`, `iteration`, `instruction`, and `updated_at`. Returns `{"phase": "unknown", "step": "unknown"}` if plan.md does not exist (backward compatible).

## Planning Phase: Specification (Inner Loop)

Agents produce and mutually review artifacts until full consensus.

### Step 1: Concurrent Artifact Generation

All three agents begin writing their artifacts simultaneously from the user instruction:

1. **Planner** writes `directions/direction-v1.md` — a business vision document defining the value proposition, risk landscape, user personas, and system positioning from a non-technical perspective. The Planner does NOT explore the codebase.
2. **Architect** writes `models/model-v1.md` — structural translation defining system coherence, boundary integrity, and the bridge between business vision and technical implementation.
3. **Constructor** writes `designs/design-v1.md` — technical implementation plan defining the engineering approach, quality strategy, and delivery plan.

- **GATE**: Leader waits for ALL THREE artifacts to be committed and complete

### Step 2: Mutual Review Session

Each agent reviews the other two agents' artifacts:

1. **Planner** reviews Model and Design: writes `models/reviews/model-v1-planner.md` and `designs/reviews/design-v1-planner.md`
2. **Architect** reviews Direction and Design: writes `directions/reviews/direction-v1-architect.md` and `designs/reviews/design-v1-architect.md`
3. **Constructor** reviews Direction and Model: writes `directions/reviews/direction-v1-constructor.md` and `models/reviews/model-v1-constructor.md`

- **GATE**: Leader waits for ALL SIX reviews to complete

### Step 3: Convergence

1. If disagreements arise, the relevant agents revise their artifacts incorporating review feedback (e.g., `direction-v2.md`, `model-v2.md`, `design-v2.md`)
2. After revisions, another mutual review round occurs (return to Step 2)
3. If disagreements between two agents persist, the third agent moderates (see Moderation Protocol)
4. **GATE**: All three agents approve all three artifacts before proceeding to Coding Phase

### Consensus Gate

Planning Phase completes when all agents confirm:
- Direction, Model, and Design are internally consistent
- No unresolved disagreements remain
- Artifacts are sufficient to begin implementation

## Coding Phase: Implementation (Outer Loop)

With approved specification artifacts, agents transition to building.

### Quality Assurance Differentiation

The three agents ensure quality through three orthogonal approaches:

| Agent | QA Role | Method | Scope |
| ----- | ------- | ------ | ----- |
| Planner | E2E / External Testing | Execute the program as a user would (CLI execution, browser via Playwright, API calls) | External interfaces and user-visible behavior |
| Constructor | Internal Testing | Run compiler/type checks, unit tests, linters | Code correctness and internal soundness |
| Architect | Analytical Review | Discover codebase changes, perform code review, architectural review, model checking | Structural integrity and specification fidelity |

These roles do not overlap:
- The Planner does NOT run unit tests or compiler checks
- The Constructor does NOT run E2E tests or validate external interfaces
- The Architect does NOT execute any tests — review is purely analytical

### Concurrent Launch

All three agents begin work simultaneously:

1. **Constructor** starts implementing the program based on the approved Design and Model. After implementation, runs internal quality checks (compiler/type checks, unit tests, linters) and fixes any failures before reporting completion.
2. **Planner** starts test planning: building the development environment, verifying it is running (using Playwright CLI MCP), and planning E2E test scenarios by examining the target website (using Playwright CLI MCP). When the project has a user-facing interface, the test plan should include E2E test scenarios (see E2E Assurance Policy below). For CLI programs, plans execution-based tests that verify outputs and behavior from the command line.
3. **Architect** starts codebase discovery: reading the existing codebase structure and patterns to prepare modeling-related artifacts that will inform the upcoming structural review

- **GATE**: Leader waits for ALL three agents to complete their concurrent tasks before proceeding

### Review and Testing

Once the Constructor's implementation is complete (with internal tests passing) and the Planner's test plan is ready:

**Architect** discovers the Constructor's changes and performs analytical review: code review for quality and consistency, architectural review for structural integrity against the Model, and model checking to verify specification fidelity. The Architect writes review findings as artifacts — does not run tests or compilers.
- **GATE**: Leader confirms review is complete before proceeding

**Planner** validates the implementation through E2E and external interface testing: executes the program as a user would (CLI commands, browser interactions via Playwright, API calls) and reports any failures with specific workflow breakdowns.
- **GATE**: Leader confirms testing is complete before proceeding

### Iteration

If review or testing reveals issues, the team iterates:
- Constructor revises implementation and re-runs internal tests → **GATE**: Leader confirms revision complete
- Architect re-reviews analytically → **GATE**: Leader confirms re-review complete
- Planner re-tests E2E / external interfaces → **GATE**: Leader confirms re-test complete
- Continue until all pass

### Rollback

At any point during the Coding Phase, an agent may propose returning to the Planning Phase instead of continuing iteration. See the Rollback Protocol section below for the full mechanism.

## Rollback Protocol

During the Coding Phase, any agent may propose returning to the Planning Phase when they determine the specification artifacts are fundamentally insufficient for successful implementation.

### Trigger Scenarios

- **Constructor**: Implementation is not feasible at the required quality level given the current design
- **Architect**: Structural review reveals the model cannot support the implementation being built
- **Planner**: Testing reveals missing requirements or business scenarios not covered by the direction

### Consensus Requirement

Rollback requires a **two-out-of-three majority**. The proposing agent counts as one supporter.

1. Proposing agent writes `rollbacks/rollback-v<N>.md` with reason, target step, and evidence → **commit**
2. **GATE**: Leader requests votes from the other two agents
3. Each voting agent writes `rollbacks/reviews/rollback-v<N>-<agent>.md` with "support" or "oppose" and reasoning → **commit each**
4. **GATE**: Leader waits for both votes
5. Leader tallies: if 2+ agents support → rollback proceeds; if only 1 → Coding Phase continues

### On Rollback Approval

- The workflow returns to the Planning Phase at the step specified in the proposal (Direction, Model, or Design revision)
- Revised artifacts use incremented version numbers (e.g., if `direction-v2.md` was the last approved version, the revision is `direction-v3.md`)
- All Planning Phase consensus gates apply again — the team must re-achieve full consensus before returning to the Coding Phase
- The rollback and its resolution are preserved in the `rollbacks/` directory as part of the process trace

### Rollback Proposal Artifact Format

```markdown
# Rollback Proposal v<N>

**Author**: <Agent Name>
**Status**: proposed | approved | rejected
**Target**: <Direction | Model | Design>

## Reason

<Why the current specification is insufficient>

## Evidence

<Specific implementation issues encountered during Coding Phase>

## Votes

- <Agent 1>: <support | oppose> — <reasoning>
- <Agent 2>: <support | oppose> — <reasoning>
```

## E2E Assurance Policy

E2E testing is the Planner's exclusive quality assurance domain. Through **end-to-end validation** of the full user experience, the Planner fulfills Explanatory Accountability: demonstrating that the delivered system satisfies the stakeholder-facing direction. Internal testing (unit tests, compiler checks) belongs exclusively to the Constructor.

### When to Apply

E2E testing applies when the project has a user-facing interface:
- Web applications (browser-based UI)
- CLI tools (terminal-based interaction)
- API services with consumer-facing workflows

Projects that are purely library or configuration may skip E2E testing. The Planner assesses applicability during test planning.

### Tool Selection

The Planner should detect the project's existing E2E framework by checking for configuration files (e.g., `playwright.config.*`, `cypress.config.*`, `wdio.conf.*`). If no framework exists, the Planner may propose one in the test plan. **Playwright** is the recommended default for web projects due to its headless CLI interface.

### Constraints

- E2E tests must be runnable from the command line (`npx playwright test`, `npx cypress run`, etc.) without requiring a GUI
- The Planner operates in a terminal environment and cannot interact with browser windows manually
- E2E test results must be interpretable from CLI output (exit codes, test report summaries)

### Scope

E2E tests validate user-visible workflows end-to-end: navigation, form submission, data persistence, authentication flows, error states. They complement the Architect's structural review (which checks code integrity) with experiential validation (which checks user outcomes). The Planner defines which workflows to cover in the test plan and runs them during the testing step.

## System Safety

Agents must not modify system-wide configuration (shell profiles, global packages, system services, `/etc/` files, `sudo` commands) unless the repository is a provisioning repository. The Constructor is the primary agent executing commands during Coding Phase, so this constraint is especially critical for implementation work.

Before any implementation that may touch system configuration, the Constructor must run the detection script from the **system-safety** skill:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/system-safety/sh/detect.sh
```

- If `system_changes_authorized` is `false`: all prohibited operations in the system-safety skill are blocked. Use project-local alternatives instead.
- If `system_changes_authorized` is `true`: system-wide changes are permitted.

If an implementation step requires a prohibited operation and no safe alternative exists, report the blocker to the team lead rather than proceeding.

## Moderation Protocol

When two agents disagree, the third agent serves as moderator:

| Disagreement | Moderator |
| ------------ | --------- |
| Planner vs Architect | Constructor |
| Architect vs Constructor | Planner |
| Planner vs Constructor | Architect |

The moderator:
1. Reads both positions from the artifact files
2. Acknowledges both domain perspectives -- understand why each side holds its position from its opinion domain (business vision, technical accountability, or structural bridge)
3. Evaluates against the dual objectives (optimization + constraint satisfaction)
4. Proposes a resolution that synthesizes both perspectives rather than simply picking a side
5. The resolution is written as the next version of the contested artifact

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
