---
type: Feedback
title: Let the tick's own findings become the loop's work
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T04:17:43+00:00
author: a@qmu.jp
supersedes: 
---

# Let the tick's own findings become the loop's work

Source: https://github.com/qmu/workaholic/issues/698

Opened by the `[Propose]` routine against the strategy
`an-autonomous-improvement-loop-run-by-the-routines`, move `breadth`.

## What it asks for

Give the moderation tick's own findings a path into the work queue.

Today `/moderate` has exactly two destinations for what it finds: a **question** to a
person (`ask-question.sh`, one per subject, capped at ten a day, held over the weekend)
and a **feedback record** in `.workaholic/feedbacks/`. Neither becomes work.
`[Specificate]`'s unattended entrance reads **issues**, not records — so a finding that
is work dies in a stream of records nobody drives, and the only finding-shaped thing
that has ever reached `file-inbound-ask.sh` from inside `/moderate` is an answer a
**person** wrote in a thread (`step-question-answers.sh`, its single caller).

The ask: file the tick's **repairable** findings as `[FB]` issues through that same
already-proven seam, so `[Specificate]` ingests them at the next `:15` and `[Implement]`
drives them at the next `:30`.

What must become true, in the ask's own terms:

- A finding whose repair is mechanical — a branch CI could not delete, a channel default
  that diverged from the channel the loop posts to, a pull request conflicting with
  `main` — becomes an issue the loop drives, without a person being asked first.
- A finding that needs a human **ruling** — which direction an unattributed mission
  answers, which account an unmapped address belongs to — still asks, exactly as it does
  now. The classification is the whole safety property and is derived from the step id
  the tick already emits: no field on any artifact, no second vocabulary, no new store.
- `propose/scripts/file-inbound-ask.sh` stays the **one** filer and
  `feedback/scripts/ask-feedback-line.sh` the one writer of the direction line.
- The rate is braked in `open_proposal`'s shape: at most one open finding issue in
  flight, read off the open-issue ledger with no cursor and no stored state. An
  unreadable ledger files nothing.
- The dedup is **structural**, keyed on the same step id the already-asked gate uses.
- A finding that has become work no longer also asks a person, read through the shared
  `ruling-suppression.sh` shape; an unreadable read holds nothing.
- The tick's *writes nothing but its own log line* contract stays intact: an issue lives
  on GitHub, outside the tree — the same ground `/propose`'s inbound sweep stands on.

## The measurement it carries

From this repository's own tick log, 2026-08-29:

- `human-checkin`: 22 candidates, 0 delivered, 22 held.
- `retire-claims`: 4 claims proved superseded, 0 retired, 3 refused `branch_delete_failed`.
- `stuck-prs`: 4 pull requests conflicting with `main`.
- `inbound-sweep`: `channel_unreadable` on every tick — captured as a record 2026-08-28,
  still captured, never driven.
- `issue-triage`: no open issues — the inbox the whole loop feeds on is empty while all
  of the above waits.

## What it is chosen against

The rival — converge the findings so a person can keep up (seven `undrivable-unit`
questions name one mapping file, three `retire-blocked` name one CI workflow) — is
refused for optimising the wrong side of the seam: it shortens the person's queue while
keeping the person in the path for work no person needs to decide. Raising
`max_per_day` is refused outright.

## The plan the ask names

An eight-ticket mission, in order: pin the gap; classify a finding as repairable or
needing a ruling from the step id; write `step-file-findings.sh`; brake it to one open
finding issue; dedup it structurally on the step id; suppress the question a filing
answers; report filed / held / left; drill it offline as `verify-findings-to-work`.
