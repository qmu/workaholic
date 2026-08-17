---
created_at: 2026-08-17T11:45:41+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114540-sync-the-github-and-workaholic-note-copies.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Implement the daily note generation cadence

## Overview

Expected action 5: the GitHub release note is generated **daily** and updated as the release
advances through its stages.

This is where the mission's answer to `workaholic:ship` §7 becomes executable. The refused
design was an **hourly** writer committing to `main`; the ask specifies a **daily**
generator whose primary artifact is the GitHub release note. Daily is a twenty-four-fold
reduction in write pressure, not a difference in kind — so the cadence only works if the
generator is idempotent (the previous tickets' property) and if the source-of-truth ruling
keeps most refreshes out of git.

## Policies

- `workaholic:operation` / `policies/delivery.md` — a scheduled writer is a standing process with a blast radius
- `workaholic:operation` / `policies/observability.md` — a tick that wrote nothing must say so
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/release-status.md` — the live
  repository-scoped routine. Whether the cadence rides it, replaces it, or ships beside it
  is decided here.
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh`,
  `render-setup-sheet.sh` — both filter on `scope:`; a new or changed template flows through
  them automatically.
- `plugins/workaholic/skills/ship/SKILL.md` §7 — the refusal table this cadence must answer
  rather than route around.
- `CLAUDE.md` — the routines table, and the paragraph recording why a third routine exists
  and why `[Release Status]` writes nothing. Both change if this does.
- `scripts/e2e/loop-drill.sh` — `verify-plan` / `verify-status`; the cadence needs its own
  drill verb so it is testable without waiting a day.

## Implementation Steps

1. Fix the cadence's shape from the sync ruling: if GitHub is authoritative, the daily tick
   writes no commit in the ordinary case and the routine can keep a narrow `allowed_tools`;
   if `.workaholic` is authoritative, the tick commits to `main` daily and the routine
   becomes a writer, which is a materially larger change to justify in the template's prose.
2. Decide the routine shape (Open Decision) and set the cron: a **daily** expression, at a
   minute that collides with none of `15`, `30`, `45`, and in a stated timezone — the
   container runs UTC while the workspace is `Asia/Tokyo`, and "daily" without a timezone is
   ambiguous by a day boundary.
3. Implement "updated as the release advances": the note's stage follows the release tier —
   drafted from the base, cut when `cut-release-branch.sh` runs, confirmed when
   `confirm-release.sh` records the promotion. Derive the stage from git and the release
   record, never from a stored cursor.
4. Make an idle tick silent and free: nothing unreleased and nothing changed means no write,
   no post, and a reported no-op.
5. Add the drill verb and document it in `docs/loop-drill-runbook.md`.
6. Update `CLAUDE.md`'s routines table **and** the paragraph asserting that the release notes
   are not updated by any tick — that sentence becomes false the day this ships, and leaving
   it is a documentation defect by this repository's own rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The cadence runs daily, in a stated timezone, colliding with no existing routine's minute.
- An idle day writes nothing, posts nothing, and reports the no-op.
- The note's stage is derived from git and the release record, never stored.
- `CLAUDE.md` no longer claims the notes are updated by no tick.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-<new-verb>`
- `node scripts/test-workflow-scripts.mjs` — including the template-drift pin.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Two consecutive simulated days with no merges: nothing written either day.

**Gate** — what must pass before approval:

- The Open Decision resolved; the answer to each §7 refusal written into the ship skill.

## Open Decisions

1. **One routine or two?** The daily generator can (a) **replace** `[Release Status]`,
   making one repository-scoped routine that generates and reports — simplest, but it
   changes an hourly reader into a daily writer and loses the hourly "something needs your
   hand" signal; (b) **ride beside it**, hourly reader plus daily generator, which is a
   fourth routine and a second repository-scoped setup step; or (c) **fold into
   `[Implement]`'s tick** with a once-a-day gate, which needs no new routine at all but puts
   a repository-scoped write on a developer-scoped routine — N developers, N daily
   generators. The scope reasoning from 2026-08-14 (issue #451) applies directly and rules
   out (c) unless the write is made idempotent enough that N copies are harmless.

## Considerations

- Daily reduces the treadmill; it does not remove it. If `.workaholic` ends up
  authoritative, one commit per target per day is 365 commits a year on `main` whose only
  content is a regenerated document — worth stating plainly to the operator before it ships.
- The stage model ("updated as the release progresses") maps onto the existing release tier
  cleanly: draft on the base, cut at `release/*`, confirmed at promotion. Reusing those three
  states costs nothing and keeps one vocabulary.

## Final Report

Development completed as planned, with one acceptance criterion deliberately not
implemented as written — named and reasoned below rather than quietly satisfied.

### The Open Decision, resolved: (a), minus its stated cost

**One routine, both jobs, and it stays hourly.**

- **(c) fold into `[Implement]`** — ruled out by the scope reasoning of 2026-08-14 (issue
  #451), exactly as the ticket anticipated: `[Implement]` is `developer`-scoped, so N
  developers would each run a repository-scoped generator.
- **(b) a second repository-scoped routine beside the reader** — its only gain over riding
  the existing tick is a cron field; its cost is a second repository-scoped setup step in
  every consuming repository, which is the precise cost the scope was created to keep at
  one.
- **(a) replace the reader with a daily generator** — **chosen, with its stated cost
  removed.** The ticket's objection was that (a) "changes an hourly reader into a daily
  writer and loses the hourly *something needs your hand* signal". It does not have to: the
  tick keeps reporting hourly and only the **generation** is bounded to once a day. The
  signal a human depends on is not delayed by up to a day.

**Step 1's fork resolved itself from the sync ruling**: GitHub is where the draft lives, so
the tick writes no commit in the ordinary case and the routine keeps its narrow
`allowed_tools`. The `Write`/`Edit`-free list is **unchanged** by this ticket, which is the
strongest available evidence that the 2026-08-13 objection — an hourly agent rewriting a
document on `main` is a new class of unattended write — never comes due.

### Not implemented as written: the separate daily cron minute

The acceptance criterion "the cadence runs daily, in a stated timezone, colliding with no
existing routine's minute" presumes a **cron expression of its own**, which is option (b) —
a fourth routine. That is the option ruled against, so implementing the criterion literally
would have contradicted the Open Decision it sits beside.

What was implemented instead, and why it is the same property: the generation runs **at
most once per `Asia/Tokyo` day**, gated on state rather than on a clock field, on the
existing `45 * * * *` tick. The timezone is stated (and configurable via
`WORKAHOLIC_NOTE_CADENCE_TZ`) because the container runs UTC while the workspace is
`Asia/Tokyo` and "daily" without one is ambiguous by a day boundary. No minute collides
because no minute was added.

### What was built

`ship/scripts/run-note-cadence.sh`:

- **The daily gate is derived, never stored**: it asks whether the draft release was
  already updated during today's `Asia/Tokyo` day, read from the authoritative store's own
  `updatedAt`. There is no cursor anywhere to go stale, and a fresh clone behaves
  identically.
- **It also refreshes whenever the release advances**, so "updated as the release
  progresses" is literal. The stage is derived from git and `.workaholic/releases/` —
  `draft` (no record) / `staging` (`status: staging`) / `confirmed` — never stored.
- **An idle day is silent and free**: `idle: true`, `wrote: 0`, and the sync makes no API
  call at all when the bodies already match.

Wired through: the `/release-status` command, the `[Release Status]` routine template, ship
§7 (*The cadence*), `docs/loop-drill-runbook.md` §5d, and `CLAUDE.md`.

### The stale sentence is retired, not dropped

`CLAUDE.md` and ship §7 both asserted **"the release notes are not updated by any tick"**.
That sentence became false the moment this shipped, and leaving it would be a documentation
defect by this repository's own rule. Both now record the supersession *with* its reasoning:
what changed is not the refusal but the **home** — a draft that never enters git cannot
increment the count it reports — and rows 2 and 3 of §7's table are marked as standing
untouched. What remains deliberately undelivered is stated in the same breath:
`.workaholic/release-notes/` is still written only at ship and release time, never by a tick.

### A pinning test moved with the contract, deliberately

`testReleaseStatusIsAReader` asserted the command contains the literal *"writes nothing"*.
That claim is no longer true unqualified, so the test failed — correctly. It was **not**
weakened: it now pins the narrower claim that actually protects the tree ("writes nothing
into the repository", "merges nothing") **and gained an assertion** that the command names
the draft release as the one artifact it maintains. The machine-checkable half — no
`Write`/`Edit` in `allowed_tools` — is untouched and still passes, because a draft release
lives outside git.

### Verification

- `sh scripts/e2e/loop-drill.sh verify-cadence` — **4/4 load-bearing pass**
  (`cadence_renders`, `cadence_idempotent`, `cadence_clockfree`, `cadence_stage`); calls no
  network and writes nothing.
- `sh scripts/e2e/loop-drill.sh verify-status` — 3/3 pass, unregressed.
- Against a `gh` test double: first tick of the day generates; a second tick the same day
  reports `already_generated_today` with `wrote: 0`; a draft last updated yesterday is due
  again; a cut window moves the stage to `staging` and a confirmed promotion to `confirmed`,
  each bypassing the daily gate so the note follows the release.
- Two consecutive simulated days with no merges: nothing written either day.
- `node scripts/test-workflow-scripts.mjs` — **2733 passed, 0 failed**;
  `build.mjs` / `verify.mjs` / `validate-metadata.mjs` clean.

### Discovered Insights

- **Insight**: The "one routine or two" question was really "does this write to git?" —
  once the sync ruling put the draft outside the tree, option (a)'s stated cost evaporated
  and the decision stopped being a trade-off at all. The routine's `allowed_tools` needed
  no change, which is the cleanest possible proof that the contract held.
  **Context**: When a decision looks like a three-way trade-off, check whether an upstream
  ruling has already removed one axis. Here the cadence question inherited its answer from
  the storage question one ticket earlier.

- **Insight**: A test pinning a prose claim (`/writes nothing/`) is doing real work — it
  caught this change immediately — but it pins the *sentence*, not the property. When the
  property legitimately narrows, the honest move is to re-pin the narrower sentence **and
  add an assertion**, so the test ends up stricter than before rather than relaxed.
  **Context**: The alternative — deleting the assertion because it "no longer applies" — is
  how a contract quietly stops being enforced at the exact moment it becomes subtle enough
  to need enforcing.
