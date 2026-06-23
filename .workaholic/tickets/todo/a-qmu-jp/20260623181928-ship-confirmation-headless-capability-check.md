---
created_at: 2026-06-23T18:19:28+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Warn when a deployment target's confirmation method can't run in the current ship environment

## Overview

The `/ship` Ship Flow executes a deployment's confirmation by `confirmation_method`: `browser` needs browser tooling, `server-batch` needs shell/SSH plus transient credentials, `db-query` needs a DB client. In a headless or CI ship context those may be unavailable, so a target with a declared method can still be **unconfirmable at run time** — forcing the §1-4 halt after deploy preparation has already begun. Add a pre-deploy capability check that detects when the environment lacks the tooling a target's method requires, warns early, and steers toward a method executable in that environment (e.g. `api-probe`/`db-query` for headless). Document each method's runtime prerequisites in the deployments template.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing code.

- `workaholic:operation` / `policies/ci-cd.md` — ship runs in interactive and headless/CI contexts; confirmation must degrade predictably across both.
- `workaholic:implementation` / `policies/directory-structure.md` — the check and the deployments contract live in their conventional homes (ship skill scripts, `.workaholic/deployments/`).
- `workaholic:implementation` / `policies/coding-standards.md` — style/convention conformance for the new check and any script changes.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - Ship Flow §1-4 (the hard gate) and §5 step 4 (execute confirmation); add the pre-deploy capability check and document the headless steering.
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` - Surfaces `confirmation_method`; the capability check consumes its output.
- `.workaholic/deployments/README.md` - The deployments contract template; document each method's runtime prerequisites and which suit headless/CI.

## Related History

Carried-over concern resolved into this ticket: [47-confirmation-execution-depends-on-tooling-that.md](.workaholic/concerns/archive/47-confirmation-execution-depends-on-tooling-that.md) (origin PR #47), re-surfaced through PRs #48/#51 before being canonicalized and ticketed in the 2026-06-23 concerns triage.

## Implementation Steps

1. Define, per `confirmation_method`, the runtime prerequisite it needs (`browser` → browser tooling/interactive agent; `server-batch` → shell/SSH + credentials; `db-query` → DB client; `api-probe` → network/curl).
2. Add a pre-deploy capability check (a ship script, or a documented step) that, given the matched target's method, detects whether the prerequisite is present in the current ship environment and warns when it is not — before the deploy procedure runs.
3. In `ship/SKILL.md`, wire the check into the Ship Flow ahead of step 3 (deploy) and document that `browser` confirmations assume an interactive agent while `api-probe`/`db-query` suit headless/CI.
4. Update `.workaholic/deployments/README.md` to list each method's prerequisites and recommend a headless-executable method for CI ship contexts.

## Considerations

- Keep the check advisory (warn + steer), not a hard block beyond the existing §1-4 gate — a missing capability should fail fast with guidance, not silently skip confirmation (`plugins/workaholic/skills/ship/SKILL.md`).
- Transient credentials for `server-batch` must never be persisted to `.workaholic/deployments/*.md`, shell profiles, or global config — preserve the existing transient-credential rule.
- Extract any multi-step capability detection into a bundled ship script rather than inline shell in the skill markdown (Shell Script Principle).
