---
type: Feedback
title: Filtering low concerns out of the story deletes them from the stream
kind: concern
source: discussion
created_at: 2026-07-31T16:57:40+00:00
author: noreply@anthropic.com
supersedes: 
---

# Filtering low concerns out of the story deletes them from the stream

Dropping low-severity concerns from the story does not just shorten the story — it deletes them from the feedback stream.

Measured: `ship/scripts/extract-deferred-concerns.sh` reads `.workaholic/stories/<branch>.md` as its only source (line 67) and records EVERY severity by design — its own header says "the promotion floor retired with the concern merger" (line 25), and the parser defaults an unknown label to `moderate` rather than discarding it (lines 243-245). Section 6's `###` block layout is parsed verbatim by that script. So a story that omits `Severity: low` blocks silently reinstates the promotion floor that decision H2/H3 retired on 2026-07-28, and the observation is lost rather than deprioritized.

Whoever implements the change has to decide, not assume: either low-severity concerns are genuinely dropped (accepting the reversal, and recording it), or they stay in the record the extractor reads and only the rendered story is filtered. The request as written does not say which.
