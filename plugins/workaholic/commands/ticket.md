---
name: ticket
description: Explore codebase and write implementation ticket for `$ARGUMENT`
skills:
  - workaholic:create-ticket
  - workaholic:branching
  - workaholic:gather
---

# Ticket

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/ticket` - whether "create /ticket", "write /ticket", "add /ticket for X", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

**CRITICAL:** NEVER implement code changes when this command is invoked - only create tickets. The actual implementation happens later via `/drive`.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens automatically on every `/ticket` run — load and apply `workaholic:planning`, `workaholic:design`, `workaholic:implementation`, and `workaholic:operation` (the 企画 / 設計 / 実装 / 運用 policy skills) before scoping the request or writing ticket content, mapping the change to the ticket's `layer` field. The `workaholic:create-ticket` skill's Workflow Step 0 and Policy Lens table document the layer→pillar mapping; `implementation/directory-structure` and `implementation/coding-standards` always apply to code work.

This command (main agent) runs the `workaholic:create-ticket` **Workflow** directly: it spawns the three discovery subagents as `general-purpose` Task calls and issues every AskUserQuestion itself — there is no `ticket-organizer` subagent.

## Instructions

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop.

### Step 0: Worktree Guard

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh`. If `has_worktrees` is `true`, present an `AskUserQuestion` with selectable options:
- **"Continue here"** — Proceed with ticket creation on the current branch.
- **"Switch to worktree"** — Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh`, display the worktree list, and inform the user to navigate to the selected worktree to run `/ticket` there.

Rationale: prevents creating tickets on a drive branch when the user may intend to work within a trip worktree.

### Step 1: Run the Create-Ticket Workflow

Follow the **Workflow** section of the preloaded `workaholic:create-ticket` skill end-to-end, with `$ARGUMENT` as the request description and the target directory (`todo` or `icebox`, based on the argument):

1. **Check branch** (skill Step 1) — create a topic branch if on main; record `branch_created`.
2. **Parallel discovery** (skill Step 2) — spawn three `subagent_type: "general-purpose"` subagents in a single message (`model: "opus"`), one per mode (history/source/policy), each preloading `workaholic:discover`. These are leaf subagents: they discover and return each mode's JSON per skill Step 2 (history's includes the `moderation` field that step 3 below branches on) — never AskUserQuestion. Wait for all three.
3. **Handle moderation** (skill Step 3) — on `duplicate`, inform the user and show the existing path (done); on `needs_decision`, present the merge/split options via `AskUserQuestion` and act on the choice; on `clear`, proceed.
4. **Evaluate complexity and write ticket(s)** (skill Steps 4–5) — run the stray-ticket sweep (skill Step 1.5) first, then split when warranted, populate `depends_on`, and write files under `.workaholic/tickets/todo/<user>/` (or `.workaholic/tickets/icebox/`, which stays flat) only.
5. **Handle ambiguity** (skill Step 6) — if the request is ambiguous, present the questions via `AskUserQuestion` and incorporate the answers.

**CRITICAL guardrails** (from `workaholic:create-ticket`): never implement code, never commit (Step 2 below handles commit), discovery subagents never call AskUserQuestion, and tickets are written ONLY under `.workaholic/tickets/todo/<user>/` or `.workaholic/tickets/icebox/` — never the flat `todo/` root and never any other `.workaholic/` subdirectory. See the skill's Allowed Locations section.

### Step 2: Commit and Present

**Skip commit if invoked during `/drive`** — the archive script handles it.

Otherwise: stage ticket(s) with `git add <paths>`, commit `"Add ticket for <short-description>"`, present the ticket location and summary, and tell the user to run `/drive` to implement.
