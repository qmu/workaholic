---
type: Feedback
title: Missions must be lightweight enough to close
kind: instruction
source: slack
created_at: 2026-07-31T16:29:46+00:00
author: noreply@anthropic.com
supersedes: 
---

# Missions must be lightweight enough to close

Reported by the requester in Slack (#dev-workaholic) while reviewing
[qmu/workaholic#121](https://github.com/qmu/workaholic/pull/121). Recorded in the reporter's own
words.

## The instruction

Missions have grown far more voluminous than what was originally said, and the formality is what
keeps them open. Make them lighter:

- Drop `## Scope` — remove it from the scaffold, not merely make it optional.
- Keep `## Acceptance` to **at most 3 items**: the minimum conditions under which the mission can
  be called done. Exhaustive lists and future audit items do not belong in a mission.
- Cap the size (~60 lines / 2KB for the whole `mission.md`), and hold `/propose`'s drafts to the
  same cap.
- Keep a feedback record to the contributor's words plus at most one paragraph of measurement.

The gates themselves do not need loosening. The approved floor — an owner, a non-comment
`## Experience`, at least one `## Acceptance` item — is fine as it is. What is missing is a
**ceiling**.

## What was measured (2026-07-31)

The four archived missions carried 3, 3, 4 and 9 acceptance items and all reached `N/N`. The five
active ones carry 7, 8, 8, 9 and 8 — every one at `0/N`. Issue #120's 1,900-character body became
12,228 bytes across three files in one proposal run.

`## Scope` and `## Goal` are read by no validator: `validate-mission.sh` and `approve.sh` require
only an owner, a non-comment `## Experience`, and one `## Acceptance` item. So this is a template
and norm change, not a gate change — the length comes from the writer filling space the scaffold
offers, not from anything the tooling demands.
