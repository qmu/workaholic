---
created_at: 2026-06-17T21:06:15+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 2h
commit_hash: 8883e3e
category: Changed
depends_on: [20260617210614-establish-deployments-directory-convention.md]
---

# Require a verified deployment-confirmation method in `/ship`

## Overview

Rewire the `/ship` workflow so it **only proceeds when there is an established,
documented way to confirm the deployment succeeded in production**. This is the
core design change: a deployment with no confirmation method is not shippable.

Today (`workaholic:ship` §1-4 and Ship Flow steps 5-6) a missing `## Deploy`
section in `CLAUDE.md` makes ship **silently skip** deploy and verify. This
ticket inverts that fallback into a **hard gate**:

- Before deploying, ship reads the deployment contract via
  `read-deployments.sh` (the `.workaholic/deployments/` reader added in the
  foundation ticket) and/or `CLAUDE.md`'s `## Verify` section.
- If an established confirmation method exists, ship deploys, then **executes
  that confirmation** (open the browser surface and check, run the batch
  program on the server, run the DB query, probe the API) and reports the
  result.
- If **no** confirmation method exists, ship **halts** and asks the user — via
  `AskUserQuestion` at the command/main-agent level — to either provide the
  credentials / a verification path to sign into the production web system or
  server, or to author a `.workaholic/deployments/` entry. Ship does not
  complete a deploy it cannot confirm.
- Optionally, **before** deploying, ship may inspect the production web system
  (e.g. via the available browser tooling) to determine *how* the deployment
  can be assured, then record that as the confirmation method.

This depends on the `.workaholic/deployments/` convention and the
`read-deployments.sh` reader from
`20260617210614-establish-deployments-directory-convention.md`.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - PRIMARY. §1 "CLAUDE.md Convention" (lines 20-48): the §1-4 Fallback (lines 46-48) that silently skips must become a halt-and-ask gate. §2 "Shell Scripts": document the new `read-deployments.sh` entry. §5 "Ship Flow" steps 5 (Deploy, line 150) and 6 (Verify, line 151): rework so a verified confirmation method is required, executed, and reported.
- `plugins/workaholic/commands/ship.md` - Thin orchestrator. The halt-and-ask-for-credentials interaction is user interaction and must live here at the command/main-agent level (One-Level Fan-Out rule), not in the skill's leaf logic. May need a new "deployment confirmation guard" mention in the routing steps (lines 17-25).
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` - Consumed here (added in the foundation ticket). Returns `{has_confirmation, count, deployments:[...]}`; the gate branches on `has_confirmation`.
- `plugins/workaholic/skills/ship/scripts/find-claude-md.sh` - Still used to locate `CLAUDE.md` for the `## Deploy`/`## Verify` procedure; the gate now consults both it and the deployments reader.
- `outputs/workflows/skills/ship/` - GENERATED public copy. Must be regenerated (`node scripts/build-plugins/build.mjs`) because ship is a `DEFAULT_TARGET` and its SKILL.md + script closure change. Do NOT hand-edit.
- `.github/workflows/outputs-freshness.yml` - CI gate that rebuilds `outputs/` and fails on any diff; the regen above must be committed.

## Related History

Every prior iteration of ship's deploy/verify treated a missing spec as "skip"; this ticket is the first to make confirmation a precondition for shipping.

Past tickets that touched similar areas:

