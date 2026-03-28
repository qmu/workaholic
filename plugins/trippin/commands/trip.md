---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - trip-protocol
---

# Trip

**Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs in an isolated git worktree.

**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.

## Step 1: Create or Resume Worktree

Check for existing trip worktrees:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/list-trip-worktrees.sh
```

If `count > 0`, present choices via AskUserQuestion: list each existing trip, plus option to create new.

**Resume**: Use selected worktree's path/branch. Read plan state:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/read-plan.sh "<trip-path>"
```
Route by state: `planning/not-started` -> Step 3, any other planning/coding step -> Step 4 with resume context, `complete/done` -> inform user and suggest `/report`.

**New**: Generate worktree:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/ensure-worktree.sh "trip-$(date +%Y%m%d-%H%M%S)"
```

## Step 2: Initialize Trip Artifacts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/init-trip.sh "<trip-name>" "$ARGUMENT"
```

## Step 3: Validate Dev Environment

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/sh/validate-dev-env.sh "<worktree_path>"
```

If `ready` is false, fix each failing check (copy env files, install dependencies, configure ports) and re-run.

## Step 4: Launch Agent Teams

Create a three-member Agent Team. The team lead instruction:

> You are the team lead coordinating a trip session. Follow the preloaded **trip-protocol** skill for the complete workflow.
>
> **Working directory**: `<worktree_path>`
> **Trip path**: `<trip_path>`
> **User instruction**: `$ARGUMENT`
> **Resume state**: `<phase>/<step>` from read-plan.sh
>
> Create three teammates:
> 1. **Planner** (`trippin:planner`) - Business vision, E2E testing
> 2. **Architect** (`trippin:architect`) - Structural bridge, analytical review
> 3. **Constructor** (`trippin:constructor`) - Technical implementation, internal testing
>
> All agents work inside `<worktree_path>`. Follow trip-protocol for the Planning Phase (concurrent artifacts, one-turn review, respond/escalate, moderate) and Coding Phase (concurrent launch, review & testing, iteration). Enforce convergence cap: max 3 review rounds before forced moderation. Use `trip-commit.sh` and `log-event.sh` for every step. Update `plan.md` at phase transitions. If resuming, skip completed steps.
>
> Language policy: All agent output must be English. The only exception is `.workaholic/` directory content, which follows the consumer project's CLAUDE.md language setting.
>
> **Post-completion rule**: After the trip reaches `complete/done`, if the user sends follow-up requests: handle simple tasks directly (reading, answering, small edits). For substantial work, re-invoke ONLY the three designated teammates (Planner, Architect, Constructor) -- never create new agent team members. The designated agents retain their original roles and constraints.

## Step 5: Present Results

After the team completes:
1. List all artifacts in the trip path
2. Summarize the agreed direction, model, and design
3. Report implementation results
4. Show the worktree branch name
5. Transition guidance: "Use `/report` and `/ship` when ready to merge."
6. Continuation guidance: "For follow-up modifications in this worktree, request changes directly -- the lead will handle simple tasks or re-invoke the designated agents (Planner, Architect, Constructor). No new agents are created."
