---
created_at: 2026-08-29T04:21:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-s-own-findings-become-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Brake the filing to one open finding issue

## Overview

PROPOSED. An hourly step that files whatever it finds would put the tick's whole debt
into the inbox in a day. The brake is **at most one open finding issue in flight**, in
the exact shape `open_proposal` already uses: read off the open-issue ledger with **no
cursor and no stored state**, because a merged repair closes its own issue and removes
its own candidate — the two states hand off with no window between them.

**An unreadable ledger files nothing.** A brake that cannot be read is not a brake, and
`list-open-proposals.sh` / `list-open-rulings.sh` both already refuse the whole act on
`ok: false` rather than defaulting permissive. Same rule here, reported by name.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — a gate that cannot be read refuses

## Key Files

- `plugins/workaholic/skills/propose/scripts/list-open-proposals.sh` — the brake's shape
  and its marker-reading pattern; read its header before writing anything.
- `plugins/workaholic/skills/moderate/scripts/list-open-rulings.sh` — the same shape one
  artifact over, with the *no cursor and no stored state* argument written out; the
  closest precedent, since it is already in `skills/moderate/`.
- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` — the consumer.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport
  (`rules/shell.md`: never `gh issue …`, which is GraphQL-backed and 403s in a web session).

## Implementation Steps

1. Read `list-open-proposals.sh` and `list-open-rulings.sh`. Decide whether the reader is
   a new script or a mode of the first; **report which and why** — a third near-copy of
   one lookup is how the three drift, and that is the failure `lib/claims.sh`'s
   live-row rule records.
2. Read the open finding issues through `gh-rest.sh`, matched on the marker ticket 5
   writes — a **visible** line in the issue body, never an HTML comment
   (`list-open-rulings.sh`'s stated rule: a fact the loop depends on that no human
   reading the issue can see is what this loop must never become).
3. Emit `{ok, any_open, open: [{number, url}]}` or `{ok: false, reason, detail}`, exit 0
   either way, and **write nothing** — a pure read.
4. Wire it into `step-file-findings.sh` **before** the candidate set is handed back:
   `any_open` yields zero candidates with the reason named, and `ok: false` yields zero
   candidates with **its** reason named — the two are different facts and must not collapse.
5. Refuse a per-day cap by name in the contract: the ask is for an hourly loop, and this
   brake already bounds the total to one in flight.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With one finding issue open, the step files nothing and says which issue held it.
- With the ledger unreadable, the step files nothing and names that reason, distinctly.
- Nothing is stored anywhere: closing or merging the open issue makes the next tick file.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Ticket 8's drill, over a stubbed transport with no network: an open issue holds the
  second tick; removing it releases the third.

**Gate** — what must pass before approval:

- The suite is green and both refusal reasons were observed by name over the fixture.

## Considerations

- Reusing `list-open-proposals.sh` outright is tempting and probably wrong: it is keyed on
  `/propose`'s `strategy: … / move: …` marker, and a finding issue is not a proposal.
  Sharing the *shape* is the point; sharing the *marker* would make one brake hold two
  unrelated flows.
- One in flight is deliberately strict. If it measurably starves the queue, that is a
  finding for a later ask — not a number to raise inside this ticket.