- [20260528091259-ship-deploy-doc-from-claude-md.md](.workaholic/tickets/archive/work-20260528-091259/20260528091259-ship-deploy-doc-from-claude-md.md) - Set the current `CLAUDE.md` `## Deploy`/`## Verify` source and the silent-skip Fallback this ticket inverts.
- [20260311121500-add-deployment-confirmation-to-ship-commands.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121500-add-deployment-confirmation-to-ship-commands.md) - Established the mandatory confirm-before-deploy `AskUserQuestion` gate; the new halt-and-ask-for-credentials interaction extends exactly this gate and must preserve it.
- [20260527012300-decouple-core-ship-from-trip.md](.workaholic/tickets/archive/work-20260518-235327/20260527012300-decouple-core-ship-from-trip.md) - Established `workaholic:ship` as the agent-neutral, portable merge/deploy/verify essence; the new gate must stay portable (plain CLI, `metadata.internal`) so the trip path inherits it automatically.
- [20260617001707-publish-github-release-on-ship.md](.workaholic/tickets/archive/work-20260617-000311/20260617001707-publish-github-release-on-ship.md) - Current Ship Flow step ordering and the "detect a state before acting" pattern (CI-publishes detection) — a close analogue for "detect a documented confirmation method before deploying".

## Implementation Steps

1. **Rework `SKILL.md` §1-4 Fallback**: replace "skip deploy and verify steps" with the gate logic — when neither a `.workaholic/deployments/` confirmation method nor a `CLAUDE.md` `## Verify` section provides an established way to confirm success, ship must halt and ask, not skip.
2. **Add the deployments read to Ship Flow step 5 (Deploy)**:
   - Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/ship/scripts/read-deployments.sh` and `find-claude-md.sh`.
   - If `has_confirmation` is true (or `CLAUDE.md` carries a usable `## Verify`): show the `## Procedure` (from the matching deployment file or `CLAUDE.md` `## Deploy`), confirm via `AskUserQuestion` (preserve the existing confirm-before-deploy gate), execute the deploy.
   - If `has_confirmation` is false: HALT. Present, via `AskUserQuestion` at the command level, options such as: (a) provide credentials / a verification path now (sign into the production web system or server so confirmation can be established), (b) author a `.workaholic/deployments/` entry first, (c) inspect the production system now to determine the confirmation method, or (d) abort the ship. Do not merge-then-skip-confirmation.
3. **Rework Ship Flow step 6 (Verify) into "Confirm"**: after a successful deploy, *execute* the confirmation method recorded for the target — branch on `confirmation_method`:
   - `browser` — open the recorded `url` (browser tooling) and check the documented signal.
   - `server-batch` — run the documented batch command (using credentials supplied transiently, never persisted).
   - `db-query` — run the documented query and compare against the expected result.
   - `api-probe` — probe the recorded `endpoint`.
   - `other` — follow the `## Confirmation` body steps.
   Report success/failure explicitly; a failed confirmation is a failed ship.
4. **Pre-deploy inspection (optional path)**: document that when no confirmation method exists, ship may inspect the production web system first (browser tooling) to determine how the deploy can be assured, then capture it as a `.workaholic/deployments/` entry before deploying.
5. **Keep user interaction at the command level**: all `AskUserQuestion` calls (credentials/verification-path prompt, confirm-before-deploy) live in `commands/ship.md` / the main agent. The skill describes the decision; leaf scripts return JSON only.
6. **Update `commands/ship.md`** routing prose if a distinct "deployment confirmation guard" step is warranted, keeping the command thin.
7. **Regenerate `outputs/`**: run `node scripts/build-plugins/build.mjs` so `outputs/workflows/skills/ship/` (SKILL.md + the now-referenced `read-deployments.sh`) is rebuilt and committed. Confirm `metadata.internal: true` is retained on the source ship skill.
8. **Verify**: `node scripts/build-plugins/verify.mjs` (self-contained), `node scripts/build-plugins/validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`, and add a hermetic smoke test exercising the gate's branch (has-confirmation vs. no-confirmation) against a throwaway repo.

## Considerations

