---
created_at: 2026-08-29T15:24:20+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Name the effect reading where the tick and the run speak

## Overview

PROPOSED. The reading is useless if it lands nowhere a person looks. Two surfaces
already exist and each has a rule about what may appear on it: the `🔎 Moderation`
root, which renders one **event** per changed step, and `/implement`'s run report,
which already names the delivery-retry outcome per undelivered unit. This ticket
names the effect reading on both, without inventing a third surface and without
loosening either surface's rules.

## Policies

- `workaholic:operation` / `policies/incident-response.md` — the finding must reach a reader
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — supplies `event` beside its
  log-facing `summary`
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the diff against the previous tick that
  decides what the root renders
- `plugins/workaholic/skills/drive/SKILL.md` — §7's run-report contract, where the retry outcome is
  already named
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post shapes, unchanged by this

## Implementation Steps

1. **`retire-claims` supplies an `event` when the effect reading says an act did not take.** A turn
   that took its acts supplies none, so a healthy hour still renders no line — the *a step with no
   event renders no line* guard is what keeps this from becoming a status line addressed to nobody.
2. **Keep the summary a function of the claim set and the act states alone**, so the diff against
   the previous tick suppresses an unchanged reading exactly as it suppresses every other
   restatement. A newly refused act moves the summary the hour it appears; an unchanged one does
   not.
3. **The event names the repository fact, not the tick's bookkeeping** — which units the loop
   believed it retired and did not, in words, never a count of steps that ran.
4. **`/implement`'s run report names the effect beside the delivery-retry outcome it already
   names.** The retry's vocabulary (`merged` / `merge_refused: <word>`) is untouched; what is added
   is the *effect* reading where the run took an act on a proof, in the same per-entry shape.
5. **A run that names an entry and reports no effect outcome for it is non-conformant on its
   face** — the enforcement the connector retry and the catch-up already use, and the only one
   available for a contract no script can check.
6. **No token moves.** State it explicitly, with the reason: a branch CI could not delete is not a
   fact about the unit this run drove, the same ground on which `backlog_all_excluded` and
   `base-health` move none. Any argument for moving `ok` belongs to a separate ask.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick whose retirement acts did not take effect renders a root line naming the units; a tick
  whose acts took, or whose reading is unchanged, renders none.
- `/implement`'s run report names the effect outcome for each entry where the run acted on a proof.
- No terminal token changes value because of this reading, in either surface.
- No new post shape is introduced; `notify/reference/notifications.md` is untouched.

**Verification method** — the commands/tests/probes that prove them:

- A drill over three ticks — acts took, acts refused, refusal unchanged — asserting one root line
  in the middle case and none in the others.
- A run-report fixture asserting the per-entry effect outcome and an unchanged token.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the post-shape drift pins.
- `sh scripts/e2e/loop-drill.sh verify-retire` passes, its held-block row still rendering no line.

## Considerations

- The strongest failure mode here is an hourly line saying nothing changed. Both existing guards
  (the diff, and *no event → no line*) are relied on rather than re-implemented.
- The run report is the only durable surface for `/implement`; a person reads it after the fact,
  which is why the tick's question — not this line — is what reaches somebody in time.
- Naming this on a **third** surface was considered and is refused: a report addressed to nobody is
  what `🔧 Needs a decision` and `📦 Release Preparation` were retired for.

## Final Report

Development completed as planned, on both existing surfaces and no third one.
`notify/reference/notifications.md` is untouched and no post shape was introduced.

**The tick.** `step-retire-claims.sh` supplies an `event` naming the units whose acts did not
take — *"N claims proved finished are still standing — neither the container nor CI could delete
their branches (…)"*. It names the repository fact and the units, never a count of steps that
ran. A tick whose acts all took supplies none.

**Which guard holds which case moved, and that is the one thing the ticket did not anticipate.**
There were two independent guards against an hourly restatement — an unchanged summary **and** an
empty `event` — and a blocked retirement now supplies an event, so a standing block has exactly
one:

| Case | What holds the root line |
| ---- | ------------------------ |
| acts all took | **no event** — *a step with no event renders no line* |
| a **standing** blocked unit | **the summary diff** — identical string, so the step is not "changed" |
| a **newly** blocked unit | neither: the unit set moves, the summary moves, the line renders |

That is now the load-bearing reason the summary carries no CI term, and it is written into both
`step-retire-claims.sh`'s header and `moderate/reference/workflow.md` rather than left implicit.
Re-implementing the renderer's diff inside the step to suppress a repeated event was **refused**:
the renderer already owns that comparison and a second copy is how the two would disagree —
which is step 1's own instruction to rely on the existing guards rather than re-implement them.
`verify-retire`'s stability row was updated to assert what actually holds it now (the summary,
plus an unchanged event) instead of an empty event.

**The run report.** `workaholic:drive` §6 gains a numbered third step for each `undelivered[]`
entry — `act-effect.sh delivery <unit-id>` — and §7 names its outcome per entry in the reader's
four words (`taken` / `refused: <word>` / `pending` / `unreadable`), beside the retry's own
vocabulary rather than inside it. A run that names an entry and reports no effect outcome is
**non-conformant on its face**, the enforcement the connector retry and the catch-up already
carry. **No token moves**, stated explicitly with its reason: what withholds `ok` is the unit's
*delivery* outcome, which this reading only describes.

### Discovered Insights

- **Insight**: adding an `event` to a step that previously had none on a path costs that path one
  of its two suppression guards, and the remaining guard's invariant becomes load-bearing.
  **Context**: here it makes "the summary carries no CI term" a correctness requirement rather
  than a stylistic one. Worth checking before adding an event to any other step.
- **Insight**: the step cannot suppress its own repetition without re-deriving the renderer's
  previous-tick diff, which it has no reader for.
  **Context**: that asymmetry — the renderer owns the diff, the step owns the meaning — is why
  "supply the event and let the diff work" is the only shape that does not duplicate a
  comparison.
