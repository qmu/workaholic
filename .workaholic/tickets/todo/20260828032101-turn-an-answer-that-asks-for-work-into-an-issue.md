---
created_at: 2026-08-28T03:21:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Turn an answer that asks for work into an issue

## Overview

**PROPOSED.** This is the ticket that closes the return path: an answer that **asks for
something** becomes an `[FB]` issue through `file-inbound-ask.sh` — the writer the `:40`
sweep already uses — assigned to the running identity, so the next `[Specificate]` tick
ingests it exactly like any other ask. **No second inbox**: the work rides the existing
issue ledger, and `file-inbound-ask.sh` is the filer.

**Dedup keys on the question's own content key**, so one answer is filed exactly once
however many ticks read the thread. That is the same no-cursor, no-tree-write property the
sweep's `slack-ref` marker already has: the marker is read back out of the issues
themselves.

Not every answer asks for work. An answer that rules on a question, declines it, or simply
says "yes, do that" may need no issue at all — the filing bar is the feedback skill's own,
and *when unsure, skip and say what made you unsure* costs one hour, not the answer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-writer.md` — one filer, no second inbox

## Key Files

- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the filer; read its
  header for the three-axis stamp, the dedup marker and how it hands to `open-issue.sh`.
- `plugins/workaholic/skills/propose/scripts/list-swept-slack-refs.sh` — the precedent for
  reading a dedup marker back out of the issue ledger with no stored cursor.
- `plugins/workaholic/skills/feedback/scripts/open-issue.sh` — the one issue-opening seam.
- `plugins/workaholic/skills/feedback/SKILL.md` — *Whether this merits filing*, the bar.
- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — the content key the
  dedup marker is derived from.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where the filing bar and
  the per-answer reporting contract are written.

## Implementation Steps

1. **Read `file-inbound-ask.sh` and `list-swept-slack-refs.sh` in full.** The marker
   mechanism, the assignee rule and the subject stamp are all already decided; this ticket
   supplies a second caller, not a second design.
2. **Decide the dedup marker and read it back from the ledger, not from a cursor.** The
   question's own content key is the natural marker: it is stable across ticks, already
   derived in one place, and identifies the answer's subject rather than its wording. Read
   it back out of the open issues the way the sweep reads its `slack-ref`.
3. **Apply the filing bar per answer**: does this answer ask for something? File through
   `file-inbound-ask.sh` when it does; skip and name what made you unsure when it does not.
   Report `filed: <issue>` or `not_filed: <reason>` per answer — an answer named with no
   outcome is non-conformant on its face.
4. **Assign to the running identity**, so `[Specificate]`'s discovery — which reads only
   issues assigned to the running identity — actually ingests it. Filing it unassigned
   would reproduce the measured defect where an ordinary crossing was proposed by nobody.
5. **Carry the direction**, as every other writer of an ask does: judge the strategy the
   answer falls under and stamp its refs through `feedback/scripts/ask-feedback-line.sh` —
   the one writer of that line — or write no line when the answer names no direction.
   Without this the work born here intersects every strategy's `feedback[]` at nothing,
   which is the measured failure the sweep's own carry fixed on 2026-08-26.
6. **Never load-bearing on the recording.** The answer is already recorded before any
   filing is attempted; a filing failure is reported and changes nothing about the
   recorded answer or the question's state.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An answer that asks for work becomes exactly one `[FB]` issue through
  `file-inbound-ask.sh`, assigned to the running identity, however many ticks read it.
- The issue carries the direction it answers, or no `feedback:` line when it names none.
- Every recorded answer reports `filed:` or `not_filed: <reason>`.
- No second inbox and no stored cursor: the dedup marker is read back out of the issues.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including a two-tick test proving the second
  tick files nothing for an answer the first already filed.
- A grep-level assertion that this path opens issues only through `file-inbound-ask.sh`.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green, the carry-chain test included.
- No new writer of the `feedback:` ask line and no new issue-opening seam.

## Considerations

- **The overlap with `step-unanswered-asks.sh` is deliberate and must not be collapsed.**
  That step asks about a channel message nobody answered; this files an answer to the
  tick's own question. One is a question, the other is work.
- If the answer's own words are the whole ask, the issue body is those words plus the
  question they answer — a filed ask that does not say what it was answering is unreadable
  a day later.
