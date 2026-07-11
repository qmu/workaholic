---
type: Engineering Policy
title: "Verify Before Building"
description: "Reducing uncertainty around investment, requirements, experience, and technical feasibility before full development by verifying small with the real thing — through PoC, working prototypes, and in-repository labs."
resource: https://qmu.co.jp/planning/verify-before-building
tags:
  - planning
  - verify-before-building
---

# Verify Before Building

_Before diving deeply into full development, build small and verify with the real thing — using PoC, prototypes, and in-repository labs to reduce uncertainty around investment, requirements, experience, and technical feasibility before building in earnest._

Before diving deeply into full development, build small and verify with the real thing. Answer the questions we want to verify against working things and real components first, reducing the uncertainty remaining around investment, requirements, experience, and technical feasibility before building in full. The method of verification is chosen based on the question — if investment decisions or technical feasibility are uncertain, we proactively propose PoC (proof of concept) before full development; if experience or requirements are not yet solid, we have clients and users try working prototypes; if there are technical challenges or components to hone in-house, we prove them in advance in the repository's labs directory. All of these are means of building "verify before building in earnest" into the planning process.

## Goal (目標)

We aim for a state in which high-uncertainty areas are verified small with the real thing before entering full development, and the uncertainty remaining around investment, requirements, experience, and feasibility is reduced. We aim for a state in which what has been verified and what has not yet been verified is visible between the client and us. We aim for a state in which components honed in the labs are in a form ready to be incorporated into the next product.

## Responsibility (責務)

Our responsibility is to prevent a state in which we dive deeply into full development with uncertainty that should have been verified left unverified, and then layer build-out on top of premises that will later be overturned.

In development where AI writes most of the implementation, implementation piles up quickly and in large quantities even on vague premises. If experience premises are filled in by AI inference and we enter build-out without verifying technical premises, the misalignment between requirements or feasibility surfaces after those inferences have been concretized into every corner of the code. We tend to slide into carrying into full development at scale the uncertainty that could have been reduced by verifying small, skipping the verification step.

## Practices (実践)

### Proactively propose PoC for high-uncertainty areas

In areas where we see significant uncertainty remaining in investment decisions, requirements, or technical feasibility, we propose PoC before entering full development — from our side, not waiting for the client's request. When we see that uncertainty is high, we propose verification ourselves and share with the client what the PoC is for and what judgment it will inform.

### Verify experience through working prototypes before finalizing specs

Rather than exchanging requests only in text, we convert them early into working prototypes and have clients and users try them. We trace requests back to which user pain they address, and use prototypes to verify whether requests share the same premises and whether satisfying one breaks another, before entering design. Points that do not fit are aligned with the client before entering implementation.

### Prove real components in advance in the repository's labs

We place a labs directory alongside docs in the repository and, in labs divided by topic, build PoC for the technical challenges we want to verify using real components. This includes not only verification conducted under a client budget, but also in-house proofs that developers initiate themselves in advance of full development. Each lab is kept to one topic so that questions we want to verify do not mix.

### Cut polished components into the product and keep the lab as a catalog

When a component takes shape in a lab, we do not leave it in the lab — we cut it out into the product or existing codebase and incorporate it. Labs that have completed verification are not deleted; they remain as a catalog of components and partial implementations that the next product build can draw from. We note in the lab what was verified and to what extent, and what has not yet been verified.

### Build small with intent to discard, using managed services as scaffolding

Both PoC and prototypes are kept to the scope that answers the questions we want to verify, and we do not assume they will continue to be used as-is in full development. We write them with intent to discard and rebuild as understanding advances. To launch quickly, we make it easy to choose managed services as scaffolding rather than building everything ourselves, standing things up in the range needed for verification.

### Related: Requirements Analysis through Modeling, Upfront IT Investment Evaluation

Related: [Requirements Analysis through Modeling](/planning/modeling-centric-design.md) and [Upfront IT Investment Evaluation](/planning/it-investment-evaluation.md).
