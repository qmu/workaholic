---
title: Objective Technical Documentation
slug: objective-documentation
category: implementation
source: https://qmu.co.jp/implementation/objective-documentation
---

# Objective Technical Documentation

_Write technical documentation in factual, objective language that describes what is, not what is aspirational; documentation that can be verified against the code is documentation that stays current._

Technical documentation has two failure modes: missing and inaccurate. Missing documentation costs time to reconstruct. Inaccurate documentation is worse — it costs time plus the additional cost of debugging behavior that contradicts the documented behavior. Both failure modes are reduced when documentation is written in verifiable, objective language, referenced close to the code it describes, and reviewed in the same PR as the change it documents. We treat documentation as part of the codebase, subject to the same review standards, not as a supplement to be written after the fact.

## Goal (目標)

The situation this policy aims to achieve is one in which a developer (or an AI agent) who reads the documentation of a component, API, or system can predict its behavior and verify that prediction by running the code.

- Documentation describes the actual behavior of the code, not the intended behavior at the time of writing.
- Decisions that are not obvious from reading the code are explained in ADRs or inline comments, with the reason stated.
- Documentation is reviewed in the same PR as the code change it documents.

## Responsibility (責務)

The situation this policy aims to prevent is one in which documentation is aspirational, marketing-inflected, or simply wrong, so that a reader acting on it encounters different behavior than described.

States we do not tolerate:

- Documentation that says "this module handles X elegantly" or "provides a powerful abstraction." Adjectives do not describe behavior.
- Documentation that was written before the code was finalized and was never updated to match the implementation.
- ADRs that record only the decision, not the reasons for the decision and the alternatives considered.
- Inline comments that restate what the code does, rather than explaining why the code does it that way.

## Practices (実践)

### Document decisions, not implementations

Code is self-describing at the implementation level. What documentation adds is the context that is not visible in the code: why this approach was chosen over alternatives, what constraints drove the design, and what invariants the implementation depends on. Write comments and ADRs at the level of reasoning, not mechanics.

### Write in direct, verifiable language

Technical documentation uses specific, verifiable statements: "this endpoint returns 422 when the email field is missing" rather than "this endpoint validates input." Avoid evaluative adjectives (elegant, powerful, simple, intuitive) and hedging adverbs that do not add precision (basically, essentially, generally).

### Keep ADRs close to the code they describe

Architecture Decision Records are stored in the repository (`docs/adr/` or inline with the relevant module). An ADR records: the context, the decision, the alternatives considered, and the consequences. The reasoning section is more valuable than the decision section — the decision can be read from the code; the reasoning cannot.

### Related: Diagram Generation from Code, Policy Conformance Auditing

Diagrams are documentation — [Diagram Generation from Code](diagram-generation.md) covers keeping them current. The audit process checks that documentation and policy alignment are maintained over time — [Policy Conformance Auditing](policy-conformance-audit.md).
