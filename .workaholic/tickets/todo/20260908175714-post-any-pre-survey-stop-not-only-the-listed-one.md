---
created_at: 2026-09-08T17:57:14+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: clear-the-residue-the-base-already-holds-and-never-stop-silently
merge_policy:
verification_handoff: 
---

# Post any pre-survey stop, not only the listed one

## Overview

PROPOSED. The 100 minutes measured on 2026-09-08 were silent on Slack, and the ask attributes that
to `workaholic:notify`'s precondition-stop class being a closed list whose only member is
`no_plugin_source`. **Discovery does not confirm that as the cause, and the ticket is written to the
mechanism rather than to the report** (`workaholic:discover`, *Diagnosis-First Rule*). What the
class actually decides is *severity* — a listed signature posts the calm `⚪ Paused` on its first
report; `notify/SKILL.md` says in its own words that a signature outside the class *is a red alert
from its first report*. So the list's membership does not by itself silence anything.

The silence has a different, verifiable cause: **nothing was ever in a position to post.** The
obligation to post a pre-survey stop lives in `commands/implement.md` ("If the run stops before
claiming anything, post `workaholic:notify`'s precondition-stop shape instead"), and the coordinator
never spawned an `/implement` runner — `claimable-units.sh` answered `readable: false,
reason: not_current` and the allocation went to zero. `claimable-units.sh`'s own header states the
caller's contract for that answer — *fall back to one runner and report it* — and
`commands/infinite-development.md` does not carry it. A reading that could not be made became zero
capacity, which is the collapse that header exists to forbid.

So the repair is at the coordinator: an unreadable allocation reading spawns the pass and says so,
and a tick that terminates before any runner is spawned reaches the channel under its own signature.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/infinite-development.md` — the allocation paragraph, which must carry
  `claimable-units.sh`'s stated caller contract, and the report/end section, which must carry the
  post obligation for a tick that spawns nothing.
- `plugins/workaholic/skills/loops/scripts/claimable-units.sh` — read only; it already answers
  `readable: false` with its reason. **Not modified**: the reader is correct.
- `plugins/workaholic/skills/loops/SKILL.md` — the execution model the coordinator's contract lives
  beside.
- `plugins/workaholic/skills/notify/SKILL.md` — *The precondition-stop class*, which gains the
  coordinator-level stop and states that a stop's visibility does not depend on the list's
  membership.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `⚪ Paused` shape.
- `plugins/workaholic/commands/implement.md` — read, to keep the two ceilings' wording from drifting.
- `scripts/test-workflow-scripts.mjs` — the suite that pins ceiling wording byte-identically.

## Implementation Steps

1. **Reproduce and localize first.** Feed the coordinator a `claimable-units.sh` answer of
   `readable: false, reason: not_current` and record what it does: the allocation reached, whether a
   runner is spawned, and what reaches Slack. Confirm against the measured 21 ticks that the silence
   is the coordinator's and not the notify class's.
2. In `commands/infinite-development.md`, state the reader's own caller contract where the fanout is
   derived: an unreadable claimable reading falls back to **one** runner and names the reason in the
   report — it never becomes zero. Say it in the same voice as the existing load rule ("never turn an
   unreadable load into zero capacity"), so the two read as one rule rather than two.
3. Give the coordinator the post obligation it lacks: a tick that ends having spawned **no** runner
   for a reason of its own — an unreadable allocation reading, a freshen refusal, a degraded issue
   source — posts the precondition-stop shape under its **own** signature, exactly as
   `commands/implement.md` requires of a run that stops before claiming. The existing dedup,
   escalation and cool-down apply unchanged; nothing new is invented for it.
4. In `notify/SKILL.md`, extend the precondition-stop class with the coordinator-level stop by a
   deliberate edit (which is what that section requires) and state plainly that the class decides
   **severity**, not whether a stop is announced at all — the misreading the ask records is worth
   closing in the text, since it cost a reader a wrong diagnosis.
5. Keep the wording byte-identical across the ceilings that carry it, and extend
   `scripts/test-workflow-scripts.mjs`'s pinning rows to cover the coordinator's copy.
6. Update `CLAUDE.md`'s notify and loop sections in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A coordinator tick whose claimable reading is `readable: false` spawns one runner and names the
  reason; it never reaches an allocation of zero on that reading.
- A tick that ends having spawned no runner posts a precondition-stop shape carrying its own
  signature.
- The post shape, dedup, escalation and cool-down rules are unchanged.
- The ceiling wording is byte-identical wherever it appears, and the suite proves it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the pinning rows, extended.
- The step 1 reproduction re-run, showing one runner spawned and one post produced.
- A diff over `notify/reference/notifications.md`'s shapes, expected empty.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs` and
  `node scripts/build-plugins/verify.mjs` clean.

## Considerations

- **The reporter's mechanism is recorded as a hypothesis and not adopted.** *Visibility depends on
  the class list being exhaustive* is what the ask proposes; `notify/SKILL.md` says the opposite in
  its own text, so the ticket repairs what discovery found instead. The ask's underlying complaint —
  100 minutes of silence — is fully real and fully addressed.
- **Falling back to one runner on an unreadable reading is deliberately not the same as ignoring the
  reading.** The runner is spawned *and* the reason is named, so a repository where the reading is
  permanently unreadable is loud rather than quietly busy.
- The coordinator's post is bounded by the existing dedup, so a condition standing for 21 ticks
  produces one root and threaded replies, not 21 roots.
- Non-goal: no new notification shape, no new transport, no second liveness authority. This ticket
  adds a caller to shapes that already exist.
- Sequencing: this ticket is independent of the two before it and can land in either order, but it
  is placed last because with the residue cleared this stop stops firing, and the repair should be
  proved against a stop that can still happen.
