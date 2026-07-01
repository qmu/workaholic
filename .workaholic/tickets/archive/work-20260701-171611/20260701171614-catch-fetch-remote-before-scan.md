---
created_at: 2026-07-01T17:16:14+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 1h
commit_hash: ad4ea8d
category: Changed
depends_on:
---

# Fetch and scan remote branches in /catch so pushed work is visible

## Overview

`/catch` answers "what has everyone been working on" but currently reads only
**local** state: `scan-window.sh` runs `git log --since ... --branches` (local
heads, `refs/heads/*` only) and the skill never fetches. On a stale clone,
another developer's pushed-but-unpulled branch is invisible — exactly the
cross-developer activity the report exists to surface.

This ticket makes `/catch` reflect what the team has pushed, in two coupled parts:

1. **Best-effort fetch** — refresh remote-tracking refs before scanning, so the
   remote's current state is locally available.
2. **Widen the scan** — include remote-tracking branches (`--remotes`) alongside
   local heads, so commits that live only on `origin/*` actually appear.

A fetch is a network operation, so it is **best-effort and non-fatal**: on
failure (offline, no remote, auth) `/catch` proceeds from local refs and the
report notes that the view may be stale. `/catch` never aborts on a fetch error.

## Policies

The standard engineering policies that govern this ticket. The implementing
session **MUST** read each linked policy hard copy before writing code and keep
every change defensible against its Goal (目標), Responsibility (責務), and
Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the change stays within the existing `catch` skill's `scripts/` layout; no new top-level areas.
- `workaholic:implementation` / `policies/coding-standards.md` — style/consistency; the script is POSIX `sh` per `rules/shell.md` (see Considerations), so this is read as the shell-analogue of the house style, not TypeScript.
- `workaholic:implementation` / `policies/objective-documentation.md` — the report must honestly state when the view may be stale (fetch failed); never present a local-only scan as a fresh remote view. This is why the scanner surfaces `fetch_ok` rather than silently swallowing the outcome.
- `workaholic:implementation` / `policies/observability.md` — surface the fetch outcome (`fetch_ok`) in the scanner's JSON so failure is visible to the report and to tests, not hidden.
- `workaholic:implementation` / `policies/test.md` — the change is proven by a hermetic script test (see Quality Gate), not by manual inspection.
- `workaholic:operation` / `policies/ci-cd.md` — graceful degradation of a delivery-path tool: a fetch failure must not break the automated `/catch` run, and the new behavior is guarded by the CI-run test harness.

## Key Files

- `plugins/workaholic/skills/catch/scripts/scan-window.sh` - add the best-effort fetch and widen the developer scan from `--branches` to `--branches --remotes`; normalize `refs/remotes/<remote>/` branch names; emit `fetch_ok`.
- `plugins/workaholic/skills/catch/SKILL.md` - update Phase 0 (fetch step, remote-branch note), the read-only claim in the intro, the `branches[]`/scan description, and add report handling for a stale (`fetch_ok: false`) view.
- `scripts/test-workflow-scripts.mjs` - extend the existing `scan-window` tests (around the `testScanWindow` / `testScanWindowBuckets` blocks) with a bare-remote push scenario and a no-remote degradation case.

## Related History

`/catch` and its scanner were built recently; the scanner already carries
per-branch (`--branches --source`) and time-bucket axes and has hermetic tests in
`scripts/test-workflow-scripts.mjs` (the `catch/scan-window.sh` blocks). This
ticket extends that same scanner and its existing test coverage rather than
introducing new machinery.

## Implementation Steps

1. **Best-effort fetch in `scan-window.sh`** — before the `DEVELOPERS` scan, refresh remote-tracking refs without ever aborting the script (`set -eu` is active). Capture the outcome into a shell boolean so the report can note staleness:
   ```sh
   FETCH_OK=false
   if git fetch --quiet --all --prune 2>/dev/null; then
     FETCH_OK=true
   fi
   ```
   - `--all` covers every configured remote; `--prune` drops remote-tracking refs for branches deleted upstream so the report does not show ghosts. A repo with no remote fails quietly → `FETCH_OK=false`.
   - This only writes `refs/remotes/*` — it does not touch the working tree, index, or any project file, preserving the "writes nothing of yours" contract (see the SKILL intro change).
2. **Widen the scan to remote-tracking branches** — change the `git log` ref selector from `--branches` to `--branches --remotes`, and exclude the symbolic `origin/HEAD` so commits are not mis-attributed to a branch literally named `HEAD`:
   ```sh
   git log --since="$WINDOW" --reverse --no-merges \
     --exclude='refs/remotes/*/HEAD' --branches --remotes --source \
     --format='...'
   ```
3. **Normalize the branch name in jq** — `%S` (`--source`) now yields `refs/remotes/<remote>/<name>` for remote-reached commits. Strip that prefix as well as `refs/heads/` so a branch present both locally and on the remote collapses to one `name` and the per-branch grouping stays coherent:
   ```
   branch: ((.[6] // "") | sub("^refs/remotes/[^/]+/"; "") | sub("^refs/heads/"; ""))
   ```
   Because `git log --source` emits each commit exactly once (first ref that reaches it), `commit_count` does not double-count a commit that exists on both a local and a remote ref.
