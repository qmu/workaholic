---
created_at: 2026-09-01T04:15:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260901032409-a-clean-stranded-publication-is-delivered-by-nothing.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
claim: work-20260901-050906
---

# Deliver a publication GitHub still calls dirty

## Overview

Minted mid-run by the unit that gave the `clean` class an owner
(`deliver-a-stranded-publication-that-needs-nothing-but-a-merge`, 2026-09-01). The class now has
an act, and the act still delivered nothing.

Measured on the tick that landed it, against pull request #813
(`work-20260901-022335`), a publication the reader classified `clean`:

- `git merge-tree --write-tree origin/main origin/work-20260901-022335` against a freshly
  fetched `origin/main` (`8147a09`) exits 0 and writes a tree — no collision, locally.
- `GET repos/qmu/workaholic/pulls/813` answers `{"state":"open","draft":false,"mergeable":false,
  "mergeable_state":"dirty"}`.
- `settle-stranded-publication.sh 813` therefore reports `outcome: settled, class: clean` with
  `delivery: merge_refused: merge_not_allowed`.

The contract held exactly as written — one attempt, the refusal in the merge vocabulary, no loop
and no escalation — and the mission's Experience did not: *"A stranded publication that needs
nothing but a merge is merged by the loop, on the tick that reads it."* Five publications read
`clean` that morning (#813, #799, #688, #635, #625), the oldest opened 2026-08-26, and giving the
class an owner moved none of them.

The mission's own ticket recorded the disagreement as a known consideration and said the contract
must keep handling it that way. That ruling is not reopened here: the question this ticket asks is
**what the loop should do about a publication the remote declines**, which is a different one, and
nobody has looked at it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the act, and the
  place its `delivery` word is derived. Read first; it may need no change at all.
- `plugins/workaholic/skills/branching/scripts/merge-reason.sh` — the rung `merge_not_allowed`
  sits on. Whether GitHub's `mergeable_state` deserves its own word is part of the diagnosis.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` and
  `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the local derivation of the
  class, and the one place a remote reading could be composed beside it.
- `plugins/workaholic/skills/moderate/scripts/step-stranded-publications.sh` — where a
  publication only a person can move reaches that person today.

## Implementation Steps

1. **Diagnose before repairing.** For each open publication the reader calls `clean`, record
   side by side: the local `merge-tree` result, the API's `mergeable` / `mergeable_state`, and
   what a `PUT .../merge` answers. Establish which of the three explanations holds — GitHub's
   `mergeable` is computed lazily and a first read can return `null` or a stale value that a
   second read after recomputation corrects; or the branch genuinely conflicts against a base the
   local ref does not reflect; or a branch-protection rule (a required check, a required review)
   is refusing the merge and 405 is how it says so. **Do not skip to a fix**: the three have
   different repairs and only one of them is in this repository's code.
2. **Localize.** If it is lazy computation, name where a re-read belongs and what bounds it (one
   read, never a poll). If it is protection, name the setting and say so — the repair is then
   configuration, not code, and this ticket ends by saying which setting and why.
3. **Decide what the act reports.** `merge_refused: merge_not_allowed` is true and uninformative:
   it is the same word a genuine conflict earns. Decide whether the refusal deserves its own rung
   in `merge-reason.sh` keyed on the API's own message, on the `session_type_cannot_merge`
   precedent, and say what a reader does differently with it.
4. **Decide who is told.** Today a `clean` publication the remote declines reaches nobody:
   `/moderate` asks about `content` alone, deliberately, and `/implement` reports the refusal into
   a run report. If the answer is that a person must act, say which step asks and on what key; if
   the answer is that nothing should ask, say why and leave both steps alone.
5. **Never loop, never escalate, never override a gate.** Whatever the repair, the act keeps one
   merge attempt, its own refusal words, and the release-safety gate ahead of the merge.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The diagnosis is written down: which of the three explanations holds, with the readings that
  establish it, for at least the five publications named in the Overview.
- Either the loop delivers a publication it classifies `clean` and the remote accepts, or the
  reason it cannot is named in one place a reader can act on — never both silent.
- No new loop, poll, retry-until-success or gate override anywhere in the act.
- If the answer is configuration rather than code, the ticket ends with the setting named and no
  code changed.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` and, per
  publication it calls `clean`, `gh-rest.sh api repos/<slug>/pulls/<n>` — the two readings quoted
  side by side.
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-stranded-publication`

**Gate** — what must pass before approval:

- No refusal word is renamed or dropped, and `reference/claims.md` gains no row — a publication
  is still not a claim.
- The 2026-09-01 ruling stands: a local `clean` and a remote refusal disagreeing is reported in
  the merge vocabulary and never retried in a loop.

## Considerations

- **This may correctly end in no code change.** If the refusal is branch protection, the loop is
  behaving exactly as it should and the finding is a repository setting; `/workaholify` already
  owns exactly one GitHub setting and the precedent for naming a second is there.
- **A re-read of `mergeable` is not a poll.** GitHub documents the field as computed on demand,
  so at most one re-read after a first `null`-or-stale answer is a reading, not a retry loop. The
  distinction matters because this repository has repeatedly refused the loop.
- **The five publications are evidence, not the deliverable.** Merging them by hand would clear
  the symptom and lose the measurement; whoever drives this should read them before anything is
  merged.
