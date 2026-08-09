---
type: Feedback
title: Lighten /report now that PRs are merged per single ticket, without losing result records or cross-document relations
kind: instruction
source: slack
created_at: 2026-08-09T01:05:11+00:00
author: a@qmu.jp
supersedes: 
---

# Lighten /report now that PRs are merged per single ticket, without losing result records or cross-document relations

The workflow has shifted toward creating and merging a PR for even a single ticket at a time, rather than batching a full Story's worth of tickets into one PR. Under that shift, /report's current scope — sized around reporting on a whole Story's volume of work — is no longer well matched to how much work and how much time is actually being spent per run; it's now doing more than the unit of work it's reporting on.

The ask is to make /report lighter/cheaper to match the new single-ticket-per-PR granularity, while preserving two things that must not be lost:

1. The recording of results (whatever /report currently persists about what was done and its outcome).
2. The relations between documents (the links/traceability across FB issues, proposal PRs, tickets, and reports that let someone — human or agent — navigate from one to the others).

Worth having a downstream design agent look at right-sizing /report's unit of work (e.g. per-ticket instead of per-Story) and/or trimming what it does per run, while keeping its output linked into the existing FB -> Proposal -> Implementation -> Report chain.

Source issue: https://github.com/qmu/workaholic/issues/308
