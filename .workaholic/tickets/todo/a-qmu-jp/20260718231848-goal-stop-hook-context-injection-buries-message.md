---
created_at: 2026-07-18T23:18:48+09:00
author: a-qmu-jp
type: enhancement
layer: [Config, UX]
effort:
commit_hash:
category:
depends_on:
---

# `/goal` Stop-hook + per-turn context injection buries the developer's own message

Filed from a downstream project that drives long `/monitor` sessions under a
`/goal` condition. Not blocking, but it degrades readability enough that the
developer loses the thread of their own conversation.

## Symptom

Setting a goal with `/goal <condition>` (e.g. `/goal /monitor ok`) installs a
session-scoped Stop hook that blocks stopping until the condition holds. That
part works as intended. The problem is the **volume of injected text around
each turn**:

- Every `UserPromptSubmit` is prefixed with a large injected block (the active
  mission roster / roadmap reminder, several lines per mission).
- The goal-condition reminder and the roadmap block reappear on essentially
  every turn for the life of the session.

When the developer types a short message, their actual words end up sandwiched
between — and dwarfed by — many lines of machine-injected context. In a busy
session (here, ~9 missions in the roster) the injected block is long enough
that **the developer can no longer easily see the message they just typed**
when scrolling back. The signal (what the human said) is lost in the noise
(what the hooks re-inject).

## Impact

- Hard to follow the conversation: the developer's own prompts are not
  visually findable amid repeated injected context.
- The repetition is largely redundant turn-to-turn (the roster rarely changes
  within a session), so most of the volume carries no new information.
- Worse the larger the mission set, i.e. exactly the long-running orchestration
  sessions `/goal` + `/monitor` are meant for.

## Request

Reduce how much the goal/roadmap machinery injects per turn, and keep the
developer's own message visible. Any of these would help (author's choice):

1. **Summarize instead of enumerate.** Inject a one-line roster summary
   (counts + the single next action) rather than a full per-mission block on
   every turn; link out to the detail rather than reprinting it.
2. **Inject on change, not every turn.** Re-emit the roadmap block only when the
   roster/progress actually changed since the last turn; otherwise emit a short
   "roadmap unchanged" line (or nothing).
3. **Keep the goal reminder terse.** The Stop-hook goal only needs a compact
   "goal active: <condition>" line, not a re-expansion of surrounding context.
4. **Preserve message visibility.** Ensure injected context is delimited so the
   developer's typed message remains clearly separable in the transcript (e.g.
   the injection stays after the message, not interleaved with it).

## Notes for the maintainer

- Reproduce with any multi-mission session: set `/goal /monitor ok`, then send
  a few short follow-up messages and observe how much injected text surrounds
  each one.
- The two contributors appear to be (a) the `/goal` session Stop-hook and
  (b) the per-`UserPromptSubmit` active-mission roster injection. The fix likely
  lives in whichever hook emits the roster and in the goal-hook's reminder text.
- No urgency; this is an ergonomics/readability improvement, not a correctness
  bug. The Stop-gating behavior itself is fine and should stay.

## Policies

- **workaholic:design** (self-explanatory-ui, no-dark-patterns) — injected
  machine context should aid, not obscure, the human's view of their own
  conversation; the developer's message must stay legible.
- **workaholic:implementation** (objective-documentation) — this request states
  observable behavior (injected block length vs. message visibility), not taste.

## Quality Gate

The maintainer decides the mechanism; a fix is acceptable when, in a session
with a `/goal` condition set and a large mission roster:

- The developer's own typed message stays clearly visible / separable in the
  transcript and is not dwarfed by injected context every turn.
- Per-turn injected roadmap/goal text is materially reduced (summarized or
  emitted only on change) without losing the ability to see the active goal and
  the next action.
- The Stop-hook gating behavior of `/goal` is unchanged (it still blocks
  stopping until the condition holds).
