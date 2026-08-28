---
created_at: 2026-08-28T03:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Record the answer through the one writer

## Overview

**PROPOSED.** The agent judges which replies in a question's thread are a person's answer
and hands them to `record-answer.sh` — **still the only writer of the answered line**,
still append-only through `log-append.sh`, still carried to the base by `persist-log.sh`.
This is the ticket that makes the previous one's read mean something: it flips
`question-state.sh` from `asked` to `answered` for a question a person answered **where it
was asked**, which is the whole point of the mission.

**A machine's own post is never an answer.** The tick's own root, its questions, its
`✅ 解消を確認` confirmations and any other post this plugin emits are excluded by shape —
the same exclusion the inbound sweep already makes for the loop's own posts.

**Nothing parses the answer.** It is a person's prose; `record-answer.sh` stores it
verbatim (flattened to one line) and acting on it stays the next run's judgement. What
this ticket owes is that the words survive, are found, and clear the gate.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-writer.md` — one writer of the answered line, never a second

## Key Files

- `plugins/workaholic/skills/moderate/scripts/record-answer.sh` — the one writer; read its
  header in full before calling it (idempotency, the empty-answer refusal, the flattening).
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — the reader that must
  now return `answered` for these keys.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate whose `answered`
  refusal already exists and must keep working unchanged.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — carries the line to the
  base; the tick already runs it twice for exactly this reason.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where the judgement's bar
  is written down.

## Implementation Steps

1. **Read `record-answer.sh` end to end first.** It refuses an empty answer deliberately
   ("answered with nothing" would clear a gate on an open question), it is idempotent per
   (tick, step), and a later, different answer appends its own line with the reader taking
   the newest. None of that changes; this ticket only supplies it a caller.
2. **Write the judgement's bar in `reference/workflow.md`**, not in a script: a reply is an
   answer when a **person** wrote it in that question's thread. Exclude every post this
   plugin emits, by shape. When unsure, **do not record** and say what made you unsure —
   the standing bar, and here it costs one hour rather than the answer.
3. **Wire the recording** into the tick after the thread read returns: per candidate, either
   `record-answer.sh --tick --key --answer` with the person's words, or a named
   not-recorded reason. One or the other for every candidate the previous step named — a
   candidate handed back with no outcome is non-conformant on its face.
4. **Persist.** The answered line must reach the base, so the recording happens where
   `persist-log.sh`'s second run still covers it. Confirm this against the existing
   `<step>-filed` precedent rather than assuming — a line that dies with the container is
   the exact defect that made the tick's feedback records evaporate.
5. **Prove the gate flips**: `question-state.sh` reads `answered`, and `ask-question.sh`
   refuses that key under `answered` rather than `already_asked`, with the words carried.
6. **Flip the pin from ticket 1** at its named flip point: the walk now ends `answered`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A person's reply in a question's own thread is recorded through `record-answer.sh` and
  the question reads `answered`.
- A machine's post in the same thread is never recorded as an answer.
- Every candidate from the read step gets an outcome: recorded, or a named reason.
- `record-answer.sh` remains the only writer of the answered line; the log stays
  append-only and the answer reaches the base.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — ticket 1's walk now asserts `answered`.
- A test asserting a machine-authored reply leaves the state `asked`.
- A grep-level assertion that no second writer of `human-checkin-answered-` exists.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green, including the flipped walk.
- The existing check-in and question-state tests pass unchanged.

## Considerations

- **Recording an answer must not re-ask or confirm anything on its own.** `answered` is
  already its own refusal at the gate, and `✅ 解消を確認` keys on `settled`, not on
  `answered` — those two paths are untouched and must be verified untouched, not assumed.
- A person who answers twice is a person correcting themselves: the later line wins, and
  nothing on the base is rewritten. That behaviour already exists; do not add an edit path.
