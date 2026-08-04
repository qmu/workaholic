---
created_at: 2026-08-04T11:10:06+00:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category: Changed
mission: make-the-branch-story-measurably-shorter
merge_policy: review
---

# Measure which story sections carry the line growth, before anything else is changed

## Overview

The predecessor mission (`make-the-branch-story-concise-by-default`) made four structural edits to the story template — Historical Analysis folded into Motivation, `low` concerns dropped from the PR body, Patterns left empty unless one was found, 8-1/8-2/8-3 flattened — and stories got **longer**: mean 127 lines across eight stories written 2026-08-01, against 164 across ten written 2026-08-03〜04. A 29% increase from edits intended to shrink the artifact.

That is the whole reason this mission exists, and it means the lever was wrong. **This ticket makes no edit at all.** It answers one question with data: which sections actually carry the added lines? A fifth structural edit made on the same assumption as the first four is the failure mode to avoid, and the only thing that prevents it is a measurement that names the cause.

## What to measure

Per section (`## 1. Overview` … `## 8. Notes`, plus frontmatter), across the same two story sets the 29% figure came from:

| quantity | why it is needed |
| -------- | ---------------- |
| lines per section, per story | the raw signal |
| mean per section, per set | which section grew, and by how much |
| share of the total delta per section | separates "grew a lot proportionally" from "carries the growth" — a section that doubled from 3 to 6 lines is not the cause |
| section presence/absence counts | a section that was *always* empty before and is *sometimes* filled now moves the mean without any section growing |
| story count and branch size per set | a confound: if the later branches were simply bigger, longer stories are correct behavior and the mission's premise is wrong |

That last row is not optional. The mission's own Experience says length should track the size of the change, so a measurement that cannot separate "the writer padded" from "the branches were larger" cannot name a cause. Report changed lines per branch alongside story length, and say plainly if the correlation explains the delta.

## Where the sets are

`.workaholic/stories/*.md`, partitioned by their commit date, not by filename: the pre-change set is the eight stories of 2026-08-01, the post-change set the ten of 2026-08-03〜04. Derive both from `git log --diff-filter=A` over the stories directory rather than hand-listing them, so the sets are reproducible by the next reader.

## The deliverable

A **feedback record** (`kind: insight`) naming the sections that carry the growth, with the per-section table, the branch-size confound addressed, and an explicit verdict sentence: either "sections X and Y carry N% of the delta" or "the delta is explained by branch size and the premise does not hold". The follow-up ticket acts on that verdict, so it must be a statement someone can act on, not a table someone must interpret.

No change to the template, the report skill, or any story. If the measurement turns out to invalidate the mission's premise, say so — that is a successful outcome of this ticket, and the mission's second criterion is then the one to revisit.

## Policies

- `workaholic:planning` / `policies/verify-before-building.md` — four structural edits shipped on an unmeasured assumption and moved the number the wrong way; this ticket exists to stop the fifth
- `workaholic:implementation` / `policies/observability.md` — the deliverable is a named cause, not a table; a measurement nobody can act on is not a measurement
- `workaholic:design` / `policies/history-structures.md` — the record goes in the feedback stream, where the direction already accretes

## Key Files

- `.workaholic/stories/` — both story sets; the corpus being measured
- `plugins/workaholic/skills/report/SKILL.md` — the section structure (`## 1. Overview` … `## 8. Notes`) the measurement bins by
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the only sanctioned writer of the deliverable
- `plugins/workaholic/skills/mission/scripts/unlinked-acceptance.sh` — the shape to follow if the measurement is worth keeping as a script

## Related History

The 29% figure was measured 2026-08-04 when the predecessor mission was closed `carried`; it is the successor's entire justification and is recorded in `.workaholic/missions/active/make-the-branch-story-measurably-shorter/mission.md`'s `## Goal`. The predecessor is in `.workaholic/missions/archive/make-the-branch-story-concise-by-default/`.

## Implementation Steps

1. Derive both story sets reproducibly from git history over `.workaholic/stories/`.
2. Bin every story's lines by section heading; record per-section means for each set.
3. Compute each section's share of the total delta, and count presence/absence changes.
4. Pull changed-lines-per-branch for both sets and state whether branch size explains the delta.
5. Write the verdict as a `kind: insight` feedback record through `feedback/scripts/create.sh`.
6. If the measurement is cheap to re-run, leave it as a script under the report skill; if it is a one-off, say so in the record rather than shipping a script nobody will run twice.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Both story sets are derived from git, not hand-listed, and the derivation is stated in the record.
- Every section has a per-set mean and a share of the total delta.
- The branch-size confound is addressed explicitly, with a stated verdict either way.
- The record ends in one sentence naming the cause (or naming the premise as unsupported).
- No file under `plugins/workaholic/skills/report/` and no existing story is modified.

**Verification method** — the commands/tests/probes that prove them:

- `git diff` shows changes only under `.workaholic/feedbacks/` (plus a script, if one was kept).
- The record's numbers reproduce from the commands it cites.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- A reader can act on the verdict sentence without re-reading the table.

## Considerations

- **Do not fix anything here.** The temptation is to shorten the obvious section while the data is in front of you. The next ticket does that, and it needs this ticket's number to prove it worked.
- **A negative result is a result.** If branch size explains the growth, that ends the mission honestly and is worth more than a fifth edit.
- **Bin by heading, not by regex over prose.** A story that renamed a heading should be counted as such, not silently dropped.
