---
name: trip-protocol
description: Two-phase collaborative workflow protocol and artifact conventions.
allowed-tools: Bash, Read, Write, Glob
user-invocable: false
metadata:
  internal: true
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

`/trip` is context-aware (like `/report` and `/ship`). With an **instruction** it runs **design-first**; over a **populated todo queue** with no instruction it runs **queue-execute** (drive the existing tickets with three-agent QA, no design). See "Determine execution mode" in the Trip Command Procedure.

Design-first Planning: Concurrent artifacts, one-turn review, accept/revise/escalate, moderate, plan fixed, **decompose into tickets**.
Coding (both modes): drive the ticket queue per ticket — Constructor implements, Architect reviews, Planner E2E, archive — iterate, done (or rollback to planning).

**Design-first flows straight through by default.** When the plan is fixed and the Decomposition gate has written the tickets, the team proceeds **directly** into the Coding Phase — it does **not** stop to present the design for a developer green-light. The one-turn review / respond-escalate / moderation / 3-round convergence cap *are* the design gate; the per-ticket three-agent QA is the build gate; the committed `designs/` artifacts plus `event-log.md` are the recorded decision a developer reviews **afterward** via `/report` (an asynchronous approval, not a synchronous pause). A pre-build developer checkpoint is opt-in only, never the default. This is true in every mode — night mode only *adds* setup and failure-handling autonomy on top (see Night Mode).

## Shell Scripts

All script paths use the same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/` form (see Script base paths below).

| Script | Location | Usage |
| ------ | -------- | ----- |
| `ensure-worktree.sh <trip-name>` | branching | Create isolated worktree and branch |
| `cleanup-worktree.sh <trip-name>` | branching | Remove worktree and branch after PR merge |
| `list-worktrees.sh` | branching | List existing worktrees with PR status (JSON) |
| `init-trip.sh <trip-name> [instruction]` | trip-protocol | Create artifact directories and plan.md |
| `validate-dev-env.sh <worktree_path>` | trip-protocol | Check env files, dependencies, ports |
| `read-plan.sh <trip-path>` | trip-protocol | Read plan state as JSON |
| `trip-commit.sh <agent> <phase> <step> <description>` | trip-protocol | Commit with `[Agent] description` format |
| `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` | trip-protocol | Append to event-log.md |
| `find-gitignored-files.sh <worktree-path>` | trip-protocol | Discover gitignored files in a worktree that differ from main (JSON) |
| `sync-gitignored-files.sh <worktree-path> <main-repo-root> <files-json>` | trip-protocol | Copy selected gitignored files from worktree to main repo root |

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

**Artifact frontmatter (OKF conformance).** Every trip artifact file starts with a YAML frontmatter block whose first key is a non-empty `type`, which makes each file readable as an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) concept document (further keys are free extensions). Use the artifact's role as the type: `type: Direction` (directions/), `type: Model` (models/), `type: Design` (designs/), `type: Review` (reviews/), `type: Rollback` (rollbacks/), `type: Event Log` (event-log.md), `type: Trip Plan` (plan.md — alongside its lifecycle keys below).

**Tickets live elsewhere.** The Decomposition gate (Planning Phase Step 5) writes implementation tickets to `.workaholic/tickets/todo/<user>/`, **never** under `trips/` — `create-ticket`'s Allowed Locations and the `validate-ticket.sh` hook forbid ticket-shaped files outside `.workaholic/tickets/`. The `trips/<trip-name>/` tree holds the **rationale** (direction/model/design); each emitted ticket links back to the design section that justifies it via a **Trip Origin** reference. So `trips/` is the *why*, `tickets/` is the *what* — the same ticket abstraction `/drive` consumes.

## Plan Document

`plan.md` tracks trip lifecycle state with YAML frontmatter (`type: Trip Plan`, `instruction`, `phase`, `step`, `iteration`, `updated_at`) and three sections: Initial Idea, Plan Amendments (leader decision log), and Progress (checklist with agent attribution). Update frontmatter at phase transitions; agents append progress entries bundled with artifact commits.

Step identifiers: `planning/not-started`, `planning/artifact-generation`, `planning/one-turn-review`, `planning/respond-to-feedback`, `planning/moderation`, `planning/decomposition`, `coding/concurrent-launch`, `coding/review-and-testing`, `coding/iteration-N`, `complete/done`, `complete/followup`.

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
Maximum 3 review rounds. If consensus is not reached after round 3, the leader invokes forced moderation on all unresolved disagreements and appends a "Forced Convergence" entry to plan.md's Plan Amendments section with the unresolved items and rationale. A `forced-convergence` event is logged. After moderation, the plan is fixed and the team proceeds to the Decomposition gate.

### Step 5: Decomposition (design → tickets)
Once the plan is fixed (consensus, accepted revisions, or forced convergence), the **Constructor** decomposes the agreed `designs/design-v<N>.md` into implementation **tickets** — the unit the Coding Phase drives. This is the bridge that unifies `/trip` with `/drive`: the trip's design becomes a ticket queue, exactly what `/drive` consumes.

Write each ticket to `.workaholic/tickets/todo/<user>/` (the `<user>` slug from `gather/scripts/ticket-metadata.sh`, under the trip's `<working_dir>`), following the standard ticket File Structure from `workaholic:create-ticket`:

- **Mandatory `## Policies`** — propagate the design's Policies list (plus any layer-selected pillar policies) so each ticket records the standard policies its build answers to.
- **Trip Origin** — a reference back to the section of `.workaholic/trips/<trip-name>/designs/design-v<N>.md` that justifies the ticket, keeping the rationale ("why") one link from the contract ("what").
- **`depends_on`** — derived from the design's delivery plan, so the Coding Phase drives the tickets in a correct order.

