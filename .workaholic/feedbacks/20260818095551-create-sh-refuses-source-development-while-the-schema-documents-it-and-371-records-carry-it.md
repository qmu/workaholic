---
type: Feedback
title: create.sh refuses source development while the schema documents it and 371 records carry it
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-18T09:55:51+00:00
author: a@qmu.jp
supersedes: 
---

# create.sh refuses source development while the schema documents it and 371 records carry it

# create.sh refuses `source: development`, the value 371 of the 507 existing feedback records carry

Measured while filing a record in housekeep tick 20260818-095114. `feedback/scripts/create.sh` validates `SOURCE` against `meeting|slack|discussion` and exits `bad_source` for anything else, but `workaholic:feedback`'s own schema block documents the field as `meeting | slack | discussion | development`, and 371 of the records already in `.workaholic/feedbacks/` carry `source: development` against 96 `discussion` and 40 `slack`. So the writer refuses the stream's most common value, a caller following the skill's documented schema is rejected, and `validate-feedback.sh` grandfathers the existing 371 rather than flagging them. Either the writer's set is wrong and `development` belongs in it, or the documentation and the stream are wrong and the four-value set should be corrected everywhere it appears — but the two must not keep disagreeing, because a caller reading the skill cannot tell which one the machine will honour.
