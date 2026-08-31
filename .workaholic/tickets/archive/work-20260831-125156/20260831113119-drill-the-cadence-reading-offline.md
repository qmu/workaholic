---
created_at: 2026-08-31T11:31:19+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notice-a-periodic-artifact-that-stopped-being-produced
merge_policy:
verification_handoff: 
---

# Drill the cadence reading offline

## Overview

A reading nothing proves is a reading that quietly stops working — which is exactly the
failure this mission exists to fix, one level up. Drill declaration → reader → step →
question offline, with a breaker row written against the behaviour.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher's `case` arms, which `verify-all` derives
  its set from.
- `docs/loop-drill-runbook.md` §9 — the drill register, read by
  `drive/scripts/drill-register.sh`; a drill it does not classify is
  `skipped:unclassified` and the suite fails on it.


## Implementation Steps

1. Add `verify-cadence-lapse` over a throwaway fixture: a declared cadence whose newest
   artifact is stale, one that is current, one whose pattern resolves to nothing, and a
   repository declaring none.
2. Prove the question fires **once** across two ticks, that a current cadence asks
   nobody, that an unreadable read asks nobody and is named, and that a repository with
   no declaration is byte-identical to today.
3. Add a **breaker** row written against the **behaviour**: wire the reader so an
   unreadable pattern answers `lapsed`, and the row must fire. A breaker satisfied by
   keeping the JSON shape proves nothing.
4. Keep it hermetic — no network, no `gh`, no Slack post — so it joins the set
   `.github/workflows/loop-drills.yml` runs on every push.
5. Register it in `docs/loop-drill-runbook.md` §9 with its classification, in the same
   commit.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-cadence-lapse` passes, makes no network call and
  needs no credential.
- Its breaker row is proved able to fail on the real script's source.
- The register classifies it and `verify-all` includes it; it is not `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-cadence-lapse`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Registered in §9 in the same commit as the drill itself.


## Considerations

- The fixture needs artifacts with controlled mtimes; set them explicitly rather than
  relying on the run clock, or the drill passes or fails by the day it runs on — the
  reason `--hour` and `--weekday` are injectable in the check-in step.


## Final Report

Development completed as planned. `verify-cadence-lapse` walks declaration → reader → step →
question over a throwaway git repository the drill builds: a lapsed cadence, a current one, an
unresolvable pattern and a repository declaring none. Ten load-bearing rows pass, including that
the question fires exactly once across two ticks through the existing gate, that a current
cadence asks nobody and renders no root line, that an unreadable read is named and asks nobody,
and that an undeclared repository is `skipped` by name. It is hermetic — no network, no `gh`, no
Slack, no credential — so it joins the set `.github/workflows/loop-drills.yml` runs on every
push, and it is registered in `docs/loop-drill-runbook.md` §9 in the same commit.

The breaker is written against the behaviour rather than the return shape: the reader is wired
so an unresolvable pattern answers `lapsed`, and the step must then hand over a candidate it
must never hand over. It fires.

### Discovered Insights

- **Insight**: the fixture controls **commit** dates (`GIT_COMMITTER_DATE`), not mtimes, and its
  verdicts are clock-independent by construction — the lapsed artifact is dated 2001 against a
  one-day period and the current one is committed now against a thirty-day period.
  **Context**: the ticket asked for controlled mtimes, which the reader deliberately does not
  read. A drill whose fixture straddles the threshold passes or fails by the day it runs on; two
  orders of magnitude on either side of the period removes the question entirely.
