---
name: drive
description: Interactively survey the claimable missions and unclaimed backlog, ask which units to take, then claim, implement, and route each by merge policy.
skills:
  - workaholic:drive
  - workaholic:report
  - workaholic:ship
---

# Drive

<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->

**Notice:** When user input contains `/drive` - whether "run /drive", "do /drive", "start /drive", or similar - they likely want this command.

**Plugin boundary — do not spelunk:** The skills this command needs are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}`. Invoke them by their loaded namespace (`workaholic:`); never search the filesystem for skill content, never read or run anything under `~/.claude/plugins/marketplaces/` or any other global install, and never guess a namespace — `drivin`, `trippin`, `core`, `standards`, and `work` are obsolete names long since merged into the single `workaholic` plugin. If a skill you expect is missing, ask the user which plugins are loaded; do not hunt for it on disk.

## What this command is

`/drive` is the **attended** executor: a developer is present, so when the survey offers more than one claimable or resumable target the run asks once which to take, and asks nothing else at any step. The unattended executor is a **separate command** — `/implement` — because a behaviour that forks on a first word is two commands wearing one name (decision P1, 2026-08-06, superseding O1's `auto`/`night` forms). Attendance is a property of *which command was invoked*, never of a TTY or the environment.

`$ARGUMENTS`, when present, names **one unit** to take (a mission slug or a ticket path). It narrows the scope and nothing else: the run is identical with and without it, except that a run already pointed at one unit has nothing left to ask.

## Run it

Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end. The skill holds every step, table and refusal — do not restate them here, and follow the skill rather than this list when the two ever disagree:

1. **§1 Survey** — confirm the install (`check-deps`), freshen the checkout (`sync-main.sh`), then `plan-units.sh`. Each `ok: false` and each survey-trustworthiness field is a **reported decision, never a prompt**, including here; the skill's §1 tables say which terminate `pending` and which merely forbid `ok`.
2. **§2 Partition, then ask** — report the partition in full and never ask how it was composed. Then, **only when more than one claimable or resumable target remains**, issue the run's one `AskUserQuestion`: `multiSelect`, at most once, one option per unit, the question body opening with `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`. Drive the chosen units in the chosen order and report each unchosen one as `deferred_by_operator`.
3. **§3–§7 Claim, drive, report, route, account** — byte-identical to `/implement`. There is no per-ticket prompt and no gate a present developer may override: the run's one question is the choice among peer units, never approval.

**Landing a claimed unit is a separate, developer-issued act — never a step of this run.** When a developer present in the session says "land this now so a fresh session can resume", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/land-unit.sh <unit-id> --developer-present` (the skill's §6, *The third route*). It refuses outright in a headless context, which is exactly why the run above never reaches for it.

**Terminal contract:** the last two lines are always the `N units: X shipped, Y PR'd, Z blocked` reconciliation and then `ok` or `pending` — `ok` **only** when nothing claimable remains undone (a unit the developer deferred at step 2 is still claimable, so it counts), **and only over a survey known current with the base**. The token is derived from the skill's §7 table, never self-graded.

**A caller-side loop must name `/implement`.** `/goal /implement ok` is the loopable form; a loop pointed at `/drive` would sit on the selection prompt with nobody there to answer it.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/drive` run (via the marker above), including the always-loaded four-pillar policy index. This is where most code is actually written, so judge each ticket's implementation against the policies the change touches — read the relevant `workaholic:design`/`implementation`/`operation` policy bodies (the index links them) per the ticket's `## Policies` section, exactly as the `workaholic:drive` Workflow's "load the policy lens first" step directs.
