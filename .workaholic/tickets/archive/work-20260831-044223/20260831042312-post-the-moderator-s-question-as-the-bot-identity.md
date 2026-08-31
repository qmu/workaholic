---
created_at: 2026-08-31T04:23:12+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# Post the moderator's question as the bot identity

## Overview

PROPOSED. `/moderate`'s check-in question is the post the previous ticket's
rule was written for: it is the one shape whose entire purpose is to reach a
named person, and in the single-developer configuration — the normal one — its
`<@U…>` resolves to the account the post is made as, so it notifies nobody.

The connector already resolves the tick root's timestamp when it posts the root,
so the coordinate is in hand: hand it to the tokened transport and let the bot
post the reply. The lookup, the key, the asked-once gate, the caps and the holds
are untouched — only the surface that carries the reply moves.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` and
  `plugins/workaholic/skills/moderate/reference/workflow.md` — where the agent is
  told how to post the question.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate, which
  must stay byte-identical; its `--record-ask` coordinate is what already proves
  the timestamp is in hand.
- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the root
  render, unchanged.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the question's
  shape, unchanged in wording.

## Implementation Steps

1. Confirm the coordinate is already held at post time: `--record-ask` writes
   the `(channel, ts)` onto the ask line, so nothing new needs resolving and no
   extra query is made. Record the reading.
2. State in the moderate workflow that the question reply is posted through the
   tokened transport with the root's `thread_ts` when a bot token is configured,
   and through the connector exactly as today when it is not.
3. Report the carrying surface per question in the step's own log line —
   `bot` / `connector` / the transport's own refusal word — so a question that
   reached nobody is never recorded as one that did.
4. Change **nothing** about the gate: the key, `already_asked`, `answered`, the
   per-tick cap, the day cap, the quiet hours, the working-day hold and the one
   bounded re-ask are byte-identical, and the question's wording does not move.
5. Keep the reply inside the tick root's thread either way, so the two speech
   acts stay told apart by position exactly as they are now.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- With a bot token configured, the question reply is posted by the bot into the
  tick root's thread and its mention resolves to the addressee.
- With no bot token, the post is byte-identical to today's and the log line says
  which surface carried it.
- The gate's keys, caps and holds are byte-identical across the change.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` — the existing gate and
  ordering rows must stay green.
- The new drill added by this mission's drill ticket.

**Gate** — what must pass before approval:

- The check-in gate's own tests pass unchanged, and a diff of `ask-question.sh`
  shows no change.

## Considerations

- The bot must be a member of the channel or the post fails; the transport
  already reports that as a named refusal, and the run reports it rather than
  retrying. Provisioning belongs to this mission's handoff ticket.
- Posting the reply as the bot changes the thread's author mix — a person's own
  thread will carry one bot reply per question. That is the intended cost: a
  reply nobody is notified of is worth less than one that reaches them.

## Final Report

**Outcome:** implemented.

**Step 1 — the coordinate is already in hand, confirmed rather than assumed.**
`ask-question.sh --record-ask` has written the question's own `(channel, ts)` onto the
`human-checkin-ask-<slug>` line since 2026-08-28, and `reference/workflow.md` §22 states in as
many words that *the agent knows the `(channel, ts)` at the moment it posts* — the coordinate is
an input, not a lookup. The same is true one level up: the connector returns the **root's** ts
when it posts the root, which is the ts this reply needs. **No query is added on this path**, so
`workaholic:notify`'s two-query lookup bound is untouched rather than merely respected.

**What changed.** `reference/workflow.md` §13's *The post this step produces* now states the
mechanics: the root is always the connector's (top-level, no mention, and the connector is the
transport the tick already holds); the question reply goes out through
`notify-slack.sh --thread-ts <root ts>` when a bot token is configured, landing **inside the tick
root's thread** so the two speech acts stay told apart by position exactly as they are now; and
with no bot token it goes out through the connector exactly as today. `moderate/SKILL.md` carries
the one-paragraph version beside the question's own shape rule. The **carrier rule itself is not
restated** — it lives in `workaholic:notify`, and this step owes it mechanics rather than a second
copy.

**Reported per question, never retried.** The step's log line names the surface that carried each
question — `bot` / `connector` / the transport's own refusal word — so a question that reached
nobody is never recorded as one that did. The two provisioning preconditions are named as
provisioning: the bot must be a member of the channel, and `WORKAHOLIC_SLACK_CHANNEL` must name
the channel the root was posted in. Both belong to this mission's handoff ticket.

**The gate is byte-identical, and that is checked rather than asserted.**
`git diff --exit-code plugins/workaholic/skills/moderate/scripts/ask-question.sh` reports no
change, and no script under `skills/moderate/scripts/` changed at all: the key, `already_asked`,
`answered`, the per-tick cap, the day cap, the quiet hours, the working-day hold and the one
bounded re-ask are exactly what they were, and the question's wording does not move either. Only
the account that speaks it does.

**Gate.** `sh scripts/e2e/loop-drill.sh verify-checkin-delivery` → `verdict: pass`, 11 load-bearing
rows, 0 failed, 1 breaker — the existing gate and ordering rows green and unmoved.
`node scripts/test-workflow-scripts.mjs` → 5434 passed, 0 failed.
`node scripts/build-plugins/build.mjs && verify.mjs` → all built skills self-contained.

**The cost is stated rather than absorbed.** A person's own thread now carries one bot reply per
question, which changes the thread's author mix. That is the intended trade: a reply nobody is
notified of is worth less than one that reaches them.
