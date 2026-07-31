---
type: Feedback
title: Make the branch story say less when there is less to say
kind: instruction
source: discussion
created_at: 2026-07-31T16:57:27+00:00
author: noreply@anthropic.com
supersedes: 
---

# Make the branch story say less when there is less to say

The PR/Story write-up format needs revision. Four structural changes:

1. Fold section 5, Historical Analysis, into section 2, Motivation, rather than keeping them separate.
2. When listing concerns, include only those above "Severity: low" — low-severity concerns should not appear in the story.
3. Leave section 7, Successful Development Patterns, empty by default and populate it only when a genuine pattern was actually found, rather than manufacturing content to fill it.
4. Replace the 8-1/8-2/8-3 sub-section structure under section 8, Release Preparation, with a single flat list covering both pre-release and post-release preparation or instructions, included only if there is actually something to say.

The underlying complaint driving all four is the same: the current generator always tries to fill every section with as much content as it can, producing longer, denser stories than the underlying change warrants. The fix should aim for a more concise story that says less when there is less to say, rather than one that pads sections to look complete.

Registered from issue #125.
