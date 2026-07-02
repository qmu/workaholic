---
title: Implementers Own Quality Assurance
slug: qa-engineering
category: development
source: https://qmu.co.jp/development/qa-engineering
---

# Implementers Own Quality Assurance

_Having the developer who makes a change also plan, execute, and improve the QA for that change, rather than delegating quality assurance to a separate later stage._

Quality assurance is not cut out as a separate later process — the implementer who made the change takes it on. The implementer identifies the conditions the change should satisfy, backs up that they are satisfied with evidence, and only then can it be said that quality has been verified. Rather than treating the fact that all checks passed or the fact that it is working as quality itself, including up to the point of showing by one's own hand the basis for what was verified and how — this is included in the implementer's responsibility.

## Goal (目標)

We aim for a state in which quality assurance is woven into each phase of development, and the developer who made the change themselves looks through quality through the loop of plan, execute, and improve. When the developer who best knows the intent of the change is in the position of verifying quality, quality is not something appended at the end of a process but something woven into each phase of development from the start.

## Responsibility (責務)

Our responsibility is to prevent a state in which QA is left to a later process or someone else, and the quality of changes that an AI coding agent has mass-produced is released without anyone looking through it. In development where AI writes much of the implementation, changes pile up in large quantities at high speed, and the situation of no one verifying what each is supposed to satisfy — and whether it is actually satisfied — and it flowing forward as having passed checks — easily arises. When QA is cut out to an independent later process and the assumption that someone will assure quality somewhere away from the developer who made the change is relied on, that "someone" is absent while the release proceeds. We want to prevent a state in which the subject who looks through quality is separated from the person responsible for the change.

## Practices (実践)

### The developer who made the change plans QA

What needs to be verified is decided at the same time as designing the change. Which boundary conditions might break, which external dependency connections should be intact, which paths breaking would reach the user — the developer who best knows the intent of the change identifies these and writes them out as a verification plan. For the aim of picking up conditions to verify, the thinking of [Active Use of Unit Tests](../../implementation/policies/test.md) is followed; this policy handles the question of where the role of planning verification sits.

### The developer looks through verification conducted with AI

Much of running verification is delegated to AI coding agents. On the other hand, the role of reading whether mass-produced verification is verifying what it claims to verify, and whether a state where all tests pass actually backs up quality, is taken on by the developer who made the change. Rather than trusting the fact of a large number of tests passing alone as healthy, the developer stands in the position of looking through whether each one is stepping through a meaningful path. We do not block AI from mass-producing verification; we leave the judgment of whether that result may be received as quality in the developer's hands.

### Improve QA from gaps found after release

Bugs and oversights that become visible after release are received by the developer who made that change as material for reconsidering the next verification plan. We cycle the improvement of reconstituting how to verify so the same gap is not repeated, without handing it off to a different person, inside development. The stance of not pushing back on troublesome verification or quality work that does not easily connect to evaluation is continuous with the standard in [Code of Conduct](code-of-conduct.md) on not prioritizing internal passivity over client benefit.

### Load QA onto automated paths

The loop of plan, execute, and improve is loaded onto paths that the codebase itself supports, not on the operator's memory. Setting up the path where verification is executed in CI and regressions are detected at PR time is handled by [Local CI/CD Execution](../../operation/policies/ci-cd.md); this policy handles the side of developers planning and improving what is loaded onto it. Developer-owned QA and the automated path where anyone executing it produces the same result stand together.

### Related: Active Use of Unit Tests, Local CI/CD Execution, Code of Conduct

The technical side of how to write tests is handled by [Active Use of Unit Tests](../../implementation/policies/test.md); the delivery and verification path for executing verification is handled by [Local CI/CD Execution](../../operation/policies/ci-cd.md). The stance of not pushing back on troublesome QA is continuous with [Code of Conduct](code-of-conduct.md). This policy bundles the technology and path and stance these handle from the side of developers owning QA.
