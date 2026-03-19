---
name: trip-protocol
description: Two-phase collaborative workflow protocol and artifact conventions.
allowed-tools: Bash, Read, Write, Glob
user-invocable: false
---

# Trip Protocol

Three-agent collaboration workflow: Planner (progressive/business), Architect (neutral/structural), Constructor (conservative/technical). Dual objectives: maximize benefit (optimization) and prevent harm (constraint satisfaction).

## Phase Gate Policy

The leader agent is the sole workflow coordinator. No sub-agent may autonomously advance. After each task, agents STOP and report completion. The leader waits for ALL concurrent tasks before issuing the next round.

## Critical Review Policy

Reviews create dialectical tension across perspectives. Requirements:
1. Identify at least one concern or trade-off per review, even when approving
2. Provide a constructive proposal for every concern raised
3. Evaluate from your domain perspective (Planner: business outcome; Architect: structural bridge; Constructor: engineering quality)
4. Use structured decisions: "Approve with observations", "Approve with minor suggestions", or "Request revision" -- never bare "approve"

## Workflow Overview

Planning: Concurrent artifacts, one-turn review, accept/revise/escalate, moderate, plan fixed.
Coding: Concurrent launch, review and testing, iteration, done (or rollback to planning).

## Shell Scripts

All scripts use absolute paths from home directory.

| Script | Usage |
| ------ | ----- |
| `ensure-worktree.sh <trip-name>` | Create isolated worktree and branch |
| `list-trip-worktrees.sh` | List existing trip worktrees (JSON) |
| `init-trip.sh <trip-name> [instruction]` | Create artifact directories and plan.md |
| `validate-dev-env.sh <worktree_path>` | Check env files, dependencies, ports |
| `read-plan.sh <trip-path>` | Read plan state as JSON |
| `trip-commit.sh <agent> <phase> <step> <description>` | Commit with `[Agent] description` format |
| `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` | Append to event-log.md |

Script base path: `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/`

## Artifact Storage

```
.workaholic/.trips/<trip-name>/
  directions/           # Planner: direction-v1.md, direction-v2.md, ...
  models/               # Architect: model-v1.md, model-v2.md, ...
  designs/              # Constructor: design-v1.md, design-v2.md, ...
  reviews/              # round-1-<agent>.md, response-<author>-to-<reviewer>.md
  rollbacks/            # rollback-v<N>.md
    reviews/            # rollback-v<N>-<agent>.md
  event-log.md          # Append-only event log
  plan.md               # Trip state and progress
```

Each revision is a new file (e.g., `direction-v2.md`), preserving history. Only the artifact's author may modify the original file; others express feedback through review files.

## Plan Document

`plan.md` tracks trip lifecycle state with YAML frontmatter (`instruction`, `phase`, `step`, `iteration`, `updated_at`) and three sections: Initial Idea, Plan Amendments (leader decision log), and Progress (checklist with agent attribution). Update frontmatter at phase transitions; agents append progress entries bundled with artifact commits.

Step identifiers: `planning/not-started`, `planning/artifact-generation`, `planning/one-turn-review`, `planning/respond-to-feedback`, `planning/moderation`, `coding/concurrent-launch`, `coding/review-and-testing`, `coding/iteration-N`, `complete/done`.

## Event Log

Append-only `event-log.md` with columns: Timestamp, Agent, Event, Target, Impact. Call `log-event.sh` before `trip-commit.sh`. Leader-authored events require accurate impact; agent-authored events are best-effort. The commit script emits a warning if event-log.md exists but was not staged. Event types correspond to workflow actions (artifact lifecycle, reviews, gates, testing, rollbacks, phase transitions).

## Planning Phase

### Step 1: Concurrent Artifact Generation
All three agents write simultaneously: Planner writes `directions/direction-v1.md` (business vision, no codebase exploration), Architect writes `models/model-v1.md` (structural bridge), Constructor writes `designs/design-v1.md` (technical plan). **GATE**: wait for all three.

### Step 2: One-Turn Review
Each agent writes ONE consolidated review of the other two artifacts to `reviews/round-1-<agent>.md`. Include: reviewer name, artifacts reviewed, decision per artifact, domain-specific feedback with concerns and proposals, and cross-artifact coherence assessment. **GATE**: wait for all three.

### Step 3: Respond to Feedback
For each "Request revision", the author writes `reviews/response-<author>-to-<reviewer>.md` choosing: (a) accept and revise (new artifact version), or (b) escalate to the third agent. **GATE**: wait for all responses.

### Step 4: Moderation (if escalated)
The uninvolved third agent reads both positions, writes a synthesized resolution as the next artifact version. After moderation, the plan is fixed -- no further review rounds.

### Consensus Gate
Planning completes when all reviews approved, all revisions accepted, or all escalations moderated.

### Convergence Cap
Maximum 3 review rounds. If consensus is not reached after round 3, the leader invokes forced moderation on all unresolved disagreements and appends a "Forced Convergence" entry to plan.md's Plan Amendments section with the unresolved items and rationale. A `forced-convergence` event is logged. After moderation, the plan is fixed and the team proceeds to Coding Phase.

## Coding Phase

### QA Differentiation
- **Constructor**: Internal testing (compiler/type checks, unit tests, linters)
- **Planner**: E2E/external testing (CLI execution, browser via Playwright, API calls)
- **Architect**: Analytical review only (code review, architectural review, model checking -- no test execution)

### Concurrent Launch
Constructor implements + internal tests; Planner builds dev env + plans E2E scenarios; Architect discovers codebase. **GATE**: wait for all three.

### Review and Testing
Architect performs analytical review of Constructor's changes. **GATE**. Planner validates via E2E testing. **GATE**.

### Iteration
If issues found: Constructor fixes → Architect re-reviews → Planner re-tests. Repeat until approved.

### Rollback
Any agent may propose returning to Planning Phase. Requires 2/3 majority. Proposer writes `rollbacks/rollback-v<N>.md`; others vote in `rollbacks/reviews/rollback-v<N>-<agent>.md`. On approval, return to Planning with incremented artifact versions.

## E2E Assurance

Applies to projects with user-facing interfaces (web, CLI, API). Planner detects existing E2E frameworks; Playwright is the recommended default. Tests must be CLI-runnable. Projects that are purely library/configuration may skip E2E.

## System Safety

Before implementation, Constructor runs: `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/skills/system-safety/sh/detect.sh`. If `system_changes_authorized` is false, use project-local alternatives only.

## Commit Convention

Format: `[Agent] Descriptive summary of what was accomplished`. Description must be a clear English sentence (not file names or terse labels). Every discrete workflow step produces a commit.

## Artifact Format

Each artifact file: `# <Type> v<N>`, then metadata fields (Author, Status: draft/under-review/approved, Reviewed-by), then Content section, then Review Notes section.
