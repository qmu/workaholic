---
created_at: 2026-08-28T10:22:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: finish-a-proved-retirement-where-the-write-is-permitted
merge_policy:
verification_handoff: 
---

# Add the workflow that takes the refused branch delete

## Overview

PROPOSED. The retirement's Act 2 is refused in the container the loop runs in. Measured
2026-08-27 in a routine-fired container, both transports agree: `git push origin --delete`
answers `RPC failed; HTTP 403`, and `DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}`
answers *"Write access to this GitHub API path is not permitted through this proxy."* It is
a **session-type** refusal — not a protection rule (422) and not a missing scope — since an
ordinary `git push` of the same branch succeeds in the same container.

This repository has already answered this exact shape once: the release-note write was
refused the same way and moved to `.github/workflows/release-note-draft.yml`, which holds
`contents: write` and defines its own checkout. This ticket adds the sibling workflow that
takes the delete. It is **not a second transport in the container** — the recorded finding
that no such transport exists stays correct; it is a different executor.

Trigger: follow the precedent. `release-note-draft.yml` runs on `push: branches: [main]`
plus `workflow_dispatch`; the loop merges onto `main` continuously, so that gives frequent
runs with no scheduler to reason about, and `workflow_dispatch` keeps the act runnable on
demand. A `schedule:` may be added beside them but is not required. The container cannot
dispatch this workflow itself (writes are refused through the proxy), which is why the
trigger must not depend on one.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.github/workflows/claim-retirement.yml` — new; the workflow that takes the act
- `.github/workflows/release-note-draft.yml` — the precedent to follow: `permissions:`,
  the self-defined checkout, and the "why CI and not the tick" header
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — read in CI for the candidates
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport; the
  delete goes through it in CI too, where `GITHUB_TOKEN` makes it permitted

## Implementation Steps

1. Read `release-note-draft.yml` end to end — its permissions block, its checkout, its
   concurrency group and the reasoning in its header comment.
2. Add `.github/workflows/claim-retirement.yml` with `permissions: contents: write` and
   nothing wider, `on: push: branches: [main]` + `workflow_dispatch`, and a
   `concurrency` group so two runs never race the same branch.
3. Define the checkout rather than inheriting one: `fetch-depth: 0`, and fetch the remote
   heads the claim scan reads. A shallow checkout makes a superseded claim
   indistinguishable from a live one, which the scan already refuses to guess through.
4. Call the candidate reader from the previous ticket and, per candidate, the bounded
   delete from the next one. The workflow itself owns no proof logic.
5. Write the header comment in the shape this repository uses: what is refused where, why
   CI holds the capability, and why the checkout is defined rather than inherited.
6. Ensure the job is a no-op with an empty candidate set — no failure, no annotation noise.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `.github/workflows/claim-retirement.yml` exists, declares `permissions: contents: write`
  and no wider permission, and defines its own full-history checkout
- It is triggered without any act by the loop's container
- An empty candidate set makes the job a clean no-op
- The workflow contains no proof logic of its own — it calls the reader and the bounded
  delete and nothing else

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- YAML parse of the new workflow; `actionlint` if available
- One `workflow_dispatch` run on a branch with no superseded claim, showing a clean no-op

**Gate** — what must pass before approval:

- The workflow file parses, the permission block is exactly `contents: write`, and the
  hermetic suite passes

## Considerations

- The 2026-08-27 finding *"no second transport can take the act"* is **not** reversed by
  this: it is a statement about the container, and remains accurate there. Say so in the
  header rather than letting a later reader think it was wrong.
- `permissions: contents: write` is the whole grant; do not add `pull-requests: write` —
  the pull-request close is Act 1 and already succeeds in the container.
- A `schedule:` trigger is optional; if added, keep the minute non-zero, as every other
  cadence in this repository does.
