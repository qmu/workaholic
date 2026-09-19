---
created_at: 2026-09-19T09:47:01+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-a-feedback-item-only-on-evidence-from-the-surface-the-person-reviews
merge_policy:
verification_handoff:
---

# Stop the ingest pull request closing the source feedback issue

## Overview

Operator's ask: **issue #1104** — *before a feedback record is considered satisfied or **its
source issue is closed***. On the measured recurrence the issue was closed while the requested
control was absent from the screen the person reviews.

**The cause is mechanical and was established in this tree, not inferred from the report.**
`branching/scripts/publish-tree-pr.sh:106` and `:193` thread a native `Closes #<N>` line into the
pull-request body from `WORKAHOLIC_CLOSES_ISSUE`, and `specificate/reference/workflow.md` step 10
sets that variable to the **triggering issue's** number on every ingest. So merging the
`[Proposal]` pull request — the act that merely *queues* the work — auto-closes the person's
issue. At that moment there is no implementation, no branch, no verification and no surface to
compare; the reconciliation reader `work/scripts/feedback-outcome.sh` has not run and cannot have
run.

**This ticket removes the closing keyword from the ingest seam and nothing else.** Where the
closing then happens is the next ticket's subject; the two are separate because removing a wrong
close and choosing the right one are independently reviewable, and shipping only the first leaves
issues open, which is the safe direction.

**The keyword is load-bearing elsewhere and must not be broken.** `WORKAHOLIC_CLOSES_ISSUE` is the
documented mechanism by which an ask stops being re-offered — but the re-offer is prevented by
`list-inbound-issues.sh`'s own exclusions (`already_planned`, `captured_on_branch`), which key on
the **record naming the issue URL**, not on the issue being closed. Establish that before
changing anything: if the exclusion in fact depends on closure, this ticket's whole approach
changes, and the reading must be recorded either way.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`
- `workaholic:implementation` / `policies/observability.md` — an issue left open must say what it
  is waiting for; an open issue nobody can explain is the defect this repairs badly
- `workaholic:implementation` / `policies/test.md` — the exclusion behaviour is pinned
  hermetically, because it is the property this change must not break

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` (lines 32-39, 106, 183, 193) —
  the writer of the `Closes #<N>` line and its documented reason.
- `plugins/workaholic/skills/specificate/reference/workflow.md` (steps 1 and 10) — where the
  triggering issue number is captured and where it is threaded into the body.
- `plugins/workaholic/skills/specificate/SKILL.md` (*Clock-fired discovery*) — the exclusion rules
  and the sentence *for the exclusion to hold, the record each run writes must carry the issue's
  URL*. This is the reading step 1 below must confirm.
- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — the inbox reader that
  performs the exclusion; its `state=open` filter and its `already_planned` /
  `captured_on_branch` terms decide whether closure matters at all.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite.

## Implementation Steps

1. **Reproduce the two readings first** (`workaholic:discover`, Diagnosis-First Rule). (a) Confirm
   from `publish-tree-pr.sh` that the ingest pull request carries `Closes #<N>`. (b) Confirm from
   `list-inbound-issues.sh` whether an ask that stays **open** but whose record names its URL is
   excluded as `already_planned`. Record both; (b) decides whether this change is safe as written.
2. **If (b) holds**, stop setting `WORKAHOLIC_CLOSES_ISSUE` at the ingest seam: the pull-request
   body references the issue (a plain `#<N>` reference, not a closing keyword) so the trail is
   intact and GitHub closes nothing.
3. **If (b) does not hold**, do not proceed with a workaround. Record what the exclusion actually
   depends on in the story and in the mission's changelog, and leave the keyword in place — a
   change that stops closing issues while the inbox re-offers them every tick would turn one
   defect into an hourly one.
4. **Leave `publish-tree-pr.sh` able to close.** The variable and its mechanism stay exactly as
   they are; only the ingest **caller** stops setting it. Another seam will set it in the next
   ticket, and a writer removed here would have to be rebuilt there.
5. **Say what an open issue is waiting for.** The ingest pull-request body states that the issue
   stays open until the work is reconciled, so a person reading it is not left wondering why the
   proposal merged and the issue did not close.
6. **Update the prose in the same change**: `specificate/reference/workflow.md` step 10 and
   `SKILL.md`'s description of the closing behaviour, both of which currently state that merging
   the proposal auto-closes the ask.
7. **Hermetic rows**: an ingest publication carries no closing keyword; the issue it came from is
   still excluded from the next inbox read; and an issue whose record does **not** name its URL is
   still offered, unchanged.
8. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ingest `[Proposal]` pull request body carries **no** `Closes #<N>` line and still references
  the issue.
- The originating issue remains **open** after that pull request merges.
- The same issue is **not** re-offered by `list-inbound-issues.sh` on the next read; the exclusion
  reason is the same word it is today.