- **One-Level Fan-Out / interaction placement** — the halt-and-ask-for-credentials decision is `AskUserQuestion` and MUST occur at the command/main-agent level; leaf scripts (`read-deployments.sh`) are non-interactive and return JSON (`CLAUDE.md` One-Level Fan-Out; `plugins/workaholic/commands/ship.md`).
- **Secrets safety** — credentials gathered to confirm a deploy are used transiently for that session only; never write them into `.workaholic/deployments/*.md` (version-controlled), shell profiles, or global config; prefer project-local `.env`/`.envrc` if anything must persist (`plugins/workaholic/skills/system-safety/SKILL.md`).
- **Portability** — keep `workaholic:ship` agent-neutral so the trip path and non-Claude agents inherit the gate; the gate's logic stays in the bundled script and the SKILL.md prose, not in Claude-only constructs (`plugins/workaholic/skills/ship/SKILL.md`; the decoupling history above).
- **outputs/ lockstep** — ship is a `DEFAULT_TARGET`; forgetting to regenerate and commit `outputs/` after the SKILL.md/script change fails the Outputs Freshness CI (`.github/workflows/outputs-freshness.yml`, `scripts/build-plugins/build.mjs`).
- **operation:CI/CD policy** — this gate is the policy realized: delivery must not depend on knowledge in one person's head, and the codebase should answer whether a deploy is good. But avoid making the gate so heavy it pushes users back to manual console deploys; the confirmation can be lightweight where scale is small (`plugins/workaholic/skills/operation/policies/ci-cd.md`).
- **implementation:Observability policy** — the executed confirmation is *posterior verification* (business-health); where possible, capture the observation window / threshold idea rather than a single point check (`plugins/workaholic/skills/implementation/policies/observability.md`).
- **Dogfooding** — this repo's own `CLAUDE.md` has no `## Deploy`/`## Verify` sections and no `.workaholic/deployments/` entry, so workaholic itself would hit the new halt path on `/ship`. Decide whether to author a `.workaholic/deployments/` entry (or a `## Deploy`/`## Verify`) for this repo as part of landing the change, or to document that a docs/config-only project legitimately has a trivial confirmation method (`CLAUDE.md`, `plugins/workaholic/skills/ship/SKILL.md` §1-4).

## Final Report

Development completed as planned.

Implemented the hard gate end-to-end. Reworked `plugins/workaholic/skills/ship/SKILL.md`: the intro and §1 now state the core design (ship requires an established confirmation method); §1 was renamed "Deployment Contract" with two sources (`.workaholic/deployments/` preferred, `CLAUDE.md ## Deploy`/`## Verify` fallback); §1-4 was inverted from silent-skip into a halt-and-ask gate with four resolution options (provide verification path/credentials, inspect production, author a deployments entry, abort); §2-3b documents the `read-deployments.sh` entry; Ship Flow step 5 (Deploy) gates on `has_confirmation`/`## Verify` and halts when absent; step 6 became "Confirm" — it executes the confirmation by `confirmation_method` and treats a failed confirmation as a failed ship. Updated `commands/ship.md` with a "Deployment confirmation is required" paragraph keeping the AskUserQuestion at the command level. Added a `testReadDeployments` hermetic smoke test (absent dir, README-only, valid target, empty-confirmation-body branches). Regenerated `outputs/` (ship SKILL.md public copy carries the gate; `metadata.internal` stripped from the public copy, retained on source).

### Discovered Insights

- **Insight**: The deployment-confirmation gate is decided at the command/main-agent level, but its *driver* (`read-deployments.sh`) is a non-interactive leaf script returning `has_confirmation` — the One-Level Fan-Out split (detection in a script, the halt question in the command) made the gate expressible without any inline conditional shell in the markdown.
  **Context**: This mirrors the existing `publish-release.sh` "detect CI state, then the command acts" pattern; future ship gates should follow the same shape (script computes the boolean/JSON, command issues the AskUserQuestion).
- **Insight**: The repo itself now hits the new halt path — it has no `.workaholic/deployments/` target entry (only the README template) and no `CLAUDE.md ## Deploy`/`## Verify`. A real deployments entry for workaholic's own release flow (or a `## Verify` in `CLAUDE.md`) was intentionally left for a follow-up rather than bundled here, so the behavior change and the project's own contract stay reviewable separately.
