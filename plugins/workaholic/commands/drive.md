---
name: drive
description: Survey the approved missions and unclaimed backlog, partition them into PR-units, claim each, implement it, and route it by merge policy.
skills:
  - workaholic:drive
  - workaholic:report
  - workaholic:ship
---

# Drive

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

`/drive` is the sole executor. Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end:

1. **Survey** — `plan-units.sh` (approved missions + this developer's unclaimed backlog, with the in-flight claims subtracted).
2. **Partition** — group the remainder into PR-units, conservatively. **Report the partition; never ask it.**
3. **Claim** — `claim.sh` per unit, before any of its work starts. Read refusals as facts (`already_claimed` means another runner has it — move on).
4. **Drive** — implement the unit's tickets in its claim worktree, per the skill's Workflow and its failure contract.
5. **Report** — compose `workaholic:report`'s story + `create-or-update.sh` for the claim branch, non-interactively.
6. **Route** — `effective-policy.sh`: `auto` ships through `workaholic:ship` (and tears the claim down after the merge), `review` stops at the PR and posts its URL via `propose/scripts/notify-slack.sh`. Never override a gate: a secret hard-stops, a size/leak block or a missing confirmation method demotes the unit to the PR path.
7. **Account** — `record-run-hours.sh` per mission unit, then the reconciliation line and the terminal token as the last two lines.

**This command issues no `AskUserQuestion` — anywhere, in any invocation.** Headless (a cron tick, `docs/drive-loop-runbook.md`) and interactive runs take the identical path; an interactive run only narrates more. A decision the run cannot make is deferred and recorded in the final report, never asked.

**`/drive night`** is a synonym kept for muscle memory. The unified run *is* the unattended shape, so the token selects nothing.

**Terminal contract:** the last two lines are always the `N units: X shipped, Y PR'd, Z blocked` reconciliation and then `ok` or `pending` — `ok` **only** when nothing claimable remains undone. A caller-side loop (`/goal /drive ok`) waits on that token, so it must never be self-graded.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/drive` run (via the marker above), including the always-loaded four-pillar policy index. `/drive` is where most code is actually written, so judge each ticket's implementation against the policies the change touches — read the relevant `workaholic:design`/`implementation`/`operation` policy bodies (the index links them) per the ticket's `## Policies` section, exactly as the `workaholic:drive` Workflow's "load the policy lens first" step directs.
