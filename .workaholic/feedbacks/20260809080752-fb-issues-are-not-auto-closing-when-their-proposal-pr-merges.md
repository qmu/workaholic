---
type: Feedback
title: FB issues are not auto-closing when their Proposal PR merges
kind: instruction
source: slack
created_at: 2026-08-09T08:07:52+00:00
author: a@qmu.jp
supersedes: 
---

# FB issues are not auto-closing when their Proposal PR merges

There is supposed to be a mechanism where, once a Proposal PR that addresses a "[FB] ***" issue is merged, that FB issue gets automatically closed. This automation does not appear to be working: FB issues remain open even after their corresponding Proposal PR has been merged.

Investigated the codebase: no existing script or routine in plugins/workaholic actually calls `gh issue close` or references "Fixes #"/"Closes #" anywhere — there is no auto-close mechanism implemented at all, despite the developer's expectation that one exists. Filed via GitHub issue #319: https://github.com/qmu/workaholic/issues/319 (Slack thread: tamura_yoshiya asked in #dev-workaholic, 2026-08-09).

Could this auto-close behavior be investigated and fixed/restored so that merging a Proposal PR correctly closes the FB issue(s) it addresses?
