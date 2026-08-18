---
created_at: 2026-08-18T13:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818132013-the-release-status-reader-trusts-whatever-refs-its-container-holds.md]
merge_policy:
verification_handoff: 
claim: work-20260818-134024
---

# Freshen or distrust the deploy status reader's refs

## Overview

`ship/scripts/report-deploy-status.sh` — what `/prepare-release` and the hourly
`[Prepare Release]` routine run — resolves the base as `origin/main` and derives the
unreleased boundary from the newest reachable release tag, and **never fetches**. In a
routine-fired container the refs are whatever the clone happened to arrive with, so the
`📦 Prepare release` line reports a count derived from a repository state nobody chose.

Measured on 2026-08-18 in a live `[Prepare Release]` container (the feedback record
carries the table): the clone held **no tags** and an `origin/main` five days stale, and
one unchanged repository reported `unreleased_count` 9 (`full_history`), then 191
(`full_history`), then the true 8 (`latest_tag:v1.0.182`) as refs were fetched.

Two defects, and the second is the worse one:

1. **The number is wrong**, and its wrongness is invisible — `full_history` is rendered
   as an ordinary boundary reason, indistinguishable from a repository that genuinely
   has no prior release.
2. **The dedup key moves with the refs.** `digest` hashes the same per-target state
   (`slug|has_conf|n|since|note_path|note_match`), so two containers holding different
   refs produce different `deploy:<digest>` keys for one real state — and the tick's
   silence rule, which exists so an unchanged repository posts nothing, can post
   repeatedly instead.

PR #499 fixed the *writing* half by defining CI's checkout (`fetch-depth: 0` + tags) for
the `Release Note Draft` workflow, and deliberately left the reading half alone; CLAUDE.md
records that as a **stated open limit**. This ticket closes it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/observability.md` — a degraded read is reported by name, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` — the tick's entry
  reader; owns the digest and `actionable`. Where the freshen and the freshness field belong.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — derives the boundary
  (`prior_release` / `latest_tag:<t>` / `full_history` / `unresolvable`) from local refs.
  Documented as a **pure local read**; keep it that way — it gains no network I/O.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — the existing precedent for
  this exact shape: a bounded best-effort `git fetch` at startup plus a `fetch_ok` field
  the report renders, with `CATCH_FETCH_TIMEOUT=0` as the offline opt-out. Reuse its
  shape rather than inventing a second one.
- `plugins/workaholic/skills/ship/SKILL.md` §7 — the "it reads and reports, it never
  writes" contract that must be restated to say a network *read* is permitted.
- `plugins/workaholic/commands/prepare-release.md`, `plugins/workaholic/skills/prepare-release/SKILL.md`
  — the command's own "writes nothing, anywhere" prose and its post gates.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `📦 Prepare release`
  post shape, if a degraded read is to be visible in the line.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests (no network); add the
  fixtures below here.
- `scripts/e2e/loop-drill.sh` (`verify-status`) and `docs/loop-drill-runbook.md` — the
  on-demand proof of the tick's behaviour.
- `CLAUDE.md` — the paragraph that records the reading half as an open limit; it is the
  documentation this change must update in the same commit.

## Implementation Steps

1. **Reproduce before changing anything.** Build a throwaway clone that reproduces the
   container: clone with `--no-tags`, reset `origin/main` to a commit several days back,
   and run `report-deploy-status.sh`. Record `unreleased_count`, `since_reason` and
   `digest`; then `git fetch origin main`, re-run; then `git fetch --tags`, re-run. Three
   different digests for one repository state is the defect, and this fixture is what
   proves the fix.
2. **Localize.** Confirm the boundary is chosen in `read-deploy-state.sh` (releases
   record → `git describe --tags` → `full_history` → `unresolvable`) and that
   `report-deploy-status.sh` is the only caller the tick reaches, so the freshen has
   exactly one home.
3. **Freshen, bounded, in `report-deploy-status.sh` only.** Before it calls
   `read-deploy-state.sh`, attempt one best-effort refresh of the refs the boundary
   depends on — the base branch **and tags** — following `scan-window.sh`: a `timeout`
   where the utility exists, an env-var cap with a `0` opt-out
   (`WORKAHOLIC_DEPLOY_FETCH_TIMEOUT`, mirroring `CATCH_FETCH_TIMEOUT`), never fatal.
   `read-deploy-state.sh` stays a pure local read and its header keeps saying so.
