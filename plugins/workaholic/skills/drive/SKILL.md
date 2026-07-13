---
name: drive
description: Use when the user runs `/drive`, asks to "implement the queued tickets", "work through the todo list", or "drive the backlog". Reads tickets from `.workaholic/tickets/todo/`, prioritizes them by dependency and severity, implements each one with a per-ticket approval gate, then archives the ticket and commits with a structured message.
skills:
  - commit
  - system-safety
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Drive

Complete drive session skill covering the `/drive` command workflow, ticket navigation and prioritization, per-ticket implementation, approval, reporting, archiving, and frontmatter updates.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent. The two Claude-Code mechanisms used below are **enhancements, not requirements**:

- **Parallel fan-out** — where a step spawns a `general-purpose` subagent (e.g. the ticket prioritizer), that is the Claude Code optimization. On other agents, perform that work **inline/sequentially** in the same session; the inputs and outputs are identical.
- **User interaction** — where a step uses `AskUserQuestion` (order confirmation, per-ticket approval, icebox/abandon choices), use the agent's native way of presenting a multiple-choice question (or ask in plain chat). The decision points are mandatory; only the prompt mechanism varies. Prefix each interactive prompt's (`AskUserQuestion`) `question` body with `[<project label>]` — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## Command Workflow

End-to-end orchestration for `/drive`. The thin `/drive` command preloads this skill and follows this section.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop. Otherwise note the
reported `version`, and if `missing_guards` is non-empty, **warn** the user that a
stale or partial plugin install is loaded (the listed PreToolUse guards are not
registered in this build) before proceeding — do not block on it.

### Phase 0: Worktree Guard

Check if trip worktrees exist before proceeding:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh
```

If `has_worktrees` is `true`, present the user with a choice using `AskUserQuestion` with selectable options:
- **"Continue here"** - Proceed with drive on the current branch
- **"Switch to worktree"** - Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/drive` there

If `has_worktrees` is `false`, proceed silently to Phase 1.

**Rationale**: Prevents accidental development on a drive branch when trip worktrees with in-progress work may be the intended target.

**Trip branch compatibility**: The drive workflow operates on any non-main topic branch, including `trip/*` branches. When running on a trip branch after a trip session completes, tickets are read from `.workaholic/tickets/todo/` and archived normally. Use `/ticket` to add refinement tickets, then `/drive` to implement them.

### Phase 1: Navigate Tickets

The command (main agent) runs the **Navigator** section below. Navigation splits into non-interactive prioritization (delegated to a leaf subagent) and user confirmation (issued by the command), because subagents cannot call AskUserQuestion.

Determine mode from `$ARGUMENT`:
- If `$ARGUMENT` contains "night": mode = "night" (autonomous overnight run — see **Night Mode** below; it overrides the per-ticket approval gate and Phase 3/4)
- If `$ARGUMENT` contains "icebox": mode = "icebox"
- Otherwise: mode = "normal"

**Normal mode:**