Split the design into 2–N independently-implementable tickets (tightly-coupled work stays one ticket). Tickets MUST be written under `.workaholic/tickets/` — never `trips/` (the `validate-ticket.sh` hook rejects ticket-shaped files written elsewhere). For ambiguous decomposition, the Constructor records reasonable assumptions in the design and `plan.md` rather than pausing for the developer. Log a `decomposition` event and commit the tickets. **GATE** (team-internal sync, not a developer pause): wait for all tickets to be written, then flow **straight into the Coding Phase** — there is no developer confirmation between Planning and Coding.

Step identifier: `planning/decomposition`.

## Coding Phase

The Coding Phase is a **trip-native drive** over the ticket queue the Decomposition gate produced (`.workaholic/tickets/todo/<user>/`). The lead walks the tickets in dependency order (`depends_on`, then severity), and each ticket passes through the three-agent QA before the next begins. This is `/drive` with the trip's three-agent QA substituted for the developer approval gate.

### QA Differentiation
- **Constructor**: Internal testing (compiler/type checks, unit tests, linters)
- **Planner**: E2E/external testing (CLI execution, browser via Playwright, API calls)
- **Architect**: Analytical review only (code review, architectural review, model checking -- no test execution)

### Concurrent Launch (once, before the queue)
Planner builds the dev env + plans E2E scenarios; Architect discovers the codebase; Constructor reviews the ticket queue and reconfirms ordering. **GATE**: wait for all three. This primes the team before the per-ticket loop.

Step identifier: `coding/concurrent-launch`.

### Per-Ticket Drive Loop
For each ticket in the queue, in `depends_on` then severity order:

