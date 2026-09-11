---
created_at: 2026-09-11T18:04:04+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260911180403-route-the-tick-s-durable-records-through-a-pull-request.md]
mission: keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main
merge_policy:
verification_handoff: 
---

# Gate every unattended write to the base ref and pin it

## Overview

Issue #1151, third repair, second half. The operator's rule, verbatim: *Add a base-ref write
gate and regression tests proving that Propose, Moderate, notification, and finish-log paths
cannot commit or push directly to `main`.* Once the previous ticket has moved the two live
writers onto the pull-request seam, nothing mechanical stops the next script, or an
agent-composed `git push`, from landing on `main` again. This ticket adds the **one reader**
that answers whether a write may reach the base ref, wires every commit and push site in the
tree to read it, and pins the four named paths with hermetic tests against a fake origin.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — the base is written only through the checked path

## Key Files

- `plugins/workaholic/skills/branching/scripts/lib/base-ref-gate.sh` - new, the one derivation: given the local branch, the remote ref and the calling role, answers `allowed` or `refused:<reason>`
- `plugins/workaholic/skills/commit/scripts/commit.sh` - the one writer of a commit; refuses a commit whose checkout branch is the base under an unattended role
- `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh` - the direct seam; reads the gate before its push, if it survives the previous ticket
- `plugins/workaholic/skills/ship/scripts/lib/push-outcome.sh` - the shared push reporter; the natural place to read the gate for every push
- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` - pushes a claim branch tip; must stay allowed
- `plugins/workaholic/skills/drive/scripts/claim-arbitrate.sh` - pushes `refs/claims/artifact/*`; must stay allowed
- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` - commits in a claim worktree; must stay allowed
- `plugins/workaholic/skills/ship/scripts/commit-release-note.sh` - a post-merge seam; classify and state
- `plugins/workaholic/skills/story/scripts/ticket-commits.sh` - reads commits; confirm it writes none
- `plugins/workaholic/skills/feedback/scripts/migrate-concerns.sh` - a living migration that stages; confirm it commits none
- `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` - records a merge outcome on a claim branch; must stay allowed
- `plugins/workaholic/skills/drive/scripts/clear-unposted-line.sh` - commits on a claim branch; must stay allowed
- `plugins/workaholic/hooks/guard-git-commit.sh` - the commit-subject gate; gains nothing, cited as the pattern
- `plugins/workaholic/hooks/guard-git-push.sh` - new PreToolUse Bash guard denying an agent-composed `git push … <base>` or `HEAD:<base>`, registered in `hooks/hooks.json`
- `plugins/workaholic/rules/shell.md` - the rule's prose home
- `scripts/test-workflow-scripts.mjs` - the tree walk over every `git commit` / `git push` site and the four path tests
- `scripts/e2e/loop-drill.sh` - a `verify-base-ref-gate` drill

## Related History

The claim protocol already keeps a runner off the base by construction (a claim is a branch);
what has never existed is a reader that says so for the writers that carry no claim.

- [20260902042039-cover-every-writer-of-the-tick-log-not-the-moderation-tick-alone.md](.workaholic/tickets/archive/work-20260906-025904/20260902042039-cover-every-writer-of-the-tick-log-not-the-moderation-tick-alone.md) - the writer set for the moderation log is derived from the tree and pinned; this ticket applies the same derivation to the base ref

## Implementation Steps

1. **Enumerate the writers** (diagnosis first). Walk `plugins/workaholic/` for every `git commit`
   and `git push` in command position and classify each: claim-branch write, publish-tree
   pull-request write, merge of a reviewed branch, or direct base write. Record the table in the
   story; the previous ticket's two writers must read as pull-request writes by then.
2. **The one reader.** Write `branching/scripts/lib/base-ref-gate.sh`: inputs are the checkout's
   branch, the remote ref a push names, the base (`main` or `WORKAHOLIC_PUBLISH_BASE`) and the
   role (`WORKAHOLIC_ROLE`: `propose` / `moderate` / `notify` / `finish-log` / `implement` /
   `ship`, absent meaning attended). A commit on a checkout of the base, or a push whose remote
   ref is the base, is `refused:base_ref_write` for every unattended role; a merge seam that
   carries a reviewed pull request (`land-unit.sh`'s fast-forward, the REST merge) is
   `allowed:reviewed_merge`; a claim branch, a `publish-main` to `work-*` push and
   `refs/claims/*` are `allowed`. Absent role and attended is `allowed:attended`, so a developer's
   own checkout is byte-identical.
3. **Wire the sites.** `commit.sh` reads the gate before `git commit`; `push-outcome.sh` and
   every push site that does not use it read the gate before `git push`, refusing with nothing
   pushed and the reason on stdout. The four roles set `WORKAHOLIC_ROLE` at their entry:
   `commands/propose.md`, `commands/moderate.md`, the notification seam (`perform.sh`,
   `notify-slack.sh`), and the finish-log seam (`log-append.sh`, `coordinator.sh` `finish`).
4. **The agent-level guard.** `hooks/guard-git-push.sh` denies a Bash `git push` whose refspec
   names the base, with the reason; register it in `hooks/hooks.json`. State in `rules/shell.md`
   that a base write is made only by a merge of a pull request, and cite the reader.
5. **Regression tests, one per named path.** In `test-workflow-scripts.mjs`, a hermetic repository
   with a bare fake origin and a `main` branch; for each of Propose (`open-proposal.sh`,
   `file-inbound-ask.sh` — prove they run no git at all), Moderate (`persist-log.sh --record`,
   `run.sh`), notification (`perform.sh` with a stub route, the outbox writer) and finish-log
   (`log-append.sh`, `coordinator.sh finish`): run the path under its role and assert the fake
   origin's `main` is byte-identical before and after and the local checkout has no new commit
   on `main`. Add a tree-walk row that fails when a `git push` site reads no gate, naming what it
   cannot see (an agent's composed call).
6. **Drill.** `loop-drill.sh verify-base-ref-gate`: the same four paths against a fake origin,
   offline, classified hermetic.
7. Update `CLAUDE.md` (*Enforcement gates*), `rules/shell.md` and `hooks/hooks.json` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `base-ref-gate.sh` answers `refused:base_ref_write` for a commit on the base checkout or a push naming the base under any unattended role, and `allowed` for claim branches, publish-tree pull-request pushes, `refs/claims/*` and attended use
- each of the four paths, run under its role against a fake origin, leaves `main` byte-identical on the origin and locally
- a `git push` site in the tree that reads no gate fails the suite by name

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green with the gate rows and the four path tests
- `sh scripts/e2e/loop-drill.sh verify-base-ref-gate` green offline
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no diff in `outputs/`

**Gate** — what must pass before approval:

- the suite is green, `hooks/posix-lint.sh` conforming, and the story carries step 1's writer table

## Considerations

- The gate must not refuse the merge seams: the REST merge and `land-unit.sh`'s fast-forward of a reviewed branch are how the base is written by design (`plugins/workaholic/skills/drive/scripts/land-unit.sh` lines 45-60)
- A `PreToolUse` deny turns a prompt into a mid-run refusal; the hook here denies only a refspec that names the base, which no unattended command body composes, so it reaches no ordinary run (`plugins/workaholic/hooks/guard-git-commit.sh` is the pattern)
- Branch protection on GitHub is the operator's act and is reported by `workaholify/scripts/check-repo-settings.sh`; this ticket adds an advisory finding there and never changes a repository setting
- Reporter-proposed mechanism recorded as a hypothesis: *a base-ref write gate* — step 1's table decides whether one reader at the push seam is sufficient or whether `commit.sh` must refuse too
