---
created_at: 2026-09-01T11:25:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Read a claim branch's pull-request state

## Overview

PROPOSED. The retirement path has exactly one candidate reading — `list-retirable-claims.sh`
over `superseded_only` rows — and the ask names two more that the pull request itself can
prove: **its pull request merged** (`merged_at` non-null) and **its pull request was closed
unmerged** (`state: closed`, `merged_at` null). Nothing in the loop answers that question per
branch today. `claim-merged.sh` is the closest thing and it answers a different one (did this
mission's claim land) with a three-valued lookup keyed on the unit, not on the branch.

This ticket adds the reader and nothing else: no candidate widens, no act fires, no verdict
moves. The two tickets after it consume this answer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded read is named, never rendered as a verdict

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — the protocol's one existing network
  read of a pull request; the precedent for the transport, the three-valued answer and the
  `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0` opt-out. Read its header before writing a second reader.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the only sanctioned GitHub transport
  (`rules/shell.md`); `gh pr view` is forbidden.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — where the branch→row projection lives,
  so the new reader takes a branch name and needs no second walk of the refs.
- `docs/drive-loop-runbook.md` — where the reading's failure modes are recorded.

## Implementation Steps

1. Add `drive/scripts/branch-pull-request-state.sh <branch>`: one repository-scoped REST read
   through `gh-rest.sh` (`GET /repos/{owner}/{repo}/pulls?head=…&state=all`, filtered locally —
   a bound session refuses `search/*`), answering
   `{"ok", "branch", "number", "state": "merged"|"closed_unmerged"|"open"|"none", "reason"}`.
2. Make it **four-valued and honest**: `none` means the branch never had a pull request (the
   ask's autofix branch), and an unreadable transport answers `ok: false` with its reason and
   **no `state` key at all** — never `none`, which a caller would read as *provably no pull
   request*. Exit 0 in every case.
3. Bound it exactly as `claim-merged.sh` is bounded: skipped by name when it cannot succeed
   (`offline`, and the same disable variable), at most one read per branch, no ref written, no
   worktree, no cursor and no field on any artifact.
4. Take the newest pull request when a branch has several, and say so in the header — a branch
   reused across two pull requests is rare and picking silently is how a reader drifts.
5. Record in `docs/drive-loop-runbook.md` why this is a **second** question from
   `claim-merged.sh` rather than a widening of it: that one is keyed on a unit and answers
   whether the unit's content landed; this is keyed on a branch and answers what became of its
   pull request.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The script answers all four states plus `ok: false` with a named reason, and never emits
  `state` on a failed read.
- It performs at most one network read per invocation and writes nothing anywhere.
- No existing claim verdict, exclusion word or candidate set changes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — add a hermetic row driving each state through a
  stubbed transport, including the unreadable case.
- `git status --porcelain` after a run is empty.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- No `gh pr`/`gh issue`/`gh repo` call is introduced (the suite fails on one).

## Considerations

- The reader is deliberately not a verdict. Naming a branch `retirable` here would put the
  proof and the act in one script, which is the shape `retire-claim.sh`'s own header refuses.
- `state: none` is the autofix branch in the ask's table; it earns no candidate and no question
  in this mission — recorded here so a later reader does not treat the silence as an oversight.

## Final Report

Development completed as planned.

`drive/scripts/branch-pull-request-state.sh <branch>` is added and consumed by nothing yet:
no candidate widens, no act fires, no claim verdict moves. It makes one repository-scoped
REST read through `gh-rest.sh` (`GET /repos/{slug}/pulls?state=all&head={owner}:{branch}`,
filtered locally because a bound session refuses `search/*`) and answers four states —
`merged`, `closed_unmerged`, `open`, `none` — with `none` reserved for a lookup that
**succeeded** and found nothing.

A read it could not make emits `{"ok": false, …, "reason": "<named>"}` and **no `state` key at
all**, which the suite asserts on the raw output rather than on the parsed object. Bounds are
`claim-merged.sh`'s own: `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0` is `disabled`, a caller whose own
fetch failed (`CLAIMS_FETCH_OK` set and not `true`) is `offline`, one read per invocation, no
ref, worktree, cursor or field, exit 0 in every case. Ordering when a head carries several
pull requests is written into the header: a merged one wins outright, then the newest
unmerged.

`docs/drive-loop-runbook.md` gains *Two readers ask GitHub about a pull request, and they ask
different questions* — a two-row table and the reason they are not one reader.

### Discovered Insights

- **Insight**: `CLAIMS_FETCH_OK` cannot be read as a plain boolean by a script that also runs
  standalone. Unset means *no caller has an opinion*; set-and-not-`true` means *a caller
  proved there is no network*. Collapsing the two would make every direct invocation answer
  `offline`.
  **Context**: `lib/claims.sh` can treat unset as false because nothing calls it from outside
  a scan. A reader that is both a library input and a command has to tell the two apart, and
  `[ -n "${VAR+x}" ]` is the test that does it.
- **Insight**: the honest way to say *I could not read* in a JSON line is to omit the answer
  key, not to add a sentinel value to it.
  **Context**: `claim-merged.sh` carries `unanswerable` inside its `state` enum, which works
  because every consumer of that field is inside the claim chain. Here the consumer is a
  branch delete, so an absent key makes a careless `state == "none"` test fail closed instead
  of deleting on the strength of a rate limit.
