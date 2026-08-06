---
name: implement
description: Unattended executor - survey the claimable missions and unclaimed backlog, claim each PR-unit, implement it, and route it by merge policy, with no prompt at any step.
skills:
  - workaholic:drive
  - workaholic:report
  - workaholic:ship
---

# Implement

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/implement` - whether "run /implement", "implement the queue", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

## What this command is

`/implement` is the **unattended** executor, and it is what the `[Implement]` routine and every caller-side loop invoke. **It issues no `AskUserQuestion` — anywhere, at any step.** That is the whole reason it is a command of its own rather than a first word on `/drive` (decision P1, 2026-08-06, superseding O1): a caller that must never meet a prompt cannot depend on a behaviour selected by an argument it might forget to pass.

`$ARGUMENTS`, when present, names **one unit** to implement (a mission slug or a ticket path) — typically read out of the artifact that triggered the routine. It narrows the scope and nothing else; with no argument the run takes everything it can claim, one unit at a time, until the survey offers nothing claimable or the session ends.

## Run it

Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end. The skill holds every step, table and refusal — do not restate them here, and follow the skill rather than this list when the two ever disagree:

1. **§1 Survey** — confirm the install (`check-deps`), freshen the checkout (`sync-main.sh`), then `plan-units.sh`. Every `ok: false`, every survey-trustworthiness field, and every excluded item is **reported**; the skill's §1 tables say which terminate `pending` and which merely forbid `ok`.
2. **§2 Partition** — report the partition in full. Nothing is asked: not which units to take, not how they were composed.
3. **§3–§7 Claim, drive, report, route, account** — byte-identical to `/drive`. A decision the run cannot make is **deferred and recorded in the final report, never asked**; an unqueued problem met mid-run becomes a ticket rather than a stop; a half-driven unit ends in `handoff` with its state written into the PR body.

**Never override a gate.** `auto` means "no *approval* needed", never "no *gate* applies": a `secret` finding hard-stops the unit as `blocked`, and a `size`/`leak` block or a missing deployment-confirmation method **demotes** it to the PR path. A demotion is reported as a demotion, with the gate that caused it.

**Never land a unit.** `land-unit.sh` refuses a headless context by construction and requires a developer's explicit instruction; this command has no interaction point, so it has no such instruction and never reaches for it.

**Terminal contract:** the last two lines are always the `N units: X shipped, Y PR'd, Z blocked` reconciliation and then `ok` or `pending` — `ok` **only** when nothing claimable remains undone, **and only over a survey known current with the base**. A caller-side loop (`/goal /implement ok`) waits on that token, so it must never be self-graded; the skill's §7 table derives it.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/implement` run (via the marker above), including the always-loaded four-pillar policy index. This is where most code is actually written, so judge each ticket's implementation against the policies the change touches — read the relevant `workaholic:design`/`implementation`/`operation` policy bodies (the index links them) per the ticket's `## Policies` section, exactly as the `workaholic:drive` Workflow's "load the policy lens first" step directs.
