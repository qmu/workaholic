---
created_at: 2026-08-22T14:14:36+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: give-the-tick-a-route-for-the-records-it-writes
merge_policy:
verification_handoff: 
---

# Persist the tick's own feedback records to the base

## Overview

`/moderate`'s inbound-sweep and issue-triage steps hand candidates back in `needs_agent`; the
agent applies the materiality bar and writes a feedback record through
`feedback/scripts/create.sh`, which stages the file and stops. A routine's container is then
discarded, so the record never reaches the base.

Three rules make this unsatisfiable as shipped: `workaholic:moderate` says `persist-log.sh`
publishes `.workaholic/moderations/` and the tick "writes nothing else anywhere";
`create.sh` ends at a staged file; and `guard-git-branch.sh` permits only
`work-YYYYMMDD-HHMMSS` and `release/YYYYMMDD-HHMMSS`, so `publish-tree-pr.sh` — the one writer
that could publish a record — creates exactly the branch shape the tick may not create.

The fix the report asks for is the narrow one: extend the seam `persist-log.sh` **already
uses** — `publish-tree-commit.sh`, direct to the base, no branch, no claim, no pull request —
to cover the feedback records the same tick wrote. The heavy prohibitions are untouched.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the existing direct-commit
  seam and its recorded reasoning (why a per-tick PR was refused, why this is not the
  unattended-`main`-writer class); the widening lands here.
- `plugins/workaholic/skills/moderate/SKILL.md` — the "writes nothing else anywhere but its
  own log" sentence, which must state the record route explicitly rather than by exception.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — steps 2 and 5, which tell the
  agent to write a record.
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh` — its header states the
  filing contract (`needs_agent`, no GitHub issue) that the route must fit.
- `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh` — the seam being
  reused; read its "post-merge seams only" wording before widening.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the writer; it stays a stager,
  the route is the caller's.
- `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md` — both state the tick's write
  boundary and must move in the same commit.

## Implementation Steps

1. **Reproduce before designing.** Run a tick that writes a record and confirm the measured
   shape: the record staged in the container, `persist-log.sh` reporting the log persisted,
   and nothing under `.workaholic/feedbacks/` on the base. Do not take this from the report —
   establish it from the scripts and a run.
2. **Localize.** Confirm `persist-log.sh` is the only path from a tick to the base, and that
   nothing else in the tick writes outside the container.
3. Widen the persist seam to carry, alongside `moderations/`, the feedback records written
   **during the same tick**. Scope it to that tick's own records — not a sweep of whatever
   happens to be staged, which would let an unrelated staged file ride the tick's commit.
4. Keep the union/idempotency properties the log already has: two concurrent ticks must both
   land, and a record already on the base is never rewritten.
5. Keep every heavy prohibition intact and say so in the SKILL: no merge, no `work-*` branch,
   no claim touched, no live strategy edited. State the record route as part of the tick's
   contract rather than as an exception to it.
6. Run the persist twice, as the log already does (the agent acts on `needs_agent` only after
   `run.sh` returns), so a record written after the first persist still lands.
7. Update `CLAUDE.md` and `rules/workaholic.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A feedback record written during a tick appears on the base after that tick, with no
  `work-*` branch created, no claim touched and no pull request opened.
- Only the tick's own records ride the commit; an unrelated staged file does not.
- Two concurrent ticks both land their records; an existing record is never rewritten.
- `SKILL.md`, `CLAUDE.md` and `rules/workaholic.md` describe the route consistently.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A hermetic two-tick run asserting the record on the base and the branch list unchanged.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- The report names a cheaper alternative — stop writing records on a tick and route findings
  into the check-in step. It is the fallback, not the ask: it drops the inbound-sweep half of
  the feedback stream. Record it under this ticket's Considerations if the primary route turns
  out to be unreachable, rather than substituting it silently.
- `publish-tree-commit.sh`'s "post-merge seams only" wording is about **when a direct commit
  is owed no approval**. A feedback record is a capture, not a decision — the same ground the
  log stands on — but say so in the header rather than leaving the widening to look like an
  exemption.
