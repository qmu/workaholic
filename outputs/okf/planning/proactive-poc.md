---
type: Engineering Policy
title: "Proactive PoC Proposals"
description: "Actively proposing proof-of-concept work for high-uncertainty areas before full development begins, reducing investment risk by validating early with small, disposable builds."
resource: https://qmu.co.jp/planning/proactive-poc
tags:
  - planning
  - proactive-poc
---

# Proactive PoC Proposals

_For areas of high uncertainty, actively propose proof-of-concept work before full development to reduce unknowns around investment, requirements, and technical feasibility._

For areas of high uncertainty, we actively propose PoC (proof of concept) before entering full development. We want to bring forward as a planning option the act of validating small before building big, to reduce the uncertainty remaining around investment decisions, requirements, and technical feasibility. Rather than leaving the question of whether to propose PoC to the client's request, we propose verification ourselves when we see that uncertainty is high.

## Goal (目標)

We aim for a state in which high-uncertainty areas are verified small before entering full development, and the uncertainty remaining around investment, requirements, and feasibility is reduced. We aim for a state in which what has been verified and what has not yet been verified is visible between the client and us.

## Responsibility (責務)

Our responsibility is to prevent a state in which we dive deeply into full development with high uncertainty remaining, and then layer build-out on top of premises that will later be overturned.

In a firm where generative AI is our default author, once we enter full development we can quickly stack up large amounts of implementation. This speed also becomes an incentive to enter build-out without skipping verification with uncertain premises. We want to avoid the state of carrying into full development at scale the uncertainty that could have been reduced by verifying small.

## Practices (実践)

### Identify and propose PoC for uncertain areas

In areas where we see significant uncertainty remaining in any of requirements, technology, or investment effectiveness, we propose PoC before entering full development. At the time of the proposal, we share with the client what the verification is for and what judgment it will inform.

### Build small, with intent to discard

PoC is kept to the minimum build-out needed to answer the question we want to verify, and we do not assume it will continue to be used as-is in full development. We write it against the real thing for the purpose of verification, treating it as something that may be discarded.

### Use managed services as scaffolding

To launch PoC quickly, we make it easy to choose managed services as scaffolding rather than building everything ourselves. We do not increase build-out from the start; we stand things up in the range needed for verification.

### Related: Upfront IT Investment Evaluation, UX Research through Prototypes

Related: [Upfront IT Investment Evaluation](/planning/it-investment-evaluation.md) and [UX Research through Prototypes](/planning/ux-research-prototype.md).
