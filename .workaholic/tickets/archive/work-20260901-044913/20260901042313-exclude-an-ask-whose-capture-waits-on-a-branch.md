---
created_at: 2026-09-01T04:23:13+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260901042106-a-captured-ask-is-re-offered-while-its-proposal-waits-on-a-branch.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260901-044913
---

# Exclude an ask whose capture waits on a branch

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`list-inbound-issues.sh`'s `already_captured` exclusion greps the caller's checkout
(`.workaholic/feedbacks`, which is `main`), so an open issue whose record exists only on an
unmerged proposal branch is offered to `[Specificate]` again every hour. The script's own
header names that case as one it means to exclude — "captured, **its proposal PR open** or
its record-only merge pending" — so this is the implementation missing its stated intent,
not a design question.

Measured 2026-09-01: issue #812's record has sat on `work-20260901-022335` behind pull
request #813 (`Closes #812`) since 02:23, and #812 was re-offered at 03:28 and again at
04:21. Each re-take writes a duplicate record, opens a fresh publish-tree branch and a
fresh pull request, and every one of those conflicts on the generated feedbacks index
against every other open proposal
(`20260901201820`-class condition, recorded at
`20260831201820-every-open-proposal-conflicts-on-the-generated-feedbacks-index.md`).

The sibling reader already solved the same problem on the other half of the run:
`list-proposed-refs.sh` walks the artifacts on unmerged remote branches through the claim
protocol's own git-native oracle, for the reason its header records — a proposal's refs on
a branch nobody reads made the seam conclude the ask had not been proposed. The dedup set
learned to read unmerged branches; the discovery set did not.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/command-scripts.md` — the exclusion is a POSIX workflow script with a stated contract
- `workaholic:implementation` / `policies/test.md` — the widened exclusion is proved by hermetic fixtures

## Key Files

- `plugins/workaholic/skills/specificate/scripts/list-inbound-issues.sh` — the exclusion
  lives in the `while IFS=... read` loop's `grep -rqE "/issues/${number}"` over
  `$FEEDBACKS_DIR`; its `ALREADY-CAPTURED EXCLUSION` header paragraph is the contract this
  ticket makes true.
- `plugins/workaholic/skills/specificate/scripts/list-proposed-refs.sh` — the branch walk to
  reuse: the merge-base ancestry test, the shallow-clone over-read warning on stderr, and the
  two-dot tree diff that reads only what a branch adds. Its measured cost profile
  (dominated by the remote branch count, not the artifact count) applies unchanged.
- `plugins/workaholic/skills/specificate/SKILL.md` — *Clock-fired discovery* states the
  exclusion's scope in prose and must say what it now covers.
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 1 names the
  exclusion's contract ("the record **must carry the issue's URL**").
- `scripts/test-workflow-scripts.mjs` — where the hermetic proof belongs.
- `CLAUDE.md` — the `/specificate` row states the exclusion as "minus those a feedback
  record already names"; that clause acquires "on the base or on an unmerged branch".

## Implementation Steps

1. **Reproduce it.** In a throwaway repository, open an issue-shaped fixture: a record
   naming `/issues/<N>` committed on a branch that is not the base, and the same issue
   number returned by the inbox read. Confirm `list-inbound-issues.sh` returns it in
   `issues[]` rather than `excluded[]`. This is the failing assertion the change flips.
2. **Localize it.** Confirm the single cause is the `grep -rqE` over `$FEEDBACKS_DIR`
   reading the working tree only — that no other term in the script consults a ref — so the
   change has exactly one site.
3. **Extend the exclusion to unmerged remote branches.** Read the records a branch adds by
   the same means `list-proposed-refs.sh` uses; a hit on `/issues/<N>` in any of them
   excludes the issue exactly as a base hit does. Reuse rather than re-derive: two walkers
   over the same oracle is the failure `read-feedback-relation.sh`'s header names for the
   relation, one artifact over.
4. **Keep the exclusion's reported shape.** `excluded[]` rows stay
   `{"number", "reason"}`; decide whether an in-flight capture keeps `already_captured` or
   earns its own reason word, and state which in the header — a reader who cannot tell a
   landed capture from an in-flight one learns less than the current output gives them.
5. **Degrade toward over-reading, never under-reading, and say so.** A shallow clone or an
   unanswerable ancestry test must resolve toward *excluding* the issue, matching
   `list-proposed-refs.sh`'s stated rule ("ambiguity resolves toward including a ref"), and
   warn on stderr as it does. The script stays `ok: true` with exit 0 in every reported case;
   a branch walk that fails must not turn a readable inbox into `list_failed`.
6. **Prove it hermetically** in `scripts/test-workflow-scripts.mjs`: a record on the base
   excludes, a record on an unmerged branch excludes, a record on a merged-and-deleted
   branch does not resurrect an exclusion, and an issue no record names anywhere is still
   offered.
7. **Update the documents in the same change** — the SKILL's *Clock-fired discovery*, the
   workflow reference's step 1, and `CLAUDE.md`'s `/specificate` row.
8. Run the local verification set: `node scripts/build-plugins/build.mjs`,
   `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An open issue whose `/issues/<N>` a feedback record names on an unmerged remote branch is
  returned in `excluded[]`, not `issues[]`.
