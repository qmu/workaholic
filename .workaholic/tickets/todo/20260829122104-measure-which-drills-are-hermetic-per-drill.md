---
created_at: 2026-08-29T12:21:04+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Measure which drills are hermetic, per drill

## Overview

Establish, per `verify-*` command, whether it runs with no network, no `gh`, no `qfs`
and no API key. The drill file's own header says it lives outside the plugin *because it
assumes the server's full `gh` and `qfs`* — a claim now true of some rows and false of
most, and `docs/loop-drill-runbook.md` already describes many rows as "no network,
stubbed transport". A header is evidence, never the answer: every ticket below takes
this measurement as its input, so it is made first and recorded where the later tickets
read it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a measurement that names what it could not answer

## Key Files

- `scripts/e2e/loop-drill.sh` — the 33 dispatched commands (30 `verify-*`, plus
  `seed`/`status`/`reset`); the subject of the measurement
- `docs/loop-drill-runbook.md` — the per-stage table whose "Reads" column already claims
  hermeticity for many rows; the claim being checked, and where the result is recorded
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport a
  drill reaches; what "no network" has to deny

## Implementation Steps

1. Enumerate the `verify-*` commands from the dispatcher itself (`case "$CMD" in`), never
   from a hand-kept list — the enumeration is what ticket 8 later pins.
2. Run each one in an environment with no network, no `gh` on `PATH`, no `qfs` and no
   `ANTHROPIC_API_KEY`, capturing its exit code and its JSON line. The drill's existing
   exit vocabulary already separates the cases: `0` completed, `1` a load-bearing row
   failed, `4` the environment could not answer (`gh_unavailable`, `identity_unresolved`,
   `list_failed`, `not_a_repo`), `5` the stage has not run yet, `3` a dirty precondition.
3. Classify each row into: **hermetic** (exit 0 against its own fixture), **needs a stub
   it does not carry** (exit 4/3 naming an environment reason), **needs the server**
   (`seed`/`status`/`reset`/`verify-specificate`/`verify-implement`, which read the real
   issue and the real remote), and **reads this checkout** (`verify-plan`,
   `verify-status`, `verify-cadence`, `verify-standup`, `verify-moderate` — no network,
   but their verdict depends on the working tree rather than a throwaway fixture, so they
   are a third kind and must not be silently folded into either).
4. Record the classification in `docs/loop-drill-runbook.md` beside each row, with the
   evidence (the exit code and the reason word), so a later reader can argue with it.
5. Re-run the measurement twice and report any row that is not stable across runs — an
   intermittent drill is a finding of its own, not a hermetic one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `verify-*` command the dispatcher names carries a classification, derived from an
  actual run rather than from its header.
- The three-plus-one kinds are distinguished by name; "reads this checkout" is never
  recorded as "hermetic".
- A row unstable across repeated runs is named as unstable.

**Verification method** — the commands/tests/probes that prove them:

- The measurement run itself, with its captured exit codes and reasons.
- `grep -c 'verify-[a-z-]*) cmd_verify' scripts/e2e/loop-drill.sh` against the count of
  classified rows.

**Gate** — what must pass before approval:

- The runbook's per-row classification matches the dispatcher's enumeration exactly, with
  no row unclassified and none classified from its header alone.

## Considerations

- The measurement is a **reading of today's tree**, so it goes stale; ticket 8's pin is
  what keeps a newly added drill from being silently unmeasured.
- A drill that needs a stub it does not carry is not a defect of this mission to fix —
  record it and let ticket 2 report it as `skipped:<reason>`.
