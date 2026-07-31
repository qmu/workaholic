---
created_at: 2026-08-01T03:04:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260801-030703
---

# Make `/workaholify` provision a developer's loop-engineering environment, and nudge them to re-run it

## Overview

Routines are how this project actually runs — the 5-minute drive loop, the 15-minute proposal loop — yet nothing in the repository records which routines it wants, and nothing on a developer's machine reports which are installed. The configuration lives in one person's account, so *"what runs against this repo"* can only be answered by asking them, and a second developer joining has no path to the same setup.

**This is `/workaholify`'s job, not a new command's.** `/workaholify` already means "wire this repository to the standards" — a scheduled routine is part of that wiring, not a separate concern. Adding `/setup-routines` would split "make this repo work the way we work" across two commands a developer has to know about, and the second one would be the one nobody runs.

Two things follow: `/workaholify` gains a routines step, and the developer gets **nudged to re-run it periodically**, because provisioning drifts — a routine added to the repo after someone set up their machine never reaches that machine otherwise.

## The two decisions this ticket settles

**1. Where routine configuration lives: `.workaholic/routines/`, registered as a lockstep amendment.**

The repository declares *which routines it wants*; the developer's machine holds *whether they are installed*. That split is the whole design: a committed declaration cannot hold a machine's paths or secrets, and a crontab cannot be reviewed in a PR.

`.workaholic/` is a closed layout, so this is a **deliberate amendment** — `hooks/workaholic-layout-allowlist.txt` and the table in `rules/workaholic.md` are updated in the same commit that first writes there (the rule exists because `strategies/` once shipped live with both sources stale). Rejected alternative: `docs/routines/`, which needs no amendment and sits next to the existing runbooks — it loses because routines are **state the workflows read**, like missions and tickets, not prose a human reads; putting machine-readable declarations in `docs/` is what makes them drift from the tooling.

**2. What an agent may apply unattended: nothing. Interactive provisioning only.**

Both runbooks say *"do not install the crontab from an agent session — applying a standing schedule is a durable outward action"*, and that rule stays exactly as written. The resolution is not to weaken it but to notice it is aimed at the **unattended** case: `/workaholify` is typed by a developer who is present, and installing a routine they just asked for is the same class of act as any other thing they typed. So:

- **Read-only always.** Surveying what is installed is safe from any context and never prompts.
- **Writing requires an interactive invocation and an explicit confirmation** of the exact crontab line, shown verbatim before it is applied — the same shape as `/request`'s body confirmation, and for the same reason: a standing schedule is an outward, durable commitment a matcher cannot judge.
- **A headless run never writes.** It reports the drift and stops. `/drive`, `/propose`, and any cron tick fall in this branch by construction.

## Policies

- `workaholic:operation` / `policies/ci-cd.md` — a scheduled routine is delivery infrastructure; how it is provisioned and how drift is detected belong to the operation pillar
- `workaholic:implementation` / `policies/directory-structure.md` — the new `.workaholic/routines/` area is a registered amendment to a closed layout, not an ad-hoc directory
- `workaholic:implementation` / `policies/objective-documentation.md` — "which routines run against this repo" must become an observable fact from a command, not an answer only one person holds
- `workaholic:development` / `policies/overnight-ai.md` — the unattended-write prohibition is the reason the interactive/headless split is the design, not an afterthought

## Key Files

