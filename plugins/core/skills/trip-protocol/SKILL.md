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

| Script | Location | Usage |
| ------ | -------- | ----- |
| `ensure-worktree.sh <trip-name>` | core | Create isolated worktree and branch |
| `cleanup-worktree.sh <trip-name>` | core | Remove worktree and branch after PR merge |
| `list-worktrees.sh` | core | List existing worktrees with PR status (JSON) |
| `init-trip.sh <trip-name> [instruction]` | work | Create artifact directories and plan.md |
| `validate-dev-env.sh <worktree_path>` | work | Check env files, dependencies, ports |
| `read-plan.sh <trip-path>` | work | Read plan state as JSON |
| `trip-commit.sh <agent> <phase> <step> <description>` | work | Commit with `[Agent] description` format |
| `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` | work | Append to event-log.md |

Script base paths:
- **branching scripts**: `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/`
- **trip-protocol scripts**: `${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/`

## Artifact Storage

```
.workaholic/trips/<trip-name>/
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

Step identifiers: `planning/not-started`, `planning/artifact-generation`, `planning/one-turn-review`, `planning/respond-to-feedback`, `planning/moderation`, `coding/concurrent-launch`, `coding/review-and-testing`, `coding/iteration-N`, `complete/done`, `complete/followup`.

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

## Post-Completion Protocol

After the trip reaches `complete/done`, the team lead may receive follow-up requests from the user. The team composition rule applies strictly:

**Never create new agent team members.** The only agents permitted in the worktree are the three designated teammates: Planner, Architect, and Constructor. This applies regardless of the nature of the follow-up request.

**Lead handles directly** when the task is: answering a question, reading files, making a single-file edit, running a command, or any task that does not require the specialized perspective of a designated agent.

**Lead re-invokes designated agents** when the task involves: multi-file changes, implementation work (Constructor), structural review (Architect), E2E validation (Planner), or any work that falls within a designated agent's domain. Re-invoked agents retain their original role boundaries, QA domains, and behavioral constraints from the trip session.

Update `plan.md` frontmatter: set step to `complete/followup` when follow-up work begins, return to `complete/done` when it finishes. Log follow-up events to `event-log.md`.

Step identifier: `complete/followup`

## E2E Assurance

Applies to projects with user-facing interfaces (web, CLI, API). Planner detects existing E2E frameworks; Playwright is the recommended default. Tests must be CLI-runnable. Projects that are purely library/configuration may skip E2E.

## System Safety

Before implementation, Constructor runs: `bash ${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`. If `system_changes_authorized` is false, use project-local alternatives only.

## Written Language Policy

All trip output must be written in English. This applies to: artifact content, review files, event log entries, plan.md content, commit messages, PR titles and bodies, code and code comments, and any agent-generated documentation.

## Commit Convention

Format: `[Agent] Descriptive summary of what was accomplished`. Description must be a clear English sentence (not file names or terse labels). Every discrete workflow step produces a commit.

## Artifact Format

Each artifact file: `# <Type> v<N>`, then metadata fields (Author, Status: draft/under-review/approved, Reviewed-by), then Content section, then Review Notes section.

## Roles

### Planner (Progressive)

Business visionary agent — Progressive stance, Extrinsic Idealism.

**Domain**: protect business outcomes and stakeholder value. Review through the lens of business value: Does this deliver the business outcome? Can stakeholders trace the reasoning? For every concern, propose a concrete alternative framed in business outcomes.

- **Planning Phase**: Write `directions/direction-v1.md` containing: value proposition, business risk assessment, user personas, system positioning, business rationale. Do NOT include file paths, code references, or codebase analysis — codebase discovery is the Architect's job. Review Model and Design in `reviews/round-1-planner.md`. Respond to feedback in `reviews/response-planner-to-<reviewer>.md`. Moderate Architect-Constructor disagreements when called upon.
- **Coding Phase QA Role**: E2E and external interface testing. Validate the system from the outside. Build dev environment, plan E2E scenarios (browser via Playwright for web apps, CLI execution for CLI tools). Do NOT run unit tests, compiler checks, or perform code review.

### Architect (Neutral)

Structural bridge agent — Neutral stance, Structural Idealism.

**Domain**: protect structural integrity and translation fidelity. Review as the bridge between perspectives: Does the structure faithfully represent the business intent? Can stakeholders trace their requirements? For every concern, propose a concrete structural alternative preserving translation fidelity.

- **Planning Phase**: Write `models/model-v1.md` containing: system coherence mapping, domain model, translation fidelity analysis, boundary integrity assessment, component taxonomy. The model bridges business and technical but is neither alone. Review Direction and Design in `reviews/round-1-architect.md`. Respond to feedback in `reviews/response-architect-to-<reviewer>.md`. Moderate Planner-Constructor disagreements when called upon.
- **Coding Phase QA Role**: Analytical review only. Discover codebase changes and perform code review, architectural review, and model checking. Do NOT execute any tests — testing belongs to the Planner (E2E) and Constructor (internal).

### Constructor (Conservative)

Technically accountable agent — Conservative stance, Intrinsic Idealism.

**Domain**: protect engineering quality and production readiness. Review with technical ownership: Is this the right technical approach? What quality bar must this meet? For every concern, propose a concrete technical alternative that maintains the quality bar.

- **Planning Phase**: Write `designs/design-v1.md` containing: scope and inventory, implementation approach, quality strategy, delivery plan, risk assessment. The design translates structure into buildable, testable components. Review Direction and Model in `reviews/round-1-constructor.md`. Respond to feedback in `reviews/response-constructor-to-<reviewer>.md`. Moderate Planner-Architect disagreements when called upon.
- **Coding Phase QA Role**: Internal testing. Implement the program, then verify with compiler/type checks, unit tests, linters. Fix failures before reporting completion. Do NOT run E2E tests or perform analytical code review.

## Agent Rules

Shared by all three role agents:

- Follow this protocol for commit/log-event commands, artifact format, and all workflow procedures.
- All output must be in English (artifacts, reviews, code, commit descriptions).
- After completing any task, STOP and wait for the team lead's next instruction.
- When re-invoked for post-completion follow-up, the same role boundaries and QA domain apply.
- Apply preloaded lead standards (validity, accessibility, security, availability) — ensure artifacts, implementation, and testing respect the team's policies, practices, and standards across all domains.
- Never modify another agent's artifact.

Role-specific:

- **Constructor only**: Run `core:system-safety` detection (`${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`) before any implementation that may touch system configuration. (See the System Safety section above.)

## Leading Standards (Soft Preloads)

The trip protocol soft-depends on the following leading skills. Callers (commands or agents) that participate in a trip preload them so the protocol's planning, design, implementation, review, and testing all respect their policies:

- `standards:leading-validity`
- `standards:leading-accessibility`
- `standards:leading-security`
- `standards:leading-availability`

## Trip Command Procedure

Procedural body for `/trip` (executed from the work-side command via this preloaded skill). All script paths use same-plugin form because they resolve from this skill's owning plugin (core).

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop.

### Step 1: Create or Resume Trip

Check for existing worktrees:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh
```

If `count > 0`, present choices via AskUserQuestion: list each existing worktree, plus option to create new.

**Resume (worktree)**: Use selected worktree's path/branch. Read plan state:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/read-plan.sh "<trip-path>"
```
Route by state: `planning/not-started` -> Step 3, any other planning/coding step -> Step 4 with resume context, `complete/done` -> inform user and suggest `/report`.

**New**: Present a choice via AskUserQuestion:
- **"Create worktree"** - Isolated environment. Run:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh
  ```
  Parse JSON to get `branch`. Then create worktree from it:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/adopt-worktree.sh "<branch>"
  ```
  Set `<working_dir>` to the `worktree_path` from the output.
- **"Branch only"** - Lightweight, no worktree. Run:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh
  ```
  Set `<working_dir>` to the repository root.

### Step 2: Initialize Trip Artifacts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT" "<working_dir>"
```

### Step 3: Validate Dev Environment

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/validate-dev-env.sh "<working_dir>"
```

If `ready` is false, fix each failing check (copy env files, install dependencies, configure ports) and re-run.

### Step 4: Launch Agent Teams

Create a three-member Agent Team. The team lead instruction:

> You are the team lead coordinating a trip session. Follow the preloaded **trip-protocol** skill for the complete workflow.
>
> **Working directory**: `<working_dir>`
> **Trip path**: `<trip_path>`
> **User instruction**: `$ARGUMENT`
> **Resume state**: `<phase>/<step>` from read-plan.sh
>
> Create three teammates:
> 1. **Planner** (`work:planner`) - Business vision, E2E testing
> 2. **Architect** (`work:architect`) - Structural bridge, analytical review
> 3. **Constructor** (`work:constructor`) - Technical implementation, internal testing
>
> All agents work inside `<working_dir>`. Follow trip-protocol for the Planning Phase (concurrent artifacts, one-turn review, respond/escalate, moderate) and Coding Phase (concurrent launch, review & testing, iteration). All agents have the team's **lead standards** preloaded — ensure all planning, design, implementation, and testing respects the policies, practices, and standards defined by the leads. Enforce convergence cap: max 3 review rounds before forced moderation. Use `trip-commit.sh` and `log-event.sh` for every step. Update `plan.md` at phase transitions. If resuming, skip completed steps.
>
> Language policy: All agent output must be English.
>
> **Post-completion rule**: After the trip reaches `complete/done`, if the user sends follow-up requests: handle simple tasks directly (reading, answering, small edits). For substantial work, re-invoke ONLY the three designated teammates (Planner, Architect, Constructor) -- never create new agent team members. The designated agents retain their original roles and constraints.

### Step 5: Present Results

After the team completes:
1. List all artifacts in the trip path
2. Summarize the agreed direction, model, and design
3. Report implementation results
4. Show the trip branch name
5. Transition guidance: "Use `/report` and `/ship` when ready to merge."
6. Continuation guidance: "For follow-up modifications, request changes directly -- the lead will handle simple tasks or re-invoke the designated agents (Planner, Architect, Constructor). No new agents are created."
