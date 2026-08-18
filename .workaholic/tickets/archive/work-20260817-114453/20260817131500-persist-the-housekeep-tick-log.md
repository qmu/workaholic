---
created_at: 2026-08-17T13:15:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff:
---

# Persist the housekeep tick log

## Overview

Minted mid-drive on `work-20260817-114453` (the housekeep mission), from an observed problem
outside every step ticket's scope: **the tick log is written into the checkout and nothing
commits it.**

A routine-fired `[Housekeep]` tick runs in a fresh container cloned from `main`, so every dedup
that reads `.workaholic/housekeeping/` behaves as if no earlier tick ever ran — the stuck-PR
reminder's `stuck:<digest>` gate, `doc-drift`'s already-filed set, the check-in's asked-once and
held sets, and the inbound sweep's window. All four would re-fire hourly. The log is also the
routine's only audit trail, so an unpersisted log means an hourly unattended process with **no
record of what it did**.

Running `/housekeep` by hand is unaffected: the checkout survives the tick. This is what stands
between the mission and a routine that is safe to switch on.

## Policies

- `workaholic:operation` / `policies/observability.md` — a log that does not survive its run is not evidence
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the repository's history is the durable record

## Key Files

- `plugins/workaholic/skills/housekeep/scripts/log-append.sh` / `log-read.sh` — the writer and
  the reader; both take `--root`, neither commits.
- `plugins/workaholic/skills/housekeep/scripts/run.sh` — the one log writer per tick, and the
  natural place for a persist step at the end of the run.
- `plugins/workaholic/skills/branching/scripts/open-publish-tree.sh`,
  `publish-tree-commit.sh`, `close-publish-tree.sh` — the sanctioned artifact-writing seam: a
  checkout of `origin/main` at git-ignored `.publish/`, leaving the caller's checkout
  byte-identical. `publish-tree-commit.sh` is the direct (non-PR) path.
- `plugins/workaholic/skills/ship/SKILL.md` §7, *Why this is a reader* — the three unattended
  `main`-writer designs that were measured and refused. A log append is not one of them (it is
  append-only, it is not self-referential, and it touches no branch the claim protocol owns), but
  the ticket must say why it is different rather than assume it.
- `plugins/workaholic/rules/workaholic.md` — the `housekeeping/` area definition, which states
  that `/housekeep` is the only writer.

## Implementation Steps

1. Decide the seam (Open Decision below), then implement it as the **last** step of a tick, so a
   tick that dies half-way still persists what it recorded.
2. Make the persist idempotent and conflict-tolerant: two ticks appending to the same day file
   from different containers must both land. Appending distinct `## <tick-id>` sections is
   already conflict-friendly; the resolution rule belongs in the script, not in a human's hands.
3. Report the persist outcome as its own log line and report row (`persisted` / the failure by
   name). A tick whose log did not reach `main` must say so — that is the same rule every other
   step in this skill follows.
4. State in `reference/workflow.md` and `rules/workaholic.md` who commits the log and when.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- After a tick, the day file is on `main` (or its failure to get there is reported by name).
- The caller's checkout is byte-identical after the persist — no branch, no stray worktree.
- Two ticks from different clones on the same day both land; neither erases the other's section.
- A tick that cannot reach the remote reports it and still completes its steps.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a hermetic fixture with two clones appending on the
  same day.
- `sh scripts/e2e/loop-drill.sh verify-housekeep`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

## Open Decisions

1. **Publish tree, or the claim protocol's own seam?** A publish-tree direct commit
   (`publish-tree-commit.sh`) is the loop's sanctioned way to put an artifact on `main` without
   touching the caller's checkout, and it is what `/propose` and `/ticket` already use — but the
   direct (non-PR) form is documented as being for post-merge seams only, and an hourly append is
   not one of those. The alternative is a pull request per tick, which is 24 pull requests a day
   for a log. Decide, and record why the chosen one is not the unattended-`main`-writer class
   `workaholic:ship` §7 refused.

## Considerations

- The failure is invisible in a hand-run: `/housekeep` in a normal checkout leaves the log in the
  working tree, where the next hand-run reads it. Only the routine loses it, which is exactly the
  case nobody watches.
- A cheaper partial answer exists and should be weighed: several dedups could key on durable
  artifacts instead of the log (a feedback record already names the issue it captured; a Slack
  search already answers "was this posted"). It does not cover the audit trail, which is the
  half that has no substitute.

## Final Report

Development completed as planned.

### Open Decision resolved

**1. Publish tree, or a pull request per tick? — the publish tree, directly
(`publish-tree-commit.sh`).**

The direct form's "post-merge seams only" documentation is about *when a direct commit is owed
no approval*, and an append-only operational log is that case by construction: nothing in it is
a decision, and there is no content a reviewer could rule on. A pull request per tick is
twenty-four a day asking a human to approve a line recording what a machine already did — a
review with no possible verdict is not a gate, it is noise that trains its reviewer to stop
looking.

It is not the unattended-`main`-writer class `workaholic:ship` §7 refused, checked against each
of that section's three rows on its own stated ground:

- *"Refresh a merged note on `main`"* was refused as **self-referential** — the plan's datum is
  the base sha, so the refresh's own commit changes the number it reports. A log append has no
  such loop: its content is the tick's probe results, fixed before the persist runs, and
  appending it changes no input to the tick that wrote it. What *later* ticks read out of it
  (the dedup sets) is the point of the ticket, not an invalidation.
- *"Push into each open PR's branch"* was refused because those branches belong to whoever holds
  their claim. This writes to no branch: `publish-main` stays local and only the commit lands on
  the base, so the claim scan never sees it.
- *"Run `/ship` hourly"* was refused because `/ship` merges. This merges nothing and reads no
  pull request.

### Discovered Insights

- **Insight**: A textual rebase cannot reconcile two end-of-file appends, so
  `publish-tree-commit.sh`'s built-in one-shot rebase is not by itself enough for a
  concurrently-written artifact — the retry has to re-derive the content against the new base.
  **Context**: `persist-log.sh` therefore loops open→union→commit rather than replaying a patch:
  each attempt re-opens the publish tree at a freshly fetched base and appends only the
  `## <tick-id>` sections that base is missing. Any future artifact written by more than one
  unattended runner on the same path will need the same shape.
- **Insight**: A publish step's blast radius is decided by *where the git repository is*, not by
  where its input is. `run.sh` takes `--root`, and the drill deliberately points it at a
  throwaway directory while running from inside the operator's own checkout.
  **Context**: Without the `not_a_repo` / `root_not_repo_root` guard the drill would have
  committed a fixture's log into the operator's base every time it ran. The guard resolves the
  git toplevel *of the log root* and refuses anything that is not exactly it.
- **Insight**: Recording the outcome of a publish, in the thing being published, does not
  terminate — the outcome is only known after the push, and pushing the line recording it needs
  its own line.
  **Context**: The persist's own log line is written to the checkout and not to the base, and
  nothing is lost by that: the base already answers the question the line would ask, because a
  tick's section is present there iff its persist succeeded. Any future self-recording write has
  the same regress and the same escape.
