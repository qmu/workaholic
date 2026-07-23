---
title: Verifying Before Building Out
slug: verify-before-building
category: planning
source: https://qmu.co.jp/planning/verify-before-building
---

# Verifying Before Building Out

_Before committing to full development, verify small against real artifacts — PoCs, working prototypes, and internal labs — to reduce uncertainty around investment, requirements, experience, and technical feasibility._

Before diving deeply into full development, we build small and verify against the real thing. We put the question we want to settle against something that works — a working artifact or real components — to get an answer first, and reduce the uncertainty remaining around investment, requirements, experience, and technical feasibility before building out. We choose how to verify according to the question: when investment judgment or technical feasibility is uncertain, we propose a PoC (proof of concept) ourselves before full development; when experience or requirements have not settled, we put working prototypes in front of clients and users; and when there is a technical question or component we want to polish internally, we prove it ahead of time in the repository's `labs` directory. All of these are means of building the order "verify, then build" into planning.

## Goal (目標)

We aim for a state in which high-uncertainty areas are verified small against the real thing before entering full development, and the uncertainty remaining around investment, requirements, experience, and feasibility is reduced. We aim for a state in which what has been verified and what has not yet been verified is visible between the client and us. We aim for a state in which components polished in a laboratory are ready in a form that can be integrated into the next product to be built.

## Responsibility (責務)

Our responsibility is to prevent a state in which uncertainty that could have been settled is carried into full development without being verified, and implementation is piled on top of premises that later turn out to be wrong.

In development where AI writes much of the implementation, code piles up quickly and in volume even on top of vague premises. When AI fills in the premises of experience by inference and we enter build-out without verifying the technical premises, requirement and feasibility discrepancies surface only after those inferences have been concretized into every corner of the code. It is easy to slip into carrying, at the scale of full development, the uncertainty that could have been reduced by verifying small.

## Practices (実践)

### Propose PoC ourselves for high-uncertainty areas

In areas where we see significant uncertainty remaining in any of investment judgment, requirements, or technical feasibility, we propose a PoC ourselves before full development. Rather than leaving the proposal to the client's request, we bring verification forward from the side where we see high uncertainty, and share with the client what the verification is for and what judgment its result will inform.

### Verify experience with working prototypes before finalizing specs

Rather than settling requests in text alone, we convert them early into working prototypes and have clients and users try them. We trace requests back to which user pain they address, and verify — before entering design — whether requests share the same premises and whether satisfying one breaks another. Points that do not fit are aligned before entering implementation.

### Prove real components ahead of time in the repository's labs

Alongside `docs`, we place a `labs` directory in the repository, and in laboratories divided by topic we build a PoC for the technical question we want to settle from real components. Beyond verification carried out under a customer's budget, internal proof that developers start on their own initiative ahead of full development also happens here. We keep one laboratory to one topic so the questions do not become mixed.

### Carve polished components out into the product, keep labs as a catalog

Components whose shape has settled in a laboratory are not left in the laboratory; they are carved out and integrated into the product or an existing codebase. Laboratories whose verification is finished are kept rather than deleted, so that they can be drawn on from the next round of product work as a catalog of components and partial implementations. We note within the laboratory what was checked and to what extent, and what has not yet been checked.

### Build small with intent to discard, on managed-service scaffolding

Both PoCs and prototypes are kept to the scope that answers the question we want to settle, and we do not assume they will continue to be used as-is in full development. We write them as things that may be discarded, and rebuild them as understanding advances. To stand things up quickly, we use managed services as scaffolding rather than building everything ourselves, launching only in the range needed for verification.

### Related: Requirements Analysis through Modeling, Upfront IT Investment Evaluation

Related: [Requirements Analysis through Modeling](modeling-centric-design.md) and [Upfront IT Investment Evaluation](it-investment-evaluation.md).
