---
title: One Person Covers All Layers
slug: generalist
category: development
source: https://qmu.co.jp/development/generalist
---

# One Person Covers All Layers

_Having one implementer carry design, implementation, operation, and QA end-to-end with AI as a co-pilot, so that cross-layer feedback loops close within a single person without handoff._

We take as the basic approach to development having one implementer carry all layers — design, implementation, operation, and QA — end-to-end. Rather than dividing and distributing roles by skill, crossing the walls between layers with generative AI as a co-pilot and looking across all of development allows cross-layer feedback to cycle fast within the person. The premise that a single person can trace — without going through handoff — how a premise set in design behaves in operation, and which implementation decision a QA finding traces back to, is built into our way of working.

## Goal (目標)

We aim for a state in which one developer, unbound by skill boundaries, looks through design to implementation, operation, and QA end-to-end and delivers value to users. The state in which a judgment placed at design time has its effect in operation, and a behavior seen in testing traces back to its origin in requirements — these are connected within the same person, and cross-layer feedback loops through without waiting for organizational transmission.

## Responsibility (責務)

Our responsibility is to prevent a state in which an issue that has fallen between layers and layers — as "outside my scope" — is left unattended by anyone. Issues found at the seam of design and operation, and the seam of implementation and QA, tend to float because they don't fit inside any particular skill. As generative AI as a co-pilot produces code and outputs broadly across areas, issues that fall at boundaries become harder to see, and a state of issues being pushed back because they belong to no area's scope tends to pile up. We want to prevent the situation where issues that fall between areas are left ownerless. A setup in which one person carries the whole through is the premise for having the perspective to pick up issues across boundaries, not a division for handing issues off by drawing a scope line.

## Practices (実践)

### Cross skill walls with AI as a co-pilot

In any area — design, implementation, operation, QA — we proceed with generative AI alongside. When one person carries broadly, the fine-grained steps in each area would otherwise become individual load, but AI running in parallel allows stepping into individual areas while keeping perspective on the whole. The basic policy of using AI as a co-pilot for crossing skill walls builds on [Active Use of Generative AI](ai-utilization.md).

### Pick up issues that fall at seams between areas

Issues found at the seam of design and operation, and the seam of implementation and QA, are not pushed back with "outside scope" — the person who noticed picks them up on the spot. A setup where one person carries the whole is the position most able to pick up issues at boundaries. The stance of not avoiding issues that are in a difficult area or troublesome — not treating them as "outside scope" — is continuous with the standard in [Code of Conduct](code-of-conduct.md) of not prioritizing internal passivity over client benefit.

### Cycle cross-layer feedback within oneself

How a premise placed at design time behaved in operation, and which implementation judgment a QA finding traces back to, is traced by the same person without going through handoff. The greatest benefit of a single person being able to see through the whole is that the round-trip of bringing knowledge gained in one area back to another area is completed within the individual without going through organizational transmission. We make this round-trip cycling fast the goal of a setup in which one person carries all layers.

### Related: Active Use of Generative AI, Code of Conduct

The basic policy of using AI to cross skill walls is [Active Use of Generative AI](ai-utilization.md), and the stance of not avoiding issues and taking them on is continuous with the standard on internal passivity in [Code of Conduct](code-of-conduct.md).
