---
created_at: 2026-09-02T04:20:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
claim: work-20260906-025904
---

# Cover every writer of the tick log, not the moderation tick alone

## Overview

PROPOSED. The measured accumulation on the base carried two commit vocabularies, not one:
`Log the moderation tick` *and* `Log the propose tick`. Both rode the same
`.workaholic/moderations/` day files. The off-main design and every guard written for it
are phrased against the moderation tick, so a guard that names that tick alone leaves the
other writer free to put the log back on the base.

This ticket proves the set of writers from the tree rather than from memory, and makes the
guard and the drill cover all of them.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — documented as the only
  writer of the log; this ticket establishes whether that is still true.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the publisher the sibling
  ticket adds the destination refusal to; the refusal must be reachable from every caller.
- `plugins/workaholic/commands/propose.md`, `plugins/workaholic/commands/moderate.md` — the
  two commands whose runs produced the two commit vocabularies.
- `scripts/e2e/loop-drill.sh` and `docs/loop-drill-runbook.md` §9 — the drill and its
  register; the drill that fails when a tick log reaches `main` must fail for any writer.
- `scripts/test-workflow-scripts.mjs` — where the writer set is pinned.

## Implementation Steps

1. Establish the writer set from the tree: find every path that appends to or commits
   `.workaholic/moderations/`, and every caller of `log-append.sh` and `persist-log.sh`.
   Write the list into the ticket's own record of what it found — the guard is only as good
   as this enumeration.
2. If a writer exists outside `log-append.sh` / `persist-log.sh`, route it through them
   rather than adding a second guard: one writer with one refusal is the property, and two
   guards drift.
3. Extend the drill so it fails when *any* of the enumerated writers puts a day file on the
   base — parameterised over the writer set, never one case per tick name.
4. Add a suite assertion that the enumerated set matches what the tree holds, so a new
   writer added later fails the build rather than silently escaping the guard.
5. Correct every prose surface that says "the moderation tick's log" where it means "the
   tick log": `workaholic:moderate`, `CLAUDE.md`, and the drill runbook, in this change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The writer set is derived from the tree and pinned, not listed by hand in prose alone.
- The drill fails for a base-bound log write from any enumerated writer.
- No prose surface still implies the guard covers the moderation tick only.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The new suite assertion fails when a synthetic extra writer is introduced.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- The enumeration is the risk: a writer reached only through an interpolated path cannot be
  found by a literal search. Say so in the assertion's own name, as the suite already does
  for jq programs built by interpolation, rather than implying the set is complete.

## Final Report

Development completed as planned.

**Step 1, the enumeration, from the tree.** Every shell script whose *code* (comments excluded)
names `.workaholic/moderations` is: `log-append.sh` (the one appender), `step-open-log.sh` (the
opener — `mkdir` only), `log-read.sh`, `condition-age.sh`, `step-blocked-tick.sh`,
`step-strategy-digest.sh` and `run.sh` (readers), `persist-log.sh` (the refuser, added by the
sibling ticket), and `scripts/e2e/loop-drill.sh` (a reader, in its own assertions). **No writer
exists outside `log-append.sh`**, so step 2's "route it through them rather than adding a second
guard" had nothing to route — the property held already and is now pinned rather than assumed.

The two commit vocabularies the ticket was written against (`Log the moderation tick`,
`Log the propose tick`) both rode `persist-log.sh`'s branch half, which was deleted on
2026-09-03; `/propose`'s own two log lines go through `log-append.sh` like every other writer, so
one guard at one writer does reach both.

**Step 3, the drill, parameterised over the writer set**: `verify-log-off-base` derives the set
from the tree at run time and asserts no member stages or commits a log path — never one case per
tick name. It carries a breaker written against the behaviour: a copy of `persist-log.sh` with
its destination guard removed must stop refusing, which is what proves the guard is what refuses.

**Step 4, the suite assertion**: the tree walk pins each script with a declared role and fails on
any script the table does not name, so a writer added later fails the build. The roles themselves
are proved by **behaviour** — the opener is run and must leave the day file unwritten, the writer
is run and must write it — rather than by grepping for a redirect, because which variable a
script redirects into is a shape rather than the property.

**Step 5, the prose.** `commands/moderate.md` still instructed the tick that its *closing act
puts that log on the base through the publish tree* — the ceiling a routine session reads,
sixteen days after that stopped being true. Corrected there, in the drill's own comment, in
`workaholic:moderate` and in `CLAUDE.md`.

### Discovered Insights

- **Insight**: the ticket asked for the enumeration to be written into its own record because
  "the guard is only as good as this enumeration" — and the enumeration immediately found the
  live defect, which was not a rogue writer but a **command ceiling** telling the tick to do the
  thing the guard forbids.
  **Context**: prose that instructs a routine is executable in the only sense that matters here;
  a stale ceiling outranks a correct script, because the session reads the ceiling first.
- **Insight**: the assertion's own name carries its limit (`literal paths only`), following the
  jq-compilation row's precedent — a path built by interpolation cannot be found by a literal
  search and is not covered.
  **Context**: the alternative, implying completeness, is what makes a guard worse than none.