- An open issue no record names anywhere is still returned in `issues[]`.
- A branch walk that cannot complete leaves the script `ok: true`, exit 0, and errs toward
  excluding, with the reason on stderr.
- The SKILL, the workflow reference and `CLAUDE.md` state the widened scope.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the four fixtures from step 6.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the
  regenerated bundle stays self-contained.

**Gate** — what must pass before approval:

- The reproduce fixture from step 1 fails before the change and passes after it.
- No second walker over the unmerged-branch oracle is introduced.

## Considerations

- **The reporter's proposed mechanism is a hypothesis, not the design.** Reusing
  `list-proposed-refs.sh`'s branch walk is what step 3 proposes because that reader already
  pays this cost for the same reason; step 2 is what confirms there is no cheaper site. If
  localization finds the exclusion better served by the caller (the run reading the dedup set
  it already builds) rather than by the script, say so and take that route — the acceptance
  criteria are on the behaviour, not on the mechanism.
- **Cost.** `list-proposed-refs.sh` measured ~4s over 195 remote branches, dominated by the
  branch count. `list-inbound-issues.sh` runs once per `[Specificate]` tick, so a few seconds
  is affordable; a repository that has let merged branches accumulate pays more, which is the
  same pressure `delete_branch_on_merge` already answers.
- **What this does not fix.** A record-only proposal still cites no artifact, so
  `list-proposed-refs.sh` cannot see it and the *dedup* half stays blind to one. This ticket
  closes the *discovery* half only, and closing it is what stops the duplicate record being
  written in the first place.
- **Adjacent, deliberately out of scope.** The reason #813 has not merged is that a `clean`
  stranded publication is delivered by nothing
  (`20260901032409-a-clean-stranded-publication-is-delivered-by-nothing.md`), which is
  already proposed as its own work. Both conditions must be closed; neither closes the other.

## Final Report

Development completed as planned.

Reproduced first (step 1): a fixture whose only record naming `/issues/8` lived on an
unmerged remote branch returned that issue in `issues[]` before the change and in
`excluded[]` after it. Localization (step 2) confirmed the single site — the
`grep -rqE` over `$FEEDBACKS_DIR` was the only term in the script that consulted a
record at all, so the change has exactly one call site.

The walk was **extracted rather than copied** (step 3). `lib/unmerged-branches.sh` now
owns the base resolution, the shallow warning and the added-paths walk; both
`list-proposed-refs.sh` and `list-inbound-issues.sh` source it and differ only in the
pathspec they hand it and the paths they keep. The Considerations' alternative — the
caller reading the dedup set it already builds — was rejected on localization: the dedup
set is a set of *feedback filenames*, not of issue numbers, so the caller would have had
to re-derive the `/issues/<N>` match anyway, and the exclusion belongs where its
contract is written.

Step 4's open question is decided as **its own reason word**: `already_captured` keeps
its meaning (the record is on the base, the ask is settled) and `captured_on_branch` is
new (the record is on an unmerged branch, the ask waits on that pull request). Nothing
keys on the word — the only consumers are the run report and the drill runbook's blame
table — and the two send a reader to different places, which is the whole reason the
ticket asked. Both are stated in the script header.

### Discovered Insights

- **Insight**: `verify.mjs`'s closure detector matches `${SCRIPT_DIR}/…` anywhere in a
  file, comments included, so a sourced library that shows its own usage line in its
  header reports itself as an unresolved reference in every bundle that ships it.
  **Context**: `drive/scripts/lib/claims.sh` had already met this and answered it by
  writing the usage prose without the token ("from a drive script, with SCRIPT_DIR its
  own scripts/ dir"). That is a convention for sourced libraries here, not a quirk of
  one file — a new `lib/` script that documents itself the obvious way fails the build.

- **Insight**: `git rev-parse --is-shallow-repository` answers from the presence of
  `.git/shallow`, so a shallow clone's degradation path is reachable in a hermetic
  fixture by writing that file — no `clone --depth` and no second repository.
  **Context**: the over-read caveat is the one behaviour of this walk that only shows up
  in a routine's container, which is exactly where it is hardest to observe; being able
  to pin its stderr line cheaply is what keeps it from becoming an untested claim.

- **Insight**: the discovery half and the dedup half of `/specificate` answer the same
  question — *has this ask been proposed* — against two different artifact classes, and
  they learned to read unmerged branches a month apart.
  **Context**: `list-proposed-refs.sh` gained the branch walk on 2026-08-05 after a
  measured duplicate (issue #242 vs PR #241); `list-inbound-issues.sh` reproduced the
  identical failure on 2026-09-01 (issue #812 vs PR #813). A capability added to one
  reader of a shared oracle is worth checking against every other reader of it.
