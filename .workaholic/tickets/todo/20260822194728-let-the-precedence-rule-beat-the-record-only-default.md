---
created_at: 2026-08-22T19:47:28+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: refuse-the-move-that-describes-the-aim-instead-of-advancing-it
merge_policy:
verification_handoff: 
---

# Let the precedence rule beat the record-only default

## Overview

`workaholic:specificate` states its form precedence as an ordered rule: *decomposable into two or
more units → mission; atomic → loose ticket; a date, an owner and an aim with no decomposable plan
→ strategy; none of those → record-only.* It also carries a standing default — *when unsure,
record-only, and name what made you unsure* — written so an unattended run cannot invent work.

The two collided and the default won. An ask naming a runtime, a database, an object store, an
access layer, a language, build and test tooling, a framework, authentication and a protocol
server was judged record-only. Nine named components is decomposable by any reading, so the
precedence rule had already answered before the default was reached.

This is the ticket the mission is driven **first**, because on its own it would have produced a
plan for the measured case.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` — *The form follows the work's shape* (the
  precedence table) and *Unattended — the defining constraint* (the record-only default). Read
  both before changing either; they are meant to compose, not to compete.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 7, where the judgment is
  made and the precedence is restated.
- `plugins/workaholic/skills/mission/scripts/check-floor.sh` — the two-ticket floor that already
  catches a mission proposed on too little; it is the backstop that makes leaning toward a plan
  safe.

## Implementation Steps

1. **Reproduce from the record, not from memory.** Take the measured ask and walk step 7 as
   written; establish which sentence produced record-only and confirm the precedence rule was
   reachable and would have said mission.
2. **Localize.** Confirm the default is stated in one place and the precedence in another, and
   that nothing today orders them.
3. State the ordering explicitly: the precedence rule is consulted **first**, and the record-only
   default applies only to an ask the precedence rule did not resolve. Uncertainty about *how* to
   decompose is not uncertainty about *whether* it decomposes.
4. Require the report to name **which rule decided** — `precedence:<form>` or `unsure:<what>` — so
   a record-only outcome can be argued with rather than assumed.
5. Keep the floor as the safety net: a candidate mission under two tickets still falls back and
   reports `check-floor.sh`'s `alternative`, unchanged. Leaning toward a plan is safe precisely
   because that gate is mechanical.
6. Update `CLAUDE.md`'s `/specificate` row in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask naming two or more separately buildable components reaches the mission form.
- Every judgment reports the rule that decided it.
- A genuinely vague ask is still record-only, with what made the run unsure named.
- The two-ticket floor still demotes an under-supported mission.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A read-back of step 7 against the measured ask, and against a deliberately vague one.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- The default exists for a real reason and must survive: an unattended run inventing work is worse
  than one recording an ask. What changes is only its **position** — last, not first.
- Do not turn this into a component counter. "Two or more separately buildable things" is a
  judgement the run states and can be argued with; a threshold would be gamed by an ask's phrasing.
