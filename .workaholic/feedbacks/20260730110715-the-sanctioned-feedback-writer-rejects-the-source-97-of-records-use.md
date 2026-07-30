---
type: Feedback
title: The sanctioned feedback writer rejects the source 97% of records use
kind: concern
source: discussion
created_at: 2026-07-30T11:07:15+00:00
author: noreply@anthropic.com
supersedes: 
---

# The sanctioned feedback writer rejects the source 97% of records use

## Description

`skills/feedback/SKILL.md` documents `source: meeting | slack | discussion | development`, and `hooks/validate-feedback.sh` (line 100) accepts all four. `skills/feedback/scripts/create.sh` — which that same SKILL.md calls "the only sanctioned writer" — accepts only three: its `case` rejects `development` with `{"created": false, "reason": "bad_source"}`, and its usage comment lists `meeting | slack | discussion`. `commands/fb.md` step 2 repeats the three-value list.

The drift is not theoretical. 283 of the 291 records in this repository's stream carry `source: development`, and none of them came through create.sh: they are written directly by `skills/ship/scripts/extract-deferred-concerns.sh`, whose line 262 emits the literal `source: development`. That is the second writer the "only sanctioned writer" sentence says does not exist. So the sanctioned writer cannot produce the source 97% of the corpus uses, and the corpus is overwhelmingly produced by an unsanctioned one.

Noticed while registering this very batch: these records are development-born observations, and had to be filed `source: discussion` because create.sh would have refused `development`. The schema's own gloss for `discussion` ("a working session with the AI, or any other origin") makes that defensible, which is precisely why the mismatch can persist unnoticed — the wrong value is always available and never errors.

## How to Fix

Two independent decisions, and they should not be collapsed into one edit. First the enum: either add `development` to create.sh's `case` and to `commands/fb.md` step 2, making the writer agree with the hook and the schema, or narrow the schema and the hook and re-source 283 records. The first is almost certainly right — the value is already load-bearing and every consumer reads it. Second the writer claim: either route `extract-deferred-concerns.sh` through create.sh, or amend SKILL.md to say what is true — create.sh is the writer for hand-registered feedback, the extractor is the writer for ship-time concerns and stamps the producer fields (`severity`, `concern_id`, `origin_pr`, …) create.sh does not. Fixing the enum while leaving the "only sanctioned writer" sentence standing would make the document less true, not more.
