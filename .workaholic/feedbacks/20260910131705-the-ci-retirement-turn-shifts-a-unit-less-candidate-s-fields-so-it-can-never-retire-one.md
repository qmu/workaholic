---
type: Feedback
title: The CI retirement turn shifts a unit-less candidate's fields, so it can never retire one
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-09-10T13:17:05+09:00
author: a@qmu.jp
supersedes: 
---

# The CI retirement turn shifts a unit-less candidate's fields, so it can never retire one

The Claim Retirement workflow reads its candidate rows with a tab IFS, and tab is IFS whitespace: a leading empty field is stripped rather than preserved. Every candidate that carries no unit is therefore called with its fields shifted by one.

## What was measured (2026-09-10, moderation tick 20260910-040330)

`list-retirable-claims.sh` answers one candidate on this repository:

    {"unit":"","branch":"work-20260908-124122","candidate_reason":"pull_request_closed_unmerged","branch_empty":"true"}

Three consecutive CI turns (runs 34433906777 @ 6af7d00d8, 34432898404 @ 4280a3722, 34431951393 @ 809aeec14) each recorded `candidates ok=true count=1` and **zero act annotations**, and `git ls-remote origin refs/heads/work-20260908-124122` still answers 505ecb0a37. So the turn saw the candidate, took no act, and recorded no refusal word either - the candidate is invisible to `read-ci-retirement-record.sh`, which answers `acts: []`.

## The mechanism

`.github/workflows/claim-retirement.yml` pipes `[(.unit // ""), .branch, (.candidate_reason)] | @tsv` into `while IFS="$(printf '\t')" read -r unit branch reason`. Reproduced verbatim against the row above:

    unit=[work-20260908-124122] branch=[pull_request_closed_unmerged] reason=[]

POSIX treats a tab in IFS as IFS whitespace, so the leading empty field vanishes. `delete-retired-claim-branch.sh` is then called with the branch as its unit, the candidate reason as `--branch`, and an empty `--reason`, which fails its own closed-set check (`Unknown --reason:`) and exits 1 writing nothing to stdout. The call is `... | tee -a acts.jsonl`, so the pipeline's status is tee's zero: the step succeeds, `acts.jsonl` stays empty, and the recording step honestly records nothing because nothing was produced.

## Why it matters

This defeats exactly the repair the workflow's own comment describes - *a candidate of the two pull-request classes may carry NO unit ... which is why the branch is passed and why a unit-only loop skipped exactly the branches those classes exist for*. A candidate with a unit aligns correctly and works; the two unit-less classes (`pull_request_merged`, `pull_request_closed_unmerged`) are the ones that can never be retired, and they fail silently, in a turn that concludes success.

## Bounds observed

The tick re-derived and reported only. It ran no act, deleted no branch, closed no pull request and dispatched no workflow.
