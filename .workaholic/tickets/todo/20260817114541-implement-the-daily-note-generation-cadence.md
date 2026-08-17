---
created_at: 2026-08-17T11:45:41+00:00
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
