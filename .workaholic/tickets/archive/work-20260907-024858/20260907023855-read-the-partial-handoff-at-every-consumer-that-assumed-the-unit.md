---
created_at: 2026-09-07T02:38:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hand-off-the-members-that-declare-and-drive-the-rest
merge_policy:
verification_handoff: 
---

# Read the partial handoff at every consumer that assumed the unit

## Overview

PROPOSED. Several consumers read the handoff axis as a property of the whole
unit. Once a unit can be **partly** handed off, each of them says something false or vague:
the mission close gate refuses naming a ticket that is not the one holding it,
`/moderate`'s `handoff-units` question names the unit rather than the members a person must
act on, and `declared-handoff-detail.sh` materialises a single reason. This ticket walks the
enumerated consumers and makes each read the partial form and name the members it is about.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/acceptance-handoffs.sh` — the close
  gate's one reader; it already distinguishes prose from `probe:` as a consumer and must now
  name **which member** holds the mission open.
- `plugins/workaholic/skills/drive/scripts/declared-handoff-detail.sh` — materialises the
  declared reason for `/moderate`; must carry the declaring member set.
- `plugins/workaholic/skills/moderate/reference/workflow.md` and
  `plugins/workaholic/skills/moderate/SKILL.md` — the `handoff-units` step: its candidates,
  its `handoff-unit:<unit>` key, and the question body's own contract (lead with what
  happened, the identifier after it).
- `plugins/workaholic/skills/drive/reference/claims.md` — the enumerated consumers of the
  `awaiting_verification` verdict.
- `docs/loop-drill-runbook.md` §9 — the drill register, so a new or widened drill is
  classified rather than reading `skipped:unclassified`.
- `CLAUDE.md` — the moderate step table and the verification-axis paragraph.

## Implementation Steps

1. **Reproduce first.** With the two previous tickets landed on a
   fixture, record what each consumer says about a mixed unit: the close gate's refusal text,
   `declared-handoff-detail.sh`'s output, and the `handoff-unit:` question body.
2. Enumerate the consumers from `drive/reference/claims.md` rather than by searching, and
   check the enumeration against the tree; add any consumer the table does not name.
3. Make `acceptance-handoffs.sh` name the member that holds the mission open, so a refusal
   points at the ticket a person must act on rather than at the mission.
4. Carry the declaring member set through `declared-handoff-detail.sh` without adding a
   second parser of the field.
5. Rewrite the `handoff-unit:` question body to the catalog's contract: lead with what
   happened in words a channel reader understands, the identifier after it, and name the one
   act asked of the addressee. **Do not change the key** — `already_asked` keys on the step
   id, and changing a body must never re-ask.
6. Update `claims.md`'s consumer table, `moderate/SKILL.md`, `moderate/reference/workflow.md`,
   `CLAUDE.md` and the drill register in the same change.
7. Extend the suite so a consumer that reads the whole-unit form fails, and so an unclassified
   drill fails as it already does.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The mission close gate names the declaring member that holds the mission open, not the
  mission alone, and still refuses only on a **prose** declaration.
- The `handoff-unit:` question names the members a person must act on and keeps its existing
  key, so no question is re-asked by this change.
- `drive/reference/claims.md`'s consumer enumeration matches the tree in both directions.
- Every drill touched carries a `bearing: "breaker"` row and is classified in the register.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the consumer-enumeration rows in both directions.
- `sh scripts/e2e/loop-drill.sh verify-all`
- The step-1 reproduction re-run against the fixture.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed>

**Verification method** — the commands/tests/probes that prove them:

- <proposed>

**Gate** — what must pass before approval:

- <proposed>

## Considerations

- Changing a question's **body** never re-asks, because `already_asked`
  keys on the step id — but changing the **key** would re-ask every standing question. Do not
  touch the key.
- This ticket is last on purpose: until the two before it land there is no partial handoff for
  a consumer to read, and rewriting these readers first would describe a state that does not
  exist.
- `/moderate` still asks and nothing else here: it clears no handoff, retries no verification,
  merges nothing and touches no claim.

## Final Report

Development completed as planned.

Every consumer the enumeration names now reads the partial form: the resolver carries the
declaring member set, the question names the tickets rather than the claim, and the close gate
was already per member and is pinned as such.

### Discovered Insights

- **Insight**: two of the three consumers named in the ticket needed **no behavioural change** —
  `acceptance-handoffs.sh` and the archive close gate were already per member, because the gate
  walks each acceptance item's own ticket and its refusal already prints `${HOFF_TICKETS}`.
  **Context**: the ticket predicted they would "say something false or vague". They do not, and
  the honest outcome is to pin that they stay per-ticket rather than to manufacture a change.
  The enumeration step is what established this — reading the consumers out of the table beat
  assuming each named consumer needed work.

- **Insight**: the positional-TSV hazard is worse than the earlier `cut -f10` comment suggests.
  **Context**: adding one column broke **four** readers, in three shapes: two `while IFS= read`
  destructurings (caught by 31 assertions that looked like unrelated backlog failures), one
  `cut -f`, and two `awk '{print $10}'` sites — one of which (`delete-retired-claim-branch.sh`)
  was caught only by `verify-ci-retirement`, and one (`claim-arbitrate.sh`) by **nothing at
  all**, so a lock would have been reaped against the string `false`. The suite now derives the
  row's width from the writer's own `printf` and checks every fixed-index reader against it;
  the guard was proved able to fail by reverting one index.

- **Insight**: `declared-handoff-detail.sh` was calling `claims_declared_handoff`, which is
  itself a read of `claims_declared_split` — so asking for the boolean and the member list
  separately would have paid the whole materialisation twice.
  **Context**: it now calls the split once and cuts both answers out of it. That is not only
  cheaper: two calls could in principle answer from two readings, which is exactly the
  divergence the single-materialisation rule exists to forbid.

- **Insight**: a question's **body** may change freely but its **key** may not.
  **Context**: `already_asked` keys on the step id `lib/question-id.sh` derives from
  `handoff-unit:<unit>`, so rewriting the composer re-asks nothing, while touching the key would
  re-ask every standing question at once. Both halves are now asserted, so a later contributor
  who rewrites the body cannot quietly rename the key with it.
