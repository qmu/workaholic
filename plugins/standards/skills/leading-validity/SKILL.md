---
name: leading-validity
description: Owns logical validity — type-driven design, functional style, layer segregation, data persistence strategy, and the testing strategy that covers what types cannot express.
user-invocable: false
---

# Leading Validity

This skill frames validity as **logical comprehensiveness** — the cases that can occur in the application are defined before the program runs. Other framings of validity are equally defensible; the priority here is static predictability because it makes gaps visible at compile time rather than at runtime. This skill defines:

1. **What logical validity is** — every case the application can encounter is represented in the types and handled explicitly, without unhandled paths.
2. **How it is assured** — cases are encoded in the type system first, types are expanded until they exhaust the domain, and runtime tests cover what types cannot express.

The policies below formalize this ordering.

## Role

This leading skill owns the project's logical-validity policy domain. It derives its viewpoint directly from the repository's type safety enforcement, linting and formatting tools, code review processes, layer segregation, data persistence strategy, testing frameworks, coverage targets, and test organization, and produces policy documentation that accurately reflects what is implemented.

### Goal

The goal of validity leadership is logical comprehensiveness — the program is a faithful representation of its domain, with every case the domain admits accounted for before users encounter the consequences of one that wasn't. From this viewpoint, correctness is a property the program carries by construction, not a hope confirmed by whatever cases someone happened to try. The program is complete when its behavior follows from the shape of its definitions rather than from the diligence of its readers.

### Responsibility

The responsibility of validity leadership is to refuse the gaps that the language itself could have closed. It keeps domain reasoning separable from the tools that store and serve it, keeps correctness claims provable rather than asserted, and keeps unhandled paths from accumulating in the dark. What can be made true by construction must be, so that runtime behavior is a consequence of the design rather than a bet placed on it.

## Policies

## TDD (Type-Driven Design)

Type-driven design encodes invariants as types before writing implementations. Runtime verification, property testing, and contract testing are all valid alternatives. The priority is types because they provide deterministic, unskippable feedback at compile time. Runtime tests remain in scope for behavior types cannot express.

## Functional Programming Style

Functional style centers code around pure functions, immutable data, and explicit data flow. Object-oriented and imperative styles are proven approaches with their own strengths — encapsulation, familiar patterns, direct state manipulation. The preference is functions because purity makes behavior follow from inputs alone, simplifying reasoning and composition. The cost is occasional verbosity where imperative code would be more direct.

## Ours/Theirs Layer Segregation

Layer segregation separates domain logic (ours) from vendor infrastructure (theirs) behind declared interfaces. Tighter coupling between domain and infrastructure is a valid choice that reduces indirection and speeds initial development. The priority is the separation because it keeps the domain testable without infrastructure and makes vendor code replaceable independently.

## Relational-First Persistence

Relational-first persistence defaults to a relational database as the system of record. Document stores, key-value stores, and graph databases solve problems that relational models handle awkwardly. The default is to relational because it enforces consistency and referential integrity at the storage boundary. Non-relational stores are adopted when a specific requirement cannot be met relationally.

## Domain–Persistence Segregation

Domain-persistence segregation shapes domain models around the business, not around the database schema. Active Record and similar patterns that unify domain and persistence are simpler to start with and widely successful. The separation is chosen so each side can evolve on its own terms, at the cost of more mapping between layers.

## Event Sourcing as a Ready Option

Event sourcing records every state transition rather than only the latest snapshot. Snapshot-only storage is simpler, cheaper to operate, and sufficient for most domains. It is kept within reach so that domains demanding temporal reasoning or replay can adopt it without restructuring.

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
