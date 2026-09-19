---
created_at: 2026-09-19T09:43:41+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
feedback: [20260919094303-a-person-s-ask-can-sit-unanswered-while-the-tick-reads-clean.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
verification_handoff:
---

# Make the inbound receipt an obligation the tick cannot judge away

## Overview

Operator's ask: **issue #908**. A person's ask sat unanswered in the channel for twenty-five
minutes while four consecutive ticks reported clean; the person had to ask 「は？なんで反応しな
いの？」, and the run's next move was to *implement* rather than answer, which drew the second
correction 「着手じゃねえよ返事だ、それからだ」. Three named gaps: the receipt is suppressible by
judgement, a stand-down aimed at another agent silenced this loop, and nothing states that a
person is answered before work starts.

**The tree was re-read before this ticket was written, and the state has moved since the ask — so
only what is still missing is specified here.** The sweep and the receipt moved out of `/propose`
into the tick on 2026-09-03 (`workaholic:propose`, *The channel is the tick's*), and the tick now
files every ask first, validates the whole page through `work/scripts/acknowledgement-contract.sh`
and renders the `📥 受理` groups afterwards (`commands/infinite-development.md`). Against that:

- **Gap 1 stands.** `notify/SKILL.md:50` still reads *the receipt is never load-bearing … a
  failure of either is reported per message as `ack_failed`*, and
  `commands/infinite-development.md:247` still reads *a reaction or reply failure is still
  `ack_failed` per source*. Neither sentence distinguishes **the transport refused it** from
  **the run decided not to post it**, which is the whole of the ask's first item.
  `acknowledgement-contract.sh` validates the facts of a receipt that is **being rendered**; it is
  never reached by a run that judged the receipt away, so it does not close this.
- **Gap 2 is half-landed, in the wrong file.** The clause the ask asks for exists, in exactly one
  place: `commands/propose.md:14-15` — *An instruction to another agent does not cancel this
  loop's acknowledgement; a hold or stand-down addressed to this loop does.* A tree-wide walk finds
  it **nowhere else**: `commands/infinite-development.md`, `commands/specificate.md`,
  `commands/implement.md`, `commands/moderate.md` and `skills/notify/SKILL.md` all carry zero
  occurrences of `stand-down`. So the rule sits on the command that **no longer performs the
  sweep** and is absent from the one that does — the ceiling that actually governs the act.
- **Gap 3 stands.** A walk for *before any work*, *reply first* and 返事 over
  `commands/infinite-development.md`, `skills/notify/SKILL.md` and `skills/work/SKILL.md` returns
  nothing. The tick's step order happens to put filing and receipts before dispatch, which is the
  right behaviour arrived at by layout rather than by a stated obligation — and a layout nobody
  wrote down is the thing a later edit reorders.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` for any script change
- `workaholic:implementation` / `policies/observability.md` — the governing policy: a tick that
  answered nobody must not be reportable as a clean one
- `workaholic:implementation` / `policies/test.md` — the vocabulary split and the ceiling's
  wording are pinned by the suite, not by a reader's memory

## Key Files

- `plugins/workaholic/commands/infinite-development.md` (lines ~195-250) — the ceiling that owns
  the sweep, the receipt shapes and the `ack_failed` sentence today. Gaps 2 and 3 land here.
- `plugins/workaholic/commands/propose.md` (lines 14-15) — where the stand-down clause currently
  lives. It stays true of `/propose`'s own posts; the point is that it must also govern the tick.
- `plugins/workaholic/skills/notify/SKILL.md` (line 50) — the catalog's own statement that the
  receipt is never load-bearing; gap 1's wording lands here and must stay byte-identical to the
  ceiling's copy (the suite pins such pairs).
- `plugins/workaholic/skills/notify/reference/notifications.md` — the receipt's shape and history.
- `plugins/workaholic/skills/work/scripts/acknowledgement-contract.sh` — the facts validator. It
  is a good place for a **rendered** receipt's facts and a wrong place for *was a receipt owed*;
  read its header before deciding whether anything belongs in it.
- `scripts/test-workflow-scripts.mjs` — pins byte-identical wording across the ceilings; the row
  that walks the four routine-fired ceilings is the model for the new assertion.

## Implementation Steps

1. **Reproduce the three readings before changing anything.** Walk the tree for `ack_failed`,
   `stand-down` and the reply-before-work phrasings and record exactly which files carry each.
   Step 4's assertion is written against that before-state.
2. **Split the vocabulary, in one wording, in both places.** `ack_failed` means **the post was
   attempted and the transport refused it**. A receipt the run chose not to post is its own word —
   `ack_withheld` — and a tick carrying one is **not** a clean tick: it is reported as an
   unanswered person, named in the tick's own report. Write the wording once and carry it
   byte-identically into `notify/SKILL.md` and `commands/infinite-development.md`.
3. **Say what a stand-down covers, on the ceiling that performs the act.** Carry
   `commands/propose.md`'s existing sentence into `commands/infinite-development.md` **verbatim**,
   and extend it with the ask's own distinction: a receipt for an ask this loop has just filed is
   not a reaction, and an instruction addressed to another agent never withholds it. Do not
   rewrite `/propose`'s copy — one wording, two homes, pinned by the suite.
4. **State the reply-before-work obligation** in the ceiling, as an obligation rather than a step
   order: *a person who wrote to the channel is answered in the channel before any work on their
   ask starts*. Name that the existing order already satisfies it, so the sentence is a constraint
   on future edits and not a behaviour change.
5. **Make the withheld case visible in the report.** The tick's report names receipts owed, posted
   and withheld, each by its own word. A tick that filed an ask and posted no receipt must be
   distinguishable from one that had nothing to acknowledge, in the report and on the channel-facing
   summary alike.
6. **Add the suite assertions.** A tree walk fails when `ack_failed` is used for a withheld post;
   when the stand-down clause is absent from `commands/infinite-development.md`; when the two
   copies of the receipt wording differ by a byte; and when the reply-before-work sentence is
   missing from the ceiling.
7. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `ack_failed` appears only where a transport refusal is meant; a withheld receipt has its own word
  and its own report line.
- A tick that filed an ask and posted no receipt is reported as an **unanswered person**, never as
  a clean tick, and is distinguishable in the report from a tick with nothing to acknowledge.
- `commands/infinite-development.md` carries the stand-down clause, byte-identical to the copy in
  `commands/propose.md`, extended with the receipt-is-not-a-reaction distinction.
- The ceiling states the reply-before-work obligation in one sentence.
- `notify/SKILL.md` and the ceiling carry the receipt wording **byte-identically**.
- No receipt shape changes: `📥 受理`, `💬`, the singleton and group forms and their Japanese are
  untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, and each new assertion fails when its own
  sentence is reverted.
- `git diff origin/main -- plugins/workaholic/skills/work/scripts/acknowledgement-contract.sh` is
  empty unless the story states why the validator had to move.
- A tree walk shows `stand-down` present in both command ceilings and the two receipt wordings
  identical.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The suite is green and the bundle rebuild is diff-clean.
- The new word for a withheld receipt is defined in exactly one place and cited elsewhere, never
  restated — the repository's standing rule for a vocabulary.
- No change weakens the existing rule that a receipt failure never changes the filed issue.

## Considerations

- **This is prose enforcement, and the ticket says so rather than implying a machine gate.**
  Whether a run judged a receipt away is not a file test; what the suite can hold is the
  vocabulary, the presence of each sentence and the byte-identity of the pair. The repository
  already accepts that shape for its other composed-at-run-time rules.
- **Do not fold the withheld case into `acknowledgement-contract.sh`.** That reader validates the
  facts of a receipt being rendered; a run that withheld one never calls it, so a check placed
  there would be unreachable exactly when it is needed.
- **The ask's first item says the tick "should not read as clean"; it does not ask for a retry or
  an escalation.** Keep the existing rule that the filed issue is never changed by an
  acknowledgement outcome.
