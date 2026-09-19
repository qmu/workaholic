---
type: Feedback
title: Verify a feedback item on its own review surface before closing it
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T09:45:36+09:00
author: a@qmu.jp
supersedes: 
---

# Verify a feedback item on its own review surface before closing it

Source: https://github.com/qmu/workaholic/issues/1104

An ingested request can be closed and reported complete even when implementation changed a
different rendering surface from the one the person was reviewing.

Concrete recurrence on a consuming repository: a channel request asked for signed-in identity and
logout in the global header of a **public prototype review screen**. It was correctly ingested as
an issue. Specification grouped it into a ticket whose implementation changed only the
application package's shell; the public prototype shell remained unchanged. The feedback issue
was nevertheless closed, and the final channel summary claimed 「アカウント導線を統合」. The
person found the control absent on the public screen and had received neither a defer reason nor
an omission report.

This is not an inbound-detection failure. It is a traceability and acceptance failure between
source feedback, ticket scope, changed surface, verification evidence, and completion
notification.

## Expected behavior

Before a feedback record is considered satisfied or its source issue is closed:

1. Preserve the named or contextually established **review surface** as an acceptance dimension.
2. Require implementation evidence **from that surface**, not merely semantically similar code
   elsewhere.
3. Reconcile every source feedback item as `implemented and verified`, `still queued`, or
   `not implemented` with a concrete reason.
4. Generate final summaries from that reconciliation. Do not infer that a broad ticket or pull
   request title means every attached feedback record landed.
5. If multiple packages render similar chrome, reject closure when only the wrong sibling surface
   changed.

The verification should catch both a direct file/surface mismatch and the broader case where
automated tests pass but the person-visible review route still lacks the requested behavior.
