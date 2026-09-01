---
type: Feedback
title: Catch a reported claim up before its conflict hardens
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-30T04:25:47+00:00
author: a@qmu.jp
supersedes: 
---

# Catch a reported claim up before its conflict hardens

kind: instruction / source: development / subject: observer_ai:[Propose] routine

Source: https://github.com/qmu/workaholic/issues/744

# Catch a reported claim up before its conflict hardens

One reading — `claim-mergeability.sh`'s `clean | mechanical | content | unanswerable`, rendered on every claim row — is consumed by two candidate sets that do not agree. `/moderate`'s `catchup-blocked` step asks about `mergeability == content` on a `report_undelivered` OR `queue_drained` claim; `/implement`'s catch-up loop acts only on the survey's `undelivered[]`, i.e. `report_undelivered` alone.

So a `queue_drained` claim — a unit the loop finished, whose pull request is open and waiting on a person — is asked about once it has hardened to `content` and never acted on while it is still `mechanical`. The loop waits for a machine-resolvable state to become a human-only one, and then asks the human.

Measured on this repository at the hour the ask was written, over the four standing claims:

- `deploy-the-docs-site-on-merge-to-main` @ `work-20260826-134108` — `queue_drained`, `mergeability: mechanical`, tip 2026-08-26, four days. Acted on by nobody (not `report_undelivered`), asked about by nobody (not yet `content`). One merge commit away from deliverable and nothing in the loop will take it.
- `batch-20260818215156` @ `work-20260818-215157` — `queue_drained`, `mergeability: content`, tip 2026-08-18, twelve days, twelve conflicting files including `CLAUDE.md` and a generated OKF index. The same shape, already hardened; now a person's job, permanently.

The act needs no new bounds, because it already has them: `catch-up-claim.sh` carries no delivery-verdict gate of its own, re-derives the verdict at the moment of the act, and reports `already_current` on a branch that already contains the base. Its one caller is the `undelivered[]` loop. What must change is the caller and the reader, not the writer.

The discipline must be stated, because the shipped code and the written rule already disagree: `drive/reference/claims.md` says a consumer may act on a proof and may only report or ask about a judgement, and every `mergeability` value is classified there as a judgement — yet the catch-up act reads `mechanical` and acts on it, made safe by re-deriving at the moment of the act over a write that is bounded, idempotent and reversible. That exception is real and correct and unwritten, which is what lets it be widened by accident later.

One bound is genuinely new: an `undelivered` unit's pull request was refused by a transport, while a `queue_drained` unit's may be one a person is mid-review on, and a push resets an approval. Refuse by name when the pull request carries a submitted review.

The ask names its own eight-ticket plan; see the issue.
