---
created_at: 2026-09-19T09:06:14+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Give the worktree reaper a caller, and stop reporting a held backlog as nothing to do

## Overview

`branching/scripts/reap-worktrees.sh` is reachable only by a person typing it. Operator's ask:
**issue #1212**; feedback record on the base:
`.workaholic/feedbacks/20260919083922-nothing-invokes-the-worktree-reaper.md` (merged in pull
request #1214). Register the sweep as a `/moderate` step that applies, and make its own output
distinguish *nothing to free* from *nothing held*.

**The claim was re-established here rather than taken from the title, and it holds.** Walking the
tracked tree for `reap-worktrees.sh`, it appears outside its own body in exactly four places:
`CLAUDE.md:244` (prose), `plugins/workaholic/skills/branching/SKILL.md:130` (a usage row),
`scripts/test-workflow-scripts.mjs:264` and `scripts/tests/agentic-loop/publication-claim.test.mjs:12`
(both test fixtures). **No command body, no skill workflow step, no entry in
`moderate/scripts/steps.json`, no `.github/workflows/*.yml` and no routine prompt invokes it.**
`survey-worktrees.sh` is the same: its only non-test caller is `reap-worktrees.sh:56`. The script
written to catch what teardown structurally cannot has never been reachable by anything that runs
on its own.

**Independently measured on this repository, 2026-09-19.** `survey-worktrees.sh` reports **4
worktrees, 191.7 M held, `reclaimable_bytes: 0`**, every one `skip_reason: "unmerged"` — the four
the ask names, oldest checkout dated 2026-09-03, sixteen days standing. All four local branches
are **gone from `origin`** (`delete_branch_on_merge` removed them at the merge), three of the four
have their unit's `archive/<branch>/` directory present on `origin/main`, and `ahead` reads 3009,
2988, 2995 and 2 against `origin/main`. So these are not live work: they are finished units whose
checkouts nothing owns.

**Why `merged` never becomes true for them, which is the second half of the ask.** `merged` is
`ahead == 0` against `origin/<base>` (`survey-worktrees.sh:113-122`) — **ancestry**. Every pull
request this loop merges is squash-merged (2026-09-01), so a landed branch is never an ancestor
of the base and `ahead` never returns to zero. This is the same reading `superseded` was repaired
for in issue #788: ancestry cannot answer *did this work land*, and the tree can.

**The predicate is nevertheless NOT loosened by this ticket, and that is the operator's own
ruling** (issue #1212, verbatim: *"`reclaimable` is merged AND clean, which is the right predicate
and I am not proposing to loosen it"*, and *"I do not think they should be deleted by a script
under the current predicate"*). The consequence is stated rather than hidden: **the first sweep on
this repository frees zero bytes and removes none of the four.** It is still worth shipping — the
same sweep, run once on a consuming repository, removed **44 worktrees and freed 5.4 GB with zero
failures**, because the merged-and-clean case does occur wherever a run reaches its end normally.

**The fork on which seam owns the call, closed here rather than recorded as an `## Open Decisions`
item.** Chosen: **a `/moderate` step**.

- **`/drive`'s teardown was rejected** for the reason the reaper's own header gives
  (`reap-worktrees.sh:12-19`): teardown already exists three times over and each is correct, but
  all three share one precondition — *somebody's run has to reach the end*. A worktree whose run
  died, whose branch was hand-driven, or whose caller was killed is nobody's teardown, and that is
  precisely the set that accumulates. Adding a fourth teardown call would add a fourth instance of
  the same precondition.
- **`/workaholify`'s converge seam was rejected** because it runs when an operator invokes it. The
  sweep would remain person-triggered, which is the defect.
- **`/moderate` fits by charter and by precedent.** It runs hourly, unattended, in the main
  checkout; its charter is finding what has gone stale; and `step-retire-claims.sh` (step 19) is
  the standing precedent for a step that **acts** on a proof rather than reporting it, including
  the precedent that **a local worktree reap is not a tree write** and so does not breach the
  tick's *writes nothing but its own log line* contract (`step-retire-claims.sh:68-73`).

**What proof the reaper requires before it removes anything — measured, not assumed.** Probed in a
throwaway repository on 2026-09-19:

- `git worktree remove` on a **clean** worktree whose branch holds commits the base lacks is
  **allowed**, and afterwards `refs/heads/<branch>` is still present and the commit is still
  reachable. A worktree removal destroys a **checkout**, never a branch and never a commit.
- `git worktree remove` on a worktree holding an untracked file is **refused by git itself**:
  `fatal: … contains modified or untracked files, use --force to delete it`.

So the proof is: **`reclaimable == true`** — re-derived by `reap-worktrees.sh` from a fresh
`survey-worktrees.sh` at the moment of the act (`reap-worktrees.sh:56`), meaning *merged* AND
*clean* AND no open publication transaction AND not the main tree, `.publish/`, or the current
worktree — **plus** `git worktree remove` **without `--force`**, which is a second, independent
gate the step does not own and must not bypass. Nothing else. No branch is deleted, no ref is
written, and nothing is pushed.

**A live claim's worktree cannot be reclaimable, by construction rather than by a second check.** A
live claim always carries at least its own `Claim <unit-id>` commit on the branch, so `ahead >= 1`
and `merged` is `false`. The step therefore adds **no** claim-liveness term: the reaper's header
forbids a second safety authority beside `reclaimable` by name (`reap-worktrees.sh:21-25`), and a
second one is exactly how the reader a human consults and the writer that acts start disagreeing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` for the new step script (all code work)
- `workaholic:implementation` / `policies/observability.md` — the governing policy for the second half: `0 B reclaimable` beside 191.7 M held is a state no reader can explain from the outside. The cost held, and the fact that none of it is reclaimable, must be answerable without anyone running `du`.
- `workaholic:implementation` / `policies/command-scripts.md` — an operation reachable only by prior knowledge of a script name is the gap this policy closes; registering it in `steps.json` is what makes it runnable by something other than a person who already knows.
- `workaholic:implementation` / `policies/test.md` — the sweep's bounds and refusals are pinned by hermetic fixtures, not by reading the step.

## Key Files

- `plugins/workaholic/skills/branching/scripts/reap-worktrees.sh` - the writer. Its predicate, its dry-run default and its `--apply` flag are unchanged by this ticket.
- `plugins/workaholic/skills/branching/scripts/survey-worktrees.sh` (lines 113-122, 134-149) - the one predicate: `ahead`, `dirty`, `merged`, the publication-transaction skip and `skip_reason`.
- `plugins/workaholic/skills/moderate/scripts/steps.json` - the registry; a step that is not here does not run.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` - the model for a step that acts: the emit contract, the summary-stability rule, the empty-`event` guard, and the precedent that a local worktree reap is not a tree write.
- `plugins/workaholic/skills/moderate/reference/workflow.md` - the per-step reference; sections currently run to 32.
- `plugins/workaholic/skills/moderate/scripts/run.sh` (line 87) - reads the registry; no per-step list to edit.
- `plugins/workaholic/skills/moderate/scripts/lib/jq-guard.sh` - sourced by every step in this skill that embeds a jq program.
- `scripts/test-workflow-scripts.mjs` (lines 31-36, 263-264) - `moderateSteps()` consumes the registry directly; the reaper's fixture paths already exist here.
- `CLAUDE.md` (line 244) - *claim-born and ship-torn* names the reaper as a backstop; update it in the same change to say which seam now calls it.

## Related History

Worktree reclamation was built once, as a reader and a sweep, after a 53 GB incident — and the
sweep was never given a caller. The reading that would make its `merged` term true for landed work
was repaired elsewhere (`superseded`, issue #788) and never carried back here.

- [20260801003034-worktrees-are-never-reclaimed.md](.workaholic/tickets/archive/work-20260801-023444/20260801003034-worktrees-are-never-reclaimed.md) - built `survey-worktrees.sh` and `reap-worktrees.sh`; its story already warned that the survey should be run on the machines driving the workflow
- [20260826113204-read-whether-a-claim-s-work-reached-the-base.md](.workaholic/tickets/archive/work-20260826-122328/20260826113204-read-whether-a-claim-s-work-reached-the-base.md) - the tree-based landing proof that ancestry could not give
- [20260829193103-let-the-retirement-act-re-derive-superseded-where-ci-runs.md](.workaholic/tickets/archive/work-20260829-205701/20260829193103-let-the-retirement-act-re-derive-superseded-where-ci-runs.md) - the re-derive-at-the-moment-of-the-act discipline this step inherits

## Implementation Steps

1. **Reproduce the two findings before changing anything.** Walk the tracked tree for
   `reap-worktrees.sh` and confirm the four non-body occurrences are the two documentation rows
   and the two test fixtures. Run
   `bash plugins/workaholic/skills/branching/scripts/survey-worktrees.sh` in the main checkout and
   record `count`, `total_human`, `reclaimable_human` and every `skip_reason`. Then run
   `bash plugins/workaholic/skills/branching/scripts/reap-worktrees.sh` (dry run, no `--apply`)
   and confirm `removed: []`. This is the before-state.
2. **Write `plugins/workaholic/skills/moderate/scripts/step-worktree-sweep.sh`.** Contract
   identical to its siblings: `--tick <tick-id> [--root <repo-root>]`, one JSON line
   `{step, status, reason, summary, needs_agent, event}`, always exit 0, source
   `lib/jq-guard.sh`. It composes `../../branching/scripts/reap-worktrees.sh --apply` **from
   `$ROOT`** and parses its envelope. It derives no predicate of its own and passes no survey in:
   the reaper re-derives the proof from a fresh survey at the moment of the act, and a step that
   handed it a cached reading would break exactly that property.
3. **Refuse rather than sweep when the reading is degraded.** A missing reaper script, empty
   output, or output this step cannot parse is `degraded` with its own reason word
   (`no_reaper`, `reaper_unreadable`, `reaper_unparseable`) and **nothing removed** — following
   `step-retire-claims.sh`'s *a degraded read retires nothing*. An absent `.worktrees/` directory
   and a repository with no linked worktrees are the ordinary `ok` case, not a degradation.
4. **Make the summary say what is held, not only what was freed** — the ask's second finding. The
   summary is the log-facing field *and* the root's change key, so it must be a function of the
   worktree set and its skip reasons alone:
   `<N> worktree(s); <R> reclaimable, <removed> removed, <skipped> skipped — <count> unmerged,
   <count> dirty, <count> unmerged_and_dirty, <count> publication_transaction`.
   A repository holding worktrees none of which can ever be freed therefore reads as what it is,
   instead of as a clean tick. **Byte totals are deliberately excluded from the summary**: `du`
   output moves between ticks, so a byte count in the diff key would render a root line every
   hour for a backlog that had not changed — the noise `step-retire-claims.sh`'s stability rule
   exists to prevent. The header names `survey-worktrees.sh` as where a reader gets the bytes.
5. **Supply an `event` only for an actual removal.** One or more worktrees removed is a
   repository fact and earns a post-facing phrase naming **how many**, never which — the
   2026-09-01 rule that a root line carries counts and a question carries identifiers. A sweep
   that removed nothing supplies an empty `event` and so renders no root line at all.
6. **`needs_agent` is empty.** This step asks nobody anything, for `step-retire-claims.sh`'s own
   reason: a merged-and-clean worktree is proved finished, so there is no judgement for a person
   to make. **Escalating the unreclaimable backlog to a person is an explicit non-goal of this
   ticket** — it would need a size or age threshold, and this repository does not add a constant
   without a home for it. The reading is shipped; whether a number should provoke a question is a
   later, separable decision, and the log now carries the evidence either way.
7. **Register the step** in `moderate/scripts/steps.json` with `id: "worktree-sweep"`,
   `script: "step-worktree-sweep.sh"` and the standard `3600` trigger. Place it beside
   `retire-claims`, whose subject it is nearest. `run.sh` needs no edit.
8. **Document it** as the next free numbered section in `moderate/reference/workflow.md`
   (sections currently end at 32), carrying: the invocation line, what it acts on, the exact proof,
   the two things it never does (no branch delete, no `--force`), and the measured reason a live
   claim's worktree cannot be a candidate.
9. **Update `CLAUDE.md:244`** so *claim-born and ship-torn* names the seam that now calls the
   backstop, and says what the sweep does and does not remove.
10. **Add hermetic rows to `scripts/test-workflow-scripts.mjs`** over a throwaway repository with
    four worktrees — one merged-and-clean, one clean-but-unmerged, one dirty, one untracked-only —
    asserting the removal set, the summary's skip-reason breakdown, the empty `event` on a
    zero-removal sweep, and that every surviving branch ref is present afterwards.
11. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
    `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
    `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `moderate/scripts/steps.json` carries a `worktree-sweep` entry, and
  `step-worktree-sweep.sh` exists beside its siblings and emits the six-key envelope on every path.
- Given a fixture worktree that is **merged and clean**, one tick removes it and the step's
  `removed` count is 1; `refs/heads/<its branch>` is **still present** afterwards and its tip
  commit is still reachable.
- Given fixture worktrees that are **unmerged**, **dirty**, or **untracked-only**, one tick
  removes none of them and each appears in the summary's skip-reason breakdown under its own word.
- The step never invokes `git worktree remove --force`, never runs `git branch -d`/`-D`, never
  runs `git push`, and never writes a file into the repository other than the tick log line.
- A sweep that removed nothing emits an **empty** `event`; a sweep that removed one or more emits
  an event naming the count and no worktree path or unit slug.
- A missing, unreadable or unparseable reaper answers `status: "degraded"` with its own reason and
  a `removed` count of 0 — never `ok` with an empty removal list.
- Two ticks over an unchanged worktree set produce **byte-identical** summaries.
- `survey-worktrees.sh`, `reap-worktrees.sh` and the `reclaimable` predicate are **byte-identical
  to `origin/main`** — this ticket loosens nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, and the new rows fail when reverted: the
  four-worktree fixture asserts the removal set, the branch-ref survival, the skip-reason
  breakdown, the empty-`event` case and the summary's stability across two runs.
- `git diff origin/main -- plugins/workaholic/skills/branching/scripts/survey-worktrees.sh plugins/workaholic/skills/branching/scripts/reap-worktrees.sh` is empty.
- `sh plugins/workaholic/skills/moderate/scripts/step-worktree-sweep.sh --tick verify-local --root .`
  run once in this checkout returns `status: "ok"`, `removed` 0, and a summary naming 4 held with
  4 `unmerged` — the after-state matching step 1's before-state, since this repository has nothing
  reclaimable. A run that removed any of the four **fails this gate**.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The suite is green, the bundle rebuild is diff-clean, and `layout-doctor.sh` reports `conforming: true`.
- Every new script line is POSIX `sh`, not bash.
- The branch-ref-survival assertion is present. A change that removes a worktree without proving
  its branch survived does not pass, whatever else is green — that survival is the entire reason
  the act is safe.

## Considerations

- **Issue #1212's third finding is deliberately out of scope and must not be silently dropped.** `drive/scripts/retire-claim.sh` looks for the worktree at exactly `${repo_root}/.worktrees/${unit}` and reports `absent` — a success — when it is not there, so a worktree whose directory name is not the unit slug has no teardown owner at all. That is a defect in a different script with a different repair (resolve the worktree by its branch rather than its directory name), and it belongs in its own ticket. On this repository three of the four survivors are unit-named and one is `batch-20260903013910`, whose directory name *is* its unit id, so the shape is not reproduced here — the measurement behind it was taken elsewhere.
- **The four worktrees standing here have no owner under any current mechanism** (`.worktrees/`). Their branches are gone from `origin`, so the claim oracle has no row for them and `retire-claim.sh` has nothing to retire; they are `unmerged` by ancestry, so the reaper will not take them. After this change they are *reported* every hour and removed by nobody. Removing them is a person's decision under the operator's ruling, and this ticket leaves it there.
- **A byte reading in the diff key is the one way this step becomes the hourly status line two keyed roots were already retired for** (`plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` lines 99-115). Keep `du` output out of `summary` and out of `event`.
- **The step must run from the main checkout.** `reap-worktrees.sh:54` resolves `here` from `git rev-parse --show-toplevel` and skips the current worktree; a sweep invoked from inside a linked worktree would silently exclude that one. `/moderate` runs in the main checkout, and the step's header should say that this is the assumption rather than leave it implicit.
- **`.publish/` is excluded by the survey and must stay excluded** (`plugins/workaholic/skills/branching/scripts/survey-worktrees.sh` lines 38-41): it is disposable but belongs to the publish lifecycle, and a sweep reaching into it would race `open-publish-tree.sh` and `close-publish-tree.sh` for no gain.
