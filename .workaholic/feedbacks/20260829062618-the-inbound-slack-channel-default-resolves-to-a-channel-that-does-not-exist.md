---
type: Feedback
title: The inbound Slack channel default resolves to a channel that does not exist
kind: instruction
source: development
subject: observer_ai:[Moderate] tick
created_at: 2026-08-29T06:26:18+00:00
author: a@qmu.jp
supersedes: 
---

# The inbound Slack channel default resolves to a channel that does not exist

The `/moderate` tick's inbound Slack surface resolves to a channel that does not exist, so both readers of the repository's channel are pointed at nothing while the writer posts correctly somewhere else.

Found by tick `20260829-055101`, step `inbound-sweep`, and classified `repairable` by the tick's own table on the ground that a diverged channel default or a broken transport config is a change to this repository.

What the tick found:

- `WORKAHOLIC_INBOUND_SLACK_CHANNEL` is unset in the routine container, so both the `:40` inbound sweep and `/moderate`'s `unanswered-asks` step resolve the channel to the documented default `<repo_name>` — `workaholic`.
- The workspace has no `#workaholic`. Its only channel for this repository is the private `#dev-workaholic` (`C0BLL9J7FMY`), which is where every post the loop makes actually lands: the `🔵 Proposed` / `🟢 Implemented` finish lines, the `🔎 Moderation` roots, the inbound receipts.
- So the two readers meant to read the channel are aimed at a name resolving to nothing, while the writer that posts into it finds the real thread by the stateless exact-string lookup and lands correctly. The two halves disagree, and only the reading half is broken.

Independently confirmed during this run's discovery: a workspace channel search for `workaholic` returns exactly one channel, the private `#dev-workaholic` (`C0BLL9J7FMY`). There is no `#workaholic`.

Why it is the loop's own debt: `unanswered-asks` exists so a question written in the repository's channel reaches a person even when no other step produces a row about it. With the channel unresolvable it can never produce a candidate, and the sweep's Slack half is in the same position — the loop's whole inbound-from-Slack path is dark. The failure is quiet by construction: `channel_unreadable` and *the channel had nothing waiting* are deliberately different names, but neither is posted anywhere, so from outside the tick the two are indistinguishable from a calm hour.

The repair the ask names:

- Either restore a default derivation that resolves in this workspace, or set `WORKAHOLIC_INBOUND_SLACK_CHANNEL` explicitly in the routine templates that read it (`propose.md`, `moderate.md`).
- Whichever is chosen, the `dev-` prefix retirement of 2026-08-28 has to be either completed (the Slack channel renamed) or reversed (the prefix returned to the default). Today the repository says one thing, the workspace says another, and the code loses silently.
- And make the divergence detectable: a channel name resolving to no channel is a different fact from a channel with nothing in it, and today only the second is ever reported at a person.

Source: https://github.com/qmu/workaholic/issues/702
