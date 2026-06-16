---
title: CI/CD Automation
slug: ci-cd
category: operation
source: https://qmu.co.jp/implementation/ci-cd
---

# CI/CD Automation

CI/CD Automation (CI/CD 自動化) is the policy for decoupling the path from commit to deployment from the operator's memory. Building, testing, inspection, and delivery are all recorded in the repository as code, creating a state in which the same result is obtained no matter who runs it or when they run it. We place CI/CD Automation at the top of the availability policy domain because operational continuity is supported not by "the reliability of human hands" but by "the reliability of the codebase itself."

## Goal (目標)

The situation this policy aims to achieve is one in which the codebase can answer for itself whether a commit is in a deployable state.

The contours of the goal are as follows:

- From day one, a `git push` runs every inspection, and the delivery path to `main` / `production` starts automatically.

- The class of discrepancy described by "it works locally but the build doesn't pass" or "it passes when person A deploys but fails when person B runs it" cannot arise structurally.

- Regressions (type errors, test failures, lint warnings, dependency vulnerabilities) are detected at the time of the PR rather than after release.

- Rollback is provided as an automated path (as a button / command, not as a runbook).

## Responsibility (責務)

The situation this policy aims to prevent is one in which the delivery path depends on an individual's operational knowledge, and reproducibility and regression detection are not built in as the default. It prevents a state in which delivery depends on a procedure that lives inside one person's head.

States that are not tolerated:

- A deployment path reachable only by hand. A state in which production rollout depends on "person A typing commands in sequence" or "logging into a console and clicking manually."

- Inspections that are not run in CI. A state in which any of type checking, unit tests, lint, dependency vulnerability scanning, or automated accessibility verification that exist in the codebase are not being run in CI.

- "Tests that fail but aren't red." A state in which flaky, skipped, and disabled tests pile up until green is no longer grounds for trust.

- A rollback procedure that has not been rehearsed. Putting "if it comes to it, we can just revert" into operation while never having actually executed it.

- CI configuration that is locked inside vendor-specific DSL. A state in which logic that cannot be reproduced locally (dependency resolution, container startup, test execution) disappears into DSL such as `.github/workflows/*` or `.gitlab-ci.yml` (consistent with Passive Vendor Dependence).

## Practices (実践)

### Establish automation ahead of other infrastructure work

In new projects, set up CI/CD before shipping the first feature. Manual deployment is easy to set up initially and is sufficient for small teams. The reason to prioritize automation nonetheless is that it makes reproducibility and regression detection the default from day one. The cost is that the setup effort is incurred before the first feature ships.

The paths to set up first are as follows:

- A push to the repository runs the build, type check, and tests.

- A merge into the `main` / `production` branch starts the production rollout (or starts it after manual approval).

- On failure, a notification is delivered (Slack, email, GitHub PR).

### The CI logic must be reproducible locally

The inspections and build steps that run in CI are kept in a state where developers can run them locally with the same commands. Rather than writing logic only inside `.github/workflows/*`, consolidate it into commands such as `npm run check` or `make test`, and have CI merely invoke them.

- Local reproducibility raises the debugging speed on CI failure by an order of magnitude.

- The blast radius of a vendor swap (GitHub Actions → CircleCI → another tool) becomes smaller.

### Operate inspection additions on the premise of "increasing the red"

When adding a new inspection (a test, a lint rule, a vulnerability scan), it is acceptable to first surface the places that currently turn red. If the addition of an inspection is delayed out of fear that `main` will turn red the instant it is added, an inspection culture will never grow.

- When the existing red cannot be resolved all at once, enable the new inspection in stages (exclusion files, an upper bound on the number of tolerated warnings).

- Leave the goal of "eventually applying it across the board" in the PR description or in an ADR.

### Deployment has "automated stages"

Rather than shipping directly to production, separate it into stages.

- build / test: the stage that runs inspections. If it fails, it stops here.

- deploy to staging: once inspections pass, it is reflected to staging automatically.

- deploy to production: once confirmation is obtained on staging (automatically / with manual approval), it is reflected to production.

The stages may be shortened according to scale (for a small documentation site, the two stages of build → production are sufficient). What matters is that each stage is an automated decision point.

### Provide rollback as an automated path

Rather than "if it comes to it, we can just revert," provide a rollback button / command.

- Rolling back to the previous successful deployment can be executed in one operation.

- Data integrity at rollback time (downgrading DB migrations, handling schema-incompatible changes) is documented as a procedure.

- Run a rollback rehearsal monthly to quarterly.

### Use caching and artifacts appropriately

CI execution time can be greatly reduced with caching of dependency resolution and build artifacts. For dependency-resolution caching (npm cache, Gradle cache, etc.), use the standard features of the CI configuration. For build artifacts (Docker images, compiled binaries), push them to a registry and have other jobs retrieve them.

### Operate required checks on Pull Requests

Using GitHub's Required status checks (or an equivalent feature), make a green CI mandatory before a merge into `main`. Leave no path by which a manual merge lets red code in.

### Treat CI maintenance "with the same weight as feature development"

Treat the improvement and tidying of CI configuration with the same weight as feature development. A CI that is slow, unstable, or inscrutable directly harms the development experience and induces manual evasion of inspections (skipping local tests before pushing).

### Retain deployment logs for the long term

Make "when and what was deployed" traceable for at least six months. Deliberately choose the retention-period settings for GitHub Actions / GitLab CI logs and artifacts. In post-incident review, deployment history is a primary source.

### Related (関連): Portability, Observability, Testing, WCAG

The inspections that run on CI take on the verification points of multiple policy domains.

- Delivery portability is linked with Passive Vendor Dependence.

- Inspection of metrics and log output is linked with Observability and Self-Healing.

- Test execution is linked with Testing (integration tests that use real components also run here).

- Automated accessibility verification (Axe, Lighthouse) is the path that defends WCAG 2.2 AA from Accessibility First in CI.
