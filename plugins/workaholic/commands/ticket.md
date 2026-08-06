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

**Project label in every prompt:** for each `AskUserQuestion` this command issues (moderation merge/split, Quality-Gate interrogation, mission association, merge policy, ambiguity), prefix the `question` body with `[<project label>]` — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse its `project` value — so a developer with several sessions open across tmux panes can see which repository is asking; leave the `header` as the decision/topic label.

## Instructions

### With no argument — report the queue

If `$ARGUMENT` is **empty**, do **not** create a ticket. Run the read-only queue summary and stop (this respects the create-only guardrail — it writes nothing):

The literal `summary` was a second way to reach this and is **retired** (P5, 2026-08-06): a behaviour selected by the first word of an argument is a second command wearing one name, and `summary` was also a word no ticket could be described with. Bare `/ticket` is the surviving way in — a *scope* (no description given, so nothing to write) rather than a mode selected by a word. `/ticket summary` now writes a ticket about the word "summary", which is what any other undescribed argument does.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/create-ticket/scripts/summary.sh
```

Present the returned JSON as a readable list of the tickets in `todo/` this developer owns (plus the unowned, claimable ones) — one line per ticket showing its title, `type`, `layer`, and any `depends_on` — or tell the user their queue is empty and that `/ticket "<description>"` writes a new one. Do not run the discovery workflow, worktree guard, or any AskUserQuestion here. With any non-empty `$ARGUMENT`, continue with ticket creation below.

### Pre-check: Dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh
```

If `ok` is `false`, display the `message` to the user and stop. Otherwise note the
reported `version`, and **warn** the user before proceeding — without blocking on
it — when either: `missing_guards` is non-empty (a stale or partial plugin install
is loaded, and the listed PreToolUse guards are not registered in this build), or
`version_drift` is `true` (the loaded `version` is not the `checkout_version` this
repository wants).

### The worktree guard is gone, and must not come back

There was a Step 0 here that asked "Continue here" vs "Switch to worktree" when worktrees existed. Its stated rationale was to stop a ticket being written against the main tree when the developer meant to be inside a claim worktree — and that is exactly the concern decision J1 eliminates: **every ticket is published to `main` by construction**, from whatever checkout the developer happens to be standing in, so both answers now produce the identical outcome. A prompt whose every answer is the same is worse than no prompt (`rules/interaction.md`), so it was removed rather than reworded. `/ticket` never creates a branch and never asks about one.

### Step 1: Run the Create-Ticket Workflow

Follow the **Workflow** section of the preloaded `workaholic:create-ticket` skill end-to-end, with `$ARGUMENT` as the request description and the target directory (`todo` or `icebox`, based on the argument):

