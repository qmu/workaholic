---
created_at: 2026-08-01T18:57:01+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-the-branch-story-concise-by-default
merge_policy: auto
---

# Decide the fate of low-severity concerns

## Overview

Issue #125 asks the story to list only concerns above `low`. Taken literally that
instruction **deletes knowledge**, and the second feedback record on this mission says so:
`extract-deferred-concerns.sh` reads the story as its **only** source and records every
severity into the feedback stream. A concern filtered out of section 6 is not merely
unprinted — it is never extracted, never keyed on a `concern_id`, and never becomes part
of the open set that later readers compute.

So the brevity ask and the extraction contract collide, and the collision has to be
resolved before the template changes. The candidates:

1. **Filter at render, keep at extract** — the story file carries every severity while the
   PR body shows only those above `low`. This needs the two to stop being the same text,
   which today they are.
2. **Keep every concern in the story, shorten elsewhere** — accept that section 6 is the
   one section whose length is load-bearing, and take the brevity from the other three
   changes.
3. **Filter genuinely, and accept the loss** — a deliberate decision that a `low` concern
   is not worth carrying. Defensible only if stated, since the promotion floor was already
   retired once on the grounds that curation is the reader's judgment over the stream.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a record that silently stops being written is worse than one that was never written; the reader cannot tell.
- `workaholic:development` / `policies/review.md` — the story is what the reviewer reads; its length is a real cost and brevity is a real goal.
- `workaholic:implementation` / `policies/objective-documentation.md` — whichever is chosen, the extraction contract must be stated where both halves can see it.

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - reads the story as its only source, records every severity
- `plugins/workaholic/skills/report/SKILL.md` - section 6's format, parsed verbatim by the extractor
- `plugins/workaholic/skills/report/scripts/create-or-update.sh` - copies the story into the PR body
- `plugins/workaholic/skills/report/scripts/shrink-pr-body.sh` - already treats story and PR body as separable when bounding

## Implementation Steps

1. Confirm the coupling by reading the extractor rather than assuming it: it parses
   section 6's `###` blocks out of the committed story file, not the PR body.
2. Note the precedent for candidate 1 — `shrink-pr-body.sh` already replaces section 6 in
   the **body** with a pointer while the extractor keeps reading the **file**, byte for
   byte. Divergence between the two is established practice, not a new idea.
3. Choose, and write the decision where both halves are described: `report/SKILL.md` and
   `ship`'s extraction section.
4. Name the rejected alternatives with reasons.

## Quality Gate

**Acceptance criteria**

- The fate of low-severity concerns is decided and written down, with rejected alternatives named.
- The decision states explicitly what the **extractor** sees after the change, not only what the reader sees.
- If the story file and the PR body diverge, that is stated as the contract rather than left as an implementation detail.
- No template change in this ticket.

**Verification method**

- Read `extract-deferred-concerns.sh` and confirm which artifact it parses; record the finding.
- Read-through of the written decision against both `report/SKILL.md` and the extraction section.

**Gate**

- The decision says what the extractor sees. A brevity change that silently stops recording a class of concern is exactly the masked failure the observability policy forbids, and it would be invisible for weeks.

Decided: this is decided before the template changes, not alongside them — three of the four structural changes are independent of it, but section 6's is not, and getting it wrong loses records rather than producing a long story (developer may override at /drive).

## Considerations

- The stream is append-only and keyed on `concern_id`, so a concern dropped from one story and re-raised later arrives as a new record with no link to the first. That is the concrete cost of candidate 3, and it is worth stating in the decision.
