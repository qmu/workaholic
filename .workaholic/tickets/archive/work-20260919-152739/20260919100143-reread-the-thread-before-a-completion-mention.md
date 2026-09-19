---
created_at: 2026-09-19T10:01:43+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: hold-the-completion-mention-until-the-whole-human-request-set-is-in
merge_policy:
verification_handoff:
---

# Reread the thread before a completion mention

## Overview

Operator's ask: **issue #1146**, first item — *immediately before a completion mention, reread the
full relevant human thread and its explicitly linked continuation threads, checking
pagination/truncation and capturing new requests before advancing observation state.*

**What the tick does today.** The *Announce landed asks* step already resolves the exact
`fb:<stem>` thread, and already says *read the thread and post only if there is no prior finish
from this loop*. That read answers **have we already posted**; it does not answer **has anything
new arrived**. Requests written while the work ran are therefore outside the mention's scope, and
the person is told the batch is done while their newest ask is unseen.

**The machinery to do it correctly already exists and must be composed, not rebuilt.**
`transport/scripts/observe-channel.sh` performs the thread read with `list_thread_changes`,
bounded by `WORKAHOLIC_THREAD_FANOUT`, and reports a truncated page as `truncated: true` rather
than as silence. It also owns the cursor: it writes `unproved_since` on an unproved read, derives
`overlap_seconds`, and clears the mark **only in the same revision-checked write that advances the
cursor**. `propose/scripts/capture-inbox.sh` is the capture, dedup-keyed on the provider id.

**So the two rules this ticket must hold are already this repository's own.** First, *an unproved
observation is unread, never quiet* — a reread that could not complete withholds the mention and
is named by its reason. Second, the cursor is advanced only by the writer that already owns it:
a reread performed for the mention must capture what it finds through the existing capture and
must not advance observation state ahead of it, or the next ordinary observation will skip the
page this read just saw.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/persistence.md` — the cursor and `unproved_since` are
  stored state with one writer; a second advancing path is a lost page
- `workaholic:implementation` / `policies/observability.md` — a truncated or unproved reread is
  named, never rendered as *nothing new*
- `workaholic:implementation` / `policies/test.md` — the withhold paths are pinned hermetically

## Key Files

- `plugins/workaholic/commands/infinite-development.md` (*Announce landed asks*) — the seam; the
  reread obligation lands immediately before the mention is composed.
- `plugins/workaholic/skills/transport/scripts/observe-channel.sh` — the thread read, the fanout
  bound, `truncated`, `unproved_since`, `overlap_seconds` and the cursor write. Read it whole
  before composing it; its cursor contract is the part this ticket must not break.
- `plugins/workaholic/skills/propose/scripts/capture-inbox.sh` — the one capture, dedup-keyed on
  the provider id; a newly found request is captured through this and nothing else.
- `plugins/workaholic/skills/transport/scripts/perform.sh` — `list_thread_changes` and the route
  and degradation vocabulary the reread reports under.
- `plugins/workaholic/skills/notify/SKILL.md` — the thread lookup rules, including the standing
  prohibition on similarity and recency matching.
- `plugins/workaholic/skills/work/SKILL.md` — the coverage readings (`thread_fanout_truncated`,
  `sender_identity_unverified`) a degraded reread must report under.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Read `observe-channel.sh` in full first**, especially its cursor and `unproved_since`
   handling, and record which of its outputs the reread can reuse unchanged.
2. **Compose, do not rebuild.** The reread is the existing thread read against the mention's own
   thread coordinate and its explicitly linked continuations. Add no second transport call shape
   and no second dedup.
3. **Linked continuations are explicit only.** A continuation is followed when the thread names it
   — a link a person wrote. Never a similar thread, never a recent one; the repository's
   prohibition on fuzzy matching in a notification path applies in full.
4. **Capture before composing.** Anything new is captured through `capture-inbox.sh` first, so a
   request found by the reread is a filed ask before the mention is even considered, and the
   completion fold in this mission's first ticket sees it.
5. **Observation state advances through its one writer.** The reread must not write the cursor
   itself; it hands its window to the existing capture exactly as the ordinary observation does.
   State in the ceiling that a mention-time reread never advances the cursor on its own.
6. **Withhold on anything short of a complete read.** A truncated page, an unproved read, a fanout
   bound reached, or an unreadable continuation withholds the completion mention and is reported by
   its own reason. Cite the standing rule rather than restating it: an absence of a reading is
   never a proof.
7. **A new request found is not a failure.** It is the ordinary good case: capture it, withhold the
   completion mention, and send scoped progress (this mission's third ticket). Say so, so a later
   reader does not treat the reread as an error path.
8. **Write the obligation in one wording** carried into `commands/infinite-development.md` and
   `skills/work/SKILL.md`, pinned byte-identically by the suite.
9. **Hermetic rows** with a stubbed transport: a reread finding a new human message captures it and
   withholds; a truncated page withholds with `truncated` named; an unproved read withholds; a
   clean reread with nothing new allows the mention; and the cursor is unchanged by the reread in
   every one of those cases.
10. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
    `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A completion mention is composed only after a reread that completed; a truncated, unproved,
  fanout-bounded or unreadable reread withholds it and names the reason.
