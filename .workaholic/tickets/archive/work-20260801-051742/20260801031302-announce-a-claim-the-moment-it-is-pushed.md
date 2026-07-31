---
created_at: 2026-08-01T03:13:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: auto
claim: work-20260801-051742
---

# Taking a unit is invisible to people until the whole unit is driven

## Overview

`claim.sh` publishes a `Claim <unit-id>` commit on a pushed `work-*` branch
**before any implementation starts**, so "this unit is being worked" is a fact in
git within seconds. But nothing tells a person. The first human-visible artifact
is the pull request, which `/drive` opens at step 5 — *after* every ticket in the
unit has been driven. Slack hears nothing until step 6, and only for a `review`
unit.

Measured 2026-08-01 while designing an hourly unattended runner: between the
claim and the PR there is a window — tens of minutes for a mission unit — in
which GitHub shows no PR, Slack shows no message, and the only way to know work
started is to run `list-claims.sh` or read remote branches. For an attended run
that is merely quiet. For an unattended fleet it is the difference between "the
routine is working" and "the routine is dead", and an operator cannot tell which.

Claiming is exactly the moment worth announcing: it is the first published,
irreversible-in-practice commitment the run makes, and it already has a
canonical, deduplicated identity (the unit id) to announce.

## Policies

- `workaholic:implementation` / `policies/observability.md` — the outcome and the progress of a run must be graspable from outside without a debugger; a silent 40-minute window is the opposite.
- `workaholic:development` / `policies/overnight-ai.md` — the developer's contact with an unattended run is its reporting surface; a run that reports only at the end cannot be supervised while it matters.
- `workaholic:development` / `policies/parallel-long-running-agents.md` — with several runners in flight, who took what and when is the operator's primary question.
- `workaholic:implementation` / `policies/command-scripts.md` — the notifier already exists as a script and must be reached as one, never as inline shell in command markdown.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and POSIX `#!/bin/sh -eu` house style.

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` - the seam; the push at its end is the moment to announce
- `plugins/workaholic/skills/propose/scripts/notify-slack.sh` - the existing bot notifier, already graceful without a token (`{"notified": false, "reason": "no_token"}`)
- `plugins/workaholic/skills/drive/SKILL.md` - *Unified Run* §3 (Claim) and §6 (Route), where the announcement contract is stated
- `docs/drive-loop-runbook.md` - §2 wires `SLACK_BOT_TOKEN` / `WORKAHOLIC_SLACK_CHANNEL`; §5 *Observability* lists what an operator can watch
- `scripts/test-workflow-scripts.mjs` - hermetic suite; must prove the notifier is never load-bearing

## Implementation Steps

1. Announce at the **claim** seam, not from the command prose: after `claim.sh`'s push succeeds and before it prints its JSON, post one line naming the unit id, the branch, and its member count.
2. Reach the notifier as a script (`propose/scripts/notify-slack.sh`), the same way `/drive`'s route step does. Do not inline a curl call and do not duplicate the notifier.
3. Keep it **never load-bearing**: a notifier failure, a missing token, or an unreachable Slack must not fail the claim, must not unwind the worktree, and must not change `claim.sh`'s exit status or JSON contract. A claim that succeeded and an announcement that did not are two different facts, and only the first one gates the run.
4. Report the announcement's outcome in the claim JSON (e.g. `announced: true|false` with a reason) so a run report can state plainly that the claim landed but the notice did not.
5. Keep the message to one line. The house Slack format for this fleet is a single status line plus an optional one-line attention block; a claim notice has no PR to link yet, so it names the unit and the branch and nothing else.
6. Update `drive/SKILL.md` §3 to state that claiming announces, and `docs/drive-loop-runbook.md` §5 to list the claim notice alongside PRs and terminal tokens as what an operator watches. Same commit.
7. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) — `claim.sh` ships into the workflows bundle.

## Quality Gate

**Acceptance criteria**

- With no `SLACK_BOT_TOKEN` set, `claim.sh` succeeds unchanged: same exit status, same `claimed: true` JSON shape plus the new `announced` field reading false with a reason, worktree and branch intact.
- With the notifier stubbed to fail (non-zero exit), `claim.sh` still succeeds and still reports `announced: false` — no unwind, no `abort_claim`.
- The announcement fires **after** the push succeeds and never for a refused claim: an `already_claimed`, `branch_collision`, or `push_failed` refusal announces nothing.
- The message names the unit id and the branch and is a single line.
- `claim.sh` contains no inline network call; the notice goes through `propose/scripts/notify-slack.sh`.
- `drive/SKILL.md` §3 and `docs/drive-loop-runbook.md` §5 describe the announcement, in the same commit.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic cases covering: claim-without-token, claim-with-failing-notifier, and no-announcement-on-refusal. The suite never calls the network, so the notifier is exercised through a stub on `PATH` or an injected script path.
- `grep` in the review confirms no `curl`/`wget` appears in `claim.sh`.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no residual `outputs/` diff.

**Gate**

- The suite is green including the two never-load-bearing cases; a claim must survive every notifier failure mode before this ships.

Decided: Slack via the existing `notify-slack.sh` rather than a GitHub draft PR at claim time — the notifier already exists, degrades gracefully, and reaches the operator where the fleet's other notices land; a draft PR would create an artifact `/report`'s `create-or-update.sh` then has to reconcile with, for no extra visibility (developer may override at /drive).

Decided: announce from `claim.sh` rather than from `commands/drive.md` — the claim seam is where the fact becomes true, and a script-side announcement covers every caller of `claim.sh` including a future resume path, whereas command prose covers only `/drive` (developer may override at /drive).

Decided: hermetic suite only, with the notifier stubbed — the acceptance criteria are all about what happens when Slack does *not* work, which a live post cannot demonstrate (developer may override at /drive).

## Considerations

- `claim.sh` currently treats every post-worktree failure as `abort_claim`, which tears the worktree down. The announcement must sit outside that error path entirely, or a Slack outage would start discarding claims (`plugins/workaholic/skills/drive/scripts/claim.sh` lines 152-226).
- The notifier lives in the `propose` skill while the caller is `drive`; `computeClosure` must pull it into the workflows bundle. Check `node scripts/build-plugins/verify.mjs` after the build rather than assuming (`scripts/build-plugins/`).
- If the resume path in `20260801031301-resume-a-claimed-but-unfinished-unit.md` lands first or second, the takeover should announce through the same seam rather than growing a second notice site.

## Final Report

Development completed as planned. The announcement fires from `claim.sh` after its
push succeeds and reports itself as `announced` / `announce_reason` in the claim JSON.

### Discovered Insights

- **Insight**: The "never load-bearing" property is a placement property, not an
  error-handling one. `claim.sh` routes every post-worktree failure through
  `abort_claim`, which tears the worktree down — so a notifier called anywhere inside
  that region would have made a Slack outage start *discarding claims*, no matter how
  carefully its own errors were caught. The announcement is correct because it sits
  below the last `abort_claim` call site, and the test that matters asserts the
  worktree still exists after a notifier that exits non-zero.
  **Context**: Anything else added to this script later faces the same question. The
  region above the final `printf` is claim-critical; the region below it is not.

- **Insight**: An injected script path (`WORKAHOLIC_NOTIFIER`) was needed because the
  acceptance criteria are all about the notifier *failing*, and `notify-slack.sh` is
  built never to fail — it exits 0 on a missing token, an unreachable host, and a
  Slack error alike. A URL override (`WORKAHOLIC_SLACK_API_URL`, the existing seam)
  can only produce `curl_failed`, never a non-zero exit, so it cannot reach the path
  under test.
  **Context**: The house pattern is that a test seam is a documented env override;
  this is the second one in the notifier's call chain, and the two test different
  layers (transport vs. the notifier itself).
