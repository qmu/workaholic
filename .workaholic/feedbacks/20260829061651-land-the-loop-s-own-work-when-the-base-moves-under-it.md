---
type: Feedback
title: Land the loop's own work when the base moves under it
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T06:16:51+00:00
author: a@qmu.jp
supersedes: 
---

# Land the loop's own work when the base moves under it

The `[Propose]` routine asks for the loop to bring its own pull request back onto the base when the base moves under it.

A claim branch is caught up with `main` exactly once, during the run that drives it, and never again. From the moment its pull request opens nothing in the loop looks at whether the branch still merges. `retry-undelivered.sh` re-attempts the merge through the same REST seam that refused it — the right act for a transport refusal, and no act at all for a base that has moved: the `PUT .../merge` answers with a conflict every hour forever. `/moderate`'s `merge-conflicts` and `stuck-prs` steps see it and only report.

Measured on this repository at 2026-08-29T04:51 UTC: 7 open pull requests, 4 of them conflicting with `main` (#622, #625, #633, #688). Three of those are units `workaholic:drive` records as green and undelivered on 2026-08-27 — finished, refused their merge, and by the time the delivery retry ran the base had moved so it could no longer land any of them. Behind them sit 4 active missions and 10 queued tickets untouched since 2026-08-18, 08-19, 08-21 and 08-26.

What must become true:

- A claim branch's mergeability against the base is readable — `clean`, `mechanical`, `content` or `unanswerable` — derived locally from refs the claim oracle already fetches, reported and never acted on until a writer is asked to act.
- A bounded writer catches the branch up: merge the base into the claim head (never a rebase, never an amend, never a force-push), regenerate what the repository's own tooling owns, validate with the repo's fast checks, push. One act, idempotent, exit 0, nothing written on any refusal.
- The bounds are the claim protocol's own and are not widened: only a claim this identity holds, only a `work-*` branch the loop opened, never a scan-held pull request, and a `content` conflict is refused rather than guessed.
- A branch that was caught up is re-delivered in the same turn through the existing `retry-undelivered.sh`, in the run report's existing merge vocabulary.
- A `content` conflict the loop refused reaches the claim holder as its own question, told apart from a conflict nobody has attempted.

The ask narrows rather than reverses this repository's written rule that resolving a conflict on a claimed branch is nobody's job here: the loop takes the mechanical case only, on its own claim, and the contested case stays a person's.

Source: https://github.com/qmu/workaholic/issues/701
