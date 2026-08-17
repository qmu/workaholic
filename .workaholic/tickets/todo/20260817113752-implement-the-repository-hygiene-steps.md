---
created_at: 2026-08-17T11:37:52+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113750-add-the-housekeep-command-and-skill.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Implement the repository hygiene steps

## Overview

Steps 4, 5, 6 and 7 of the ask — the four that act on the repository's own state:

- **4. Conflict state.** Check pull requests awaiting merge and rebase where necessary.
- **5. Issue triage.** Consolidate or remove stale items; resolve drift between the GitHub
  side (issues, pull requests) and the `.workaholic/` side (tickets, stories).
- **6. Auto-merge reminders.** Remind about pull requests that failed to auto-merge,
  explaining what needs a human decision.
- **7. Documentation drift.** Check whether features are reflected against the latest
  concept, starting from `README.md`; file what is needed.

Two of these already have partial machinery to reuse rather than duplicate:
`report/scripts/doc-drift.sh` and `area-freshness.sh` exist as `/report`'s documentation
backstops, and the `📦 Release status` line is the precedent for a gated recurring post.
Step 4 is the one that touches other people's branches, and it is fenced below.

## Policies

- `workaholic:operation` / `policies/observability.md` — a reminder is only useful if it names the decision needed
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the repository's history is the durable record; a rewrite is not a cleanup

## Key Files

- `plugins/workaholic/skills/report/scripts/doc-drift.sh` and `area-freshness.sh` — the
  existing documentation backstops. `area-freshness.sh`'s stated contract is **it reports,
  it never writes**, and the reasoning generalises to step 7.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` and
  `drive/reference/claims.md` — **unmerged remote branches are the only claim oracle**. A
  pull request awaiting merge is, in the normal case, a *claimed* unit.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the transport for the GitHub side
  of the drift check.
- `plugins/workaholic/skills/notify/SKILL.md` — the bright line (what earns a post) and the
  dedup rules. Step 6 is a recurring post and needs a content key, exactly as
  `deploy:<digest>` does.
- `plugins/workaholic/skills/ship/SKILL.md` §7, *Why this is a reader* — the three
  unit-less writer designs that were measured and refused; step 4 is the second of them.

## Implementation Steps

1. **Step 5 and 7 first — they only read.** Compute the GitHub↔`.workaholic/` drift set
   (an archived ticket whose issue is still open; an open issue whose ticket is archived; a
   story with no PR) and the documentation drift, and report both. Reuse `doc-drift.sh`
   rather than writing a second checker.
2. **File, do not fix.** A drift finding becomes a feedback record (the inbound-sweep
   ticket's ruling applies), never an edit to `README.md` by the tick. The reasoning is
   `area-freshness.sh`'s and it holds here: a machine rewriting the document records what
   happened rather than what should happen.
3. **Step 6**: identify pull requests whose auto-merge did not take, derive the human
   decision each needs (a scan finding, a conflict, a failing check, a missing review), and
   post one gated reminder — both gates required, as `📦 Release status` has: something
   actionable, and a content-keyed exact-string search finding no earlier post for the same
   state. An unchanged answer is never repeated.
4. **Step 5's "remove old/unnecessary items"**: close, never delete, and only with the
   reason recorded. Consolidation that merges two issues is a judgment; propose it, do not
   perform it.
5. **Step 4** only after its Open Decision is resolved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Steps 5 and 7 write no file outside the tick log and the records they file.
- Step 6 posts at most one reminder per distinct state, and an idle tick posts nothing.
- Step 4 never pushes to a branch held by another runner's claim.
- Every GitHub call goes through `gh-rest.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Two consecutive dry runs against an unchanged repository: the second posts nothing and
  files nothing.
- A dry run against a repository with a known drift pair: it is reported exactly once.

**Gate** — what must pass before approval:

- The Open Decision resolved and recorded in the Final Report.

## Open Decisions

1. **May the tick rebase a pull request at all?** Step 4 asks it to. Pushing into an open
   pull request's branch is one of the three writer designs `workaholic:ship` §7 measured
   and refused, and the reason is structural rather than stylistic: a `work-*` branch **is**
   the claim — the heartbeat is its tip and `archive.sh` pushes it after each archive
   commit — so a third party rebasing it races the claim holder's own pushes and can strand
   or duplicate a unit. Three branches to choose from, and this session cannot recommend
   one: (a) do not rebase; report the conflict and let the claim holder resolve it, which is
   already the drive loop's own instruction on a merge-conflict notice; (b) rebase only
   branches with **no live claim** (merged-out or heartbeat long lapsed), which needs a
   staleness rule the claim protocol deliberately does not have — it reports staleness and
   never acts on it; (c) rebase anything, and accept the race. Option (a) writes nothing and
   is the smallest, but it is also the one that does least of what the ask asked for.

## Considerations

- Step 5's drift check is the most valuable and cheapest of the four: it is a pure read over
  two lists and it catches the failure mode nobody watches.
- Step 6 overlaps `[Release Status]`'s territory in spirit but not in content — one reports
  what is waiting to deploy, this reports what is waiting on a human. Keep the keys
  distinct so neither dedups the other away.
- If the routine ends up `scope: developer` (the template ticket's Open Decision), steps 5,
  6 and 7 run N times an hour for N developers and post N reminders. That is the strongest
  argument in that decision and it belongs on the record here too.
