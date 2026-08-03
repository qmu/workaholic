---
type: Feedback
title: Low-severity concerns are filtered at render, kept at extract
kind: concern
source: discussion
created_at: 2026-08-03T21:28:53+09:00
author: a@qmu.jp
supersedes: 
---

# Low-severity concerns are filtered at render, kept at extract

Issue #125 asks the branch story to list only concerns above `low`. Taken literally that instruction deletes knowledge: `extract-deferred-concerns.sh` parses the committed story file (`.workaholic/stories/<branch>.md`) as its only source and records every severity into the feedback stream, so a concern filtered out of the story is never extracted, never keyed on a `concern_id`, and never joins the open set later readers compute.

Decision: filter at render, keep at extract.

- The story file records every concern at every severity. It is the durable artifact and the extractors only source.
- The PR body drops the `low` blocks and says how many it dropped, pointing at the story file.
- What the extractor sees is unchanged. It reads the file, never the body.

Rejected, with reasons:

- Keep every concern in both. Gives up brevity in the one section most likely to be long, which is the actual complaint.
- Filter genuinely and accept the loss. The stream is append-only and keyed on `concern_id`, so a low concern dropped from one story and re-raised later arrives as a fresh record with no link to the first. The observability policy is explicit that a record which silently stops being written is worse than one never written, because the reader cannot tell.

The divergence between story file and PR body is stated as the contract in `report/SKILL.md` and in `ship/SKILL.md` section 2-5, not left as an implementation detail. Precedent: `shrink-pr-body.sh` already replaces the Concerns section in the body with a pointer while the extractor keeps reading the file byte for byte.