4. **Emit `fetch_ok`** — add `"fetch_ok": ${FETCH_OK}` to the output JSON object so the report (and the tests) can see whether the remote view was refreshed.
5. **Update `SKILL.md`**:
   - Intro read-only claim: soften to "writes no files and makes no commits; the one exception is a best-effort `git fetch` that only updates remote-tracking refs so the scan sees pushed work." (`objective-documentation`.)
   - Phase 0 step 2 and the `developers[]`/`branches[]` bullets: note the scan now includes remote-tracking branches and that a best-effort fetch runs first; document `fetch_ok`.
   - Report handling: when `fetch_ok` is `false`, add a short line to the report noting the remote could not be refreshed and the view may be stale (do not fabricate freshness).
6. **Extend the hermetic tests** in `scripts/test-workflow-scripts.mjs` (see Quality Gate).

## Quality Gate

How the outcome's quality is assured, captured from the developer at ticket time.
`/drive` surfaces this in its approval prompt and forwards it into the commit
`Verify:` key. Every line is objective and checkable.

**Acceptance criteria** — the checkable conditions that must hold:

- After a commit is pushed to a bare remote and the local branch is then reset/behind, `scan-window.sh` (which fetches internally) includes that commit's author and branch in `developers[]`, with the branch name normalized (no `refs/remotes/…` / `origin/` prefix).
- A commit present on both a local head and a remote-tracking ref is counted **once** (no `commit_count` inflation).
- With **no** remote configured, `scan-window.sh` still emits valid JSON, returns `fetch_ok: false`, and the existing local developers/tickets/stories assertions still pass (graceful degradation — no non-zero exit, no aborted report).
- Output JSON always includes a boolean `fetch_ok` field.
- `origin/HEAD` never appears as a developer branch named `HEAD`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, with the `scan-window` blocks extended by: (a) a bare-remote push case asserting the remote-only commit surfaces with a normalized branch name and `fetch_ok: true`; (b) a no-remote case asserting valid JSON + `fetch_ok: false` + local assertions intact. The bare remote is a local filesystem path — hermetic, no network, consistent with the harness's existing "no real remotes" posture.
- `plugins/workaholic/hooks/posix-lint.sh` passes over `scan-window.sh` (already exercised by the harness) — the added `if`/fetch stays POSIX `#!/bin/sh -eu`, no bashisms.

**Gate** — what must pass before approval:

- The full `node scripts/test-workflow-scripts.mjs` suite is green (new assertions included) and posix-lint is conforming. A live `/catch` run is **not** required for the gate.

## Considerations

- **POSIX shell only** — `scan-window.sh` is `#!/bin/sh -eu`; the added `if`/`git fetch` must avoid bashisms (Alpine/CI has no bash). Keep it dash-clean so the harness's `POSIX_SH` gate passes (`plugins/workaholic/skills/catch/scripts/scan-window.sh`, `rules/shell.md`).
- **Read-only contract wording** — a fetch mutates `refs/remotes/*`, so the intro's "writes nothing" must be corrected honestly rather than left overstated (`plugins/workaholic/skills/catch/SKILL.md` line ~18; `objective-documentation`).
- **`--prune` is a deliberate choice** — it removes remote-tracking refs for upstream-deleted branches so the report doesn't show ghosts; it only touches `refs/remotes/*`, never local heads or the working tree.
- **Performance** — `git fetch --all` adds a network round-trip to every `/catch`. It is `--quiet` and best-effort; acceptable for a report command, but worth noting the added latency on large remotes (`plugins/workaholic/skills/catch/scripts/scan-window.sh`).
- **Deployment scan unchanged** — the `emit_deployments` join still keys on branch-story ship commits; widening the developer scan does not change deployment attribution.

## Final Report

Development completed as planned. `scan-window.sh` now fetches best-effort at startup, scans `--branches --remotes`, normalizes branch names via a `strip_branch` jq helper, and emits `fetch_ok`. `SKILL.md` gained the fetch/remote-scan description, corrected read-only claim, and a stale-view report step. Verified by `node scripts/test-workflow-scripts.mjs` (268 passed, 0 failed) with two new remote scenarios, posix-lint conformance, and `outputs/` rebuilt + `verify.mjs`/`validate-metadata.mjs` green.

### Discovered Insights

- **Insight**: `git fetch --all` in a repo with **no** remote configured exits 0 (a vacuous success), so `fetch_ok` is `true` there, not `false`. The ticket's acceptance criteria assumed no-remote ⇒ `fetch_ok: false`; in reality only an *unreachable/failing* remote (bad URL, offline, auth) yields `false`. The tests were written to the true behavior: no-remote asserts `fetch_ok: true`, and a separate unreachable-remote scenario asserts `fetch_ok: false` with the local scan intact.
  **Context**: The stale-view note in the report keys on `fetch_ok: false`, so it correctly fires only when a configured remote genuinely could not be refreshed — never on a purely local repo where "stale relative to remote" is meaningless.

- **Insight**: `%S` (`git log --source`) emits the **short** ref form — a local head as `feature`, a remote-only ref as `origin/feature` — not the full `refs/remotes/origin/feature`. Stripping a `refs/remotes/<remote>/` regex alone leaves the `origin/` prefix. Normalization must strip the actual remote names (hence passing `git remote` into jq as `$remotes`). Because `--branches` is traversed before `--remotes`, a commit on both a local and remote ref is attributed to the local head, so branch grouping never fragments.
  **Context**: Anyone extending the per-branch axis must keep the `strip_branch` helper and the `$remotes` argument in sync; dropping either re-leaks `origin/` prefixes into branch names.
