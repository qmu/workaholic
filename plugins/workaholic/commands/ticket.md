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

**Project label in every prompt:** for each `AskUserQuestion` this command issues (worktree guard, moderation merge/split, Quality-Gate interrogation, mission association, ambiguity), prefix the `question` body with `[<project label>]` — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## Instructions

### Summary mode (bare `/ticket` or `/ticket summary`)

If `$ARGUMENT` is **empty** or exactly `summary`, do **not** create a ticket. Run the read-only assigned-ticket summary and stop (this respects the create-only guardrail — it writes nothing):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/create-ticket/scripts/summary.sh
```

Present the returned JSON as a readable list of the current user's `todo/<user>/` queue — one line per ticket showing its title, `type`, `layer`, and any `depends_on` — or tell the user their queue is empty and that `/ticket "<description>"` writes a new one. Do not run the discovery workflow, worktree guard, or any AskUserQuestion in this mode. For any other `$ARGUMENT`, continue with ticket creation below.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop. Otherwise note the
reported `version`, and if `missing_guards` is non-empty, **warn** the user that a
stale or partial plugin install is loaded (the listed PreToolUse guards are not
registered in this build) before proceeding — do not block on it.

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
4. **Quality Gate interrogation** (skill Step 4b — **mandatory, always run**) — before writing, interrogate the developer about how the outcome's quality will be assured (verification method, acceptance criteria, the gate that must pass before approval, edge cases, division of assurance). Issue these as `AskUserQuestion`(s) at this command level — grill until the gate is objective and checkable. **Do not soften or skip this** on "obvious" requests; record the answers in the ticket's mandatory `## Quality Gate` section so the later `/drive` approval is concrete.
5. **Offer mission association** (skill Step 4c — optional) — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh`; if any missions with `status: active` exist, issue one **`multiSelect: true`** `AskUserQuestion` (options = each active mission by title+slug, plus "None") and write **every** chosen `slug` into each written ticket's `mission:` frontmatter — `[alpha, beta]` for several, a bare slug for one (closed missions are never offered). Skip silently when there are no active missions. The choices are drawn from existing missions, so the slugs are valid by construction — no extra validation. A ticket can advance more than one mission; `/drive` will hold it to **every** named mission's quality gate, so a mission named here is a commitment, not a label.
6. **Evaluate complexity and write ticket(s)** (skill Steps 4–5) — run the stray-ticket sweep (skill Step 1.5) first, then split when warranted, populate `depends_on`, and write files (including the `## Quality Gate` section) under `.workaholic/tickets/todo/<user>/` (or `.workaholic/tickets/icebox/`, which stays flat) only.
7. **Handle ambiguity** (skill Step 6) — if the request is ambiguous, present the questions via `AskUserQuestion` and incorporate the answers.

**CRITICAL guardrails** (from `workaholic:create-ticket`): never implement code, never commit (Step 2 below handles commit), discovery subagents never call AskUserQuestion, and tickets are written ONLY under `.workaholic/tickets/todo/<user>/` or `.workaholic/tickets/icebox/` — never the flat `todo/` root and never any other `.workaholic/` subdirectory. See the skill's Allowed Locations section.

### Step 2: Commit and Present

**Skip commit if invoked during `/drive`** — the archive script handles it.

Otherwise: stage ticket(s) with `git add <paths>`, commit `"Add ticket for <short-description>"`, present the ticket location and summary, and tell the user to run `/drive` to implement.
