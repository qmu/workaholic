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

**Two invocation forms, chosen by the caller and never inferred** (decision O1, 2026-08-05, amending G1–G2). Bare `/drive` is the **attended** form: a developer is present, so when the survey offers more than one target the run asks which to take (step 2) and asks nothing else. `/drive auto` is the **unattended** form: zero prompts, the contract the `[Drive]` routine and every caller-side loop depend on. Attendance follows from *how the command was invoked* — never from a TTY, an environment variable, or a guess, because a wrong inference either parks a cron tick on a prompt nobody will answer or silently strips the developer's choice, and neither failure is visible from the far side.

`/drive` is the sole executor. Run the preloaded `workaholic:drive` skill's **Unified Run** section end to end:

0. **Confirm the install first** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/check-deps/scripts/check.sh`. **Terminate `pending` without surveying** when `loaded_version_behind_registry` is `true`, when `registry_unreadable` is `true`, or when the output carries **neither field** (a build too old to report them is the stale build they exist to catch). Name `version` and `registry_version`; the repair is a fresh session, not a retry. `version_drift` (the checkout axis) is a **warning** — report it and continue.

0b. **Freshen** — `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/sync-main.sh`, **before** the survey. Artifacts are published to `main`, and the survey reads this working tree, so a checkout behind `origin/main` surveys a stale queue and reports it confidently — the worst shape an unattended tick can take. Same step interactively and on cron: one code path. Handle each `ok: false` as a **reported decision** (this command asks nothing):

   | reason | what the run does |
   | ------ | ----------------- |
   | `no_origin` | Survey the local tree, **say so**, and continue. The terminal token may not be `ok`: a survey that could not consult the remote has not established that nothing claimable remains. |
   | `not_on_main` / `dirty_workspace` | The runner is not in a surveyable state. Report the reason and **terminate `pending`** — never silently survey a branch. |
   | `origin_unreachable` | Like `no_origin`: survey locally, say so, and the token may not be `ok`. |
   | `diverged` | A human's decision (the `detail` says `local_ahead` or `both_diverged`). Report and **terminate `pending`**. Never merge or reset. |

1. **Survey** — `plan-units.sh` (the approved missions this runner may take + this developer's unclaimed backlog, with the in-flight claims subtracted). A mission owned solely by another developer is dropped as `owned_by_other`; unowned means claimable. It reports what it observed rather than repairing it:

   | field | what the run does |
   | ----- | ----------------- |
   | `current: false` | The survey could not see everything on the base. **Forbids `ok`** — carry it into step 7. |
   | `backlog_error` non-empty | The queue was not read at all (`identity_unresolved` = the runner has no `git config user.email`). An empty `backlog[]` here means *unknown*, not *empty*: report the reason and **terminate `pending`**. Never repair the identity — the plugin cannot invent an email. |
   | `user_slug` | Whose queue was surveyed. Report it whenever `backlog_error` is set, so the operator can see what the runner thought it was. |

2. **Partition, then let the operator choose** — group the remainder into PR-units, conservatively. **Report the partition in full, in both forms; never ask how it was composed.** Then, **in the attended form only, and only when it offers more than one claimable or resumable target**, ask which to take: one `AskUserQuestion`, `multiSelect`, at most once per run, one option per unit (id + kind + a one-line summary of its content), the question body opening with `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh`. Drive the chosen units in the chosen order; report each unchosen one as `deferred_by_operator` in step 7 — it stays claimable, so it forbids `ok`. A single target, an invocation naming a specific unit, and the unattended form all ask nothing.
3. **Claim** — `claim.sh` per unit, before any of its work starts. Read refusals as facts (`already_claimed` means another runner has it — move on).
4. **Drive** — implement the unit's tickets in its claim worktree, per the skill's Workflow and its failure contract.
5. **Report** — compose `workaholic:report`'s story + `create-or-update.sh` for the claim branch, non-interactively.
6. **Route** — `effective-policy.sh`: `auto` ships through `workaholic:ship` (and tears the claim down after the merge), `review` stops at the PR and posts its URL via `propose/scripts/notify-slack.sh`. Never override a gate: a secret hard-stops, a size/leak block or a missing confirmation method demotes the unit to the PR path.
7. **Account** — `record-run-hours.sh` per mission unit, then the reconciliation line and the terminal token as the last two lines.

**The unattended form issues no `AskUserQuestion` — anywhere, at any step.** `/drive auto` is what a cron tick (`docs/drive-loop-runbook.md`) and a `/goal /drive auto ok` loop wait on: a decision the run cannot make is deferred and recorded in the final report, never asked. **The attended form adds exactly one prompt and nothing else** — the step-2 selection, at most once per run. Steps 3 through 7 are identical in both forms; an attended run only narrates more, and there is still no per-ticket confirmation in either.

**A caller-side loop must name the unattended form.** `/goal /drive auto ok` and the `[Drive]` routine template both invoke it explicitly; a loop pointed at the bare form would sit on the selection prompt with nobody there to answer it.

**`/drive night`** is a synonym of `/drive auto`, kept for muscle memory.

**Landing a claimed unit is a separate, developer-issued act — never a step of this run.** When a developer present in the session says "land this now so a fresh session can resume", run `bash ${CLAUDE_PLUGIN_ROOT}/skills/drive/scripts/land-unit.sh <unit-id> --developer-present` (the skill's §6, *The third route*). It refuses outright in a headless context, which is exactly why the unified run above never reaches for it.

**Terminal contract:** the last two lines are always the `N units: X shipped, Y PR'd, Z blocked` reconciliation and then `ok` or `pending` — `ok` **only** when nothing claimable remains undone (a unit the developer deferred at step 2 is still claimable, so it counts), **and only over a survey known current with the base** (step 0/1). A caller-side loop (`/goal /drive auto ok`) waits on that token, so it must never be self-graded.

**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens on every `/drive` run (via the marker above), including the always-loaded four-pillar policy index. `/drive` is where most code is actually written, so judge each ticket's implementation against the policies the change touches — read the relevant `workaholic:design`/`implementation`/`operation` policy bodies (the index links them) per the ticket's `## Policies` section, exactly as the `workaholic:drive` Workflow's "load the policy lens first" step directs.
