---
created_at: 2026-08-29T15:24:20+00:00
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
