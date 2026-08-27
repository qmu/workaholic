---
created_at: 2026-08-26T15:25:28+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152528-read-a-person-s-addresses-through-one-script.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Stamp only an address the loop can drive

## Overview

PROPOSED. `/specificate` stamps *the triggering issue's assignee* on every artifact it emits.
The issue carries a **GitHub login**; the artifact needs a **git address**; and nothing in the
run converts one to the other, so the running session resolves it by judgement. Measured on
this repository: the judgement produced `tamura.yoshiya@gmail.com` for the login
`tamurayoshiya`, whose committed mapping says `a@qmu.jp`. Every artifact stamped that way is
excluded from every survey, permanently.

This is the **writer's** half of the repair, and it prevents the next strand. Ticket 3 is the
reader's half and recovers what already exists; ticket 4 recovers the artifacts.

The prevention is the point: an address the loop cannot resolve must never be stamped, because
a wrong address is silently unrecoverable while `assignees: []` is a documented, claimable
state that any run can pick up.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/identity.sh` — ticket 1's reader; the only
  permitted resolution.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — steps 8 and 9, where
  `--assignee` is passed to the two scaffolds; step 13, the run report.
- `plugins/workaholic/skills/specificate/SKILL.md` — *Act only on an ask that is yours*, which
  states the `--assignee` contract and the standing refusal to substitute the running identity.
- `plugins/workaholic/skills/specificate/scripts/scaffold-draft.sh` and
  `scaffold-proposed-ticket.sh` — both already write an empty `assignees:` when no flag is
  given, so the unresolvable path needs no new behaviour from either.

## Implementation Steps

1. Reproduce first: take an issue assigned to a login the mapping does **not** name, run the
   assignee resolution as it stands, and record what address it stamps. The defect is that a
   judgement runs where a lookup should; confirm that before changing it.
2. Resolve the triggering issue's assignee **through `identity.sh`** before either scaffold
   call. Resolvable → pass the **canonical** address to `--assignee`.
3. Unresolvable → pass **no** `--assignee` at all, so the artifact is written team-owned. Never
   a guessed address; the standing refusal to substitute the running identity is untouched and
   applies here with the same force.
4. Report it per artifact as `assignee_unmapped: <the login>` in the run report (step 13) and
   name it in the pull-request body (step 10). A team-owned artifact is a real outcome, not a
   degradation — but one nobody was told about reads like a decision somebody made.
5. Update `SKILL.md` and `reference/workflow.md` so the `--assignee` contract states the
   resolution and its named refusal.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An issue assigned to a mapped login (canonical **or** alias) produces artifacts stamped with
  the canonical address.
- An issue assigned to an unmapped login produces `assignees: []` and an `assignee_unmapped`
  report line naming the login.
- No path stamps an address the mapping does not name, and none substitutes the running identity.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases for all three inputs (canonical,
  alias, unmapped) over a fixture mapping, asserting the stamped value and the report line.
- Ticket 8's end-to-end case covers the same three inputs through to the survey.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No case produces an address absent from the fixture mapping.

## Considerations

- **An unassigned issue and an unmapped assignee both produce team-owned work, and they are
  different facts.** The first is nobody's; the second is somebody's, unresolvably. Report them
  by different names so a reader can act on the second by adding a mapping line.
- The strategy form's `no_assignee` rule is untouched: `create.sh` refuses an empty assignee
  list, so an unmapped assignee makes a strategy record-only exactly as an unassigned issue
  does. Check that path explicitly rather than assuming the mission/ticket fix covers it.

## Final Report

Development completed as planned.

**Reproduced first, as step 1 required.** The defect is not a wrong lookup — there is no
lookup at all. `reference/workflow.md` step 8 read `--assignee <the triggering issue's
assignee>`, a prose instruction the running session fills by judgement, with nothing in the
chain converting a GitHub login to a git address. That is why the judgement produced a
person's second address and why no test could have caught it.

The assignee is now resolved through `identity.sh` before either scaffold is called, once,
and reused for every call in step 9. Resolvable passes the canonical address; unresolvable
passes **no** `--assignee` at all and reports `assignee_unmapped: <login>` in the run report
and the pull-request body. Both scaffolds already wrote an empty field with no flag, so the
unresolvable path needed no new behaviour from either. The strategy form's path was checked
explicitly rather than assumed: `create.sh` refuses an empty assignee list, so an unmapped
assignee makes a strategy record-only reporting `assignee_unmapped`, exactly as an unassigned
issue makes it record-only reporting `no_assignee`.

### Discovered Insights

- **Insight**: the two team-owned outcomes are reported under different names because only one
  of them has a repair. An unassigned issue is nobody's work; an unmapped assignee is
  somebody's, unresolvably, and the fix is one line in `.claude/git-identities`.
  **Context**: folding them into one reason would tell an operator that work is team-owned
  without telling them it is team-owned *by mistake* — which is the difference between a
  decision somebody made and a defect nobody was told about.

- **Insight**: the ticket scaffold writes `assignees:` bare when empty while the mission
  scaffold writes `assignees: []`; both read back as unowned through `owners.sh`.
  **Context**: a test asserting the literal `[]` on a ticket fails for a reason that has
  nothing to do with the behaviour under test. Assert through the oracle, not the shape.
