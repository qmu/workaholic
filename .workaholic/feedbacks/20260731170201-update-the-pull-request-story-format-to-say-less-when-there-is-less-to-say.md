---
type: Feedback
title: Update the Pull Request Story format to say less when there is less to say
kind: instruction
source: discussion
created_at: 2026-07-31T17:02:01+00:00
author: noreply@anthropic.com
supersedes: 
---

# Update the Pull Request Story format to say less when there is less to say

# Update the Pull Request (Story) format to say less when there is less to say

Registered from [qmu/workaholic#125](https://github.com/qmu/workaholic/issues/125). Recorded in the
reporter's own words.

## The instruction

The PR/Story write-up format workaholic generates for merged pull requests needs four structural
changes:

- **Fold section 5, Historical Analysis, into section 2, Motivation**, rather than keeping them
  separate.
- **When listing concerns, include only those above "Severity: low"** — low-severity concerns should
  not appear in the story.
- **Leave section 7, Successful Development Patterns, empty by default** and populate it only when a
  genuine pattern was actually found, rather than manufacturing content to fill it.
- **Replace the 8-1/8-2/8-3 sub-section structure under section 8, Release Preparation, with a single
  flat list** covering both pre-release and post-release preparation or instructions, included only
  if there is actually something to say.

The underlying complaint driving all four changes is the same: the current generator always tries to
fill every section with as much content as it can, producing longer, denser stories than the
underlying change warrants. The fix should aim for a more concise story that says less when there is
less to say, rather than one that pads sections to look complete.

## What was measured (2026-07-31)

Across the eight most recent stories: 35 concerns, of which 20 (57%) are `- **Severity:** low`;
section 7 is populated in every one of the eight (1-8 bullets, 33 in total) although
`review-sections/SKILL.md` already permits "None"; the stories run 84-179 lines. The sections are
template prose, not gates — `report/SKILL.md` §5/§7/§8 and `review-sections/SKILL.md` define them and
no validator reads them — so this is a template and generator-instruction change, with one knock-on
the fix has to face: section 6 is parsed **verbatim** by `ship`'s `extract-deferred-concerns.sh`, so
dropping low-severity concerns from the story also drops them from the feedback stream unless the
extractor is fed from somewhere else.
