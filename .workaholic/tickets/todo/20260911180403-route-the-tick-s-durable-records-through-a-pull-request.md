---
created_at: 2026-09-11T18:04:03+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-native-loop-alive-preserve-slack-input-and-stop-direct-commits-to-main
merge_policy:
verification_handoff: 
---

# Route the tick's durable records through a pull request

## Overview

Issue #1151, third repair, first half. The operator measured 335 `Log ... tick` and nine
`Record the tick's feedback findings` first-parent commits on `main`, and a deferred-concern
commit with no pull request. Re-measured on `origin/main` at `97eb62fc1` over the last 600
first-parent commits: the `Log the propose tick` commits (217) date 2026-08-27 to 2026-08-31
and stopped when the log came off git; the two writers still landing on `main` directly are
`moderate/scripts/persist-log.sh --record` (`Record the tick's feedback findings`, 17 commits
2026-09-06 to 2026-09-11, the newest today) and `ship/scripts/extract-deferred-concerns.sh`
(`Add deferred concerns from PR #…`, two on 2026-09-08). Both go through
`branching/scripts/publish-tree-commit.sh`, the direct post-merge seam.

The operator's rule, verbatim: *Runtime cadence logs and unattended maintenance records must not
update the base branch directly. Keep ephemeral loop state outside git, and route durable
repository artifacts through a claim or publish branch and pull request with the normal
checks.* This ticket moves the two live writers onto `publish-tree-pr.sh`; the gate that keeps
them there is the next ticket.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — every change to the base reaches it through the checked path

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` - `--record` carries records to the base through `publish-tree-commit.sh` (lines 200-215)
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` - publishes concern records through `publish-tree-commit.sh` (lines 105-125) and, inside the tree, a bare `git commit` (line 368)
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` - the pull-request seam every other writer uses
- `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh` - the direct seam; its remaining callers after this change are enumerated
- `plugins/workaholic/skills/branching/reference/publish-tree.md` - the publish-tree contract
- `plugins/workaholic/skills/drive/scripts/land-unit.sh` - names the same push idiom for a reviewed branch; not a caller
- `plugins/workaholic/skills/moderate/SKILL.md` - the tick's persistence contract
- `plugins/workaholic/skills/ship/SKILL.md` - the deferred-concern contract
- `scripts/test-workflow-scripts.mjs` - the `persist-log.sh` rows (around lines 22378-22460) and the direct-commit vocabulary pin (around line 40400)
- `scripts/e2e/loop-drill.sh` - `verify-log-off-base`

## Related History

The tick log itself was taken off `main` on 2026-09-01 and off git on 2026-09-03; the records
took *the other road* to `main`, and that road is the one the operator measured.

- [20260902042038-refuse-the-base-as-a-destination-in-the-tick-log-writer.md](.workaholic/tickets/archive/work-20260906-025904/20260902042038-refuse-the-base-as-a-destination-in-the-tick-log-writer.md) - `log_destination_is_base`: the record seam refuses a log path; this ticket changes where the seam lands, not what it accepts

## Implementation Steps

1. **Reproduce and localize** (diagnosis first). Run `git log --first-parent --format='%ad %s' --date=short origin/main` over the window and count the subjects; confirm each writer by reading `persist-log.sh` and `extract-deferred-concerns.sh` and the seam they call. Confirm the log commits are historical (2026-08-27 to 08-31) and name that in the story so the 335 is not chased as a live writer.
2. **Records through a pull request.** In `persist-log.sh`, replace the `publish-tree-commit.sh` call with `publish-tree-pr.sh` under `WORKAHOLIC_AUTO_MERGE=1` and a `[Record]`-prefixed title, keeping every per-record state (`carried` / `already_on_base` / `missing` / `unreadable` / `unlanded`) and the `log_destination_is_base` refusal byte-identical. `carried` means the pull request opened and, when the seam merged it, the record is on the base; a pull request left open is `unlanded` with the seam's `merge_reason`.
3. **Deferred concerns through a pull request.** In `extract-deferred-concerns.sh`, the outer run publishes through `publish-tree-pr.sh` the same way; the inner `NO_COMMIT` run is unchanged. The in-tree bare `git commit` at line 368 goes through `commit.sh`.
4. **Ephemeral state stays out of git.** Assert in a test that `.workaholic/moderations/`, the runtime state directory `state.sh` writes to, and the transport outbox are git-ignored on a fresh checkout, and name any that is not.
5. **Narrow the direct seam.** Enumerate `publish-tree-commit.sh`'s remaining callers; if none remain, retire the script and its reference section, otherwise state in its header which caller may still use it and why. `publish-tree.md` and `CLAUDE.md` (*The publish tree*, the moderation paragraph's `persist-log.sh` description) say the records now travel behind a pull request.
6. **Tests.** Update the `persist-log.sh` rows in `test-workflow-scripts.mjs` to expect a pull-request publication and to fail on a `publish-tree-commit.sh` call from either writer; extend `verify-log-off-base` in `loop-drill.sh` so the records' road is the pull-request seam.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `persist-log.sh --record` and `extract-deferred-concerns.sh` reach the base only through `publish-tree-pr.sh`; neither calls `publish-tree-commit.sh` or a bare `git commit`
- every per-record state word and the `log_destination_is_base` refusal are byte-identical before and after
- the ephemeral state paths are git-ignored, proved by a test on a fresh checkout

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green with the updated `persist-log.sh` rows and the new caller pin
- `sh scripts/e2e/loop-drill.sh verify-log-off-base` green
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no diff in `outputs/`

**Gate** — what must pass before approval:

- the suite is green, `hooks/posix-lint.sh` conforming, and the story quotes the measured commit counts per subject and date from step 1

## Considerations

- A record pull request that auto-merges is still a squash merge through `merge-method.sh` and `merge-commit-body.sh`; do not spell either at the new call site (`plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh`)
- Two concurrent ticks writing different records must both land, as they do today; the pull-request seam's non-fast-forward retry covers it once, and a second refusal is `unlanded`, reported by name (`plugins/workaholic/skills/moderate/scripts/persist-log.sh` lines 216-222)
- `land-unit.sh` names the `push origin <branch>:<base>` idiom for a **reviewed** branch; it is a merge of reviewed work, not an unattended write, and is out of this ticket's scope (`plugins/workaholic/skills/drive/scripts/land-unit.sh` lines 45-60)
