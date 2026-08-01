---
created_at: 2026-08-01T18:48:01+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: adopt-a-git-flow-branching-model-with-durable-ship-records
merge_policy: auto
---

# Survey /ship's merge flow and record the release-tier decision

## Overview

The mission's own acceptance requires its **first** ticket to be exploratory: a written
survey of `/ship`'s current merge flow and where a `release/*` cut-and-promote step fits.
Nothing downstream can be scoped honestly without it, because `/ship` is not a single
script — it is a documented flow across `pre-check.sh`, `catchup-main.sh`,
`record-evidence.sh`, `merge-pr.sh`, `publish-release.sh`, `commit-release-note.sh` and
`extract-deferred-concerns.sh`, each with its own ordering constraint.

The design question itself is **already settled** and must not be re-opened: exactly one
new tier (`release/*`), `main` unchanged as default and production, per-unit claim
mechanics untouched. What is missing is the record: a feedback entry naming the chosen
shape and the alternatives that were rejected (full Git Flow, a `develop`-only tier), so
the next session does not re-propose them blind.

## Policies

- `workaholic:operation` / `policies/deployment-pipeline.md` — the branching model *is* the delivery path; a new tier must be designed against the pipeline as it actually runs, not as it is described.
- `workaholic:implementation` / `policies/objective-documentation.md` — the survey's value is that it names concrete seams and their ordering constraints, not that it summarizes intent.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - the flow to survey, in order
- `plugins/workaholic/skills/ship/scripts/` - the seven scripts the flow composes
- `plugins/workaholic/skills/feedback/scripts/create.sh` - the only sanctioned writer of the design record
- `docs/loop-engineering-workflow.md` - where a decision of this size is numbered

## Implementation Steps

1. Read `ship/SKILL.md` end to end and write down, per step, what it reads and writes and
   what must precede it. The ordering constraints are the deliverable — particularly the
   evidence-before-merge rule, which any promotion step must not invert.
2. Identify **where** a `release/*` cut fits: after a unit's merge to `main`, at a
   promotion moment that is not per-unit. Name the seam concretely.
3. Register a `kind: insight` feedback record stating the chosen tier set (`release/*`
   only), and naming full Git Flow and a `develop`-only tier as rejected, with the reason
   from the `#dev-workaholic` discussion.
4. Add the numbered decision to `docs/loop-engineering-workflow.md`.

## Quality Gate

**Acceptance criteria**

- A feedback record exists naming the chosen tier set and both rejected alternatives with their reasons.
- `docs/loop-engineering-workflow.md` carries the numbered decision.
- The survey names, per `/ship` step, what it reads/writes and the ordering constraint it imposes — concretely enough that the next ticket can place the cut without re-reading the flow.
- No code changes: this ticket decides and records, it does not implement.

**Verification method**

- `bash plugins/workaholic/skills/feedback/scripts/list.sh` shows the record.
- Read-through of the survey against `ship/SKILL.md`, confirming every step is accounted for.

**Gate**

- The rejected alternatives are named with reasons. A decision record that states only the choice invites the same discussion again.

Decided: a feedback record plus a numbered decision, rather than a new document — long-lived direction accretes in the feedback stream by design (B3), and the numbered log is where the branching model's other decisions already live (developer may override at /drive).

## Considerations

- The survey must not become a second copy of `ship/SKILL.md`. What it adds is the ordering constraints, which the SKILL states in prose and a promotion step can violate without noticing.
