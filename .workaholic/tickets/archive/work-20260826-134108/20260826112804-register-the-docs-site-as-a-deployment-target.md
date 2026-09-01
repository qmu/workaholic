---
created_at: 2026-08-26T11:28:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deploy-the-docs-site-on-merge-to-main
merge_policy:
verification_handoff: 
---

# Register the docs site as a deployment target

## Overview

PROPOSED. `.workaholic/deployments/` is how this repository knows what it deploys:
`/ship` reads a target's `## Confirmation` and halts when a target declares no
confirmation method, and `/prepare-release` reports per target what is waiting. A docs
site that deploys on merge and is registered nowhere is invisible to both — so the loop
would gain a deployment it cannot see.

Register it, with the procedure and the confirmation an operator (or `/ship`) actually
runs.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.workaholic/deployments/docs-site.md` — NEW. `type: Deployment`, `environment:
  production`, a `confirmation_method` and its `command`, `## Procedure`, `##
  Confirmation`.
- `.workaholic/deployments/marketplace.md` — READ FIRST. The existing target, and the
  model for a **deploy-on-merge** record: the merge *is* the deployment, so the
  confirmation splits into a pre-merge branch proof and a post-merge liveness check.
- `.workaholic/deployments/index.md` — regenerated, never hand-edited.
- `plugins/workaholic/rules/workaholic.md` — READ. The `deployments/` area's definition:
  what it holds, who writes it, when it is refreshed.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — READ, to confirm the
  record's fields are the ones the reader actually consumes.

## Implementation Steps

1. Read `marketplace.md` whole and `rules/workaholic.md`'s definition of the area. The
   docs site is the same **deploy-on-merge** shape, so the record's structure is already
   decided; do not invent a second shape for it.
2. Write `.workaholic/deployments/docs-site.md` with the required frontmatter and a
   `confirmation_method` that a person or a run can actually execute — an HTTP check
   against the live hostname is the honest one, since the merge is the deployment.
3. `## Procedure`: merge to `main`; the `docs-deploy` workflow builds and deploys; for a
   first deploy or a documentation-free merge, `workflow_dispatch`.
4. `## Confirmation`: pre-merge, the build passes with no credential; post-merge, the
   hostname serves the merged content (name the command, e.g. a `curl` for a string the
   merge introduced) — so the check proves *this* merge is live rather than that some
   site exists.
5. Regenerate the OKF indexes (`okf/scripts/refresh-index.sh`) rather than editing
   `index.md`, and verify the layout still audits clean.
6. Note in the record that the target is **inactive until the Cloudflare secrets exist**
   — a registered target that cannot deploy must say so, or `/prepare-release` will
   report it as waiting forever with no reason given.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `read-deploy-state.sh` sees the new target and reports it.
- The record declares a confirmation method and a command; `/ship` does not halt on it
  for want of one.
- `.workaholic/deployments/index.md` is regenerated, not hand-edited, and
  `layout-doctor.sh` reports `conforming: true`.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` names the target.
- `bash plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` reports it.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.

## Considerations

- Registering the target makes `/prepare-release` start reporting it, which is the point
  — but until the secrets exist it will report a target that cannot deploy. Saying so in
  the record is what keeps that from reading as an unexplained backlog.
- The area is **hand-maintained** by rule: `area-freshness.sh` reports on it and never
  writes it. Nothing in this ticket should make a machine the author of a deployment
  procedure.

## Final Report

Development completed as planned.

`.workaholic/deployments/docs-site.md` registers the site as a **deploy-on-merge** target
— the same shape `marketplace.md` documents, not a second shape — with
`confirmation_method: api-probe` and a `command` a headless `/ship` can actually run.
`## Confirmation` splits pre-merge (build and `wrangler deploy --dry-run`, neither needing
a credential) from post-merge (the `Docs Deploy` run is green *and did not skip*, the
hostname answers 200, a string the merge introduced is present, and an unknown path
returns 404). Step 5 is the one that proves *this merge* is live rather than that some
site exists; step 6 guards the soft-404 failure the Worker's `not_found_handling` setting
exists to prevent. A named section records that the target is **inactive until the two
Cloudflare secrets exist**, so `/prepare-release` reporting it as waiting is reporting a
stated precondition rather than an unexplained arrears.

Verified: `read-deploy-state.sh` returns `count: 2` with `docs-site` carrying
`deploy_model: deploy-on-merge`, `confirmation_method: api-probe` and
`has_confirmation: true`; `report-deploy-status.sh` reports the target;
`layout-doctor.sh` reports `conforming: true`; `index.md` was regenerated by
`okf/scripts/refresh-index.sh`, never hand-edited; and the full CLAUDE.md local
verification block passes (`build.mjs` leaves no diff, `verify.mjs`,
`validate-metadata.mjs`, and 3555 hermetic tests passing).

### Discovered Insights

- **Insight**: `paths:` is deliberately left undeclared here, so the target reads
  `attribution: whole_range` like `marketplace.md`. Declaring it on this target alone
  flips `read-deployments.sh`'s `any_paths` flag, at which point every top-level
  component the *other* target has not claimed starts reporting as an
  `unmatched_component` gap.
  **Context**: Path attribution is only an improvement when every target declares it —
  one declaring target makes the whole mapping read as full of unclaimed components. The
  weakness is already named rather than hidden: `path_attribution_undeclared` is reported
  for both targets, which is the reader's own way of saying the count is the whole range.
- **Insight**: A green `Docs Deploy` run is not evidence of a deploy — the workflow skips
  its deploy step and stays green when the Cloudflare secrets are absent.
  **Context**: This is why the post-merge confirmation checks the job summary for the
  named skip before it checks the site at all; without that step, the confirmation would
  pass on a merge that published nothing the moment a secret was rotated away.