- A new human request found by the reread is captured through `capture-inbox.sh` before anything
  is composed, and withholds the mention.
- The reread advances **no** cursor; `observe-channel.sh` remains the one writer of observation
  state, byte-identical unless the story states why it had to change.
- Continuations are followed only where the thread explicitly links them; no similarity or recency
  matching appears anywhere in the change.
- The obligation is written in one wording across the ceiling and the skill.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and each withhold row fails when reverted.
- The stubbed-transport fixture shows the stored cursor byte-identical before and after a
  mention-time reread in all five scenarios.
- A fixture reread that finds a new message produces a captured ask and no mention.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- No second cursor writer and no second dedup exists after the change.
- The withhold direction is asymmetric and stated: incomplete discovery never completes a set.
- The suite is green, the bundle rebuild is diff-clean; POSIX `sh` throughout.

## Considerations

- **The cost is one extra thread read per completion mention.** It is bounded by the existing
  fanout and happens only when a fold already reads complete, which is the rare path — the same
  placement argument `/propose` uses for reading decision maturity only at its refusal.
- **A chatty thread can hold a mention indefinitely**, since every new request re-opens the set.
  That is the ask's intent, and the scoped progress message is what keeps the person informed.
- **Do not widen this into a general re-scan.** It is the mention's own thread and its explicitly
  linked continuations; a full-channel read is forbidden by the notify contract and is not the
  instrument here.

## Final Report

Development completed as planned. The reread **composes** `transport/scripts/observe-channel.sh`
and `transport/scripts/capture-inbox.sh` rather than rebuilding either, so there is no second
transport call shape, no second dedup and no second cursor writer.
`work/scripts/mention-reread.sh` is the verdict over the reading that read already reported: a
pure reader that touches no file, ref or transport. The obligation ships in **one wording** in
`commands/infinite-development.md` and `skills/work/SKILL.md`, marked and pinned byte-identically.

Verification: `node scripts/test-workflow-scripts.mjs` 7671 passed / 0 failed;
`node --test scripts/tests/agentic-loop/repair-contracts.test.mjs` 29/29 with the two new rows
(every withhold path and the one allow, plus the byte-identical pin);
`node scripts/build-plugins/build.mjs` + `verify.mjs` clean.
`git diff origin/main -- .../observe-channel.sh .../capture-inbox.sh` is empty: no cursor writer
moved.

### Discovered Insights

- **Insight**: The ticket names the capture as `propose/scripts/capture-inbox.sh`; it actually
  lives at `transport/scripts/capture-inbox.sh`, beside the observation it serves.
  **Context**: Both surfaces here cite the real path. A reader following the ticket's path would
  find nothing and might write a second capture, which is the one thing its own step 2 forbids.
- **Insight**: `observe-channel.sh` already derives `observation_settled` and `unsettled[]` as
  the single answer to *may this read be reported as nothing new* — exactly the question the
  mention needs answered.
  **Context**: That is why the verdict reader needs no coverage logic of its own; it passes the
  term through verbatim, so a new coverage axis added to the observation reaches the mention
  gate with no second edit.
- **Insight**: `noclobber` is set in this environment, and a `>` onto an existing scratch file
  silently left the previous contents in place — every fixture case in a first smoke run read
  the first case's input.
  **Context**: `rules/shell.md` predicts exactly this ("the consequence is a stale read rather
  than an empty one"); the script itself writes only into its own `mktemp -d`.
