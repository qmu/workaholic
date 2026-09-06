---
created_at: 2026-09-07T02:38:55+09:00
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