1. **Constructor implements** the ticket — reads the ticket's `## Policies` and opens each named `policies/<slug>.md`, applies any Patches, follows the Implementation Steps, and runs internal tests (compiler/type checks, unit tests, linters). **GATE**.
2. **Architect reviews** the Constructor's changes against the ticket and its policies (analytical / code / architectural review, no test execution). **GATE**.
3. **Planner E2E-tests** the change (CLI / browser via Playwright / API per the project). **GATE**.
4. On three-agent consensus, **archive the ticket**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh <ticket-path> "<message>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"`. This stamps the ticket's frontmatter (`effort`/`commit_hash`/`category`), moves it to `.workaholic/tickets/archive/<branch>/`, and commits — so `/report` finds it. Log a trip event in `event-log.md` alongside.

The three-agent QA (Architect review + Planner E2E) **is** the per-ticket approval gate — there is no developer `AskUserQuestion`, so the loop is night-mode-safe. If a ticket fails review or testing, iterate within that ticket (Constructor fixes → Architect re-reviews → Planner re-tests) before archiving and moving on.

Step identifier: `coding/ticket-<id>` (one per ticket; `<id>` is the ticket's filename-timestamp slug). The legacy single `coding/iteration-N` identifier is retained only for resuming pre-decomposition trips.

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

**Exception — per-ticket archiving.** In the Coding Phase's Per-Ticket Drive Loop, completed tickets are committed by `drive/scripts/archive.sh` (the structured five-section drive message), **not** the `[Agent]` format. This is intentional: it moves the ticket into `.workaholic/tickets/archive/<branch>/` so `/report` finds it, and there is no second archive path to maintain. Preserve agent attribution by logging the trip event in `event-log.md` alongside the archive.

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

- **Planning Phase**: Write `designs/design-v1.md` containing: scope and inventory, implementation approach, quality strategy, delivery plan, risk assessment, and a **Policies** section. The design translates structure into buildable, testable components. The **Policies** section is the trip's equivalent of a ticket's `## Policies` list — it records the standard engineering policies (synced from qmu.co.jp into `workaholic:design` / `workaholic:implementation` / `workaholic:operation`) the build answers to, one `workaholic:<pillar>` / `policies/<slug>.md` entry per line with why it applies; always list `implementation/directory-structure` and `implementation/coding-standards` for code work. All three agents read this list in the Coding Phase and judge their implementation, review, and testing against each named policy. Review Direction and Model in `reviews/round-1-constructor.md`. Respond to feedback in `reviews/response-constructor-to-<reviewer>.md`. Moderate Planner-Architect disagreements when called upon. After the plan is fixed, **decompose the agreed design into tickets** under `.workaholic/tickets/todo/<user>/` (Planning Phase Step 5: Decomposition) — each ticket carries the design's `## Policies` and a Trip Origin link, and is the unit the Coding Phase drives.
- **Coding Phase QA Role**: Internal testing. Implement the program, then verify with compiler/type checks, unit tests, linters. Fix failures before reporting completion. Do NOT run E2E tests or perform analytical code review.

## Agent Rules

Shared by all three role agents:

- Follow this protocol for commit/log-event commands, artifact format, and all workflow procedures.
- All output must be in English (artifacts, reviews, code, commit descriptions).
- After completing any task, STOP and wait for the team lead's next instruction.
- When re-invoked for post-completion follow-up, the same role boundaries and QA domain apply.
- Apply the preloaded engineering policies (`workaholic:design`, `workaholic:implementation`, `workaholic:operation`) — ensure artifacts, implementation, and testing respect the team's policies, practices, and standards across all domains. Before coding, open every policy hard copy recorded in the design artifact's **Policies** section (`policies/<slug>.md`) and judge your work against each one's Goal (目標), Responsibility (責務), and Practices (実践).
- Never modify another agent's artifact.

Role-specific:

- **Constructor only**: Run `workaholic:system-safety` detection (`${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh`) before any implementation that may touch system configuration. (See the System Safety section above.)

## Engineering Policies (Soft Preload)

The trip protocol soft-depends on the project's engineering policy indexes. Callers (commands or agents) that participate in a trip preload them so the protocol's planning, design, implementation, review, and testing all respect its policies:

- `workaholic:design`
- `workaholic:implementation`
- `workaholic:operation`

## Trip Command Procedure

Procedural body for `/trip` (executed from the work-side command via this preloaded skill). All script paths use same-plugin form because they resolve from this skill's owning plugin (workaholic).

**Project label in interactive prompts.** In normal mode, prefix the `question` body of each interactive prompt (`AskUserQuestion`) this procedure issues — worktree setup selection, copy-back, ship-worktree selection, drive-vs-trip routing — with `[<project label>]` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` (run once, reuse its `project` value), so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label. Night mode issues no `AskUserQuestion`, so this does not apply there.

**Determine mode from `$ARGUMENT`**: if it contains the `night` token (e.g. "go night /trip …", "/trip night …"), mode = "night" — **strip** the `night` token so the remainder is the trip instruction, and apply the **Night Mode** subsection's overrides to Steps 1, 4, and 5 (unattended, no developer questions). Otherwise mode = "normal" and the steps run interactively as written.

**Summary mode (read-only)** — if the (night-stripped) `$ARGUMENT` is exactly `summary`, do **not** determine execution mode or launch a team. Run the trip summary and stop:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/summary.sh
```