4. **Report the freshness by name.** Emit a `refs` field on the JSON —
   `fresh` (the fetch succeeded), `stale` (it failed or timed out), `skipped` (opted out)
   — with the failure's reason. A `since_reason` of `full_history` or `unresolvable`
   under anything but `fresh` is a **doubtful** read and must be reported as one, not as
   an ordinary boundary.
5. **Make the digest honest.** Fold the freshness state into the digest's input so a
   doubtful read can never dedup against a trusted one, and state in the header why the
   base sha is still excluded while this is not. Verify the fixture from step 1 now
   yields one stable digest across all three ref states once the fetch succeeds.
6. **Carry it into the surfaces.** Update `/prepare-release`'s report and its `📦 Prepare
   release` line so a `stale`/`skipped` read says so instead of printing a bare number,
   and keep the post's dedup key `` `deploy:<digest>` `` unchanged in shape.
7. **Documentation in the same commit** — `workaholic:ship` §7 (a network read is
   permitted; a write is still not), the `/prepare-release` contract in its command,
   its skill and `CLAUDE.md`'s command table, and the CLAUDE.md paragraph that records
   the reading half as an open limit.
8. **Tests and the drill.** Add hermetic fixtures for the three ref states and for the
   digest's stability; extend `loop-drill.sh verify-status` to assert the freshness field
   is present and that a degraded read is named; regenerate `outputs/` with
   `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Running the tick's reader in a clone with no tags and a stale `origin/main` reports the
  same `unreleased_count` and the same `digest` as a clone with current refs, whenever the
  freshen succeeds.
- When the freshen cannot run or fails, the output names it (`refs: stale|skipped` with a
  reason) and the rendered line says the read is doubtful rather than printing a bare count.
- `read-deploy-state.sh` performs no network I/O and its "pure read" header is still true.
- `/prepare-release` still writes nothing — no file, no commit, no branch, no PR, no
  merge, no deployment, no GitHub write.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 fixture, re-run after the change: three ref states, one digest.
- `node scripts/test-workflow-scripts.mjs` (hermetic, no network) covering the three
  `refs` states and digest stability.
- `sh scripts/e2e/loop-drill.sh verify-status` on the server.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The above all pass; `git diff` shows no network call added under `read-deploy-state.sh`;
  the documentation listed in step 7 is updated in the same commit.

## Open Decisions

<!-- Recorded, not resolved: the driving session rules on this explicitly and records the
     ruling in its Final Report. -->

- **When the freshen fails, does the tick post the degraded status or stay silent?**
  Posting keeps the operator informed and makes the degradation visible, but publishes a
  count derived from refs the run has just said it does not trust — the reader could be
  read as endorsing a number it flagged. Staying silent never publishes a wrong count, but
  a silent tick is indistinguishable from a quiet repository, which is the same class of
  invisible degradation this ticket exists to remove. This session cannot honestly
  recommend one side; the third option (post, but with the count suppressed and only the
  degradation named) is worth weighing against both.

## Considerations

- The reporter framed the ask as an either/or ("freshen, **or** detect and say so"). The
  steps above deliberately do both, because `scan-window.sh` already established that
  shape in this repository — a bounded best-effort fetch plus a reported `fetch_ok` —
  and a fetch that can fail needs the reporting half regardless. Treat that as the
  hypothesis the implementation confirms, not as a settled design.
- The freshen makes a documented pure reader touch the network. It remains a **read**:
  `/prepare-release`'s "writes nothing" contract is about writes, and the wording in each
  place needs to say so precisely rather than being quietly loosened.
- A container behind a filtering proxy or with no network must degrade to the current
  behaviour, not hang — the timeout and the `0` opt-out are load-bearing, and `[Standup]`
  / `[Housekeep]` share the same container shape.
- The digest currently excludes the base sha on purpose ("a base that merely advanced is
  not news"). Adding the freshness state does not reopen that decision; keep the header's
  reasoning intact and extend it.
