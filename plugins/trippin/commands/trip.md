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

### Step 1: Create Worktree

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

### Step 3: Launch Agent Teams

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
> 1. **Planner** (Progressive) - Responsible for creative direction, stakeholder profiling, and explanatory accountability. Writes direction artifacts to `<trip_path>/directions/`.
> 2. **Architect** (Neutral) - Responsible for semantical consistency, static verification, and accessibility. Writes model artifacts to `<trip_path>/models/`.
> 3. **Constructor** (Conservative) - Responsible for sustainable implementation, infrastructure reliability, and delivery coordination. Writes design artifacts to `<trip_path>/designs/`.
>
> **All agents work inside the worktree at `<worktree_path>`.**
>
> **Commit rule**: Every discrete step produces a git commit. After writing or updating any artifact, run:
> ```
> bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh <agent> <phase> "<step>" "<description>"
> ```
> The `<description>` is **mandatory** and must be a clear English sentence summarizing what was accomplished (e.g., "Define user authentication flow and stakeholder priorities"). Do NOT use file names or terse labels as descriptions. The commit message format is: `[Agent] <description>`.
>
> **Phase 1 - Specification (Inner Loop)**:
> 1. Ask Planner to write `directions/direction-v1.md` based on the user instruction → **commit**
> 2. Ask Architect to review the direction and write `directions/reviews/direction-v1-architect.md` → **commit**
> 3. Ask Constructor to review the direction and write `directions/reviews/direction-v1-constructor.md` → **commit**
> 4. **WAIT FOR ALL REVIEWS** — do NOT proceed until both Architect and Constructor have completed their reviews
> 5. If disagreements arise, the third agent moderates and writes resolution → **commit**
> 6. Iterate revisions until all three approve the direction → **commit each revision**
> 7. **GATE: Direction approved** — only after all three agents approve, proceed to Model and Design
> 8. Ask Architect to write `models/model-v1.md` → **commit** → **WAIT** for model to be complete
> 9. After the model is complete, ask Constructor to READ the model, then write `designs/design-v1.md` based on BOTH the direction AND the model → **commit** → **WAIT** for design to be complete
> 10. Each agent reviews the other's artifact by writing to `reviews/` subdirectories (e.g., `designs/reviews/design-v1-architect.md`) → **commit each review**
> 12. **WAIT FOR ALL CROSS-REVIEWS** — do NOT proceed until all reviews are complete
> 13. Iterate until full consensus on direction, model, and design → **commit each revision**
>
> **Phase 2 - Implementation (Outer Loop)**:
> 1. Ask Planner to create a test plan → **commit**
> 2. Ask Constructor to implement the program → **commit**
> 3. Ask Architect to review structural integrity → **commit**
> 4. Ask Planner to validate through testing → **commit**
> 5. Iterate until all agents approve → **commit each iteration**
>
> **Artifact format**: Each artifact uses the structure defined in the trip-protocol skill (title, author, status, reviewed-by, content, review notes).
>
> **Communication**: Agents communicate by reading and writing markdown files in the trip path. After writing an artifact, commit it, then notify the relevant agent(s) to review it.

### Step 4: Present Results

After the team completes:
1. List all artifacts created in `<trip_path>/`
2. Summarize the agreed direction, model, and design
3. Report any implementation results from Phase 2
4. Show the worktree branch name for the user to merge or inspect
