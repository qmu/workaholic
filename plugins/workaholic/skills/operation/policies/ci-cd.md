---
title: CI/CD Automation
slug: ci-cd
category: operation
source: https://qmu.co.jp/implementation/ci-cd
---

# CI/CD Automation

*Consolidating the deployment path as repository scripts executed by generative AI, verified against production before and after, so the safety of a shipment rests on reproducible evidence rather than an operator's care.*

CI/CD Automation (CI/CD 自動化) is the policy for recording the path to production deployment as scripts in the repository and having generative AI execute them. Before and after each deployment, verifications are run against production — the live site — and the fact that deployment passed is backed by online confirmation. We want to hold the path from building through inspecting to deploying in the codebase itself, separate from any operator's memory, so that whether a human or an AI executes it, the same result is reached.

## Goal (目標)

The aim is a state where the deployment path is recorded as code in the repository and, whether executed by a human or an AI, arrives at the same result.

Deployment is consolidated into scripts in the repository, reproducible from anyone's machine at any time, producing the same build and the same delivery. Before deployment, builds and inspections run through containers configured to match production, with every inspection the codebase provides applied at this stage; after deployment, the production response itself is confirmed to match expectations through a live-site check. The safety of a deployment rests not on a particular operator's care but on the reproducibility of the deployment path and the verifications that bracket it.

## Responsibility (責務)

The situations this policy aims to prevent are: a state where unverified deployment reaches production, and a state where the deployment procedure depends only on a particular person's or session's memory and cannot be reproduced. Our responsibility is to not let deployments lacking pre/post verification pass through to production, and to not leave a state where deployment procedures do not remain in the repository as code but instead depend only on someone's memory.

In a setup where AI writes most of the implementation and also executes deployments, deployments run fast and often. In this arrangement, "just ship it" deployments that skip verification and one-off commands that touch production directly tend to accumulate. Treating the deployment process turning green as sufficient evidence that production is healthy — without checking the live site's actual responses — leaves a broken state unnoticed in production while the next deployment proceeds.

## Practices (実践)

### Run builds and inspections through containers before deployment

Before deploying, run builds and inspections through containers in the same configuration as production and confirm they pass. Apply the inspections the codebase provides — link resolution, type checking, tests, and others — at this stage; anything that stops here does not proceed to production. Pre-deployment inspection also gives the generative AI executing the deployment a scaffold it can re-run to self-correct.

### Apply online verification to production after deployment

After deploying, confirm the actual responses from the production origin. Check whether the home page, representative pages, and the sitemap return the expected responses; check whether changes from the branch appear in the live HTML — newly added slugs are reachable, removed slugs return 404, retitled pages show the new title, and content that should not appear is absent. If these checks do not pass, treat the deployment as failed and do not proceed to merge. Ground the decision to ship not in the fact that the deployment process turned green but in the fact that production actually responds as expected.

### Consolidate deployment paths into scripts and execute from the shipping flow

Consolidate the deployment procedure into a repository script (`scripts/deploy.sh`) and have generative AI (Claude Code) execute it as part of the `/ship` shipping flow. This keeps the deployment approach from scattering across one person's memory or ad-hoc commands, and makes the same deployment reproducible by anyone from the repository. Managed CD such as GitHub Actions functions as support for this flow where appropriate. Our company, adapted to a small-team setup where AI executes deployments, leans toward placing the deployment path in repository scripts and adopts a form where both humans and AI can execute the same script without routing through CI-specific DSL.

### Only pass credentials at runtime; do not leave them in the repository

Place credentials needed for deployment only in the environment of the host executing the deployment — not in the repository and not in deployment contract files. Bringing the deployment path closer to local execution means giving up CI's secret isolation, but the single point of never baking credentials into version control is maintained without exception.

### Link deployment records to change history

Maintain a state where what was deployed and when can be traced after the fact. Link deployment to the change history — tickets, stories, release notes, and commit messages — so that what was reflected in production with each shipment is preserved. The actual state of production is confirmed through the online verification results at deployment time and the dashboard of the deployment target.

### Related (関連): Testing, Observability, External Dependencies

Pre-deployment container inspection connects with [Active Use of Unit Tests](../../implementation/policies/test.md), with real-component verification also applied at this stage. The stance of confirming production responses after deployment connects with [Observability and Self-Healing](../../implementation/policies/observability.md). The choice not to lock the deployment path to a specific vendor's CI DSL is continuous with [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md).
