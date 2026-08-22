---
created_at: 2026-08-22T14:14:36+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: give-the-tick-a-route-for-the-records-it-writes
merge_policy:
verification_handoff: 
---

# Stop reporting a record the tick did not persist

## Overview

The sibling ticket gives the tick a route. This one removes what made the missing route
invisible for an unknown number of hours.

On the measured tick, `persist-log.sh` reported both records `filed` and `persisted`, and the
17-line log reached `main` — while `origin/main` carried the tick's log section and not one
record. Every mechanism reported success. The next tick then read `inbound-sweep-filed` and
`issue-triage-filed` out of the log, concluded both findings were already captured, and did not
re-derive them. So the loss compounds: the finding is neither published nor recoverable, and
the dedup actively prevents a second chance at it.

The defect is that the dedup keys on **a line in the log** rather than on the artifact the line
claims exists, and that the persist report conflates "the log landed" with "what the log says
landed, landed".

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — emits the per-step
  `filed`/`persisted` report; it must distinguish the log from the artifacts.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the only writer of the
  `<step>-filed` lines the dedup reads.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader those dedups consult.
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh`,
  `step-issue-triage.sh` — the two steps whose dedups depend on those lines.
- `plugins/workaholic/skills/moderate/SKILL.md` — the degraded-read rule ("a degraded read is
  reported by name, never as a step that ran and found nothing"), which this extends to writes.

## Implementation Steps

1. **Reproduce before designing.** Force a tick whose record does not reach the base and read
   what `persist-log.sh` reports and what `log-append.sh` writes. Confirm from the scripts —
   not the report — that a `-filed` line is written before the artifact is known to have
   landed, and that `log-read.sh` cannot tell the difference.
2. **Localize** which of the two is load-bearing: the report's wording, the `-filed` line's
   timing, or both.
3. Make the persist report state the two facts separately: whether the **log** reached the
   base, and whether each **record** it names reached the base. A record that did not land is
   named, with its reason — the same shape the SKILL already requires for a degraded read.
4. Make the `-filed` line assert only what is true: written when the artifact is known to be on
   the base, or carrying its landed state so the dedup can tell a claim from a fact.
5. Make the two dedups treat an unlanded record as **not filed**, so the next tick re-derives
   the finding. Re-deriving a finding is cheap; losing it is not.
6. Keep the log append-only and never-pruning: this changes what a line asserts, never
   rewrites a line already on the base.
7. Update `SKILL.md`, `CLAUDE.md` and `rules/workaholic.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The persist report distinguishes the log landing from each record landing, and names any
  record that did not land with its reason.
- A record that did not reach the base is not treated as filed by either dedup; the next tick
  re-derives the finding.
- The log stays append-only and no line already on the base is rewritten.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A hermetic two-tick run with the persist forced to fail, asserting the second tick
  re-derives rather than skipping.

**Gate** — what must pass before approval:

- All three criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Drive this **after** its sibling. With the route in place the failing case is rare, but it is
  exactly the rare case that must not be silent — which is why the honesty fix is a ticket of
  its own rather than a clause in the other.
- Do not "fix" this by having the dedup re-read the base for every candidate: that turns an
  hourly tick into a repository scan. The `-filed` line stays the dedup's index; what changes
  is that it must be true when written.
