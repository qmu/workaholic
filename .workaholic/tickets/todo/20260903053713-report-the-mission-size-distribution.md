---
created_at: 2026-09-03T05:37:13+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# Report the mission-size distribution

## Overview

Rule 2 is a position about the corpus, and nothing in the loop can see the corpus. The measured
distribution in the ask was produced by hand. Without a reading, the loop cannot tell whether
the change is working, and the next report of this defect will be another hand count.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/list.sh`, `queue-size.sh`, `progress.sh` — the
  readers that already count.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where a repository-level reading
  is reported once a day rather than hourly.
- `plugins/workaholic/skills/standup/scripts/digest.sh` — the daily digest.

## Implementation Steps

1. Add a pure reader answering the mission-size distribution across `active/` and `archive/`:
   per bucket, how many missions, composing the existing counters — no second walker, no field
   on any artifact.
2. Report it **once a day**, not hourly: an unchanged answer restated every hour is what
   `📦 Release Preparation` was retired for, and this number moves slowly by construction.
3. Report it as evidence and never as a gate: nothing is refused, ordered, closed or held on it.
4. A degraded read is named as degraded with null counts, never as an empty distribution.
5. Add a hermetic case over a small synthetic corpus.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- The distribution is derived from the existing counters and matches a hand count on a fixture.
- It is reported at most once a day and gates nothing.
- A degraded read is named as degraded with null counts.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the fixture case.
- One run against this repository, compared against a hand count.

**Gate** — what must pass before approval:

- No hourly surface carries it.

## Considerations

- The reading is about the corpus, not about any one mission, so it names no slug — *how many*
  is news and *which* is a task, and this line is addressed to nobody.
