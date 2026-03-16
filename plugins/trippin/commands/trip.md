---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - trip-protocol
---

# Trip

**Notice:** When user input contains `/trip` - whether "run /trip", "start /trip", "take a /trip", or similar - they likely want this command.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs in an isolated git worktree.

**Prerequisites**:
- Agent Teams must be enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings
- Repository must be in a clean git state (worktree creation requires it)

## Instructions

### Step 1: Create or Resume Worktree

First, check for existing trip worktrees:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/list-trip-worktrees.sh
```

Parse the JSON output. If `count` is greater than 0, present the user with a choice using AskUserQuestion:

- List each existing worktree: "Active trips: `<trip_name>` (branch: `<branch>`)" for each entry
- Include an option to create a new trip session
- Ask: "Would you like to resume an existing trip or start a new one?"

**If the user chooses to resume an existing worktree:**
- Use the selected worktree's `worktree_path`, `branch`, and `trip_name`
- Skip the `ensure-worktree.sh` call
- Check if `.workaholic/.trips/<trip_name>/` exists inside the worktree:
  - If it exists: skip Step 2 and proceed to Step 3 (Validate and Prepare Dev Environment)
  - If it does not exist: proceed to Step 2 to initialize artifacts

**If the user chooses to create a new trip (or no worktrees exist):**

Generate a trip name and create an isolated worktree:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh "trip-$(date +%Y%m%d-%H%M%S)"
```

Parse the JSON output for `worktree_path` and `branch`. If an error is returned, inform the user and stop. Common errors:
- "not inside a git repository" — cannot proceed
- "worktree already exists" — a trip with this name is already active
- "branch already exists" — clean up the stale branch first

### Step 2: Initialize Trip Artifacts

Inside the worktree, create the artifact directory structure:

```bash
cd <worktree_path> && bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/init-trip.sh "<trip-name>"
```

Parse the JSON output for `trip_path`. If an error is returned, inform the user and stop.

### Step 3: Validate and Prepare Dev Environment

