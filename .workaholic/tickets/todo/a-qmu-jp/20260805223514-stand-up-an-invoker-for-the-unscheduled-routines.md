---
created_at: 2026-08-05T22:35:14+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
mission: drive-on-a-merged-proposal-and-report-it-in-that-proposal-s-thread
feedback: [20260805130407-trigger-the-drive-routine-on-a-merged-proposal-and-report-start-and-completion-in-its-thread.md]
merge_policy:
---

# Establish how an unscheduled routine is invoked

## Overview

**Answered by the developer, 2026-08-06, before any session investigated**: `[Propose]`
fires when **a GitHub issue assigned to them is opened** — the wiring lives in the GitHub
integration, outside the routine record. What remains of this ticket is narrower than
either of its earlier framings: **verify** that wiring exists per repository, make "has
this routine run, and when" **observable** to a reader, and list — for a human to fix in
the routines UI, since the trigger wiring is invisible to `RemoteTrigger` — any `[Propose]`
routine configured to fire on a **merge**, which the developer has already observed
elsewhere in the fleet and ruled a misconfiguration (a merge is `[Consent]`'s event).

**Rewritten 2026-08-06.** This ticket was minted the previous evening as *Stand up an
invoker for the unscheduled routines*, on the premise that `[Propose]` and `[Consent]`
have never fired because nothing invokes them. **The premise was wrong**, and the ticket
would have had a session building an invoker for routines that may already have one.

What the premise rested on was an absent `last_fired_at` key. It does not carry that
weight: on 2026-08-05 a Claude Code **web container** session ran against this repository
between 13:20Z and 13:32Z, turned issue #260 into a feedback record, opened PR #261 and
posted to `dev-workaholic` — the `[Propose]` routine's exact job, while that routine was
the only one of its kind here and was `enabled` — and the key stayed absent throughout.
Either the routine fired and the field is simply never populated for it, or a web session
was started some other way; **the field cannot tell those apart**, which is the whole
point. The retraction is recorded in `workaholify/SKILL.md`, *What a routine can be
triggered by*.

What still stands is the narrower observation the retraction did not touch: a routine
record carries **no event-subscription field**, so nothing in it explains how an
unscheduled routine comes to run. That is now an open question rather than a settled
absence, and answering it is what this ticket is for. It matters because two loops the
project depends on are unscheduled, and nobody can currently say what starts them, how to
start one deliberately, or what to check when one does not run.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a system's state must be answerable from outside without a debugger
- `workaholic:implementation` / `policies/objective-documentation.md` — a stated guarantee must be checkable
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *What a routine can be triggered by*,
  which now carries the retraction and must carry the answer
- `plugins/workaholic/skills/workaholify/routines/fb.md` / `merged-pr.md` — the two
  unscheduled templates
- `plugins/workaholic/skills/workaholify/scripts/lib/list_routines.py` — the reader that
  reports a routine's trigger; where "how is this invoked" would surface to a developer
- `docs/proposal-loop-runbook.md` — §3, which tells a developer how to provision the loop

## Implementation Steps

1. **Determine what actually started the 2026-08-05 13:20Z session.** The developer knows
   whether they ran it by hand; ask, because it is a one-sentence answer that decides
   everything downstream and no amount of API reading substitutes for it. Record it.
2. If a routine fired: **find what the record does not show.** Whether the Claude app's
   GitHub integration invokes triggers, whether a token exists outside
   `api_token_hint`, and what event class reaches an unscheduled routine. Record the
   mechanism with the evidence that established it, not the inference.
3. If no routine fired: the original premise is back on the table, and the ticket becomes
   what it originally said — design the invoker, with the token's storage as part of the
   design, and stand it up as a human act.
4. **Either way, make invocation observable.** A developer must be able to answer "has
   this routine run, and when" without reading a Slack channel. `last_fired_at` is absent
   for these, so `list-routines.sh` reports nothing about it today; whatever the answer to
   step 2 is, a routine that cannot be told from a dead one is the state this ticket
   exists to end.
5. Correct `docs/proposal-loop-runbook.md` §3 to describe provisioning as it actually
   works once known.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The repository states, with the evidence that established it, what invokes an
  unscheduled routine — or states that nothing does and what standing an invoker up
  requires.
- `/setup-routines` output lets a reader distinguish a routine that has run from one that
  never has, or says plainly that the account cannot answer it.
- No claim about firing rests on the presence or absence of `last_fired_at`.

**Verification method** — the commands/tests/probes that prove them:

- `RemoteTrigger list` / `get` read back, with the fields quoted in the branch story
- `node scripts/test-workflow-scripts.mjs` for whatever `list_routines.py` gains
- A deliberate invocation attempted and its outcome recorded

**Gate** — what must pass before approval:

- No live routine is created, refreshed or re-pointed by the driving session; provisioning
  stays a verbatim-confirmed human act.
- Nothing in the answer is inferred from a missing key.

## Considerations

- **The failure mode this ticket is itself an instance of.** A field's absence was read as
  a measurement, the conclusion was written into six documents and a ticket, and it was
  contradicted within a day. Whatever this ticket concludes must name the observation it
  rests on, so the next reader can check it rather than inherit it.
- The developer answered step 1 unprompted (above). Do not re-ask it; the remaining work
  is verification, observability, and the misconfiguration list.
