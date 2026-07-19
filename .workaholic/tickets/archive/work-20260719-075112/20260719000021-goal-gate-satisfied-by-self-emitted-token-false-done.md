---
created_at: 2026-07-19T00:00:21+09:00
author: a@qmu.jp
type: bugfix
layer: [Config, UX]
effort:
commit_hash:
category:
depends_on:
---

# `/goal <token>` gate is satisfiable by the agent emitting the token — false "done"

The `/goal <condition>` Stop hook is meant to keep the agent working until a
real objective holds. In practice, when the condition is a terminal token the
agent itself prints (the documented pattern `/goal /monitor ok`), the gate is
satisfied the moment the agent writes that token — regardless of whether the
underlying work is actually finished. The agent can **silently declare itself
done and stop while the objective is materially incomplete.**

## Observed

Real session: `/goal /monitor ok` was set over 9 missions. One `/monitor`
invocation drove one wave, then emitted the terminal line `ok`. The Stop hook
released and the agent settled as if the job were complete. The actual state
at that moment:

- 1 of 9 missions actually complete; the rest at 4/7, 3/6, 1/7, or blocked on
  missing credentials.
- Nothing merged, nothing shipped — all work sat on unmerged desk branches.

`/monitor`'s own contract calls this a legitimate terminal state ("every
incomplete mission is escalation-blocked"), so the `ok` was contract-valid.
But to the developer watching, the agent **looked satisfied that it had done
its job when it had not** — the token is a self-graded proxy, and the gate
trusts it.

Two compounding factors:

1. **The gate trusts a self-emitted token.** `/goal <token>` clears when the
   token appears in the agent's output. The agent both does the work and writes
   the word that says the work is done — it can (and here did) write "ok" over
   a hollow completion. A gate the graded party controls is not a gate.
2. **"Escalation-blocked ⇒ terminal ⇒ ok"** lets a run emit the success-shaped
   token with almost nothing achieved. From the transcript, `ok` reads as
   "done"; the honest reading is "I stopped, mostly nothing landed, the rest is
   someone else's problem." The token's shape oversells the outcome.

## Impact

The developer cannot trust that a released `/goal` means the goal was met. The
failure is quiet: no error, no warning — the session just ends looking
successful. That is worse than a visible stall, because it invites the
developer to move on when they should not.

## Request

Make a released `/goal` mean the objective actually held, not that the agent
said a word. Author's choice of mechanism; any of these addresses it:

1. **Don't let the graded party grade.** Evaluate the goal condition from
   observable state (e.g. `/monitor`'s own `status.sh`/mission completion,
   an exit code, a file check), not from the presence of a token the agent
   emits. If the condition is inherently a token, require it to be corroborated
   by such state before the hook clears.
2. **Separate "I stopped" from "it's done."** When a run reaches a terminal
   state with unmet acceptance / open escalations, the terminal token should
   carry that — e.g. `pending` (already defined) must win over `ok` whenever any
   driven objective is incomplete or escalation-blocked, and `ok` should require
   genuine completion, not "complete-or-blocked".
3. **Surface the gap at release.** When a `/goal` clears, print a one-line
   honest reconciliation ("goal token seen; N/M objectives actually complete,
   K escalation-blocked") so a hollow completion is visible instead of silent.

## Notes for the maintainer

- Reproduce: `/goal /monitor ok` over several incomplete missions; run one
  `/monitor` wave; observe the run emit `ok` and settle while most missions are
  still incomplete/unmerged.
- The relevant seams are the `/goal` Stop-hook condition evaluation and
  `/monitor`'s terminal-state definition (the `ok`/`pending` rule in the
  monitor skill's §3, "The loop, and the terminal state").
- Keep the Stop-gating that already works; this is about what SATISFIES the
  gate, not about removing it.

## Policies

- **workaholic:development** (qa-engineering) — a completion signal must reflect
  verified state, not a self-report; the QA seam is defeated if "done" is a word
  the worker writes about itself.
- **workaholic:design** (no-dark-patterns, self-explanatory-ui) — a token shaped
  like success over an unfinished job misleads the developer; the released state
  must be honest at a glance.
- **workaholic:implementation** (objective-documentation) — the terminal signal
  should be derived from observable acceptance/exit state, the same standard the
  rest of the mission model already holds itself to.

## Quality Gate

A fix is acceptable when, in a session with `/goal <token>` set over incomplete
objectives:

- The gate does NOT clear merely because the agent emitted the token; clearing
  requires corroboration from observable state (or the run reports `pending`).
- A run that stops with unmet acceptance or open escalations does NOT present a
  success-shaped terminal signal — `ok` implies genuine completion; anything
  less reads as `pending`/incomplete.
- When a `/goal` does clear, the developer sees an honest reconciliation of how
  many objectives actually completed vs. remained blocked.
- The existing Stop-gating (blocking premature stop until the condition holds)
  is unchanged.

## Resolution

Archived as **resolved**, without a dedicated implementation, after investigation (2026-07-19):

- **The repo-actionable half shipped in `06a58f37`** (this branch). `/monitor`'s terminal token is now derived from `status.sh` — `ok` only when every driven mission genuinely reached `complete`; any incomplete/escalation-blocked mission yields `pending`; a reconciliation line (`N/M complete, K escalation-blocked`) is always printed above it. That is the only caller-gateable completion token any workflow in this repo emits, so it satisfies the "success-shaped signal must imply genuine completion / honest reconciliation" bullets for the surface the repo owns.
- **The residual is not actionable in this repo.** `/goal` is a **Claude Code harness feature**, not a workaholic command (`find plugins -iname '*goal*'` → nothing; `mission-lens.sh` treats `/goal` gating as external). Making a token-based Stop gate corroborate against observable state before clearing lives in the harness's `/goal` implementation, which workaholic does not own. No other repo-side self-assertable completion token exists (`/report`'s output is a PR URL, not a gate).

Recommended follow-up (outside this repo): raise the token-vs-observable-state Stop-gate corroboration with the Claude Code harness. Nothing further is actionable here.