1. **Open the publish tree** (skill Step 1) — `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh`; take its `path` and treat it as the root every subsequent write resolves against. On `ok: false`, report the reason and stop before writing anything.
2. **Parallel discovery** (skill Step 2) — spawn three `subagent_type: "general-purpose"` subagents in a single message (`model: "opus"`), one per mode (history/source/policy), each preloading `workaholic:discover`. These are leaf subagents: they discover and return each mode's JSON per skill Step 2 (history's includes the `moderation` field that step 3 below branches on) — never AskUserQuestion. Wait for all three.
3. **Handle moderation** (skill Step 3) — on `duplicate`, inform the user and show the existing path (done); on `needs_decision`, present the merge/split options via `AskUserQuestion` and act on the choice; on `clear`, proceed.
4. **Quality Gate interrogation** (skill Step 4b — **mandatory, always run**) — before writing, interrogate the developer about how the outcome's quality will be assured. **Ask decisions; derive the rest**, and run each decision through the **Recommended-label test** (`rules/interaction.md`): question only what is genuinely the developer's call (verification depth/method, scope, risk tradeoffs) **and unrecommendable** — a decision whose answer you could honestly recommend is decided-and-recorded as a `## Quality Gate` `Decided:` line, not asked. Unrecommendable forks are issued as `AskUserQuestion`(s) at this command level and grilled until objective and checkable; acceptance criteria that follow from discovery and repo conventions are **drafted by you directly into the ticket's mandatory `## Quality Gate` section**, never posed as a select-which-apply menu. **Do not soften or skip the modeling** on "obvious" requests — the test narrows the prompt *count*, never the gate's thoroughness; every recommendable call is still decided and written down, and the recorded gate is what makes the later `/drive` approval concrete. The `Decided:` record format and a worked example live in skill Step 4b — do not restate them here.
5. **Offer mission association** (skill Step 4c — optional) — run `bash ${CLAUDE_PLUGIN_ROOT}/skills/mission/scripts/list.sh`; if any **in-flight** missions exist (`status: draft` or `approved` — the active area), issue one **`multiSelect: true`** `AskUserQuestion` (options = each in-flight mission by title+slug, plus "None") and write **every** chosen `slug` into each written ticket's `mission:` frontmatter — `[alpha, beta]` for several, a bare slug for one (closed missions are never offered). Skip silently when there are no in-flight missions. The choices are drawn from existing missions, so the slugs are valid by construction — no extra validation. A ticket can advance more than one mission; `/drive` will hold it to **every** named mission's quality gate, so a mission named here is a commitment, not a label.
6. **Record the merge policy** (skill Step 4d) — issue **one** `AskUserQuestion`: may this work merge automatically once it is done and verified (`auto`), or must a human review the PR (`review`)? Write the answer as `merge_policy:` into every ticket this run writes. This is a genuinely unrecommendable fork — the developer's trust in *this* change landing unattended is information you cannot derive — so it is asked, not decided. A **mission-emitted** ticket inherits its mission's policy instead and this question is skipped; an empty field is legal and reads as `review`.
7. **Evaluate complexity and write ticket(s)** (skill Steps 4–5) — run the queue-layout migration (skill Step 1.5) first, then split when warranted, populate `depends_on`, and write files (including the `## Quality Gate` section) under `.workaholic/tickets/todo/` (or `.workaholic/tickets/icebox/`) only. Both the migration and the writes resolve **inside the publish tree**: run the scripts as `( cd <publish_path> && … )` and give every Write an absolute path under `<publish_path>/`.
8. **Handle ambiguity** (skill Step 6) — if the request is ambiguous, present the questions via `AskUserQuestion` and incorporate the answers.

**CRITICAL guardrails** (from `workaholic:create-ticket`): never implement code, never commit (Step 2 below handles commit), discovery subagents never call AskUserQuestion, and tickets are written ONLY under `.workaholic/tickets/todo/` (flat) or `.workaholic/tickets/icebox/` — never a per-user subdirectory and never any other `.workaholic/` subdirectory. See the skill's Allowed Locations section.

### Step 2: Publish and Present

**Skip publishing if invoked during `/drive`** — the archive script commits on the claim branch, and that is correct: a ticket minted mid-run belongs to the PR that discovered it and reaches `main` when that PR merges. Do not open a publish tree in this case.

Otherwise, publish the batch as one commit and tear the publish tree down:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh "Add ticket for <short-description>" "<why>" "None" "None" "None" "<verify>" <ticket-path>...
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh
```

Then present the ticket path, the pushed commit, the **branch and pull-request URL**, and the fact that the ticket becomes claimable by `/drive` **when that pull request merges** — not before. Say that plainly: a developer who reads "published" as "queued" will wonder why the next tick ignored their ticket.

**Name only the tickets this run wrote.** The Step 1.5 migration has already git-staged its moves inside the publish tree, and they ride the same commit through the index — but naming a migrated ticket's *old* path here refuses the entire publish (`commit.sh` treats an unstageable named path as fatal, correctly), leaving the batch unpublished. So pass the newly written paths and nothing else.

**A publish failure is never swallowed.** On `no_origin`, `branch_collision`, `push_failed`, or `nothing_to_commit`, tell the developer plainly that the ticket is **not published**, name the reason, and say that the body is intact in the publish tree (do **not** close it — closing refuses unpublished commits, and the tree is how the work is recovered). A developer who believes work is queued when it is not is the worst outcome available here.

**`pr_failed` and `no_gh` are a different report, and must not be collapsed into the one above.** The ticket **is** pushed to the named branch; only the pull request is missing. Report the branch, and say the recovery is to open the PR by hand — re-running `/ticket` would write a second copy of the same ticket.
