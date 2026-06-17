---
title: UX Research through Prototypes
slug: ux-research-prototype
category: planning
source: https://qmu.co.jp/planning/ux-research-prototype
---

# UX Research through Prototypes

_Verify requirements through the experience of working prototypes, rather than reaching full agreement on specifications in text alone._

Before finishing working through client requests purely in text, we have clients and users try working prototypes and verify requirements through experience. Rather than making a complete specification before starting work the goal of planning, we show experience through prototypes and confirm with clients the outline of what to build and what not to build. We verify in a form that can actually be touched the requirements and issues captured through requirements analysis through modeling.

## Goal (目標)

We aim for a state in which the client and we share the same completed vision through working experience rather than text, and what how a request works as an operation is visible at an early stage. We aim for a state in which each request's response to which user pain it addresses is verified through experience, and misaligned requests surface before they take shape.

## Responsibility (責務)

Our responsibility is to prevent a state in which we advance to design and implementation based only on textual agreement without verifying the experience.

Requests are expressions of a part of a business or pain; even when we can agree in text, discrepancies tend to appear when actually operating. If we proceed without surfacing those discrepancies at the prototype stage, contradictions are carried forward to stages that are more concrete and harder to fix. In a firm where generative AI is our default author, there is a tendency to fall into a state where AI fills in vague experience premises by inference, and requirement discrepancies are found after those inferences have been concretized into every corner of the code.

## Practices (実践)

### Verify with working prototypes before finalizing specs

Rather than exchanging requests only in text, we convert them early into working prototypes and have clients and users try them. It is only through actual operation that one can see how a request works as experience and where it does not fit.

### Surface requirement-experience gaps early

We trace requests back to which user pain they address. On top of that, we use prototypes to verify whether requests share the same premises and whether satisfying one breaks another, before entering design. Points that do not fit are aligned with the client before entering implementation.

### Build to discard, keeping verification granularity intact

We do not treat prototypes as "something to fix the completed vision in one go." We limit them to the scope that answers the question we want to verify, build them with intent to discard, and rebuild as understanding advances.

### Related: Requirements Analysis through Modeling, Proactive PoC Proposals

Related: [Requirements Analysis through Modeling](modeling-centric-design.md) and [Proactive PoC Proposals](proactive-poc.md).
