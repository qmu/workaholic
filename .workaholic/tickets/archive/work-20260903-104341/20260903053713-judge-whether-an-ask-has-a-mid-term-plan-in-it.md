---
created_at: 2026-09-03T05:37:13+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: emit-a-mission-only-when-there-is-a-mid-term-plan-to-hold
merge_policy:
verification_handoff: 
---

# Judge whether an ask has a mid-term plan in it

## Overview

`/specificate` emits one mission per inbound ask. Measured in a single hour: eight asks arrived
from the channel, seven became missions and one a record — seven missions inside twenty-one
minutes, forty-eight tickets between them. Nothing asks whether a given ask *deserves* a
mid-term plan. This is the judgement the operator asked for, and it sits in the form precedence
where the decision is already made.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/SKILL.md` — *The form follows the work's shape*, the
  ordered four-row rule.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 7, where the form is
  decided, and step 13, where the deciding rule is reported.
- `plugins/workaholic/rules/workaholic.md` — the rule from the sibling ticket, cited here.

## Implementation Steps

1. Add the question to row 1 of the precedence: an ask decomposes into two or more units **and**
   there is a mid-term plan to hold — several tickets wanting ordering and allocation across a
   period. Both terms, not either.
2. An ask that decomposes but carries no such plan takes the next row it fits: a loose ticket
   when it is atomic enough, otherwise the tickets it names without a mission wrapper, otherwise
   the record alone.
3. Report the judgement by name in step 13 and in the pull-request body, beside the existing
   `precedence:<form>`: what the ask was judged to be and what it became instead. A reader must
   be able to disagree with it.
4. Do **not** bound how many missions the ingest path may open in a window. `WORKAHOLIC_WIP_LIMIT`
   deliberately holds origination only, and a limit that swallowed the operator's own
   instructions on a busy day is a defect rather than a brake — state that here so the obvious
   next request is refused deliberately rather than by accident.
5. Keep every existing floor over the top: the two-ticket floor, the mission ceiling, the carry
   floor and the handoff rules are untouched.

## Quality Gate


**Acceptance criteria** — the checkable conditions that must hold:

- Row 1 requires both terms, and an ask with no mid-term plan does not produce a mission.
- The judgement is named in the run report and the pull-request body.
- No cap is placed on the ingest path.

**Verification method** — the commands/tests/probes that prove them:

- A dry read of the next several inbound asks against the new rule, recorded in the result.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Every existing floor still runs; the change adds a judgement, not an exemption.

## Considerations

- This makes `/specificate` emit fewer missions and more loose tickets. That is the intent, and
  the run report saying which is what keeps a quieter loop from being indistinguishable from a
  stopped one.
