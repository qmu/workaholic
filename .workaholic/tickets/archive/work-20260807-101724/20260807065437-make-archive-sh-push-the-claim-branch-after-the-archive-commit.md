---
created_at: 2026-08-07T06:54:37+00:00
author: noreply@anthropic.com
assignees: [a@qmu.jp]
depends_on:
feedback: [20260807065338-archive-sh-should-auto-push-the-claim-branch-after-archiving.md]
merge_policy:
claim: work-20260807-101724
---

# Make archive.sh push the claim branch after the archive commit

## Overview

**PROPOSED**, from `#290` (assignee `tamurayoshiya`) and its Slack thread. `drive/scripts/archive.sh` commits the ticket archive onto the claim branch but never pushes it — the push is left to the calling session's discretion. When it is forgotten, the claim's heartbeat lapses even though an archive commit already exists locally, so the unit reads as `resumable` again (inviting a takeover of work that is in fact done), and a reviewer looking at the remote branch sees a stale tip missing the archive commit. An archive commit is a progress signal that must always reach the remote, so `archive.sh` itself — not the session — should push the claim branch immediately after making the archive commit, following the same non-blocking push convention `heartbeat.sh` already uses for the branch tip. Merging the pull request this was published on is what turns this from a proposal into queued work.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — add the push step right after the archive commit succeeds.
- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — the existing non-blocking `git push --quiet origin "$branch"` convention this ticket reuses rather than inventing a new one.
- `plugins/workaholic/skills/drive/SKILL.md` (Claims section) — document that the archive commit is pushed by the script, not left to the session.
- `scripts/test-workflow-scripts.mjs` — add/extend a hermetic smoke test asserting the archive commit reaches the remote branch.

## Implementation Steps

1. In `archive.sh`, immediately after `commit.sh` succeeds and `COMMIT_HASH` is captured, add `git push --quiet origin "$BRANCH"` (the branch already read at the top of the script via `git branch --show-current`).
2. Make the push **non-blocking**, matching `heartbeat.sh`'s and the rest of the claim protocol's convention: a failed push is reported loudly (a `! could not push claim branch <branch>` line, mirroring `report_mission_roll`'s style) but does not fail the archive — the commit is already made locally and must not be lost or treated as an error; the session can retry the push, and the next heartbeat or commit will carry it forward regardless.
3. Update the "Archive complete!" summary to note whether the push succeeded, so a session (or its logs) can tell without re-checking git state.
4. Update `drive/SKILL.md`'s Claims section (and any other prose asserting the push is the session's job) to state that `archive.sh` pushes the claim branch itself.
5. Extend `scripts/test-workflow-scripts.mjs` with a hermetic case: archive a ticket in a throwaway repo with a real (local) remote, then assert the remote branch tip includes the archive commit without any separate push call.
6. Rebuild `outputs/` if `archive.sh`'s script closure changed shape (`node scripts/build-plugins/build.mjs`), then `verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- After `archive.sh` completes successfully, the claim branch's remote tip already carries the archive commit — no separate `git push` is required to make it visible to `list-claims.sh`.
- A push failure is reported (not silent) and does not abort the archive or lose the local commit.
- `drive/SKILL.md` and any other doc asserting the old session-push convention are updated in the same change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new/extended case covering the push) green.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean if `archive.sh`'s closure changed.

**Gate** — what must pass before approval:

- No regression to the existing non-blocking-failure contract of `archive.sh` (a mission-roll or OKF-index failure still must not abort the archive; the new push failure must follow the same "loud but non-fatal" shape).

## Considerations

- Push failures (auth, network, force-push races) must degrade the same way `heartbeat.sh`'s do: reported, not fatal — the commit already exists locally and a later heartbeat or commit will carry it forward.
- This does not change the claim protocol's invariants (claim = pushed branch, heartbeat = branch tip) — it only closes the gap where a real commit could sit unpushed between an archive and the next heartbeat.
