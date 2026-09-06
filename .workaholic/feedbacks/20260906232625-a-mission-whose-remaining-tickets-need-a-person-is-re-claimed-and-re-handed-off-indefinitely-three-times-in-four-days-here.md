---
type: Feedback
title: A mission whose remaining tickets need a person is re-claimed and re-handed-off indefinitely — three times in four days here
kind: instruction
source: development
subject: person:TAMURA Yoshiya
created_at: 2026-09-06T23:26:25+09:00
author: a@qmu.jp
supersedes: 
---

# A mission whose remaining tickets need a person is re-claimed and re-handed-off indefinitely — three times in four days here

Source: https://github.com/qmu/workaholic/issues/1044

**A mission whose remaining tickets only a person can finish is re-claimed by machine runners
again and again.** Each run redoes the half a machine *can* do, writes a handoff saying a person
is still needed, and releases. Nothing counts the repetitions, and nothing stops the next one. In
this repository it has now happened three times in four days over the same two tickets.

## The measurement

Mission `make-the-screens-previewable-and-tell-the-operator-what-to-open`. Two queued tickets,
both carrying a `verification_handoff` that says outright only the operator's own browser can
discharge it — no service token this checkout holds is admitted past two of the three Cloudflare
Access entrances.

| Pull request | Opened | State | Title |
| ------------ | ------ | ----- | ----- |
| #611 | 2026-09-03 00:35 | closed | Measure and report what the three addresses serve past their entrances |
| #684 | 2026-09-06 06:36 | merged | Recheck preview access and **record** the browser handoff |
| #693 | 2026-09-06 12:30 | open | Recheck preview access and **preserve** the browser handoff |

Two of those titles differ by one word. Reading #693's own story:

```
tickets_completed: 0
## Handoff
**This branch is unfinished. Someone must continue it.**
- Done: Rechecked all three published entrances, the admitted application index,
  /themes, and both same-host stylesheets.
- Not done: Both queued confirmation tickets still need the operator's own browser result.
```

That is an honest run doing exactly what it should — and it is the third time the same three
entrances have been rechecked to reach the same conclusion.

The corresponding `handoff-unit:make-the-screens-previewable-and-tell-the-operator-what-to-open`
question was asked **2026-09-03** and appears in the moderation logs for 09-03, 09-05 and 09-06,
still unanswered. Four days, three claims, one question nobody has answered.

## Why nothing stops it

Two mechanisms, each individually reasonable:

1. **`plan-units.sh` offers a mission whenever its todo tickets carry no live claim.** A claim
   that finishes by handing off releases the unit, so the mission returns to `missions[]` and the
   next `implement` runner takes it. Nothing in the offer consults whether the *reason* the
   previous claim ended was "a person is needed" — a handoff and a completion look the same from
   the claimability side.
2. **The outstanding question is keyed on the unit, not on the claim or the pull request.** The
   underlying artifact went #611 → #684 → #693 while the question stayed one `already_asked` row.
   So the question is never re-asked *and* never satisfied, and neither state blocks a re-claim.

Neither is wrong on its own. Together they make an unbounded loop whose period is however long a
claim takes to go stale, running for as long as the person does not answer.

## What it costs, stated plainly

Each repetition burns a runner, a worktree, a branch, CI on a pull request, and a review decision
from whoever lands it — to re-derive a fact the repository already recorded twice. It also puts
near-identical pull requests in front of a human, which is exactly the noise that trains a reader
to stop looking.

And it defeats a rule a caller cannot enforce. This session has been briefing **every** runner
with "never claim this mission — its tickets need a person's browser," and that briefing reaches
only this session's own runners. #693 came from elsewhere. A per-caller instruction cannot hold a
line that belongs in the claim protocol.

## What would fix it

Cheapest first; any one of these ends the loop.

1. **Let a claim end in a state the offer respects.** A claim released *because* its handoff needs
   a person should mark the unit `awaiting_person` rather than returning it to the free pool. The
   claim readers already distinguish `resume_reason` values — `awaiting_verification` is right
   there on #693's claim — so the information exists; `plan-units.sh` simply does not consult it
   when deciding what to offer.
2. **Make the outstanding question suppress the re-claim.** A unit with an unanswered
   `handoff-unit:` question is, by that question's own existence, waiting on a person. Offering it
   to a machine while the question stands is the contradiction.
3. **At minimum, count the repetitions and say so.** If a unit has been claimed and handed off N
   times with no ticket completed, the next offer should carry that number, and a run should be
   able to refuse on it by name — `repeated_handoff: 3` — instead of discovering it by reading
   three pull-request titles side by side.

**What is deliberately not proposed**: refusing every mission with a `verification_handoff`. The
first pass is genuinely useful — someone has to measure what a machine *can* measure and write the
handoff. The defect is the **second and third** passes, not the first.

## Provenance

Captured by the moderation tick's inbound sweep from issue #1044, written by the operator
(`subject: person:TAMURA Yoshiya`). The issue carries no assignee, so `/specificate`'s
assignee-scoped discovery cannot reach it; this record exists so the finding is not lost to the
next issue-triage sweep, and does not itself resolve, assign, or judge the fix.
