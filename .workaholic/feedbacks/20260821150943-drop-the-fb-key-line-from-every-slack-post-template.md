---
type: Feedback
title: Drop the fb: key line from every Slack post template
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-08-21T15:09:43+09:00
author: a@qmu.jp
supersedes: 
---

# Drop the fb: key line from every Slack post template

# Drop the fb: key line from every Slack post template

Source: https://github.com/qmu/workaholic/issues/545

Remove the trailing key line from every Slack notification template — not only `🔵 Proposed`. The observed post:

    🔵 Proposed - #21 [Proposal] V3 Design section, conceptual model page, and V2 nesting
    by the routine of @YO
    fb:20260820184743-restructure-v3-docs-nest-v2-materials-under-v3-requirements-analysis-and-add-a-v3-design-conceptual-model-page

The third line is what should go, everywhere it appears.

The ask states its own cost. That line is the **dedup key**, load-bearing rather than decoration (`workaholic:notify`, *One thread per feedback item*): case 2 of the stateless thread lookup searches for the exact string `` `fb:<stem>` `` to find the thread a feedback item already owns, and case 4 posts a new keyed root when nothing matches. Delete the key from the post and case 2 can never match, so every run posts a new root and one feedback item accumulates one thread per tick — the failure issue #360 and FB `20260811084546` were spent fixing. The sibling keys are the same mechanism: `` `stuck:<digest>` ``, `` `deploy:<digest>` ``, `` `standup:<date>` ``, `` `unit:<unit-id>` ``.

So this is not a template edit. It needs a home for the key that a human does not read, and the obvious one is already ruled out: a persisted `thread_ref` in the feedback record was drafted and refused by the developer on 2026-08-11 (FB `20260811084130`), because a Slack thread coordinate committed to this public repository is the exposure the P9 withdrawal already found irretractable. Any replacement store must sit outside the repository.

Three candidate directions are offered for whoever specs it: move the key out of the visible text into Slack metadata the search surface still indexes — the shortest path if `slack_search_public_and_private` matches on it, and needing measurement first, because the 2026-08-11 record shows how badly an unmeasured assumption about the search surface goes; shorten rather than delete, keying on a hash of the stem, which keeps case 2 exact-matchable but does not satisfy the ask literally; or delete it and accept duplicate roots, recorded so it is rejected on the record rather than by omission.

One thing is flagged to check first: `🔵 Proposed` is specified as a **reply** in every connector case, carrying the key only on the tokened fallback, which cannot thread (`notify/reference/notifications.md`). A `🔵 Proposed` seen with the key on it is therefore either the tokened fallback or the description root — so part of what was observed may be the fallback path firing, which is its own question and may be the more useful one to answer first.
