---
created_at: 2026-08-26T15:25:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152528-read-a-person-s-addresses-through-one-script.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Audit the addresses the tree actually uses

## Overview

PROPOSED. Ticket 4's migration recovers the addresses the mapping *can* resolve. It reports the
rest by name and stops, correctly — an address no entry covers is a person the tree knows about
and the mapping does not, and inventing the entry is the guess this whole mission refuses.

That report needs a home a human reads. `/workaholify` is the preparation command: it audits and
applies. This ticket adds the mapping's **coverage** audit — every `assignees:` value in the
tree, resolved through the mapping, with each uncovered address named **together with the line
that would cover it**, applied on one confirmation.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — audits the hook; the
  queued ticket `20260821151250-install-and-audit-the-identity-mapping.md` adds the mapping's
  **existence** check here. Read that ticket whole before starting — this is the coordination.
- `plugins/workaholic/skills/workaholify/scripts/apply-bootstrap.sh` — one repair per named
  problem, one confirmation; the refusals (`settings_unparseable`, `hook_source_missing`,
  `unwritable`) write **nothing**, hook included.
- `plugins/workaholic/skills/workaholify/SKILL.md` §4 and `reference/bootstrap.md` — the named
  problems list; it stays complete.
- `plugins/workaholic/skills/gather/scripts/identity.sh` — the reader.

## Implementation Steps

1. **Coordinate with `install-and-audit-the-identity-mapping` first.** That ticket audits the
   file *exists* and covers the running account; this audits it *covers what the tree uses*.
   The ask requires they land as **one check, not two**. Read both, decide which lands first,
   and if that ticket is still queued, extend its named problem rather than adding a rival one.
   Record the decision in the ticket that lands second.
2. Read every `assignees:` value under `.workaholic/tickets/`, `missions/` and `strategies/`,
   resolve each through `identity.sh`, and collect the addresses no entry covers.
3. Report each uncovered address by name, **with the mapping line that would cover it** — a
   report naming a problem without its repair is what leaves an operator guessing at format.
4. Apply on **one** confirmation, in the style of the other repairs. An unwritable mapping
   refuses with **nothing written**, exactly as the existing refusals do.
5. **A mapping's contents are the operator's, not this plugin's** — the constraint the queued
   ticket already states. The audit may propose a line; whether an address belongs to a person
   is a human's ruling, so an unattended path must never write one unaided.
6. Keep §4's and `reference/bootstrap.md`'s named-problems list complete in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `assignees:` address across all three areas is resolved and reported as covered or not.
- Each uncovered address is named with the mapping line that would cover it.
- The apply takes exactly one confirmation and writes only the mapping.
- An unwritable mapping refuses with nothing written.
- The existence check and the coverage check are one named problem set, not two rival ones.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture tree: full coverage,
  partial coverage, no mapping file, unwritable mapping.
- Run the audit on this repository and confirm it names the addresses ticket 4 left alone.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- The named-problems list in both `workaholify` documents matches what the scripts emit.

## Considerations

- **The two audits must not become two problems with two repairs.** An operator told twice
  about one file, in two vocabularies, will fix one and assume the other followed. This is why
  step 1 is a read of the other ticket rather than a note at the end.
- A repository with legitimately team-owned work (`assignees: []`) has nothing to cover; empty
  is not an uncovered address and must not be reported as one.

## Final Report

Development completed as planned. Step 1's coordination was the first act and its decision is
recorded here, in the ticket that lands second — which turned out to be this one.

**The coordination.** `20260821151250-install-and-audit-the-identity-mapping.md` was read
whole. It is still queued, and it is one of the units this mission's own defect stranded (its
mission, `refuse-ok-under-a-placeholder-identity`, is excluded `owned_by_other`), so it could
not land first. The ask requires the two checks be **one check, not two**, so both names are
emitted from one place — `workaholify/scripts/audit-identity-coverage.sh` — and carried through
`check-bootstrap.sh` in one vocabulary: `identity_map_missing` (the file is absent, so the
hook's step 0b is a permanent no-op — that ticket's own premise) and `identity_map_uncovered`
(it exists and names no entry for an address the tree uses). A later session driving that
ticket **extends this set** rather than adding a rival one; the instruction is in
`audit-identity-coverage.sh`'s header, which is that ticket's own first Key File.

The audit walks every `assignees:` value under `tickets/`, `missions/` and `strategies/`
through `identity.sh`, and names each uncovered address **with the mapping line that would
cover it** — with a `<login>` placeholder, because which account an address belongs to is a
fact only a human has. `assignees: []` names nobody and is never reported as uncovered.
`apply-bootstrap.sh` scaffolds the file's header when absent and appends each proposed line as
a **comment**, under the same single confirmation as every other repair; an unwritable mapping
refuses `unwritable` with nothing written, hook included.

**One decision the ticket did not settle, made here and recorded.** Neither problem gates `ok`.
`identity_map_uncovered` can only be settled by a human, so gating a completion signal on it
makes `ok` unreachable by any machine — and `/workaholify`'s report-only outcome is a named
refusal's recovery path rather than the ordinary one. Whether `identity_map_missing` should
gate belongs to the queued ticket that owns the existence check, and is left to it so one
mission does not land another's ruling. Both ride `check-bootstrap.sh`'s `advisories` field.

### Discovered Insights

- **Insight**: a commented proposal is not an entry — `identity.sh` skips comments — so a
  repository that applies the repair and never edits the file behaves exactly as it did before,
  and `identity_map_uncovered` stays reported until a person completes the line.
  **Context**: that persistence is the design, not a failure of the repair. It gives the
  operator the format without letting a machine assert who somebody is, which is the line every
  ticket in this mission draws in a different place.

- **Insight**: run on this repository the audit names `noreply@anthropic.com` beside the real
  stranded address — a placeholder identity carried in six artifacts' `assignees:`.
  **Context**: it is an uncovered address that genuinely must never be mapped, which is a live
  demonstration that proposing a line and applying one have to stay different acts.