- `publish-tree-pr.sh` is unchanged in behaviour: given `WORKAHOLIC_CLOSES_ISSUE`, it still writes
  the closing line.
- The prose surfaces that describe the old behaviour are updated in the same change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- A fixture ingest run produces a body with no closing keyword; a direct call to
  `publish-tree-pr.sh` with the variable set still produces one.
- The inbox fixture proves the exclusion is unchanged with the issue open.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- Step 1(b)'s reading is recorded in the story, whichever way it came out. A change that assumes
  the exclusion is URL-keyed without proving it does not pass.
- The suite is green and the bundle rebuild is diff-clean.

## Considerations

- **Shipping this ticket alone leaves feedback issues open indefinitely.** That is the deliberate
  order: an open issue is visible and arguable, a wrongly closed one is invisible. The mission's
  next ticket closes them on evidence.
- **A person may still close an issue by hand**, and nothing here should interfere with that.
- **`/fb`'s cross-repository path and any other caller of `WORKAHOLIC_CLOSES_ISSUE` are out of
  scope**; the ticket touches the ingest caller only, and the story should name any other caller
  it found so the next reader knows the set.

## Final Report

Development completed as planned. Step 1(b)'s reading came out in the direction the ticket
needed, so step 2 was taken and step 3 was not.

**Reading (a): the ingest pull request did carry `Closes #<N>`.** `publish-tree-pr.sh:106`
(the transaction path) and `:193` (the ordinary path) both write it from
`WORKAHOLIC_CLOSES_ISSUE`, and `specificate/reference/workflow.md` step 10 set that variable
to the **triggering** issue's number on every ingest.

**Reading (b): the exclusion is keyed on the record naming the issue's URL, not on closure —
so this change is safe as written.** `list-inbound-issues.sh` asks GitHub for
`state=open&assignee=<login>` and then, for each row, `grep`s the feedback area for
`/issues/<number>`: a match promotes to `already_planned` when `list-proposed-refs.sh` shows a
planned artifact relating to that record, and to `captured_on_branch` when the record lives
only on an unmerged proposal branch. **Closure appears in neither term.** What it was doing was
suppressing the re-offer one layer *earlier* — a closed issue never reaches the listing at all —
so leaving the issue open simply moves the suppression onto the exclusion that was always there.
That is exactly why step 3's `Source:` line is load-bearing: a record omitting the URL leaves the
ask re-proposed every tick, which is the failure mode step 3 already warns about.

**What changed.** `publish-tree-pr.sh` gained a second, validated env var,
`WORKAHOLIC_REFERENCES_ISSUE`, writing a plain `Refs #<N>` plus one line stating that the issue
stays open until the work is reconciled; the ingest caller sets that one and no longer sets
`WORKAHOLIC_CLOSES_ISSUE`. A new variable rather than a prose instruction, because the
acceptance criterion is *the body carries no closing keyword and still references the issue* and
a prose instruction is checkable by nothing. The two are mutually exclusive and the **closing
keyword wins** when both are set — a body saying `Closes #<N>` and *this stays open* at once
contradicts itself, and the caller that set the closing keyword asked for a close.

**The writer is unchanged in behaviour.** Given `WORKAHOLIC_CLOSES_ISSUE` it still writes the
closing line, on both the ordinary and the transaction path, and the existing hermetic rows for
that behaviour pass untouched. Only the ingest **caller** stopped setting it.

**The caller set, walked.** A tree-wide grep for `WORKAHOLIC_CLOSES_ISSUE` across `plugins/`,
`scripts/`, `docs/` and `.github/` returns the writer itself, `specificate/SKILL.md`,
`specificate/reference/workflow.md` and the suite. **`/specificate` step 10 was the only caller
that assigned it**; `/fb`'s cross-repository path never used it, and there is no other. The next
reader therefore has the whole set.

**Shipping this alone leaves feedback issues open indefinitely, deliberately.** The mission's
next ticket supplies the one act that may close one, on a reconciliation reading
`implemented_and_verified`. An open issue is visible and arguable; a wrongly closed one is
invisible.

### Discovered Insights

- **Insight**: `publish-tree-pr.sh` composes the pull-request body in **two** places — a
  transaction path (`WORKAHOLIC_PUBLICATION_ID` set, body built as an escaped string for
  `publication.sh`) and the ordinary path (a `printf` heredoc into a body file) — and a change to
  the body must be made in both or it silently applies to only some callers.
  **Context**: the two paths diverged for a real reason (the transaction seam hands JSON to
  another script) and neither is dead, so a single body composer would be a larger change than
  this ticket. Worth knowing before editing that script again.

- **Insight**: a GitHub closing keyword in a publication body is a *delivery* claim made by a
  *queueing* act, and nothing downstream could contradict it.
  **Context**: the reconciliation reader that decides whether work landed cannot have run when
  the proposal merges — there is no branch yet. Any seam that closes an ask has to sit after
  implementation, which is what makes the keyword the wrong mechanism here rather than merely
  mistimed.
