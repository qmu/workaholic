---
type: Feedback
title: thread-reconcile calls a merged proposal the item's finish
kind: instruction
source: development
subject: person:a@qmu.jp
created_at: 2026-08-31T20:32:18+00:00
author: a@qmu.jp
supersedes: 
---

# thread-reconcile calls a merged proposal the item's finish

Source: https://github.com/qmu/workaholic/issues/787

kind: instruction / source: development / subject: person:a@qmu.jp

Measured 2026-08-31 on a consuming repository channel. An operator asked for a change to a
prototype index. The thread then ran: `📥 受理` on the `[FB]` issue, `🔵 Proposed` on the
proposal pull request, and then `🟢 Implemented` on the same pull request with the sentence
that it had been merged outside the loop and no run had posted the item completion.

The operator read the green circle as their ask being done. It was not. That pull request is
a **proposal**: three files, all under `.workaholic/`, +200 −0, no product code — a feedback
record, the regenerated feedbacks index, and one ticket in `tickets/todo/`. That third file
is still sitting in `todo/`. The prototype index is byte-identical to what the operator
complained about.

`thread-reconcile` posts one reply when a thread last status reply is `🔵 Proposed` or
`🟡 Handoff` and the pull request it names has merged or closed. But `🔵 Proposed` names a
**proposal** pull request, and merging one lands a feedback record and a ticket set. That
merge is the moment the work becomes queued — it is the START of the item, not its finish.
The step nonetheless renders the same `🟢 Implemented` it renders for `🟡 Handoff`, where the
transition really is a finish. One shape is doing two jobs, and for the `🔵 Proposed` case it
asserts the opposite of what happened.

It is worse than a wrong label. The second line — no run posted this item finish — is an
explanation for why a completion notice is arriving late, so it gives a reader a reason to
believe the first line rather than question it. A wrong status that explains its own lateness
is harder to catch than a bare one. And the reconcile step exists precisely for threads
nobody is watching closely: it fires on items whose finish nobody posted, so its whole
audience is readers who will not go and check the diff.

The distinction: `🟡 Handoff` → merged means the work is done and a run failed to say so, and
`🟢 Implemented` is right. `🔵 Proposed` → merged means the ticket set landed, the item is now
**queued**, and the thread next true status is a later `🟢 Implemented` from the run that
drives it — there is no shape for this today, so the step reaches for the one that is there.
`🔵 Proposed` → closed without merging is a refused proposal, and `⚫ Closed` already covers
it.

What would settle it: a shape of its own for a merged proposal — the tickets are queued, and
this is not the finish — or, if a new shape is not wanted, `thread-reconcile` simply not
treating a merged `🔵 Proposed` as a reconcilable finish at all. Saying nothing is strictly
better than saying the opposite: the thread keeps its last true status and the real
`🟢 Implemented` still arrives when the work is driven. Distinguishing the two cases needs no
new state — the last status reply is already read, and it is what tells them apart.
