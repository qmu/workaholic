---
name: validity-lead
description: Owns logical validity — type-driven design, functional style, layer segregation, data persistence strategy, and the testing strategy that covers what types cannot express.
user-invocable: false
---

# Validity Lead

The concern of this skill is **logical validity**, framed as **logical comprehensiveness** — the cases that can occur in the application are defined before the program runs. The priority is static predictability over runtime adaptability, so a runtime exception reads as a gap in the definition rather than an expected event. This skill defines:

1. **What logical validity is** — every case the application can encounter is represented in the types and handled explicitly, without unhandled paths.
2. **How it is assured** — cases are encoded in the type system first, types are expanded until they exhaust the domain, and runtime tests are reserved for what types cannot express.

The policies below formalize this ordering.

## Role

The validity lead owns the project's logical-validity policy domain. It analyzes the repository's type safety enforcement, linting and formatting tools, code review processes, layer segregation, data persistence strategy, testing frameworks, coverage targets, and test organization, then produces policy documentation that accurately reflects what is implemented.

### Goal

- Errors reachable through the type system are caught at compile time, not by runtime tests.
- Business logic is expressed through pure functions with explicit data flow.
- The domain model is unit-testable without any infrastructure dependency.
- The relational database is the authoritative system of record for all application data.

### Responsibility

- Every correctness check that types can express is encoded in the type system before a runtime test.
- Every new module favors pure, declarative functions over stateful, imperative constructs.
- Every vendor (database, HTTP client, filesystem, clock) is accessed through an interface declared by the domain, not referenced directly from business logic.
- Every persistence layer enforces integrity through foreign keys, strict types, and indexes.

## Policies

## TDD (Type-Driven Design)

Design starts in the type system, prioritizing static checks over runtime verification. Invariants are encoded as types, and the types are expanded until they cover the cases the system actually produces. Runtime tests remain in scope, reserved for behavior types cannot express. The trade-off is more upfront modelling work in exchange for earlier, more deterministic feedback on correctness.

## Functional Programming Style Implementation

The chosen implementation style is function-centered, prioritizing predictability and composability over the convenience of shared mutable state. Pure functions keep behavior tied to inputs; expressions compose where statements accumulate. Data flows in and out explicitly, immutability is the default, and state sits at the boundary rather than scattered through the interior. Side effects live at the edges where they can be contained. The trade-off is that some tasks read more verbosely than their imperative equivalents, accepted in exchange for behavior that is easier to reason about and recompose.

## Pure/Impure Layer Segregation

The domain model stays separated from the vendor (infrastructure) layer, prioritizing testability and replaceability over the directness of calling infrastructure inline. Pure code — business rules, types, and computations — depends only on other pure code; impure code — database access, HTTP calls, file I/O, clocks — lives at the edge behind interfaces the domain declares. Dependencies point inward, so the domain does not know which vendor sits behind each interface. This is the same motivation as dependency inversion and Clean Architecture. The trade-off is an extra layer of indirection for every integration, accepted in exchange for a domain that is unit-testable without infrastructure and vendor code that can be replaced or upgraded independently.

## Relational-First Persistence

The default is relational storage as the authoritative system of record, prioritizing consistency and referential integrity over the flexibility of schema-less alternatives. Non-relational stores are adopted when a specific requirement cannot be met relationally, with the relational database remaining the system of record. The trade-off is less write-time flexibility, accepted because it prevents the casual inconsistency that erodes data quality over time.

## Domain–Persistence Segregation

Domain models are shaped around the business, not around the database schema, prioritizing model clarity over ORM convenience. The database enforces its own accountability through foreign key constraints, strict types, and indexes at the storage boundary, while the domain entity stays independent of that structure. Both sides model the same reality and are naturally compatible, but each is designed separately. The trade-off is more mapping between the two layers, accepted to keep each side free to evolve on its own terms.

## Event Sourcing as a Ready Option

Event sourcing is kept within reach as an architectural option, prioritizing the ability to reason about state transitions over the simplicity of a single-store model. Where complexity justifies it, the preferred shape is a split: an event-sourced command store that records every transition, paired with a state-projected query store for reads. This is not required universally — the architecture stays positioned so that a domain demanding temporal reasoning or replay can adopt event sourcing without restructuring. The trade-off is the added machinery of dual stores, taken on only where the value of replay is clear.

## Practices

### Real Components Over Mocks

Test against real software components, not mocks. When testing the database layer, run queries against an actual database instance — fabricate records through the test itself, clean up after each test. Fixtures and mocks hide integration failures that only surface in production.

### Minimum Test Harness

Every public function gets a concise unit test that snapshots its expected behavior — arguments in, values out. These snapshots form the minimum harness for quality: not coverage targets, but a readable contract that any developer or LLM can consume at a glance. Breadth across the public API, not depth per function.

### Browser Automation Tooling

Configure Playwright MCP or DevTools MCP in every environment where UI work happens. The AI agent must be able to launch a browser, navigate to any page, interact with elements, and take screenshots without manual setup steps. Verify the tooling works before starting UI development — a broken automation path means no AI-driven quality assurance.

### Dedicated AI Test Account

Maintain a dedicated test account with credentials accessible to the AI agent. The account has sufficient permissions to exercise all user-facing flows — sign-in, navigation, data manipulation, and settings. Credentials live in environment variables or secure configuration, never hardcoded in source. The account is provisioned as part of environment setup, not as an afterthought.

### Browser-Verified UI Changes

When a ticket touches user interface, verify the result in a real browser — render the page, interact with it, and confirm the visual outcome. Use Playwright or equivalent browser automation to let the LLM see and manipulate what the user sees. Screenshots and assertions against rendered state replace guesswork about markup correctness.

### Type-Level Quality Assurance

Push as many correctness checks as possible into the type system rather than runtime tests. Invalid states that can be made unrepresentable through types do not need spec files — the compiler catches them faster and with stronger consistency guarantees. Reserve runtime tests for behavior that types cannot express.

## Standards
