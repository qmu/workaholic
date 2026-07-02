---
type: Engineering Policy
title: "Local CI/CD Execution"
description: "Running CI checks and CD releases inside the team's own containerized development environment rather than external hosted services, so that both inspections and releases are reproducible locally and the safety of a shipment rests on verifiable evidence rather than an operator's care."
resource: https://qmu.co.jp/implementation/ci-cd
tags:
  - operation
  - ci-cd
---

# Local CI/CD Execution

*Running CI (commit health checks) and CD (production delivery) inside the team's own containerized development environment rather than on external hosted services, with most execution handled by generative AI — checks run in local containers, releases from repository scripts, bracketed by online verification against production before and after.*

Local CI/CD Execution (CI/CDのローカル実施) is the policy for running CI (checking whether a commit is healthy) and CD (releasing it to production) inside our containerized development environment rather than routing them through external hosted services. Most execution is handled by generative AI; checks run in local containers and releases run from repository scripts, with online verification against production before and after each release. The aim is a state where the codebase itself and the live site can answer locally whether the code is currently healthy and whether it was correctly delivered to production — without connecting to external runners.

## Goal (目標)

The aim is a state where inspections and releases are recorded as code in the repository and arrive at the same result whether a human or an AI executes them.

Inspections show type errors, test failures, lint issues, and dependency vulnerabilities at the site of the change — not in a distant runner — so the author (whether human or AI) can fix them on the spot. Releases are consolidated into scripts in the repository; the same build and the same delivery are reproducible from anyone's machine at any time; and before and after each release, verifications run against production, so the fact that a release passed is backed by confirmation against the live site. The safety of inspections and releases rests not on a particular operator's care but on the reproducibility of the path and the verifications that bracket it.

## Responsibility (責務)

The situations this policy aims to prevent are: treating a green indicator — absent any evidence of what the inspection actually verified — as proof the code is healthy; an unverified release reaching production; and a state where the only means of reproducing an inspection or release lives inside an external service's configuration and cannot be reproduced locally.

In a setup where AI writes most of the implementation and also runs inspections and releases, both happen fast and often. In this arrangement, failures accumulate: seeing a large volume of AI-generated tests pass and treating that alone as a health signal, without asking what those tests actually verify about real behavior; "just ship it" releases that skip verification; and inspection or release paths that only run inside external runners, making it hard to see from local what actually happened — leaving green or red indicators as the only basis for judgment.

## Practices (実践)

### Consolidate inspections into a single command and run the same thing locally and in containers

Consolidate build, type checking, tests, lint, and dependency vulnerability scanning into a single inspection command (such as `npm run check`) so that the same checks run from the same command whether on a developer's machine or inside a container. Keep the inspection logic in repository scripts rather than locked inside external service configuration files, so results are consistent regardless of where the command runs. Fast checks (type checking, lint, formatting) run locally before commit; heavier checks (full tests, vulnerability scanning) run in containers.

### Before release confirm inspections pass; after release apply online verification to production

Before releasing, confirm that the build passes and inspections are green in the same configuration as production. After releasing, confirm the actual responses from the production origin. Check whether the home page, representative pages, and the sitemap return the expected responses; check whether changes from the branch appear in the live HTML — newly added slugs are reachable, removed slugs return 404, retitled pages show the new title, and content that should not appear is absent. If these checks do not pass, treat the release as failed and do not proceed to merge. Ground the decision to ship not in the fact that the process turned green but in the fact that production actually responds as expected.

### Consolidate inspection and release paths into scripts and execute from the shipping flow

Consolidate inspection and release procedures into repository scripts (releases into `scripts/deploy.sh`) and have generative AI (Claude Code) execute them as part of the `/ship` shipping flow. This keeps the approach from scattering across one person's memory or ad-hoc commands and makes the same inspections and the same release reproducible by anyone from the repository. When inspection failures and release results come back as output from local containers rather than from distant runner logs, generative AI can determine the next step and retry on the spot.

### Only pass credentials at runtime; do not leave them in the repository

Place credentials needed for release only in the environment of the host executing the release — not in the repository and not in deployment contract files. Bringing the release path closer to local execution means giving up CI's secret isolation, but the single point of never baking credentials into version control is maintained without exception.

### Link records to change history

Maintain a state where what was inspected and released, and when, can be traced after the fact. Link releases to the change history — tickets, stories, release notes, and commit messages — so that what was reflected in production with each shipment is preserved. The actual state of production is confirmed through the online verification results at release time and the dashboard of the release target.

### Do not rely on external CI/CD services as the primary axis

Keep inspections and releases centered in local containers; do not make connection to hosted CI/CD services a required path. Hosted CI/CD such as GitHub Actions functions as a backstop — a check point that does not depend on individual environment configuration, and one that still runs checks when someone newly clones the repository and commits. As a small team running inspections and releases in containers through generative AI, we accept not having that backstop and lean toward keeping the dependency on external services thin rather than building reliance on it.

### Related (関連): Testing, Observability, External Dependencies, Containerization

The construction of inspections themselves connects with [Active Use of Unit Tests](/implementation/test.md), with real-component verification also applied at this stage. The stance of confirming production responses after release connects with [Observability and Self-Healing](/implementation/observability.md). The choice to keep dependency on external CI/CD services thin is continuous with [Conservative Vendor Dependence](/design/vendor-neutrality.md). The execution environment for running inspections and releases connects with [Containerization](/implementation/containerization.md).
