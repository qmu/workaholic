---
created_at: 2026-08-28T12:21:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Drill the check-in delivery path with no network

## Overview

Add `verify-checkin-delivery` to `scripts/e2e/loop-drill.sh`: the whole delivery path over
a fixture log spanning several days, with no network — so the repair is provable on demand
rather than by waiting for a tick. Every other reading in this loop has one
(`verify-arrival`, `verify-retire`, `verify-return-path`, …); the path that reaches a
person has none.

## Policies

- `workaholic:implementation` / `policies/testability.md` — machine-checkable gaps caught early
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the new `verify-checkin-delivery` subcommand
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason→file table
- `plugins/workaholic/skills/moderate/scripts/` — the scripts under drill

## Implementation Steps

1. Build a fixture `.workaholic/moderations/` spanning several days with held findings, and
   drive the tick's check-in over it with the transport stubbed and no network at all.
2. Assert, each as its own row: **the held question lands**; **the second tick does not
   re-ask it**; **the drain honours `max_per_tick`**; **a genuinely spent day still holds**;
   and **a tick that delivered nothing renders its line while an idle tick renders none**.
3. Carry a **breaker row** — a deliberately wired copy that fires the moment the day count
   is unbounded again. It must fail loudly, and it is what makes the drill worth running.
4. Prove the drill can fail: confirm the breaker row goes red when the bound is removed,
   the discipline `verify-identity-handoff` and `verify-ci-retirement` already hold.
5. Document the subcommand in `docs/loop-drill-runbook.md` and name it in `CLAUDE.md`'s
   drill list, in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` passes on the repaired tree.
- The breaker row fails when the day bound is removed.
- The drill makes no network call and leaves the working tree untouched.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery`
- The same, with the bound reverted in a scratch copy — the breaker row must go red.

**Gate** — what must pass before approval:

- Fixtures live under the OS temp dir; the repository's own log is never read or written.

## Considerations

- The drill is operator tooling outside the plugin and may assume the server's full `gh`
  and `qfs`, as the others do — but this one needs neither, and should not acquire them.
- Keep the breaker row targeting the **cause** (an unbounded count), not the symptom (a
  particular refusal string), or a later refactor renames the symptom and the row passes
  over a live defect.
