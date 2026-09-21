---
created_at: 2026-09-21T18:04:18+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
mission: hold-operator-deferred-tickets-out-of-the-offer-and-say-so
depends_on:
feedback: []
merge_policy:
verification_handoff: 
---

# Declare an operator deferral on a queued ticket

## Overview

The declaration and its write-time floor, and nothing that reads it. This ticket introduces the
field and the one reader; the survey does not change until the next ticket.

**Why a new field rather than `status: icebox`** — decided here, recorded so a reviewer can veto
it. `icebox` exists and `drive/scripts/promote-icebox.sh` already clears it, so reuse was
weighed first. It loses on two measured grounds. (1) In this repository's vocabulary `done`,
`abandoned` and `icebox` all mean *archived with that outcome* — `drive/scripts/list-todo.sh`
drops all three from the queue walk — while the ask asks for a ticket that stays **queued** and
is **named** as held. (2) One field answering two questions is the shape this repository has
twice recorded as how two readings drift (`overdue` beside `pace`; `self_refining` beside
`describing_move`). So `icebox` is left **byte-identical** and deferral gets its own key.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a refusal is named, never silent
- `workaholic:design` / `policies/data-modeling.md` — one field answers one question

## Key Files

- `plugins/workaholic/skills/create-ticket/reference/ticket-format.md` — the frontmatter
  contract; the declaration is defined here.
- `plugins/workaholic/hooks/validate-ticket.sh` — the write-time floor on the `todo/` queue.
  It validates the ticket's *path* shape today and does not validate the *value* of `status:`;
  the new key needs its own assertion.
- `plugins/workaholic/skills/drive/scripts/` — home of the one reader this ticket adds.
- `plugins/workaholic/skills/gather/scripts/ticket-metadata.sh` — the existing metadata reader,
  to check before adding a second one.
- `plugins/workaholic/skills/drive/scripts/promote-icebox.sh` and `list-icebox.sh` — the
  existing parking mechanism. Read before writing; **not** modified by this ticket.
- `CLAUDE.md` (*Tickets, ownership, identity*) and `plugins/workaholic/rules/workaholic.md` —
  update in the same change.

## Implementation Steps

1. **Read the existing parking mechanism first** — `list-todo.sh`'s end-state filter,
   `promote-icebox.sh`, `list-icebox.sh` and `validate-ticket.sh`'s `status:` handling — and
   record in the branch story what each one does today. The new key must not duplicate any of
   it.
2. **Name the key and its value.** Prefer a key whose presence alone is the declaration and
   whose value carries the operator's reason, so the reason is visible where the hold is (the
   shape `verification_handoff:` already uses). **Absent means not deferred**, the
   `merge_policy`/`status:` convention this repository already holds, so every existing ticket
   is byte-identical.
3. **Write the one reader.** A pure read, exit 0 in every case, answering at minimum whether
   the ticket is deferred and the reason it names. An unreadable ticket answers a named reason
   and **never** `deferred: false` — an absence of a reading is never a proof that nothing is
   deferred. Nothing else in the tree may parse the key.
4. **Add the write-time floor** to `validate-ticket.sh`: a malformed declaration is refused with
   a named message. Keep the assertion syntactic and narrow; prose elsewhere in the ticket is
   not read.
5. **Verify the floor against legacy rows**, not a fresh fixture (`rules/general.md`, *A
   tightened constraint over persisted data is verified against legacy rows*): run it over the
   tickets already in `todo/`, including ones carrying `status:` values, and prove none is newly
   refused.
6. **Change no reader yet.** `list-todo.sh`, `plan-units.sh` and `claimable-units.sh` are
   byte-identical after this ticket; prove it.
7. Document the key in `ticket-format.md`, `CLAUDE.md` and `rules/workaholic.md` in the same
   commit, and run the local proof set.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket carrying a well-formed declaration validates; one carrying a malformed declaration is
  refused with a named message.
- The one reader answers deferred/not-deferred and the reason, and answers a named reason rather
  than `false` on an unreadable ticket.
- Every ticket already in `todo/` validates unchanged, and a ticket carrying no declaration
  reads exactly as before.
- `list-todo.sh`, `plan-units.sh` and `claimable-units.sh` are byte-identical.
- `status: icebox`, `promote-icebox.sh` and `list-icebox.sh` are byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/validate-ticket.sh` over every file in `.workaholic/tickets/todo/`
- `git diff --stat` proving the three readers and the icebox scripts are untouched
- `bash plugins/workaholic/skills/branching/scripts/local-proof.sh`

**Gate** — what must pass before approval:

- The local proof set reports `ok: true` with every `not_run` row named.
- The legacy-row run from step 5 appears in the branch story with its result.

## Considerations

- **The reader must be the only parser.** If a second site parses the key, the two drift; the
  suite should fail on any other reference to it.
- **Stated cost of a new key**: two parking concepts now exist side by side. That is deliberate
  — they answer different questions — and the documentation must say when to reach for which,
  or operators will use them interchangeably and the distinction will be lost.

## Final Report

Development completed as planned. `deferred: <why>` is the declaration, `drive/scripts/read-deferral.sh` is
its one reader, and `hooks/validate-ticket.sh` carries the write floor. No reader changed: `list-todo.sh`,
`plan-units.sh` and `claimable-units.sh` were byte-identical after this ticket, and `status: icebox`,
`promote-icebox.sh` and `list-icebox.sh` are untouched for the whole mission.

Step 1 (read the existing parking mechanism first) found what decided the design: `list-todo.sh` filters
`done | abandoned | icebox` out of the **queue walk**, so an iceboxed ticket never reaches the survey at
all — the ask asks for a ticket that stays queued and is named. `promote-icebox.sh` clears `status:` to
bring one back; `validate-ticket.sh` validates `status:`'s *path* implications and never its value.

Step 5 (the legacy-row floor) ran the hook over **every** ticket on disk under the old and the new copy
and diffed the exit statuses: **1516 rows, 747 of them carrying a `status:` value, byte-identical**. The
96 refusals are all pre-existing and all from other rules (frontmatter absent in the 2026-01 `feat-*`
archive, a retired filename shape, a `depends_on` entry that is not a filename); **zero** come from the new
key, and every one of the 5 queued tickets passes.

### Discovered Insights

- **Insight**: An empty frontmatter value and an absent key are the same answer to every existing reader
  in this plugin (`fm_field`, `validate_field`), so a floor that must tell them apart needs its own
  presence probe — here an `awk` emitting `present<TAB><value>`.
  **Context**: That is why the write floor refuses a bare `deferred:` rather than tolerating it the way
  `merge_policy:` does: for `merge_policy` an empty value has a safe reading (`review`), and for a hold
  it has two contradictory ones.
- **Insight**: The scaffolded ticket template in `create-ticket/reference/ticket-format.md` is copied
  verbatim into new tickets, so any key added there with an empty value is written into every ticket.
  **Context**: `deferred:` is deliberately absent from that template — adding it would make the scaffold
  emit the one shape the floor refuses, and the file now says so beside the template.
