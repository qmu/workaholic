---
created_at: 2026-08-23T09:38:03+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: route-a-stalled-unit-to-a-person-who-is-asked-by-name
merge_policy:
verification_handoff: 
---

# Let an answer in the moderator session clear the question

## Overview

The developer's flow ends where the plugin currently has nothing: they open the session link on
the question, answer **inside the moderator's own session**, and expect the loop to continue.

Today the tick has no notion of an answer. `ask-question.sh` records that a key **was asked** and
refuses to ask it again; nothing records that it was **answered**. So an answered question and a
question nobody will ever answer are the same state, and whatever the person said in that session
dies with the container.

This is the same shape as the defect that made `/moderate`'s own feedback records evaporate: work
done inside a routine's container reaches nobody unless something carries it to the base.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the `already_asked` ledger,
  matched on the step id derived from the content key.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` / `log-read.sh` — the tick log's
  only writer and reader; append-only, idempotent per `(tick, step)`.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the one seam that carries a
  tick's log to the base, and the reasoning for why it is a direct commit.
- `plugins/workaholic/skills/moderate/SKILL.md` — states what the tick writes and where.

## Implementation Steps

1. **Reproduce.** Ask a question, answer it in the session, run the next tick, and confirm from
   the scripts that nothing distinguishes that from an unanswered one.
2. **Localize.** Confirm the asked-once ledger is the only record of a question's life, and that
   the tick log is the only thing a tick carries to the base.
3. Record an **answered** state distinct from both *asked* and *never asked*. The tick log is the
   natural home — it already holds the ledger, it is append-only, and `persist-log.sh` already
   carries it to the base without a branch or a claim.
4. Make the check-in read it: an answered question is not re-asked **and not re-held**; an
   unanswered one keeps its existing behaviour exactly.
5. **Say what the answer was**, not merely that one came. A recorded answer nobody can read is
   the same failure at one remove — the next run must be able to act on it.
6. Keep the log append-only and never rewrite a line already on the base.
7. Update `moderate/SKILL.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A question answered in the moderator session is recorded with its answer, on the base.
- The next tick neither re-asks nor re-holds it, and an unanswered question is unchanged.
- `answered`, `asked` and `never asked` are three distinct states.
- The tick log stays append-only; no line already on the base is rewritten.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A two-tick hermetic run: ask, answer, re-tick, assert not re-asked and the answer readable.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Drive this last in the mission; without a question there is nothing to answer.
- The answer is a person's words in a session, so nothing can parse it into a decision
  automatically. What this ticket owes is that the words **survive and are found** — acting on
  them stays the next run's judgement.

## Final Report

Development completed as planned. A question now has three states, distinguishable from the tick
log alone and with **no new store**:

| State | In the log |
| --- | --- |
| `never_asked` | no `human-checkin-ask-<slug>` line |
| `asked` | that line, and no answer beside it |
| `answered` | `human-checkin-answered-<slug>`, whose **summary is the person's words** |

`record-answer.sh` writes the answer through `log-append.sh` — the log's only writer, append-only,
idempotent per (tick, step) — so `persist-log.sh` carries it to the base with no branch and no
claim, exactly as it carries every other line. `question-state.sh` reads the three states back.
`ask-question.sh` consults it before the asked-once ledger and refuses an answered question under
its **own** reason, `answered`, carrying the words.

**Why `answered` is its own refusal rather than a kind of `already_asked`.** Both refuse and
neither holds, so the volume behaviour is byte-for-byte what it was — but *a person resolved this*
and *nobody ever will* were the same state, and that was the defect. Making them one reason again
would have shipped the flag without the distinction it exists for.

**The words, not the flag.** A recorded answer nobody can read is the same failure at one remove,
so the answer rides in the log summary and comes back on both the state read and the gate's
refusal. **Nothing parses it**: it is a person's prose, and acting on it stays the next run's
judgement — what this ticket owed is that the words survive and are found.

**One derivation of the question id**, extracted to `lib/question-id.sh` and sourced by the gate,
the writer and the reader. Three scripts key on that identity now, and a question whose id differed
between them would silently be a different question — an answer filed under one id would never
clear a gate reading another. The derivation itself did not change, so no live question's id moved.

**Append-only is preserved by construction.** Recording the same answer twice in one tick is a
no-op; a correction in a later tick appends its own line and the reader takes the newest, so no
line already on the base is ever rewritten and both remain as the audit trail. An **empty** answer
is refused (`no_answer`) rather than recorded: it is indistinguishable from a mis-click and would
clear the gate on a question still open. A missing log reads `never_asked` — a repository with no
tick history has asked nothing — while a log that exists and cannot be read is `unreadable`, named,
because only one of those is calm.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3360 passed, 0 failed, with a
hermetic two-tick fixture that walks never_asked → asked → answered, asserts the words come back
on both surfaces, asserts an empty answer is refused and leaves the key untouched, and asserts
that a later correction appends without rewriting the earlier line.