It emits `{"trips": [...], "queue": [...]}`: each trip under `.workaholic/trips/` with its plan `phase`/`step`/`instruction`/`blocked` (via `read-plan.sh`), followed by the current user's todo-queue snapshot a `/trip` would execute (via `drive/list-todo.sh`). Present each trip as one line — `name` — `phase/step` (note `blocked` when set) — and then the queued ticket count/paths. This reports only; it creates no worktree, branch, or artifact. Bare `/trip` (no argument) keeps its context-aware queue-execute behavior below.

**Determine execution mode (design-first vs queue-execute)** — `/trip` is context-aware, like `/report` and `/ship`. After the Pre-check, list the current todo queue:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-todo.sh
```

Route by the (night-stripped) instruction and the queue:

- **Instruction present** → `design-first` (default, unchanged): Planning → Decomposition → Coding. The instruction seeds the trip; the Decomposition gate fills the queue. Steps 1–5 run as written.
- **No instruction + non-empty queue** → `queue-execute`: the trip drives the **existing** queue with three-agent QA — **no** Planning, **no** Decomposition (the tickets are the spec). This is the `ticket → trip` direction. It modifies the steps below: **Step 1** uses the **current branch / working dir** (the tickets live here — do NOT create a new, empty worktree); **Step 2** initializes only a trip session record (`plan.md` + `event-log.md`, no design artifacts) with the `plan.md` step set to `coding/concurrent-launch`; **Step 4** launches the team with the **queue-execute team-lead instruction** (below); the team share-reads the queue and runs the Coding Phase Per-Ticket Drive Loop.
- **No instruction + empty queue** → nothing to do: tell the user to run `/ticket` first or pass an instruction, then stop.

For `design-first` with a non-empty queue, the instruction wins (design-first runs); the Coding loop then drives the full resulting queue, including any pre-existing tickets. Use a fresh worktree to keep an existing queue separate (already the night/default).

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

**Night mode** overrides this entire step (see the Night Mode subsection): present no `AskUserQuestion`. Default to a **new isolated worktree** for the (night-stripped) instruction — run `create.sh`, then `adopt-worktree.sh "<branch>"`, set `<working_dir>` to its `worktree_path`. Never auto-resume an existing worktree. Log the auto-selected default via `log-event.sh`, then continue to Step 2.

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
> 1. **Planner** (`workaholic:planner`) - Business vision, E2E testing
> 2. **Architect** (`workaholic:architect`) - Structural bridge, analytical review
> 3. **Constructor** (`workaholic:constructor`) - Technical implementation, internal testing
>
> All agents work inside `<working_dir>`. Follow trip-protocol for the Planning Phase (concurrent artifacts, one-turn review, respond/escalate, moderate) and Coding Phase (concurrent launch, review & testing, iteration). **When the plan is fixed and the Decomposition gate has written all tickets, proceed directly into the Coding Phase — do NOT pause to present the design for developer approval or wait for a green-light.** The review / moderation / convergence machinery is the design gate; the per-ticket three-agent QA is the build gate; the developer reviews the finished branch afterward via `/report`. Insert a pre-build developer checkpoint only if the user explicitly asked for one. All agents have the team's **engineering policies** (`workaholic:design`, `workaholic:implementation`, `workaholic:operation`) preloaded — ensure all planning, design, implementation, and testing respects those policies, practices, and standards. Enforce convergence cap: max 3 review rounds before forced moderation. Use `trip-commit.sh` and `log-event.sh` for every step (including a `decomposition` event and a phase-transition event at the Planning→Coding handoff, so the autonomous handoff stays explainable for morning review). Update `plan.md` at phase transitions. If resuming, skip completed steps.
>
> Language policy: All agent output must be English.
>
> **Post-completion rule**: After the trip reaches `complete/done`, if the user sends follow-up requests: handle simple tasks directly (reading, answering, small edits). For substantial work, re-invoke ONLY the three designated teammates (Planner, Architect, Constructor) -- never create new agent team members. The designated agents retain their original roles and constraints.

**Night mode**: append the **Team-lead night directive** (see the Night Mode subsection) to the instruction above before launching, so the team *additionally* auto-resolves setup, safe-parks on unrecoverable blockers, and emits a morning report. The design→build flow-through is already the default above; night mode adds only the *setup* and *failure-handling* autonomy on top. The normal-mode instruction is otherwise unchanged.

**Queue-execute mode**: replace the "Follow trip-protocol for the Planning Phase … and Coding Phase" sentence with this directive (the rest of the instruction — teammates, policies, language, post-completion rule — is unchanged):

> **QUEUE-EXECUTE — no design phase.** The todo queue already holds the tickets to build (`.workaholic/tickets/todo/<user>/`); they are the spec. Skip the Planning Phase, the Consensus/Convergence gate, and the Decomposition gate entirely. First, all three teammates **share-read** the queued tickets (and any Trip Origin links). Then run the **Coding Phase Per-Ticket Drive Loop** over the queue in `depends_on` then severity order: per ticket, Constructor implements (reading its `## Policies`) + internal tests → Architect reviews → Planner E2E → archive via `drive/archive.sh`. The three-agent QA is the per-ticket gate. Rollback to add a design pass is available only if the queue proves underspecified.

