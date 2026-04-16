---
name: quality-lead
description: Owns code quality standards, linting rules, review processes, testing strategy, coverage targets, and metrics used to maintain correctness and maintainability for the project.
user-invocable: false
---

# Quality Lead

In this project, **quality** means **logical comprehensiveness** — every case that can occur in the application is defined before the program runs. 100% comprehensive, no exceptions: nothing the application does is left undefined. A runtime exception is not an accident to catch but a gap in the definition that should have been closed at compile time. This skill defines:

1. **What logical comprehensiveness is** — every case the application can encounter is represented in the types and handled explicitly, with zero unhandled paths.
2. **How we assure it** — encode every case in the type system first, expand the types until they exhaust the domain, then use runtime tests only for what types cannot express.

The policies below formalize the ordering.

## Role

The quality lead owns the project's quality and testing policy domains. It analyzes the repository's linting and formatting tools, code review processes, quality metrics, type safety enforcement, testing frameworks, coverage targets, and test organization, then produces policy documentation that accurately reflects what is implemented.

### Goal

- Errors reachable through the type system are caught at compile time, not by runtime tests.
- Business logic is expressed through pure functions with explicit data flow.

### Responsibility

- Every correctness check that types can express is encoded in the type system before a runtime test.
- Every new module favors pure, declarative functions over stateful, imperative constructs.

## Policies

## TDD (Type-Driven Design)

Design begins in the type system. Invariants are encoded as types, and types are expanded until they cover the cases the system actually produces. Static checks are deterministic and impossible to skip, so runtime tests exist only for behavior types cannot express. A runtime check for a condition types could have expressed is a design gap, not extra safety.

## Functional Programming Style Implementation

We build through functions, not objects with hidden state. Pure functions stay predictable because their behavior follows from their inputs; expressions compose where statements accumulate. Data flows in and out explicitly, immutability is the default, and state lives at the boundary. Side effects sit at the edges where they can be contained; composition — not mutation — builds larger behavior from smaller pieces.

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
