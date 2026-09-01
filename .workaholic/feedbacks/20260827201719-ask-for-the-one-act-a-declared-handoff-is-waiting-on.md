---
type: Feedback
title: Ask for the one act a declared handoff is waiting on
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-27T20:17:19+00:00
author: a@qmu.jp
supersedes: 
---

# Ask for the one act a declared handoff is waiting on

The `[Propose]` routine asks that a **declared verification handoff** reach the person who
can clear it, more than once, in the vocabulary of the act it is waiting for.

Source: https://github.com/qmu/workaholic/issues/664

## The ask

Today the handoff axis is complete on the *routing* side and empty on the *asking* side. A
unit declaring `verification_handoff:` is routed at §6, its pull request is left open, its
claim stands, and the run posts one `🟡 Handoff` finish line into a thread — with no mention
token, because it is a record of an outcome. After that hour, nothing addresses anybody
again:

- `plan-units.sh` excludes it `claimed_awaiting_verification`;
- `claim.sh resume` refuses it by name;
- no `/moderate` step reads the verdict at all — `awaiting_verification` appears nowhere
  outside `drive/`, and `moderate/scripts/` holds no step that mentions a handoff;
- and once the branch tip goes stale, `step-stalled-units.sh` — which filters only
  `superseded` — asks about it as *"a claimed unit has not moved for a day or more"*, which
  is the wrong question. The unit is not stalled by accident. It was **declared**
  unverifiable here at creation.

Measured on this repository at 2026-08-27 19:41 UTC: seven claims, six of them stale. Three
units are parked on a human act and each names it in its own ticket —
`turn-off-routine-completion-notifications` (*"requires the developer's own Claude app
account and device"*, queued since 2026-08-18), `rule-on-renaming-a-live-routine-in-place`
(*"a RemoteTrigger-family tool over account routines"*, queued since 2026-08-19), and
`build-and-deploy-the-docs-site-on-merge-to-main` (*"an API token and account id must be
added as repository secrets, and workaholic.qmu.co.jp must be bound to the Worker"*, queued
since 2026-08-26). Nine days, eight days, one day, and not one of them has been mentioned to
the person who holds the account since the hour it routed.

## What must become true

The claim verdict `awaiting_verification` is read by the one surface in this plugin that
names a person; the question carries **the declared reason** rather than an age; it is
addressed to the claim holder; it is asked exactly once through the existing
`ask-question.sh` ledger; and `stalled-units` stops asking the wrong question about the same
unit — counting it in its summary as a finding, exactly as it already does for `superseded`.

The reading writes nothing, clears nothing and merges nothing. `awaiting_verification` is
classified a **judgement** in `drive/reference/claims.md`, so a consumer may only report it
or ask about it, and this adds a consumer of the second kind and no other.

## What it is chosen against

A unified "what the loop is blocked on" digest over the four vocabularies
(`undrivable-unit`, `stalled-unit`, `undelivered-unit`, and the unread declared handoff) is
refused: this repository has retired a status line addressed to nobody twice, and a fifth
surface summarising four readings is a fifth thing to keep in sync. The shape that has
worked here every time is the narrow one — one reading, one question, one named person,
asked once — and three of the four already have it.

Making the loop *clear* a handoff itself is refused on the axis's own terms: a handoff names
a credential, a device or a third-party account an unattended run does not hold, so there is
nothing to retry, and acting on a judgement is what the proof/judgement split forbids.

feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