### Step 5: Present Results

**Night mode**: replace this interactive presentation with the **morning-review report** (see the Night Mode subsection).

After the team completes:
1. List all artifacts in the trip path
2. Summarize the agreed direction, model, and design
3. Report implementation results
4. Show the trip branch name
5. Transition guidance: "Use `/report` and `/ship` when ready to merge."
6. Continuation guidance: "For follow-up modifications, request changes directly -- the lead will handle simple tasks or re-invoke the designated agents (Planner, Architect, Constructor). No new agents are created."

### Night Mode (mode = "night")

Autonomous, unattended overnight `/trip`, triggered when `$ARGUMENT` contains "night" (e.g. "go night /trip <instruction>"). The Agent Team judges everything itself. Like every design-first trip it flows from the fixed design straight into the build with no developer green-light (that is the default — see Workflow Overview); night mode *additionally* removes the remaining interactive points — the Step 1 setup question and the Step 5 results presentation — and adds a safe-park failure policy and a morning-review report. Night mode overrides Steps 1, 4, and 5 above.

**1. Authorization is the `/trip night` invocation itself — zero developer questions.** Invoking `/trip night <instruction>` authorizes the entire unattended run. Night Trip asks the developer **nothing** at any point (stricter than night `/drive`, which permits one group question) — the trip-protocol's own review / moderation / convergence machinery is what makes self-judgment safe. The `night` token is stripped from `$ARGUMENT`; the remainder is the trip instruction.

**2. Auto-resolved setup (Step 1).** Skip every `AskUserQuestion`. Default to a **new isolated worktree** for the instruction (`create.sh` → `adopt-worktree.sh`); never auto-resume an existing worktree (resuming is an interactive decision). Log the auto-selected default via `log-event.sh`.

**3. Autonomous session (Step 4).** Append the Team-lead night directive (below) to the Step 4 instruction. The lead and teammates run Planning → Coding → Completion judging everything themselves: every disagreement resolves through the existing one-turn review, respond/escalate, moderation, and the 3-round convergence cap with forced moderation (and 2/3-majority rollback) — never escalated to the developer. For an ambiguous instruction, the Planner makes the most reasonable interpretation and **records the assumptions** in `directions/direction-v1.md` and `plan.md` rather than asking.

**4. Attempt-first safe-park policy (no human present).** Carry every phase as far as it can go before any park — a **phase's size, complexity, or "all-or-nothing" scope is never a park reason; attempt the work in full first.** Park only when a phase genuinely cannot complete **after a real attempt**: a dev-env that stays broken after attempting the fix, or a blocking external dependency (a missing credential, an unreachable external service). For an ambiguous requirement, do **not** park — make the most reasonable interpretation and record the assumptions (§3); reserve a park for a genuinely contradictory/irreducible requirement. When a park is warranted, **record the blocker** as a "Night Park" amendment in `plan.md` and an event in `event-log.md`, and **park at the furthest safe state**. NEVER halt waiting for a human, NEVER run destructive git (`git reset --hard` / `git clean` / `git restore .`), and NEVER create new agents. The convergence cap guarantees Planning terminates; the safe-park rule guarantees the run never wedges.

**5. Bounded run.** Night mode runs the single instruction fixed at invocation through to `complete/done` (or a recorded park). It does not expand scope mid-run.

**Team-lead night directive** (append to the Step 4 instruction in night mode):

