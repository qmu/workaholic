---
created_at: 2026-08-28T03:21:02+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Write the return path into the documents

## Overview

**PROPOSED.** This repository's own rule is that a change altering behaviour updates every
affected document **in the same change** — outdated documentation is a defect, and
`doc-drift.sh` is only a backstop. This ticket is that update for the return path, and it
carries one correction the discovery pass already found.

**The correction, not merely an addition.** `docs/routine-loop.md` already tells the reader
that a reply written in the Slack thread is recorded by the next tick as an answer
(`record-answer.sh`). That was never true: nothing read the thread. So the documents do not
gain a new claim here — one of them stops being wrong, and the rest gain the mechanism that
finally makes it right.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `docs/routine-loop.md` — carries the false claim today; the line about the tick recording
  a thread reply as an answer must become true rather than be deleted.
- `CLAUDE.md` — the `/moderate` contract and the three-states paragraph; states current
  behaviour only, so the return path belongs there with what it does and does not do.
- `plugins/workaholic/skills/moderate/SKILL.md` — *Nothing parses the answer* and the
  question-states section; the return path is this skill's behaviour.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step-by-step contract,
  where the new step, the judgement bar and the per-answer reporting live.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog entry for the
  stamp, the single source for its emoji name.
- `plugins/workaholic/skills/propose/SKILL.md` — states that answers to the tick's own
  questions belong to `record-answer.sh`; that sentence now names a path that exists.

## Implementation Steps

1. **Fix the false claim first.** Correct `docs/routine-loop.md` so what it says about a
   thread reply matches what the loop now does. Read the surrounding Japanese section and
   keep it in Japanese — that document's audience reads it there.
2. **State the return path in `CLAUDE.md`**, in the `/moderate` row's own vocabulary: what
   it reads, on what coordinate, what it writes and through which single writer, what it
   files and where, what it stamps — and, as this file's entries consistently do, **what it
   does not do**: no new store, no second inbox, no second writer of the answered line, no
   parsing of the answer, still never merges and never prompts.
3. **Update `workaholic:moderate`** — SKILL and `reference/workflow.md` — with the step,
   the judgement bar ("a person's reply in that question's thread; a machine's post is never
   an answer; when unsure, do not record and say why"), the per-answer reporting contract,
   and the named degradations.
4. **Name the catalog entry** for the stamp in `notify/reference/notifications.md`, if the
   stamp ticket has not already placed it there, and keep the drift pin green.
5. **Check the seam sentences that now read differently**: `propose/SKILL.md`'s exclusion
   of answers to the tick's own questions, and `record-answer.sh`'s own header, whose
   "developer opens the session link" flow is no longer the only route.
6. **Run the backstops rather than trusting the sweep**: `doc-drift.sh` and
   `area-freshness.sh` are backstops, so the read above is the actual check.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `docs/routine-loop.md` no longer claims a behaviour the loop does not have.
- `CLAUDE.md`, `workaholic:moderate` (SKILL and reference) and the notify catalog describe
  the return path, including what it deliberately does not do.
- Every document changed in the **same** change as the behaviour, not after it.
- No document restates the reaction's name — the catalog stays its single source.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the catalog↔template drift pin passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the
  generated bundle and the policy index stay in sync.
- A read of each changed document against the shipped behaviour.

**Gate** — what must pass before approval:

- The build and verify pair green, `outputs/` regenerated if any skill text moved.
- `node scripts/test-workflow-scripts.mjs` green.

## Considerations

- **Language per surface**: `docs/` and code comments are untouched by the Japanese/English
  rule, but `docs/routine-loop.md` is already written in Japanese for its audience — keep
  it that way rather than converting it while correcting it.
- Resist documenting the *design history* here. `CLAUDE.md` states current behaviour only;
  the reasoning belongs in this mission's record and the skill's `reference/`.