0. Sweep stray tickets into per-user subdirectories first, so root-level strays are routed even when `/drive` runs before any `/ticket`:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/create-ticket/scripts/sweep-todo.sh
   ```
   The sweep routes each root-level `todo/*.md` into `todo/<author-slug>/` by the stray's own `author:` frontmatter, git-staging each move (these staged moves ride along into the next archive commit, which runs `git add -A`). It never moves a ticket to the icebox.
1. Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-todo.sh` — it lists only the current user's `todo/<user>/` queue. If it prints nothing, follow the Navigator section's empty-queue handling (offer icebox/stop via `AskUserQuestion`).
2. If todo tickets exist, spawn a `subagent_type: "general-purpose"` subagent (`model: "opus"`) whose prompt instructs it to preload `workaholic:drive`, run the Navigator section's **list / analyze / prioritize** logic (read frontmatter, dependency topo-sort, severity ranking, context grouping), and return the proposed ordered ticket list with tier grouping as JSON. This subagent does NOT call AskUserQuestion.
3. The command presents the prioritized list and confirms the order with the user via `AskUserQuestion` (Navigator section, "Confirm Order with User"), then proceeds to Phase 2 with the resolved order.

**Icebox mode:** the command runs the Navigator section's Icebox Mode steps directly (list via script, select via `AskUserQuestion`, promote via script).

Outcomes:
- No tickets in todo or icebox - Inform user: "No tickets in queue or icebox."
- User chooses to stop - End the drive session
- User chooses icebox - Run icebox mode
- Order confirmed - Proceed to Phase 2 with the ordered ticket list

### Phase 2: Implement Tickets

For each ticket in the ordered list:

#### Step 2.1: Implement Ticket

Follow the **Workflow** section below. Implementation context is preserved in the main conversation, providing full visibility of changes made. Apply the policies, practices, and standards from the relevant preloaded `workaholic:*` policy skill(s) — see the Policy Lens table in the `create-ticket` skill for the layer-to-skill mapping.

#### Step 2.2: Request Approval

Follow the **Approval** section below to present the approval dialog. **CRITICAL**: You MUST use the `title` and `overview` fields from the Step 2.1 workflow result to populate the approval prompt header and question (the `question` body opens with the `[project]` label — see the Approval section). If these fields are unavailable, re-read the ticket file to obtain them. Never present an approval prompt without the ticket title and summary.

**CRITICAL**: Use `AskUserQuestion` with selectable `options`. NEVER proceed without explicit user approval. (In **night mode** this gate is auto-resolved as "Approve" — the user authorized the batch by invoking `/drive night`, optionally narrowed by the §1b group choice; see **Night Mode**.)

#### Step 2.3: Handle User Response

**"Approve" or "Approve and stop"**:
1. Follow the **Final Report** section below to update ticket effort and append the Final Report section
2. **Verify update succeeded**: If Edit tool fails, halt and report the error to user. DO NOT proceed to archive.
3. Archive and commit by calling the archive script directly:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
     <ticket-path> "<title>" <repo-url> "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"
   ```
   Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
   and `<repo-url>` comes from the gather skill's `git-context.sh` output. Map the ticket and your
   Final Report into the body args: `<why>` from the ticket Overview/motivation, `<changes>` from
   what changed for users, `<concerns>` from the ticket Considerations (or "None"), `<insights>`
   from your Discovered Insights (or "None"), `<verify>` from the verification you ran. These keys
   feed `/report` (Motivation / Changes / Concerns / Successful Development Patterns).
   **NEVER manually move tickets** with `mv` + `git add` -- always use the archive script.
4. If "Approve and stop": break loop, skip Phase 3, go directly to Phase 4
5. Otherwise: continue to next ticket

**Free-form feedback** (user selects "Other" and provides text):

> **CRITICAL**: Update the ticket file FIRST. Do NOT re-implement until the ticket reflects the user's feedback.

1. Follow the **Approval** section below (Handle Feedback) — this updates the ticket
2. **Verify** the ticket file was updated (re-read it)
3. Re-implement changes based on the updated ticket
4. Return to Step 2.2

**"Abandon"**:
1. Follow the **Approval** section below (Handle Abandonment)
2. Break loop, skip Phase 3, go directly to Phase 4 (same as "Approve and stop")

### Phase 3: Re-check and Continue

**Night mode skips this phase** — it runs only the batch authorized at session start and does not absorb tickets added during the run (see **Night Mode**). Proceed directly to Phase 4.

After all tickets from the navigator's list are processed:

1. **Re-check todo directory**:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-todo.sh
   ```

2. **If new tickets found**:
   - Inform user: "Found N new ticket(s) added during this session."
   - Re-run Phase 1 navigation (mode = "normal")
   - Continue to Phase 2 with the new ticket list

3. **If no new tickets**:
   - Check icebox (existing behavior from navigator)
   - If user declines icebox or icebox empty, proceed to Phase 4

### Phase 4: Completion

After todo is truly empty (and user declines icebox):
- Summarize what was done across all batches
- List all commits created during the session

**Session-wide tracking**: Maintain counters across multiple navigator batches:
- Total tickets implemented
- Total commits created
- List of all commit hashes

**In night mode**, Phase 4 emits the **whole-night report** to stdout (see **Night Mode** §5): per-ticket outcome from the closed set (implemented / failed / blocked — no "declined" category), commit hashes, failure/blocker reasons, totals reconciled to the authorized batch size, and any stashed partial work — the deliverable the developer reviews in the morning.

### Night Mode (mode = "night")

Autonomous, unattended overnight run for morning review, triggered when `$ARGUMENT` contains "night" (e.g. "go night /drive"). Night mode overrides parts of the normal flow:

**1. Authorization is the `/drive night` invocation itself — no per-ticket checkbox.** Invoking `/drive night` over the queue authorizes an autonomous run of the **whole** prioritized batch (the current user's `todo/<user>/` queue, kept in dependency/priority order). Night mode does **not** present a `multiSelect` checklist asking the developer to tick which tickets to run — that is not what "night drive" means. The full prioritized list IS the night's batch.

**1b. One question only on distinct topic groups.** The single exception: if the prioritizer's `groups` field (see Navigator → Determine Priority Order) reports the queued tickets span **two or more clearly distinct topic groups**, the command issues exactly **one** `AskUserQuestion` (selectable options, never a per-ticket checklist) — while working on Group A, should Group B (and any further groups) be included too? The chosen groups, in dependency/priority order, become the night's batch. If the queue forms a single cohesive group, **no question is asked** and the whole batch runs. The heuristic is conservative (prefer one group when in doubt), so a cohesive queue never triggers a prompt.

**2. Autonomous loop (skip the per-ticket gate).** For each authorized ticket, run Step 2.1 (implement, including the type-check/test verification). Then **auto-approve without issuing the Step 2.2 `AskUserQuestion`**: update effort, append Final Report, run `archive.sh`, commit, continue. The per-ticket approval is satisfied by the `/drive night` batch authorization (§1, optionally narrowed by the §1b group choice), so it is *skipped*, not invoked (the Workflow "NEVER use AskUserQuestion" boundary stays intact).

**3. Attempt every ticket — skip only on a demonstrated failure or a named hard blocker.** Every authorized ticket **must be attempted** (run Step 2.1 in full). A ticket's **size, complexity, "all-or-nothing" scope, and "this looks like it needs a human" are NOT skip reasons** — a large or all-or-nothing ticket is implemented in full, then verified; you do not get to decline it because it looks big. A skip is legitimate in exactly two cases, and **only after a real attempt**:
- **Failed** — the ticket was implemented but its type-check/tests are red (or its frontmatter update fails). Record it as `failed` with the reason for the night report.
- **Blocked** — implementation is stopped by a **named hard external blocker** (a missing credential, an unreachable external service or dependency). Record the specific blocker and what would unblock it. A vague "too complex" or "any other reason" is **not** a blocker.

In either case, apply the safety floor and continue to the next authorized ticket (this floor is unchanged — only the *entry condition to skipping* is tightened):
- **Isolate partial changes** so a failed ticket's uncommitted work cannot contaminate the next ticket's commit: `git stash` the failed ticket's changes (recoverable; only `git stash drop` is prohibited) before continuing, and note the stash in the report.
- Leave the ticket in `todo`; a failing type-check/test means **failed → skipped + recorded**, never force-committed.
- **NEVER** auto-move it to icebox, auto-abandon it, or run destructive git (`git restore .` / `git clean` / `git reset --hard` / `git stash drop`) — those require a human.

**4. Bounded run.** Night mode runs ONLY the batch fixed at session start (the whole prioritized queue, or the groups chosen in §1b). Do NOT pick up tickets added during the run (skip Phase 3's re-check). The run terminates when the authorized batch is exhausted.

**5. Whole-night report (the deliverable).** At the end (Phase 4), print a complete, skimmable stdout report for morning review. Every authorized ticket appears as exactly one of a **closed set of three outcomes** — there is **no** "declined / did not force / too large / needs a human" category:
- **implemented** — commit hash.
- **failed** — attempted, but its checks/tests went red; reason + stash location.
- **blocked** — a **named** hard external blocker; what would unblock it.
- Totals: implemented / failed / blocked counts, which **must reconcile to the authorized batch size**, plus all commit hashes.
- Any stashed partial work and where to find it.

**Critical Rule exception (scoped).** Night mode is the ONLY mode that skips the per-ticket "explicit user approval" gate — and only because invoking `/drive night` is itself the explicit authorization for the batch (optionally narrowed by the §1b group choice). Every other Critical Rule below remains in force.

### Critical Rules

**NEVER autonomously move tickets to icebox.** Moving tickets is a developer decision, not an AI decision.

If a ticket cannot be implemented **after a genuine attempt** — its type-check/tests fail, or a **named** hard external blocker (missing credential, unreachable external service/dependency) stops it. A ticket's size, complexity, or "all-or-nothing" scope is **never** a reason to not attempt it:

1. **Stop and ask the developer** using `AskUserQuestion` with selectable `options` — **except in night mode**, which is unattended and follows the attempt-first policy in **Night Mode** §3 (attempt every ticket; on a demonstrated failure or named hard blocker, stash + record + continue); never auto-icebox or use destructive git.
2. Explain why implementation cannot proceed
3. Use selectable options (NEVER open-ended text questions):
   - "Move to icebox" - Move ticket to `.workaholic/tickets/icebox/` and continue to next
   - "Skip for now" - Leave ticket in queue, move to next ticket
   - "Abort drive" - Stop the drive session entirely

**Never commit ticket moves without explicit developer approval.**

## Navigator

Navigate tickets for the `/drive` command: list, analyze, prioritize, and confirm execution order. Responsibilities split across two contexts because subagents cannot call AskUserQuestion:

- **Prioritization (leaf `general-purpose` subagent, or inline at command level)** — the non-interactive logic: list todo tickets, read frontmatter, build the dependency graph and topologically sort it, apply severity ranking and context grouping, and return the proposed ordered ticket list with tier grouping as JSON. This runs with `workaholic:drive` preloaded and issues NO AskUserQuestion.
- **User interaction (command / main agent only)** — every `AskUserQuestion`: the order-confirmation dialog, the empty-queue "work on icebox / stop" choice, and the icebox ticket selection. The command spawns the prioritizer subagent, then presents its result for confirmation.

The recommended flow is: command spawns the prioritizer subagent → subagent returns the ordered list JSON → command presents it and confirms via AskUserQuestion → command resolves the final order.

### Input

The prioritizer receives:

- `mode`: Either "normal" or "icebox"

### Icebox Mode (mode = "icebox")

Run by the command (main agent), since steps 3–4 need AskUserQuestion:

1. List icebox tickets:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-icebox.sh
   ```
2. If no tickets, inform the user the icebox is empty and stop.
3. If tickets found, use `AskUserQuestion` with selectable options listing each ticket.
4. Promote the selected ticket to todo (moves the file and stages both paths):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/promote-icebox.sh <selected-icebox-path>
   ```
5. Proceed to Phase 2 with the promoted ticket.

### Normal Mode (mode = "normal")

#### 1. List and Analyze Tickets

List all tickets in the todo queue:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-todo.sh
```

**If no tickets found** (handled by the command, since it needs AskUserQuestion):

1. Check whether the icebox has tickets:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/list-icebox.sh
   ```
2. If the icebox has tickets, the command uses `AskUserQuestion` with selectable options:
   - "Work on icebox" - Run icebox mode
   - "Stop" - End the drive session
3. If the icebox is also empty, inform the user: "No tickets in queue or icebox."

**If tickets found** (prioritizer logic — no AskUserQuestion):

For each ticket, read and extract YAML frontmatter to get:
- `type`: bugfix > enhancement > refactoring > housekeeping (priority ranking)
- `layer`: Group related layers for context efficiency
- `depends_on`: List of ticket filenames this ticket depends on (optional)

#### 2. Determine Priority Order

Consider these factors (in order of precedence):

1. **Dependency ordering**: Build a dependency graph from `depends_on` fields and perform topological sort. Tickets with no dependencies come first, then tickets whose dependencies are satisfied. If a cycle is detected, warn in the output and fall back to type-based priority for the cycled tickets.
2. **Severity**: Within the same dependency tier, bugfixes take precedence over enhancements
3. **Context grouping**: Process tickets affecting same layer/files together
4. **Implicit dependencies**: If ticket A modifies files that ticket B reads, process A first

Handle missing metadata gracefully - default to normal priority when fields are absent. Treat empty or missing `depends_on` as no dependencies.

Priority ranking by type (used within same dependency tier):
1. `bugfix` - High priority
2. `enhancement` - Normal priority
3. `refactoring` - Normal priority
4. `housekeeping` - Low priority

#### 2b. Detect Topic Groups (for night mode's group question)

Cluster the queued tickets into **topic groups** so night mode can decide whether to ask its one group-inclusion question (Night Mode §1b). A topic group is a set of tickets that belong together; clearly unrelated clusters are separate groups.

Derive groups from signals already read above, in this order:

1. **Dependency components** — tickets connected (directly or transitively) through `depends_on` belong to the same group.
2. **Shared layer / key files** — tickets in the same `layer` or touching overlapping Key Files reinforce membership in one group.

Be **conservative: prefer a single group when in doubt.** Only split into separate groups when clusters are clearly unrelated (disjoint dependency components AND non-overlapping layers/files). The goal is to avoid prompting on a cohesive queue — a single group means night mode asks nothing. Label each group by its dominant theme (e.g. its shared layer or a short phrase from the tickets' titles).

#### 3. Present Prioritized List

Show tickets grouped by priority tier:

```
Found 4 tickets to implement:

**High Priority (bugfix)**
1. 20260131-fix-login-error.md

**Normal Priority (enhancement)**
2. 20260131-add-dark-mode.md [layer: UX]
3. 20260131-add-api-endpoint.md [layer: Infrastructure]

**Low Priority (housekeeping)**
4. 20260131-cleanup-unused-imports.md [depends on: 20260131-add-api-endpoint.md]

Proposed order considers dependencies, severity, and context grouping.
```

#### 4. Confirm Order with User

**Runs at command level** (the prioritizer subagent returns the proposed order; the command presents it). **ALWAYS use `AskUserQuestion` with selectable `options` parameter. NEVER ask open-ended text questions.**

Use selectable options:
- **Proceed** - Execute in proposed order
- **Pick one** - Let user select a specific ticket to start with
- **Original order** - Use chronological/alphabetical order instead

If user selects "Pick one", present a follow-up question with each ticket as an option.

### Prioritizer Output

The prioritizer subagent returns a JSON object with the proposed order (steps 1–3); the command then runs the step-4 confirmation:

```json
{
  "tickets": [
    ".workaholic/tickets/todo/20260131-fix-login-error.md",
    ".workaholic/tickets/todo/20260131-add-dark-mode.md"
  ],
  "tiers": {
    "high": [".workaholic/tickets/todo/20260131-fix-login-error.md"],
    "normal": [".workaholic/tickets/todo/20260131-add-dark-mode.md"],
    "low": []
  },
  "groups": [
    {"label": "auth", "tickets": [".workaholic/tickets/todo/20260131-fix-login-error.md"]},
    {"label": "UX / dark mode", "tickets": [".workaholic/tickets/todo/20260131-add-dark-mode.md"]}
  ],
  "cycle_warning": null
}
```

`tickets` is the proposed ordered list; `tiers` groups them by severity for the display; `groups` is the topic-group clustering from step 2b (one entry when the queue is cohesive — the common case); `cycle_warning` is a message string if a dependency cycle was detected, otherwise null. In **normal mode** the command resolves the final order after the step-4 confirmation. In **night mode** the command uses `groups`: one entry → run the whole batch with no question; two or more → issue the single §1b group-inclusion `AskUserQuestion`. Then it proceeds to Phase 2.

## Workflow

Step-by-step workflow for implementing a single ticket during `/drive`. This skill is preloaded directly by the drive command.

**IMPORTANT**: This workflow implements changes only. Approval and commit are handled by the `/drive` command after implementation.

### Steps

#### 1. Read and Understand the Ticket

- Read the ticket file to understand requirements
- Identify key files mentioned in the ticket
- Understand the implementation steps outlined
- **Read the ticket's `## Policies` section.** It is the recorded list of standard engineering policies (synced from qmu.co.jp) this ticket answers to. Note every `workaholic:<pillar>` / `policies/<slug>.md` entry — Step 3 opens each one before writing code.
- **Read the ticket's `## Quality Gate` section** (if present). It is the developer-agreed acceptance criteria, verification method, and the gate that must pass before approval — captured at `/ticket` time. Implement *to* this gate, and run its verification before requesting approval. Carry its acceptance criteria into the Step 4 return so the approval prompt can state them, and into the archive `<verify>` arg so the commit `Verify:` key records what cleared the gate.
- **If the ticket carries a `mission:` relation, also read the owning mission's quality gate** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/gate.sh <mission-slug>`. When `type` is `documentation` or `live-app`, the mission has a live gate: the change must move the mission toward passing it. Verify it by running the project's dev/docs server on the mission worktree's `dev_port` (from the gate reader) and driving `target` with the Playwright plugin to check `assert`. This is the mission-level "is the outcome good?" check on top of the per-ticket gate.

#### 2. Apply Patches (if present)

If the ticket has a "## Patches" section:

1. For each patch in the section:
   - Write patch content to a temporary file
   - Validate with `git apply --check <patch-file>`
   - If valid, apply with `git apply <patch-file>`
   - Clean up temporary file
2. Report which patches applied successfully
3. For failed patches, note them and proceed with manual implementation

If no Patches section exists, skip to step 3.

#### 3. Implement the Ticket

- **Load the policy lens first (when the standards plugin is installed).** `/drive` preloads `workaholic:design`, `workaholic:implementation`, and `workaholic:operation`, so the three index `SKILL.md` files are in context. Before writing code, open every policy hard copy the ticket's **`## Policies`** section lists — that recorded list (synced from qmu.co.jp) is authoritative for which policies this implementation answers to. Read each `policies/<slug>.md` it names. If a ticket predates the `## Policies` section (it is absent or empty), fall back to deriving the set from the ticket's `layer` field via the Policy Lens mapping: UX → `workaholic:design` plus `workaholic:implementation`, Domain/DB → `workaholic:implementation`, Infrastructure → `workaholic:implementation` plus `workaholic:operation`, Config → the skill whose policies the config touches. Either way, judge the change's **design** (interaction and behavior), **implementation** (code structure and correctness), and **operation** (delivery, runtime, and recovery) against each applicable policy's Goal (目標), Responsibility (責務), and Practices (実践). If the standards plugin is not installed, proceed without it.
- Follow the implementation steps in the ticket
- Use existing patterns and conventions in the codebase
- For areas where patches applied, verify and adjust as needed
- Run type checks (per CLAUDE.md) to verify changes
- Fix any type errors or test failures before proceeding

#### 4. Return Summary (DO NOT COMMIT)

After implementation is complete, return a summary to the parent command:

```json
{
  "status": "pending_approval",
  "ticket_path": "<path to ticket>",
  "title": "<Title from H1>",
  "overview": "<Summary from Overview section>",
  "changes": ["<Change 1>", "<Change 2>", "..."],
  "quality_gate": "<acceptance criteria + what passed, from the ticket's ## Quality Gate, with the verification you ran against it — omit if the ticket has no Quality Gate>",
  "repo_url": "<repository URL>"
}
```

### Critical Rules

- **NEVER commit** - drive command handles commit after user approval
- **NEVER use AskUserQuestion** - drive command handles approval dialog
- **NEVER archive tickets** - drive command handles archiving
- **NEVER spawn the `/trip` Agent Teams members** (`planner`/`architect`/`constructor`) — they are trip-only. Implement in the main agent, or fan out to `general-purpose` subagents only.
- After implementation, proceed to approval flow

### Prohibited Operations

**Context**: This repository may have multiple contributors (developers, other agents) working concurrently. Uncommitted changes in the working directory may not belong to you.

The following destructive git commands are **NEVER** allowed during implementation:

| Command | Risk | Alternative |
|---------|------|-------------|
| `git clean` | Deletes untracked files that may belong to other contributors | Do not use |
| `git checkout .` | Discards all uncommitted changes including others' work | Use targeted checkout for specific files |
| `git restore .` | Discards all uncommitted changes including others' work | Reserved for abandonment flow only |
| `git reset --hard` | Discards all uncommitted changes and resets HEAD | Do not use |
| `git stash drop` | Permanently deletes stashed changes | Only with explicit user request |

**Rationale**: You are not the only one working in this repository. Destructive operations affect everyone's uncommitted work, not just your own implementation. Always check `git status` before any operation that discards changes, and be considerate of work that may not be yours.

If an implementation requires discarding changes, use targeted commands that affect only specific files you modified, or request user approval first.

### System Safety

Before implementation, check whether the repository authorizes system-wide configuration changes. Run the detection script and respect the result:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh
```


- If `system_changes_authorized` is `false`: the prohibited operations list in the system-safety skill applies unconditionally. Do not install global packages, edit shell profiles, modify `/etc/` files, manage system services, or use `sudo`.
- If `system_changes_authorized` is `true`: system-wide changes are permitted because the repository is a provisioning repository.

When an implementation step requires a prohibited operation, propose a safe project-local alternative (see the system-safety skill's Safe Alternatives table). If no alternative exists, report the blocker to the user.

## Approval

User approval flow for `/drive` implementation review.

### 1. Request Approval

Present approval dialog after implementing a ticket.

#### Format

```
**Ticket: <title from ticket H1>**
<overview from ticket Overview section>

Implementation complete. Changes made:
- <change 1>
- <change 2>

[AskUserQuestion with selectable options]
```

#### Options

**CRITICAL**: The `header` and `question` fields below are templates that MUST be replaced with actual values before presenting to the user. The `header` is the ticket **title** (from the H1). The `question` body begins with the **project label** as a `[<project>]` prefix (`project` from `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`), so a developer with several sessions across tmux panes sees which repository is asking, followed by `overview`. Use `title` and `overview` from the workflow result JSON. If those values are not available in context, re-read the ticket file to obtain the H1 title and Overview section. Presenting an approval prompt with missing, empty, or literal angle-bracket placeholder values is a failure condition -- the user cannot make an informed decision without knowing what ticket was implemented and in which project.

**Surface the quality gate.** If the ticket has a `## Quality Gate` (and the Step 4 result carries `quality_gate`), include the agreed acceptance criteria and what you verified against them in the question body, so the developer approves against the concrete, pre-agreed gate rather than a vague summary. This is the payoff of the `/ticket`-time interrogation — never drop it from the prompt when it exists.

```json
{
  "questions": [{
    "question": "[<project label from project-label.sh>] <overview from ticket Overview section>\n\nQuality gate: <acceptance criteria from the ticket's ## Quality Gate, and what you verified against them>\n\nApprove this implementation?",
    "header": "<title from ticket H1>",
    "options": [
      {"label": "Approve", "description": "Commit and archive this ticket, continue to next"},
      {"label": "Approve and stop", "description": "Commit and archive this ticket, then stop driving"},
      {"label": "Abandon", "description": "Write failure analysis, discard changes, stop session"}
    ],
    "multiSelect": false
  }]
}
```

Users can also select "Other" to provide free-form feedback.

### 2. Handle Approval

When user selects "Approve" or "Approve and stop":

1. Update ticket with effort and Final Report (see **Final Report** section below)
2. Archive and commit (see **Archive** section below)
3. For "Approve": continue to next ticket
4. For "Approve and stop": end drive session

### 3. Handle Feedback

When user selects "Other" and provides feedback:

**CRITICAL: Update the ticket file BEFORE making ANY code changes. Do NOT skip this step. Do NOT write code until steps 1-2 are verified complete.**

1. **Update Implementation Steps** in the ticket file:
   - Add new steps for requested functionality
   - Modify existing steps that need adjustment

2. **Append Discussion section** (before Final Report if exists):

```markdown
## Discussion

### Revision 1 - <YYYY-MM-DDTHH:MM:SS+TZ>

**User feedback**: <verbatim feedback>

**Ticket updates**: <list of Implementation Steps added/modified>

**Direction change**: <interpretation of how to change approach>
```

For subsequent revisions, append as "### Revision 2", etc.

3. **Verify ticket update**: Re-read the ticket file to confirm both Implementation Steps and Discussion section were written successfully. If the update failed, retry before proceeding.

4. **Re-implement** following the updated ticket's Implementation Steps
5. Return to approval flow (Section 1). **CRITICAL**: Before presenting the approval prompt again, ensure you have the ticket title (H1 heading) and overview available. Re-read the ticket file if needed -- the feedback loop must not lose ticket context.

### 4. Handle Abandonment

When user selects "Abandon":

#### Discard Changes

Check for other contributors' work before discarding:

```bash
git status --porcelain
```

Discard only your implementation changes:

```bash
git restore <file1> <file2> ...
```

#### Record Failure

Append to ticket:

```markdown
## Failure Analysis

### What Was Attempted
- <implementation approach>

### Why It Failed
- <reason abandoned>

### Insights for Future Attempts
- <learnings>
```

#### Archive Abandoned Ticket

```bash
mkdir -p .workaholic/tickets/abandoned
mv <ticket-path> .workaholic/tickets/abandoned/
```

Commit using **commit** skill:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh \
  "Abandon: <ticket-title>" \
  "Implementation proved unworkable" \
  "Ticket moved to abandoned with failure analysis" \
  "None" \
  "<why it failed / what to retry, from the Failure Analysis, or None>" \
  "None" \
  .workaholic/tickets/
```

Stop the drive session. Return control to the drive command to present the completion summary.

## Final Report

After user approves implementation, update the ticket with effort and final report.

### Update Effort Field

Estimate the actual time this implementation took, then round to the nearest valid value.

**The ONLY valid values are:** `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Do NOT use t-shirt sizes (S/M/L/XS/XL), minutes (10m/30m), or any other format. The `update.sh` script will reject invalid values.

**Valid values (hour-based only):**

| Value | Use For |
|-------|---------|
| `0.1h` | Trivial changes (typo fix, config tweak) |
| `0.25h` | Simple changes (add field, update text) |
| `0.5h` | Small feature or fix (new function, bug fix) |
| `1h` | Medium feature (new component, refactor) |
| `2h` | Large feature (new workflow, significant refactor) |
| `4h` | Very large feature (new system, major rewrite) |

ALWAYS use one of these exact values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

#### How to Update

**MUST use update.sh** -- NEVER use the Edit tool to modify the effort field directly.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh <ticket-path> effort <value>
```

Example:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh .workaholic/tickets/todo/20260212-example.md effort 0.5h
```

### Final Report Section

Append `## Final Report` section to the ticket file.

**If no insights discovered:**

```markdown
## Final Report

Development completed as planned.
```

**If meaningful insights were discovered:**

```markdown
## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: <what was discovered>
  **Context**: <why this matters for understanding the codebase>
```

### What Makes a Good Insight

Include insights that fall into these categories:

- **Architectural patterns**: Hidden design decisions or conventions not documented elsewhere
- **Code relationships**: Non-obvious dependencies or coupling between components
- **Historical context**: Why something exists in its current form
- **Edge cases**: Gotchas or surprising behaviors future developers should know

### Insight Guidelines

- Keep insights actionable and specific, not vague observations
- Insights should benefit someone reading the ticket months later
- Don't duplicate information already in Overview or Implementation Steps
- If no meaningful insights, omit the subsection entirely

## Archive

Complete commit workflow after user approves implementation. Always use this script - never manually move tickets.

> **CRITICAL: NEVER manually archive tickets.** Do not use `mv` + `git add` + `git commit` to move
> tickets from `todo/` to `archive/`. The `archive.sh` script is the ONLY authorized method.
> Manual moves cause unstaged deletions because agents forget to stage the old path.

### Prerequisites

**CRITICAL**: Before calling the archive script, verify that all required frontmatter fields have been successfully updated:

1. **Verify effort field**: The ticket MUST have a valid `effort:` value (e.g., `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`)
2. **Abort on failure**: If frontmatter update failed (e.g., Edit tool error), **DO NOT proceed with archiving**
3. **Report the error**: Inform the user that frontmatter update failed and the ticket cannot be archived

**Never archive a ticket without all required frontmatter fields.**

### Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/archive.sh \
  <ticket-path> "<title>" <repo-url> "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"
```

Follow the **commit** skill's Message Format section for message format.

### Archive Example

```
Add structured commit message format

Why: Commit messages had two report-dead sections (Test Planning, Release Preparation) that /report never read, while the sections it works hardest to produce -- Concerns and Successful Development Patterns -- got nothing from git log. Re-aimed the body at the report's narrative so the log feeds Motivation/Changes/Concerns/Patterns directly.

Changes: None -- this is an internal change to the commit message format. CLI behavior, command interfaces, and user-facing output remain identical.

Concerns: collect-commits.sh previously dropped the commit body entirely; if that drop is ever reintroduced, the new keys stop reaching /report. Keep the collect-commits body-emission assertion green.

Insights: Aligning the commit body keys one-to-one with the report's section taxonomy means a reviewer reading git log sees the same structure the PR story will have -- the log becomes a draft of the report.

Verify: Ran commit.sh with sample inputs and confirmed the labeled sections, the omit-when-empty behavior for Why/Concerns/Insights, and that archive.sh forwards the body args. Confirmed collect-commits.sh now emits the body as valid JSON via the smoke tests.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Update Frontmatter

Update ticket YAML frontmatter fields after implementation.

### Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/update.sh <ticket-path> <field> <value>
```

### Fields

#### effort

Time spent in numeric hours.

Valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Invalid: `XS`, `S`, `M`, `10m` (t-shirt sizes and minutes are not allowed)

Update when: After implementation, before archiving.

#### commit_hash

Short git commit hash (7 characters).

Update when: After creating the commit, set automatically by archive script.

#### category

Change category based on commit message verb.

Values:
- **Added**: Add, Create, Implement, Introduce
- **Changed**: Update, Fix, Refactor (default)
- **Removed**: Remove, Delete

Update when: After creating the commit, set automatically by archive script.

### Field Insertion Order

When a field doesn't exist, it's inserted in this order:
1. After `layer:` -> `effort:`
2. After `effort:` -> `commit_hash:`
3. After `commit_hash:` -> `category:`