> **NIGHT MODE — run unattended.** Never pause to ask the developer a question. **Attempt every part of the work in full — a phase's size, complexity, or all-or-nothing scope is never a reason to park.** Resolve every disagreement through the trip-protocol review / moderation / convergence-cap mechanisms; for ambiguous requirements, make and record reasonable assumptions in the direction artifact and `plan.md` rather than parking. Park only when something genuinely cannot be completed after a real attempt (a dev-env that stays broken after attempting the fix, or a blocking external dependency): record the blocker in `plan.md` (a "Night Park" amendment) and `event-log.md` and park gracefully at the furthest safe state — do not wait for a human, do not run destructive git, do not create new agents.

**Morning-review report (replaces Step 5's interactive presentation).** At the end, emit a complete, skimmable stdout report for morning review: phases completed; the agreed direction / model / design; implementation and internal/E2E test results; any forced-convergence entries, recorded assumptions, and parked blockers (with where to find them); the trip branch / worktree path; and next steps (`/report`, `/ship`). This is the deliverable the developer reviews in the morning.

## Trip Ship

Trips run in isolated git worktrees, so shipping a trip adds worktree lifecycle handling around the trip-independent ship essence (`workaholic:ship`). This section is Claude-Code-only (worktrees are a trip mechanism); it wraps `workaholic:ship`'s **Ship Flow** with worktree sync and cleanup. The `/ship` command routes here when it detects a worktree/trip context.

### Worktree gitignored-file handling

The create side is symmetric: `ensure-worktree.sh` copies the root git-ignored `.env` (the single credential source) into a new worktree, and a pre-existing worktree may need a manual `cp <repo-root>/.env .env` (see the Credentials section of `workaholic:branching`). Cleanup preserves it back:

Before cleaning up a worktree, preserve any gitignored files (e.g. `.env`, local config) that exist only in or differ in the worktree:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/find-gitignored-files.sh "<worktree-path>"
```

Excludes reinstallable directories (`node_modules/`, `.venv/`, `vendor/bundle/`, `.cache/`, `__pycache__/`) and files over 1MB. Returns `{"has_changes": true, "files": [{"path": ".env", "status": "modified", "size": "1KB"}]}` (`status` is `new` or `modified`).

If `has_changes` is `true`, display the file list and ask the user via AskUserQuestion: **"Copy all to main worktree"** or **"Skip and erase"**. If "Copy all":

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/sync-gitignored-files.sh "<worktree-path>" "<main-repo-root>" '<files-json>'
```

### Trip Ship flow

1. **Sync gitignored files** (above) from `.worktrees/<branch>/` to the main repo root.
2. **Run the ship essence**: follow `workaholic:ship`'s **Ship Flow** for the worktree's branch/PR. The merge is the **LAST** step, gated on a passing pre-merge production confirmation: pre-check → catch up with `main` → deploy (gated on a `.workaholic/deployments/` confirmation method or `CLAUDE.md` `## Verify`; halt-and-ask if none) → execute the confirmation and record evidence → **merge LAST** → publish release / extract deferred concerns. A failed confirmation leaves the PR unmerged (that is the rollback).
3. **Reset or clean up the worktree**:
   - **Mission worktree** — a `.worktrees/<slug>/` worktree with a descriptive slug directory (`list-all-worktrees.sh` tags it `"type": "mission"`) is **persistent**: it is removed only at `/mission close`, never on a merge. Instead of deleting it, **reset** it for the mission's next batch — cut a fresh `work-*` branch off `main` inside the same worktree:
     ```bash
     bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reset-mission-worktree.sh "<slug>"
     ```
   - **Ordinary drive/trip worktree** (a `work-*`-named `.worktrees/<branch>/`) — clean it up as before: `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"`.
4. **Summarize**: include gitignored sync status and whether the worktree was **reset** (mission) or **cleaned up** (ordinary) alongside the ship essence's summary.

### Context routing (used by the /ship command)

- **work context**: not a trip — run `workaholic:ship`'s Ship Flow directly. No worktree handling.
- **worktree context** (not on a work branch, worktrees exist): run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh`, filter to `has_pr: true`, ask the user which shippable worktree to ship via AskUserQuestion, then run the Trip Ship flow for it.
- **unknown context**: ask the user "drive or trip?" via AskUserQuestion; route to the Ship Flow (drive) or Trip Ship flow (trip) accordingly.