- `plugins/workaholic/commands/workaholify.md` — gains the routines step; stays thin, referring to the skill
- `plugins/workaholic/skills/workaholify/SKILL.md` — where the routine model, the two decisions above, and the interactive/headless split are written down
- `plugins/workaholic/skills/workaholify/scripts/` — the new survey and installer live here alongside `audit-claude-md.sh`
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` and `plugins/workaholic/rules/workaholic.md` — the lockstep pair the new directory must be registered in, in the same commit
- `docs/drive-loop-runbook.md`, `docs/proposal-loop-runbook.md` — the hand-written procedures the routine declarations replace as the source of truth; they stay as the explanation and must point at the new mechanism
- `CLAUDE.md` — the command table row and the closed-layout section

## Related History

`/workaholify` was deliberately kept thin: rules live in the gateway skill, never copied into `CLAUDE.md`. That shape is preserved here — the routines step refers to the skill, and the skill holds the model.

The feedback records `20260731160449-support-a-setup-routines-skill-…` and `20260731160517-routine-configuration-has-no-source-of-truth-…` are the origin. They asked for `/setup-routines [repository]`; this ticket answers the need inside `/workaholify` instead, and that redirection is the developer's ruling (2026-08-01).

## Implementation Steps

1. **Register `.workaholic/routines/`** in both sources of truth, in the commit that first writes there. `layout-doctor.sh .` must still report `conforming: true`.
2. **Define the routine declaration format** — one file per routine, with a non-empty `type` in its frontmatter so the OKF bundle reads it like every other artifact: the schedule, the command, the env file it expects, and a short statement of what the routine is for.
3. **Write `survey-routines.sh`** (read-only, safe anywhere): for each declared routine, report whether an entry for *this repository* is present in the developer's crontab, its schedule, and whether it matches the declaration — `{routine, declared, installed, matches, drift_reason}`. Missing crontab, missing env file, and a schedule that has drifted are each named rather than collapsed into "not set up".
4. **Write `install-routine.sh`** — renders the crontab line from the declaration and applies it. It **refuses in a non-interactive context** and emits a machine-readable reason; the caller (the command, at main-agent level) shows the exact line and confirms before invoking it. Idempotent: re-running against an already-correct entry changes nothing.
5. **Add the routines step to `/workaholify`**, between the `CLAUDE.md` audit and the guard check: survey, report drift self-explanatorily, and offer to install what is missing.
6. **Add the periodic nudge.** The mission lens already demonstrates the mechanism — a non-blocking `UserPromptSubmit`/`Stop` hook that stays silent unless it has something to say. The nudge fires only when the survey reports drift, is rate-limited so it cannot repeat every turn (the lens's per-session cksum dedupe is the precedent), and never blocks a stop.
7. **Declare this repository's own two routines** and point both runbooks at them.
8. **Update the docs in the same change** and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/routines/` is registered in `hooks/workaholic-layout-allowlist.txt` and in the `rules/workaholic.md` table, in the same commit that first writes there; `layout-doctor.sh .` reports `conforming: true`.
- `survey-routines.sh` reports, for each declared routine, whether it is installed for this repository and — when it is not — which of {no crontab entry, missing env file, schedule drift} applies.
- `install-routine.sh` refuses to write in a non-interactive context, with a named reason, and is idempotent when the entry is already correct.
- The nudge stays silent when the survey reports no drift, and never blocks a stop.
- `/workaholify` reports the routine state without being asked to, and the runbooks point at the declarations rather than being the source of truth.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases for the survey against a fixture crontab (installed / absent / drifted), the non-interactive refusal, and installer idempotency. No test may touch the real crontab.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live `/workaholify` run in this repository reports both routines and their true state.

**Gate** — what must pass before approval:

- The suite is green, the layout audit conforms, and a live run shows the real state of this machine's two routines.

## Considerations

- **The unattended-write prohibition is the constraint most likely to be eroded later.** Someone will want `/drive` to self-heal its own routine. The refusal must be in the script, not only in prose, so the erosion requires deleting a test (`plugins/workaholic/skills/workaholify/scripts/install-routine.sh`).
- A crontab is per-user and per-machine, and the survey reads only the invoking user's. A routine installed under a different account is invisible to it — the survey must say "not installed **for this user**" rather than "not installed" (`survey-routines.sh`).
- The nudge is printed unasked, so its silence condition is as important as its message. The mission lens's signal gate is the precedent: say nothing rather than say something with no action attached (`plugins/workaholic/hooks/mission-lens.sh`).
- Routine declarations name a command and a schedule; they are close enough to executable that a reviewer must read them as such in a PR. Keeping them small and human-readable is what makes that review possible.

## Final Report

Development completed as planned. Both decisions the ticket was blocked on were settled and
written down with their rejected alternatives, and all eight steps landed.

### Discovered Insights

- **Insight**: The "do not install a crontab from an agent session" rule did not need
  weakening — it needed *reading precisely*. It is aimed at the **unattended** case, and
  `/workaholify` is typed by a developer who is present. Encoding that as `[ ! -t 0 ]` in
  `install-routine.sh` turns a prose prohibition into a boundary someone has to delete a
  test to cross.
  **Context**: This is the same shape as the mission-size norm decided earlier today —
  *norm for a human, gate for the batch*. The question that resolves both is **who holds
  the pen at the moment of writing**, not how important the rule is.

- **Insight**: Naming *which* thing is wrong is worth more than a boolean, and the test
  suite proved it mid-implementation. The nudge picked up a fixture whose declaration was
  missing its `schedule`, and reported `not_installed` — pointing the developer at their
  crontab for a fault in a committed file. `incomplete_declaration` was added as its own
  reason.
  **Context**: `missing_env` is the same class and the reason the survey exists at all:
  the routine is scheduled, it fires, and it fails silently every tick — a state
  `crontab -l` alone cannot show.

- **Insight**: A hook that dedupes on `session_id` under `TMPDIR` is machine-global, so a
  test using a fixed session id is deduped by the *previous run of the suite* and the
  feature looks broken. Real session ids are UUIDs, so this is a test-isolation problem
  rather than a product bug — the fix is to derive the id from the fixture's unique temp
  dir.
  **Context**: Worth knowing before writing any test against `mission-lens.sh`, which
  uses the identical dedupe mechanism.
