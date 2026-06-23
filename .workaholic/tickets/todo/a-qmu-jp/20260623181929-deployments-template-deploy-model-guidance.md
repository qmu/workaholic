---
created_at: 2026-06-23T18:19:29+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Document deploy-on-merge vs deploy-from-branch in the deployments contract template

## Overview

The `/ship` "confirm before merge" flow fits **deploy-from-branch** projects cleanly (deploy + confirm from the branch, then merge). But **deploy-on-merge** projects — where the release is published *from* the merge commit, like this repo's own marketplace target — must split confirmation into pre-merge readiness (branch/staging proof) and post-merge promotion. The `.workaholic/deployments/README.md` template does not spell out the two models, so a new user authoring a contract may not infer the split. Expand the template (and the §1 Deployment Contract prose) with both models, when each applies, and a copyable deploy-on-merge example.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/objective-documentation.md` — the template must describe how `/ship` actually treats each model (factual, verifiable), not aspirational behavior.
- `workaholic:implementation` / `policies/directory-structure.md` — the guidance belongs in the established `.workaholic/deployments/` contract home.
- `workaholic:operation` / `policies/ci-cd.md` — deploy-on-merge typically promotes via CI from the merge commit; the docs should make that boundary explicit.

## Key Files

- `.workaholic/deployments/README.md` - PRIMARY. The contract template; add a "Deploy models" section spelling out deploy-from-branch vs deploy-on-merge and when each applies, with a copyable example of each.
- `.workaholic/deployments/marketplace.md` - This repo's real deploy-on-merge contract; reference it as the worked example and keep it consistent with the new guidance.
- `plugins/workaholic/skills/ship/SKILL.md` - The Ship Flow §1/§3 prose already mentions the deploy-on-merge case; cross-link so the template and the skill agree.

## Related History

Carried-over concern resolved into this ticket: [48-deploy-on-merge-vs-deploy-from.md](.workaholic/concerns/archive/48-deploy-on-merge-vs-deploy-from.md) (origin PR #48), re-surfaced through PR #51 before being canonicalized and ticketed in the 2026-06-23 concerns triage.

## Implementation Steps

1. Add a "Deploy models" section to `.workaholic/deployments/README.md` describing deploy-from-branch (deploy + confirm from the branch, then merge) and deploy-on-merge (pre-merge readiness proof, merge promotes, post-merge confirmation), with the trade-offs and when each applies.
2. Provide a copyable deploy-on-merge contract example (a `## Procedure` that names "the merge IS the deployment" and a `## Confirmation` split into pre-merge and post-merge), modeled on `.workaholic/deployments/marketplace.md`.
3. Add a short paragraph to the §1 Deployment Contract description in `ship/SKILL.md` (or cross-link the README) so the two stay consistent.

## Considerations

- Documentation-only change; verify wording matches `/ship`'s real behavior in `ship/SKILL.md` (Ship Flow §3 deploy-on-merge note) so the template is not aspirational (`workaholic:implementation` / objective-documentation).
- Keep `.workaholic/deployments/marketplace.md` as the canonical worked example and ensure the README example does not contradict it.
