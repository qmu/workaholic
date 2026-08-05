---
type: Feedback
title: list-proposed-refs.sh dedup misses feedback refs on unmerged pull requests
kind: instruction
source: slack
created_at: 2026-08-05T05:36:36+00:00
author: noreply@anthropic.com
supersedes: 
---

# list-proposed-refs.sh dedup misses feedback refs on unmerged pull requests

`list-proposed-refs.sh` builds the propose seam's dedup set only from artifacts already on `main` — the `feedback:` refs carried by every mission and ticket in the merged tree. A proposal that exists but has not merged yet is therefore invisible to it: the refs on an open pull request's branch do not enter the set until that pull request merges.

This surfaced in qmu/workaholic on 2026-08-05. Issue #242 restated an ask that had already been proposed ten minutes earlier in open pull request #241, and the scripted dedup did not catch it — the duplicate was noticed only because a reviewer happened to list the open pull requests by hand, which is not part of the dedup path. A propose run firing inside that window would have seen no existing proposal for the ask and could have opened a second one for it.

The ask is to widen the dedup set so it also covers the `feedback:` refs carried by open pull requests, rather than merged artifacts alone.
