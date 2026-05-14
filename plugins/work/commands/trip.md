---
name: trip
description: Launch Agent Teams session with Planner, Architect, and Constructor
skills:
  - core:trip-protocol
---

# Trip

**Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.

Launch an Agent Teams session to collaboratively explore and develop a concept through the Implosive Structure workflow. The session runs either in an isolated git worktree or on a trip branch in the main working tree.

**Prerequisites**: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), clean git state.

## Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop.

## Step 1: Create or Resume Trip

Check for existing worktrees:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/list-worktrees.sh
```

If `count > 0`, present choices via AskUserQuestion: list each existing worktree, plus option to create new.

**Resume (worktree)**: Use selected worktree's path/branch. Read plan state:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/read-plan.sh "<trip-path>"
```
Route by state: `planning/not-started` -> Step 3, any other planning/coding step -> Step 4 with resume context, `complete/done` -> inform user and suggest `/report`.

**New**: Present a choice via AskUserQuestion:
- **"Create worktree"** - Isolated environment. Run:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh
  ```
  Parse JSON to get `branch`. Then create worktree from it:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/adopt-worktree.sh "<branch>"
  ```
  Set `<working_dir>` to the `worktree_path` from the output.
- **"Branch only"** - Lightweight, no worktree. Run:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/create.sh
  ```
  Set `<working_dir>` to the repository root.

## Step 2: Initialize Trip Artifacts

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/init-trip.sh "<trip-name>" "$ARGUMENT" "<working_dir>"
```

## Step 3: Validate Dev Environment

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/trip-protocol/scripts/validate-dev-env.sh "<working_dir>"
```

If `ready` is false, fix each failing check (copy env files, install dependencies, configure ports) and re-run.

## Step 4: Launch Agent Teams

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

## Step 5: Present Results

After the team completes:
1. List all artifacts in the trip path
2. Summarize the agreed direction, model, and design
3. Report implementation results
4. Show the trip branch name
5. Transition guidance: "Use `/report` and `/ship` when ready to merge."
6. Continuation guidance: "For follow-up modifications, request changes directly -- the lead will handle simple tasks or re-invoke the designated agents (Planner, Architect, Constructor). No new agents are created."
