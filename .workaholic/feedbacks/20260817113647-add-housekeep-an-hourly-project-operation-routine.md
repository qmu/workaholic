---
type: Feedback
title: Add /housekeep an hourly project operation routine
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-17T11:36:47+00:00
author: a@qmu.jp
supersedes: 
---

# Add /housekeep an hourly project operation routine

The ask: add `/housekeep`, an hourly routine configured as part of `/setup-dev-routines`,
that repeats nine steps against the strategies it relates to — so the repository's state
stays easy for a human to judge while the system finds its own issues, files them, and
keeps improving.

The nine steps, as given:

1. Prepare a log storage location under `.workaholic/`.
2. Check Gmail, Google Drive, Slack and GitHub for updates; reflect anything needed into
   the repository as a GitHub issue through `/fb`.
3. Check workload logs on any environment whose credentials are available; reflect
   anything needed the same way.
4. Resolve conflict state — check pull requests awaiting merge and rebase where necessary.
5. Triage issues — consolidate or remove stale items, and resolve drift between the GitHub
   side (issues, pull requests) and the `.workaholic/` side (tickets, stories).
6. Remind about pull requests that failed to auto-merge, explaining what needs a human
   decision.
7. Resolve documentation drift, starting from `README.md`, against the latest concept.
8. Auto-propose missions and tickets for the strategy — expansion *and*
   cleanup/consolidation directions, so the repository keeps an active metabolism without
   losing consistency. Create the FB, mission, ticket, pull request and Slack thread, and
   mention from Slack marked `:large_yellow_circle: Proposing` rather than
   `:large_blue_circle: Proposed`. Not every run needs to do this — wait up to about a week
   for reactions. Negative feedback is recorded as a decline in the repository, including
   the process leading to it, and the pull request is closed as part of the lifecycle.
9. Check in with humans — up to five questions per run, never during late-night hours.

Five points where the ask meets a decision the loop already made, each of which the
proposal carries forward rather than resolving:

- **Step 8 inverts the propose bar.** `workaholic:propose` states that missions, the queue
  and commits are *constraints, never triggers*, and that feedback is the only input that
  can originate a proposal — the retired `[Propose Batch]` design was exactly a sweep of
  the repository's own state for something to propose. Step 8 asks for proposals
  originating from a strategy. It may be the right change, and it is a reversal, not an
  addition.
- **`:large_yellow_circle: Proposing` collides with an existing shape.** 🟡 is the handoff
  finish line today, and the `📐 Proposing` start post was retired on 2026-08-11 by the
  developer's order. Reintroducing a start post and reusing 🟡 are two separate rulings.
- **Step 4 races the claim protocol.** Pushing into an open pull request's branch was
  measured and refused for the deployment-plan refresh (`workaholic:ship` §7): the branch
  belongs to whoever holds its claim.
- **Step 9 needs a surface and a clock.** A routine-fired session has no `AskUserQuestion`;
  asking means posting into Slack. "Late-night hours" needs a timezone (the workspace's is
  Asia/Tokyo) and a boundary.
- **`scope: developer` multiplies steps 5, 6 and 7.** Those three read the repository, not
  the developer, so N developers' copies each triage the same issues and post the same
  reminders every hour — the exact failure the `repository` scope was introduced for on
  2026-08-14 (issue #451). The ask names `/setup-dev-routines` explicitly, so the split is
  a ruling to make, not an inference.

One measured fact about the premise: the repository currently holds **zero** strategies
(`strategy/scripts/list.sh` → `{"count": 0}`), so the steps scoped "per strategy" have no
data to act on until the operator authors one.

Source: https://github.com/qmu/workaholic/issues/471
