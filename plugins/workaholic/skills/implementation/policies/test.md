---
title: Active Use of Unit Tests
slug: test
category: implementation
source: https://qmu.co.jp/implementation/test
---

# Active Use of Unit Tests

Testing has several distinct purposes — regression detection, coverage management, describing behavior, verifying behavior during development, and so on. Beyond combining these to underpin quality, we make it our default to write unit tests actively from an early stage of development, and we do not shy away from writing tests that are difficult to run in CI.

Unit tests serve two roles. The first is the role of a foothold (足がかり). Before a subcomponent has an external interface (HTTP / CLI / UI), we use a real database or a real API to verify its execution results under conditions close to the actual runtime environment, efficiently confirming both the correctness of internal implementation that cannot yet be reached from the outside and whether the connection to the genuine dependencies is established. Even for tests that we will ultimately discard or switch over to being skipped, we actively write them as a foothold in the early phase of implementation. The second is the role of regression (回帰). Tests in the domain layer are maintained beyond the development period, together with the lifetime of the product.

Complex E2E tests, as well as integration tests run against the real thing, are also taken in as an extension of this active stance. Our aim is a development culture in which writing tests is not felt as friction.

## Goal (目標)

The situation this policy aims to achieve is the dissolution of the current state in which humans are asked to check completeness as part of the tools invoked by AI. Our software production envisions a form in which humans spend more time exchanging qualitative evaluations — rather than checks of completeness — with the AI, raising the number of turns in the feedback loop and building up something better.

We believe that if we keep accumulating tests and implementations written against the real thing as footholds, the ground on which the AI itself can take over the checking of completeness will broaden, and human time will gather on the side of qualitative evaluation.

## Responsibility (責務)

The situation this policy aims to prevent is a state in which developers and the AI come to believe "the codebase is healthy" solely on the fact that a large number of tests written by AI coding agents are passing. An operation that treats counts or green statuses as a substitute for reliability — without it being visible what each individual test verifies, whether tests are duplicated, or whether they traverse meaningful paths — leads directly to false reassurance, so we do not permit it.

## Practices (実践)

### Test against the real thing whenever possible (可能な限り実物を用いてテストする)

Our policy is to test against the real thing (実物) whenever possible. For a database layer we choose to issue queries against an actual database; for an external API client we send requests to the integration partner's real API (such as a sandbox environment); for UI we render in a real browser.

Tests that use mocks tend to fall into "mocks that exist to make the test pass," and under a regime in which coding agents are the primary authors of tests, that tendency tends to accelerate. Moreover, confirming that the connection to external dependencies is correctly established is one of the principal purposes of testing. Even if you pass a test by connecting to something that is not the genuine article, the significance of the test itself thins out. Rather than confining ourselves to verifying the domain layer, we choose to test against the real thing as the place to confirm whether the implementation of the infrastructure layer correctly integrates with external dependencies.

### Leave regression tests in the domain layer (ドメイン層には回帰テストを残す)

For many of the tests written as footholds, the default treatment is that they can be removed from CI once the external interface is in place. However, for the domain layer — unit tests in which side effects are parameterized and which are kept in a form that passes green with fake implementations (see Domain Layer Isolation / ドメイン層の分離) — our policy is to continue putting them into CI for regression detection. Because domain-layer tests do not need to run against the real thing, run fast, and are easy to read as descriptions of behavior, they are an area where the cost of keeping them around for a long time is low.

Tests written as footholds (boundaries run against the real thing, integration paths, UI verification through a browser) have no inherent necessity to remain in CI at all times, whereas domain-layer regression tests are distinguished as tests that are maintained beyond the development period, together with the lifetime of the product.

### AI agents write tests by default (テストは AI エージェントが既定で書く)

In our development workflow, we adopt a division in which the developer conveys "what to build" (intent, requirements, what is happening in production, and so on) to the AI coding agent, while "how to build it" — the procedure, including writing tests — is assembled by the agent following default conventions. Rather than a form in which the developer instructs "write tests too" every time, we describe the writing of unit tests as the agent's default behavior in skill files and plugin conventions.

This lets developers concentrate on conveying intent, while unit tests are automatically assembled as the agent's default behavior. Without bearing the burden of instructing "write tests / don't write tests" each time, we aim for a state in which verification of behavior during development, regression detection in the domain layer, and description of behavior are all provided on the agent's side.

### Operating real-thing tests (実物テストの運用)

Tests run against the real thing are operated in two forms depending on the environment.

When the real thing can be run in CI — for targets where a container can be started (for example, a database), we stand up the real thing and run the tests in CI as well, and use that directly as regression verification. In database tests, records are generated by the test itself and cleaned up per test. We avoid dependence on a shared dataset, because it makes tests order-dependent and destroys reproducibility.

When the real thing cannot be run in CI — for targets where standing up the real thing in CI is not practical (heavy external services, external APIs that require connecting to a staging environment, and the like), we take the form of writing tests using the real thing during development and switching them to a skip setting before committing. Even an operation of testing against the real thing during development and then committing carries sufficient significance as verification during development.

### Write down the behavior of public functions (公開関数の振る舞いを書き残す)

We write down the behavior of public functions as tests, keeping a state in which new joiners and AI agents can read off "what the code does" from the tests.

- Write at least one 3–5 line unit test per public function.
- Align test names into a form that reads as a description of behavior.
- Keep additional tests written for the sake of pursuing coverage within the range that protects the readability of the tests.

### Pursue quality over quantity (数よりも質を追求する)

"Quality" here refers to the precision of aim in deciding which conditions to pick up as tests. Rather than increasing the count, or aimlessly lining up one normal-case and one abnormal-case test each, we prioritize deliberately targeting the boundary conditions that should be verified. The idea is to find the edges that can occur when a user touches the service — empty, maximum, minimum, inputs that straddle boundaries, reorderings, race conditions, occasions of failure, and so on — and to pick exactly those up and leave them behind as tests.

We observe coverage as an evaluation metric for existing tests, and we do not increase tests just to fill in the numbers.

### E2E testing carried out with AI (AI と進める E2E テスト)

With the arrival of AI coding agents, we have gained two forms of E2E testing. One-shot behavior verification is a form in which the AI directly operates the browser via the Playwright CLI or Chrome DevTools for agents, finishing a one-off verification on the spot. E2E that writes and runs test code is a form in which, because the AI can now grasp screen transitions and displayed content while operating the browser, tests can be written more accurately and quickly than before. We use the two according to purpose and actively take in E2E run against actual behavior.

The correctness of UI changes is judged not by eyeballing the markup but by assertions against the rendered state, and we leave screenshots in the PR as needed. The same mechanism can be reused for the runtime verification path of Accessibility-First (アクセシビリティ・ファースト).

### AI-only test accounts (AI 専用テストアカウント)

To carry browser automation past the point of login, we prepare an AI-only test account in each environment.

- The account is equipped with the permissions to execute all user flows — signing in, transitions, data operations, and configuration changes.
- Credentials are stored in environment variables or in secure configuration (Secrets Manager, under a gitignored .dev.vars, and the like) and are not written directly into source code (following the credential management of the Safety policy / 安全性ポリシー).
- The account is prepared as part of building the environment (環境構築) rather than as incidental work, and is included in the Day 1 setup procedure.

### Tests must not impede design improvement (テストは設計改善を妨げない)

When a test breaks during refactoring, it is either (a) the expected behavior changed, or (b) the test is over-coupled to the implementation. If the latter, we choose to rewrite the test. We keep the positioning that tests exist not to bind the design, but to write down behavior.
