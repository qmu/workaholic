---
type: Feedback
title: Make /propose survey the whole repository state and propose a mission with its tickets on a branch
kind: instruction
source: discussion
created_at: 2026-07-31T16:16:50+09:00
author: a@qmu.jp
supersedes: 
---

# Make /propose survey the whole repository state and propose a mission with its tickets on a branch

The proposal batch as it stands reads one input and produces one output: feedback records added between the runner-local cursor and origin/main, in, draft missions pushed to main, out. That is too narrow to answer the question a developer actually opens the repository with, which is "what should I do next". The answer to that question lives in more than the feedback stream.

## The direction

/propose should survey the whole recent state of the repository and come back with a concrete proposal for the next piece of work — both the mission and the tickets under it — on a branch the developer can read as a pull request before anything is accepted.

Three changes to what it is today:

1. **Broaden the inputs.** Read the latest feedback records, the current missions, the current tickets, and the recent commit messages — not feedback alone. What has just been built, what is queued, and what is already planned all constrain what should come next, and a proposer blind to them will re-propose work that is underway or already decided.

2. **Propose tickets, not only a draft mission.** A draft mission with a provisional acceptance sketch and no ticket set is not yet a proposal a developer can act on or judge — the survey already excludes such a mission as `no_tickets`. The proposal should carry the ordered ticket set it implies, so the developer is reviewing real work rather than a title.

3. **Land it on a branch cut from the latest main, not straight to main.** The proposal should arrive as a pull request, so the developer reads it in the place where reviewing is natural and can reject it by closing rather than by cleaning up main.

## Why

The loop only advances when a human supplies direction, and the current batch can only convert direction that was already written as feedback. Broadening the inputs and emitting the ticket set makes the batch able to propose the next step from the state of the work itself, which is what makes an idle loop productive rather than merely honest about being idle.
