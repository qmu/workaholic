---
created_at: 2026-07-16T16:30:02+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# /catch's scanner has three blind spots: abandoned tickets, inferred deployers, and an unbounded fetch

## Overview

Promoted from three triaged deferred concerns (2026-07-16 triage-to-zero;
verdicts verified against source):

1. **`by-developer-axis-joins-on-commit`** — `scan-window.sh:111` loops only
   `todo archive icebox`; `.workaholic/tickets/abandoned/` holds two real
   tickets that are invisible to `/catch` and attributable to no developer.
2. **`catch-deployment-attribution-is-approximate`** — `record-evidence.sh`
   writes no author into the Deployment Evidence block, so `scan-window.sh:270`
   infers the deployer from the git author of the commit that last touched the
   story.
3. **`best-effort-fetch-adds-a-per`** — `scan-window.sh:32` runs an
   unconditional `git fetch --quiet --all --prune` with no timeout and no
   opt-out; an unresponsive remote stalls `/catch` indefinitely.

## Key Files

- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — roster loop (line ~111), scope case (~130-135), fetch (~32), deployer inference (~270)
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` — the Deployment Evidence block writer
- `scripts/test-workflow-scripts.mjs` — `testScanWindow*`, `testRecordEvidence`

## Implementation Steps

1. Add `abandoned` to the roster loop and the scope case mapping in `scan-window.sh`.
2. Stamp an explicit author line into `record-evidence.sh`'s Deployment Evidence block; have `emit_deployments` read the recorded author, falling back to inference for legacy blocks.
3. Bound the fetch (timeout or opt-out flag), keeping it best-effort and reporting staleness via `fetch_ok` as today.
4. Extend the hermetic tests for all three; rebuild `outputs/` (catch/ship scripts are bundled).

## Policies

- `workaholic:implementation` / `policies/observability.md` — a report that silently omits a ticket state or guesses an actor misexplains the system; record the fact, don't infer it.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` throughout; the timeout must not introduce a bashism.

## Quality Gate

- An abandoned ticket appears in `/catch`'s by-developer roster, attributed to its author.
- A deployment recorded after the fix reports the recorded deployer, not the last story-toucher; legacy blocks still resolve.
- With an unreachable remote, `/catch` completes within the bounded window and reports `fetch_ok: false`.
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- Keep fetch best-effort: a failed fetch degrades to local data, never a hard stop.