Validate the development environment inside the worktree:

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh "<worktree_path>"
```

Parse the JSON output. If `ready` is false, take corrective action for each failing check:
- `env_files` missing: Copy `.env` files from the repository root to the worktree
- `dependencies` missing: Run the appropriate install command inside the worktree (e.g., `cd <worktree_path> && npm install`)
- `ports` conflict: Modify port values in the worktree's environment files to avoid conflicts with other running worktrees

After corrections, re-run validation. Repeat until `ready` is true.

If validation cannot be resolved (e.g., no `.env` file exists anywhere to copy), warn the user and proceed with the caveat that Coding Phase implementation may encounter environment issues.

### Step 4: Launch Agent Teams

Create a three-member Agent Team with the following instruction:

> You are the team lead coordinating a trip session using the Implosive Structure protocol.
>
> **CRITICAL: You are the sole workflow coordinator. No agent may autonomously advance to the next step. After assigning a task to an agent, wait for its completion before issuing the next task. After assigning reviews to multiple agents, wait for ALL reviews to complete before advancing.**
>
> **Working directory**: `<worktree_path>`
> **Trip path**: `<trip_path from step 2>`
> **User instruction**: `$ARGUMENT`
>
> Create three teammates:
> 1. **Planner** (Progressive) - Represents the business vision side: business phenomena, stakeholder advocacy, and explanatory accountability. Evaluates from the perspective of business outcomes and stakeholder value. Does NOT set technical direction. Does NOT explore the codebase -- codebase discovery is the Architect's responsibility. Writes Direction artifacts based on business analysis of the user instruction to `<trip_path>/directions/`.
> 2. **Architect** (Neutral) - Represents the structural bridge between business vision and technical implementation: system coherence, translation fidelity, and boundary integrity. Evaluates whether business intent is faithfully represented in technical structure. Writes model artifacts to `<trip_path>/models/`.
> 3. **Constructor** (Conservative) - Represents technical accountability: engineering quality, quality assurance, and delivery ownership. Evaluates from the perspective of technical excellence and production readiness. Owns the technical approach. Writes design artifacts to `<trip_path>/designs/`.
>
> **All agents work inside the worktree at `<worktree_path>`.**
>
> **Commit rule**: Every discrete step produces a git commit. After writing or updating any artifact, run:
> ```
> bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh <agent> <phase> "<step>" "<description>"
> ```
> The `<description>` is **mandatory** and must be a clear English sentence summarizing what was accomplished (e.g., "Define user authentication flow and stakeholder priorities"). Do NOT use file names or terse labels as descriptions. The commit message format is: `[Agent] <description>`.
>
> **Planning Phase - Specification (Inner Loop)**:
> 1. **Concurrent artifact generation** — ask all three agents to begin writing their artifacts simultaneously:
>    - Ask Planner to write `directions/direction-v1.md` (business vision) → **commit**
>    - Ask Architect to write `models/model-v1.md` (structural translation) → **commit**
>    - Ask Constructor to write `designs/design-v1.md` (technical implementation plan) → **commit**
> 2. **WAIT FOR ALL THREE ARTIFACTS** — do NOT proceed until Planner, Architect, and Constructor have all completed their artifacts
> 3. **Mutual review session** — ask each agent to review the other two agents' artifacts:
>    - Ask Planner to review Model and Design → **commit each review**
>    - Ask Architect to review Direction and Design → **commit each review**
>    - Ask Constructor to review Direction and Model → **commit each review**
> 4. **WAIT FOR ALL SIX REVIEWS** — do NOT proceed until all agents have completed all reviews
> 5. If disagreements arise, the relevant agents revise their artifacts incorporating review feedback → **commit each revision**
> 6. After revisions, repeat mutual review (step 3) until full consensus on all three artifacts → **commit each revision**
> 7. If disagreements between two agents persist, the third agent moderates and writes resolution → **commit**
>
> **Coding Phase - Implementation (Outer Loop)**:
> Quality assurance is split into three orthogonal roles: Constructor owns internal testing (unit tests, compiler checks), Planner owns E2E/external testing (execute CLI, browser via Playwright, API calls), Architect owns analytical review (code review, architectural review, model checking — no test execution).
> 1. **Concurrent launch** — ask all three agents to begin work simultaneously:
>    - Ask Constructor to implement the program and run internal quality checks (compiler/type checks, unit tests, linters) → **commit**
>    - Ask Planner to create a test plan: build the dev environment, verify it is running (Playwright CLI MCP), plan E2E scenarios by examining the target website (Playwright CLI MCP) → **commit**
>    - Ask Architect to discover the codebase and prepare modeling-related artifacts for structural review → **commit**
> 2. **WAIT FOR ALL THREE** — do NOT proceed until Constructor, Planner, and Architect have all completed their concurrent tasks
> 3. Ask Architect to discover the Constructor's changes and perform analytical review: code review, architectural review, and model checking (no test execution) → **commit**
> 4. Ask Planner to validate the implementation through E2E and external interface testing: execute the program as a user would (CLI commands, browser via Playwright, API calls) → **commit**
> 5. Iterate until all agents approve → **commit each iteration**
>
> **Rollback Rule**:
> If any agent proposes a rollback to the Planning Phase during Coding Phase:
> 1. Pause all Coding Phase work
> 2. The proposing agent writes a rollback proposal artifact → **commit**
> 3. Request votes from the other two agents → **commit each vote**
> 4. **WAIT FOR BOTH VOTES** before proceeding
> 5. If 2+ agents support: return to Planning Phase at the specified step, re-run specification loop from that point
> 6. If only 1 supports: continue Coding Phase iteration
>
> **Artifact format**: Each artifact uses the structure defined in the trip-protocol skill (title, author, status, reviewed-by, content, review notes).
>
> **Communication**: Agents communicate by reading and writing markdown files in the trip path. After writing an artifact, commit it, then notify the relevant agent(s) to review it.

### Step 5: Present Results

After the team completes:
1. List all artifacts created in `<trip_path>/`
2. Summarize the agreed direction, model, and design
3. Report any implementation results from Coding Phase
4. Show the worktree branch name for the user to merge or inspect
5. Show transition guidance: "To continue developing this branch with drive-style tickets, create tickets with `/ticket` and implement them with `/drive` from this worktree. When ready, use `/report` and `/ship` to merge."
