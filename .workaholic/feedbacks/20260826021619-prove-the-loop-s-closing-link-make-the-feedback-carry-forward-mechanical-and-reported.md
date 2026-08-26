---
type: Feedback
title: Prove the loop's closing link: make the feedback carry-forward mechanical and reported
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-26T02:16:19+00:00
author: a@qmu.jp
supersedes: 
---

# Prove the loop's closing link: make the feedback carry-forward mechanical and reported

## The ask

The `[Propose]` routine opened issue #603 against the strategy `an-autonomous-improvement-loop-run-by-the-routines` (move: depth): make the loop's closing link — carrying a proposal's `feedback:` refs onto the work `/specificate` emits — **mechanical and reported**, and make its failure distinguishable from a direction nothing has answered yet.

Source: https://github.com/qmu/workaholic/issues/603

## What must become true

1. **One reader for the ask's own `feedback:` line.** A script under `skills/specificate/scripts/` parses that line from an ask's body, resolves each ref under `.workaholic/feedbacks/`, and returns the carried and dropped sets with a reason per drop. Step 3b invokes it instead of asking the run to do it by eye.
2. **The run says what it carried.** `/specificate`'s run report and the pull-request body name, per emitted artifact, each ref carried and each ref dropped with its reason.
3. **A floor at the publish seam.** When the ask carried refs that resolve and the run emitted a mission or a ticket, those refs must be on the emitted artifacts — checked beside `mission/scripts/check-floor.sh`.
4. **The two zero-states stop reading alike.** A strategy whose emitted work carried its refs must be distinguishable from one nothing has ever cited. `attributed-work.sh` stays the one attribution reader and no artifact gains a field.

## Why it commits to the strategy

The Aim's completion condition is a chain of four links — proposed, ingested, driven, and visible back on the strategy through the existing attribution reader. Three are carried by scripts that fail loudly; the fourth is carried by a paragraph. Its failure mode is invisible: a forgotten step 3b leaves `strategy.feedback[] ∩ artifact.feedback[]` empty, and `survey-strategies.sh` reports `no_citing_artifacts` — byte-identical to the reading for a direction nothing has answered yet, which `workaholic:propose` says is explicitly *not* a refusal.

Measured in the ask: the strategy is 5 days from `target_date: 2026-08-31`, `pace: late`, `count: 0` attributed artifacts, `empty_reason: no_citing_artifacts`, and no issue on this repository carries the `strategy: / move:` marker — the chain has never run end to end.

## What it was chosen against

The `breadth` move (enrich the direction layer itself) is refused for now: it would add a third writer to an artifact deliberately built with two, and it builds on an unproven base. Proposing nothing is refused by `pace: late`. The prose-contract-in-principle argument does not reach here: whether a ref landed on an emitted artifact is a string in a file, not a judgment.
