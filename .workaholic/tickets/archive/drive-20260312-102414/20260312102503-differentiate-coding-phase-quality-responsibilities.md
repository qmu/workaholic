---
created_at: 2026-03-12T10:25:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 1h
commit_hash: 31377ed
category: Changed
---

# Differentiate Coding Phase Quality Assurance Responsibilities

## Overview

Clarify and enforce distinct quality assurance roles for each agent during the Coding Phase. Currently, the Planner and Constructor both broadly "review" and "test" artifacts, but their responsibilities overlap and lack clear boundaries. The Architect's review role is described generically as "structural integrity" without prohibiting it from performing direct testing actions.

The new model establishes three orthogonal quality assurance approaches:

1. **Planner (E2E/External Testing)**: The Planner focuses exclusively on end-to-end style testing of external interfaces. For CLI projects, the Planner executes the program and verifies its output. For web applications, the Planner launches a browser via Playwright or CLI-MCP and interacts with the page. The Planner does NOT run unit tests, compiler checks, or internal quality verification. The Planner treats the system as a black box and validates it from the user's perspective.

2. **Constructor (Internal Testing)**: The Constructor owns internal quality verification: unit tests, integration tests, compiler/type checks, linting, and code-level quality assurance. The Constructor ensures the code is correct and sound from the inside. The Constructor does NOT perform E2E testing -- that is the Planner's domain.

3. **Architect (Discovery-Based Review)**: The Architect conducts quality assurance through codebase discovery and analysis, NOT through direct testing actions. The Architect reads the Constructor's changes, performs code review, architectural review, and model checking (verifying the implementation matches the Model). The Architect does NOT run tests (neither E2E nor unit) and does NOT execute the program. The Architect's quality assurance is purely analytical: reading code, checking structure, verifying patterns.

This separation ensures three distinct quality signals that together provide comprehensive coverage: the Planner proves the system works for users, the Constructor proves the code is internally correct, and the Architect proves the implementation is structurally sound.

## Key Files

- `plugins/trippin/agents/planner.md` - Planner agent; Coding Phase section (lines 66-71) needs explicit restriction to E2E/external testing only, with a prohibition on running unit tests or compiler checks
- `plugins/trippin/agents/constructor.md` - Constructor agent; Coding Phase section (lines 48-51) needs explicit addition of internal testing responsibility (unit tests, compiler checks) after implementation, with a prohibition on E2E testing
- `plugins/trippin/agents/architect.md` - Architect agent; Coding Phase section (lines 52-57) needs explicit scoping to discovery-based review only (code review, architectural review, model checking), with a prohibition on running any tests or executing the program
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill; the Coding Phase Review and Testing section (lines 246-260) needs restructuring to reflect three distinct quality tracks; the E2E Assurance Policy section (lines 316-341) may need reinforcement that E2E is exclusively the Planner's domain
- `plugins/trippin/commands/trip.md` - Trip command; the Agent Teams instruction block Coding Phase section (lines 100-108) needs updating to describe three distinct quality roles during review/testing

## Related History

The Coding Phase quality workflow evolved through several iterations: the E2E assurance policy established the Planner's E2E testing role, and the concurrent coding phase restructured agents to work in parallel. However, neither change explicitly prohibited agents from crossing into each other's quality domains. The Constructor's responsibility has always been described as "implementation" without specifying that internal testing (unit tests, compiler checks) is also its domain. The Architect's "structural review" has been vague enough that it could be interpreted as including running tests.

Past tickets that touched similar areas:

- [20260310234932-add-e2e-assurance-policy-to-planner.md](.workaholic/tickets/archive/drive-20260310-220224/20260310234932-add-e2e-assurance-policy-to-planner.md) - Added E2E Assurance Policy establishing the Planner's E2E testing capability (this ticket builds on that by making E2E the Planner's exclusive quality domain and prohibiting it from internal testing)
- [20260311215034-concurrent-coding-phase-agents.md](.workaholic/tickets/archive/drive-20260311-125319/20260311215034-concurrent-coding-phase-agents.md) - Restructured Coding Phase for concurrent agent work (same Coding Phase sections being refined; the concurrent launch included Planner test planning and Architect codebase discovery, which this ticket further differentiates)
- [20260311215505-enforce-planner-business-focus-in-planning-phase.md](.workaholic/tickets/archive/drive-20260311-125319/20260311215505-enforce-planner-business-focus-in-planning-phase.md) - Enforced Planner's business focus in Planning Phase (same pattern of explicit behavioral boundaries, now applied to the Coding Phase quality role)
- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Repositioned agents along business-vision/structural-bridge/technical-accountability spectrum (this ticket extends that differentiation into the Coding Phase quality domain)
- [20260311213007-phase-rollback-from-coding-to-planning.md](.workaholic/tickets/archive/drive-20260311-125319/20260311213007-phase-rollback-from-coding-to-planning.md) - Added rollback mechanism triggered by quality issues (the clearer quality roles will make rollback triggers more specific: Planner rollback from E2E failures, Constructor from internal test failures, Architect from structural review failures)

## Implementation Steps

1. **Update the Planner agent Coding Phase section** (`plugins/trippin/agents/planner.md`): Revise the Coding Phase responsibilities to explicitly scope the Planner to E2E and external interface testing only. Add a clear prohibition: the Planner does NOT run unit tests, compiler checks, linting, or any internal quality verification. The Planner treats the implementation as a black box and validates it from the user perspective. For CLI projects, the Planner executes the program and verifies output. For web applications, the Planner uses Playwright or CLI-MCP to interact with the UI. The Planner's test plan should describe E2E scenarios only, not internal test suites. Retain the reference to the E2E Assurance Policy.

2. **Update the Constructor agent Coding Phase section** (`plugins/trippin/agents/constructor.md`): Add an explicit internal testing responsibility after implementation. The Constructor runs unit tests, integration tests, compiler/type checks, and linting to verify code quality from the inside. This happens as part of the implementation step (the Constructor is expected to write and run tests as part of building the program). Add a clear prohibition: the Constructor does NOT perform E2E testing or external interface validation -- that is the Planner's domain. The Constructor's quality assurance is code-internal.

3. **Update the Architect agent Coding Phase section** (`plugins/trippin/agents/architect.md`): Explicitly scope the Architect's quality assurance to discovery-based review only. The Architect discovers the codebase changes made by the Constructor, performs code review (reading diffs, checking patterns, evaluating naming), architectural review (verifying the implementation respects the structural model, boundaries, and decomposition), and model checking (verifying the implementation matches the Model artifact). Add a clear prohibition: the Architect does NOT run any tests (neither E2E nor unit), does NOT execute the program, and does NOT compile the code. The Architect's quality assurance is purely analytical.

4. **Restructure the Review and Testing subsection in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Update the Coding Phase Review and Testing section to describe three distinct quality tracks that happen during the review/testing step:
   - Architect performs discovery-based code review and architectural review (no test execution)
   - Planner performs E2E testing of external interfaces (no unit tests)
   - Constructor verifies internal test results (unit tests, compiler checks already run during implementation)
   Update the Iteration subsection to clarify that when issues are found, the Constructor revises implementation (including re-running internal tests), the Architect re-reviews the changes, and the Planner re-runs E2E tests.

5. **Update the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): Revise the Coding Phase steps 3 and 4 to reflect the three distinct quality roles. Step 3 should describe the Architect's discovery-based review (not "structural integrity" generically but code review, architectural review, and model checking without running tests). Step 4 should describe the Planner's E2E validation (external interface testing only). Add a note that the Constructor is expected to have run internal tests (unit, compiler) as part of step 1 implementation.

6. **Reinforce the E2E Assurance Policy** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Add a boundary statement to the E2E Assurance Policy clarifying that E2E testing is exclusively the Planner's domain and that other agents should not duplicate this work. Add a parallel statement that internal testing (unit tests, compiler checks) is exclusively the Constructor's domain.

## Patches

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -64,9 +64,11 @@
 ## Coding Phase

-1. Begin test planning immediately when the Coding Phase starts, concurrent with the Constructor's implementation and the Architect's codebase discovery. Build the development environment by running the appropriate build/start scripts. Verify the dev environment is accessible using Playwright CLI MCP. Examine the target website using Playwright CLI MCP to plan E2E test scenarios. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
-2. Once the Constructor's implementation is complete, validate it through testing. This includes running E2E tests via CLI when the test plan includes them. Report failures with specific workflow breakdowns to the team lead.
+1. Begin test planning immediately when the Coding Phase starts, concurrent with the Constructor's implementation and the Architect's codebase discovery. Build the development environment by running the appropriate build/start scripts. Verify the dev environment is accessible using Playwright CLI MCP. Examine the target website using Playwright CLI MCP to plan E2E test scenarios. Create an E2E test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
+2. Once the Constructor's implementation is complete, validate it through E2E testing of external interfaces only. For CLI projects, execute the program and verify its output and behavior. For web applications, use Playwright or CLI-MCP to interact with the UI, click elements, fill forms, and verify page state. Treat the implementation as a black box -- validate what users can see and interact with. Report E2E failures with specific workflow breakdowns to the team lead.
 3. If testing reveals missing requirements or business scenarios not covered by the direction, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the requirement gaps
 4. When another agent proposes a rollback, evaluate from your business vision perspective and vote support or oppose
+
+**Scope boundary**: The Planner does NOT run unit tests, compiler checks, linting, or internal quality verification. Internal testing is the Constructor's responsibility. The Planner's quality assurance is exclusively external: proving the system works from the user's perspective.

 Refer to the **E2E Assurance Policy** in the trip-protocol skill for tool selection, scope, and constraints.
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -46,7 +46,9 @@
 ## Coding Phase

-1. Implement the program based on the approved Design and Model. Implementation begins immediately when the Coding Phase starts, concurrent with the Planner's test planning and the Architect's codebase discovery.
+1. Implement the program based on the approved Design and Model. Implementation begins immediately when the Coding Phase starts, concurrent with the Planner's E2E test planning and the Architect's codebase discovery. As part of implementation, write and run internal tests: unit tests, integration tests, compiler/type checks, and linting. Internal testing is the Constructor's quality assurance domain -- verify code correctness, type safety, and adherence to coding standards from the inside.
 2. If implementation reveals the design is not feasible at the required quality level, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific evidence of the gap between design and implementability
 3. When another agent proposes a rollback, evaluate from your technical accountability perspective and vote support or oppose
+
+**Scope boundary**: The Constructor does NOT perform E2E testing or external interface validation -- that is the Planner's responsibility. The Constructor's quality assurance is code-internal: unit tests, compiler checks, linting, and integration tests that verify the implementation is correct and sound from the inside.
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -52,7 +52,9 @@
 ## Coding Phase

 1. Begin codebase discovery immediately when the Coding Phase starts, concurrent with the Constructor's implementation and the Planner's test planning. Read the existing codebase structure, patterns, and conventions to prepare modeling-related artifacts that will inform the structural review.
-2. Once the Constructor's implementation is complete, review it for structural integrity against the Model
-3. If structural review reveals the model cannot support the implementation being built, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific structural evidence
-4. When another agent proposes a rollback, evaluate from your structural bridge perspective and vote support or oppose
+2. Once the Constructor's implementation is complete, perform discovery-based quality review. This consists of three activities:
+   - **Code review**: Read the Constructor's diffs and changes. Check naming conventions, code patterns, error handling, and adherence to project conventions.
+   - **Architectural review**: Verify the implementation respects the structural model, module boundaries, layer separation, and decomposition defined in the Model artifact.
+   - **Model checking**: Verify the implementation faithfully translates the business intent from the Direction through the structural Model into working code. Check that the translation chain (Direction -> Model -> Implementation) maintains fidelity.
+3. If structural review reveals the model cannot support the implementation being built, propose a rollback to the Planning Phase by writing a rollback proposal artifact with specific structural evidence
+4. When another agent proposes a rollback, evaluate from your structural bridge perspective and vote support or oppose
+
+**Scope boundary**: The Architect does NOT run tests (neither E2E nor unit), does NOT execute the program, and does NOT compile the code. The Architect's quality assurance is purely analytical: discovering codebase changes and reviewing them for structural integrity, pattern adherence, and translation fidelity. Test execution belongs to the Planner (E2E) and Constructor (unit/internal).
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -244,11 +244,17 @@
 ### Review and Testing

-Once the Constructor's implementation is complete and the Planner's test plan is ready:
+Once the Constructor's implementation is complete and the Planner's E2E test plan is ready, three distinct quality tracks execute:

-**Architect** reviews the implementation for structural integrity against the Model.
+**Architect** performs discovery-based review: reads the Constructor's code changes, conducts code review and architectural review, and verifies model fidelity. The Architect does NOT run tests or execute the program.
 - **GATE**: Leader confirms review is complete before proceeding

-**Planner** validates the implementation against the test plan. This includes running E2E tests via CLI when the test plan includes them.
+**Planner** validates the implementation through E2E testing of external interfaces only. For CLI projects, executes the program and verifies output. For web applications, uses Playwright or CLI-MCP to interact with the UI. The Planner does NOT run unit tests or compiler checks.
 - **GATE**: Leader confirms testing is complete before proceeding
+
+**Constructor** reports internal test results (unit tests, compiler checks, linting) from the implementation step. If internal tests were not yet comprehensive, the Constructor runs additional internal verification at this point.
+- **GATE**: Leader confirms internal testing is complete before proceeding
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -100,10 +100,11 @@
 > **Coding Phase - Implementation (Outer Loop)**:
 > 1. **Concurrent launch** --- ask all three agents to begin work simultaneously:
->    - Ask Constructor to implement the program -> **commit**
+>    - Ask Constructor to implement the program, including writing and running internal tests (unit tests, compiler checks, linting) -> **commit**
 >    - Ask Planner to create a test plan: build the dev environment, verify it is running (Playwright CLI MCP), plan E2E scenarios by examining the target website (Playwright CLI MCP) -> **commit**
 >    - Ask Architect to discover the codebase and prepare modeling-related artifacts for structural review -> **commit**
 > 2. **WAIT FOR ALL THREE** --- do NOT proceed until Constructor, Planner, and Architect have all completed their concurrent tasks
-> 3. Ask Architect to review the Constructor's implementation for structural integrity -> **commit**
-> 4. Ask Planner to validate the implementation through testing (including E2E test execution if included in the test plan) -> **commit**
+> 3. Ask Architect to review the Constructor's implementation through codebase discovery: code review, architectural review, and model checking (no test execution) -> **commit**
+> 4. Ask Planner to validate the implementation through E2E testing of external interfaces only (no unit tests) -> **commit**
+> 5. Ask Constructor to report or run additional internal tests if needed -> **commit**
 > 5. Iterate until all agents approve -> **commit each iteration**
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch reinforces the E2E Assurance Policy with boundary statements.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -339,3 +339,9 @@
 E2E tests validate user-visible workflows end-to-end: navigation, form submission, data persistence, authentication flows, error states. They complement the Architect's structural review (which checks code integrity) with experiential validation (which checks user outcomes). The Planner defines which workflows to cover in the test plan and runs them during the testing step.
+
+### Quality Domain Boundaries
+
+The three agents provide orthogonal quality signals during the Coding Phase:
+- **Planner**: E2E testing of external interfaces (exclusively). Does not run unit tests or compiler checks.
+- **Constructor**: Internal testing (unit tests, integration tests, compiler checks, linting). Does not perform E2E testing.
+- **Architect**: Discovery-based analytical review (code review, architectural review, model checking). Does not run any tests or execute the program.
```

## Feedback

### Refactor for Conciseness and Symmetry (2026-03-12)

The agent markdown files are too large. Refactor with:

1. **Symmetric Syntax**: Use the same headings and schema across all three agent files. Every agent file should have identical section structure.

2. **Symmetric Semantics**: Each role should have contrasting viewpoints that protect specific values. The Planner and Constructor should have different but parallel concerns representing their roles.

3. **Conciseness**: Remove redundant, recurring, or duplicated expressions. Make text more concise and well-organized.

4. **Review Policy**: Each agent reviews based on the values they are responsible for protecting. If a point is not their domain, they can ignore it. However, careless mistakes should always be pointed out. Ultimately, each agent must represent their assigned role.

## Considerations

- The Constructor currently has no explicit testing responsibility in its Coding Phase section -- it only says "Implement the program." Adding internal testing as part of implementation is natural (good developers write and run tests while coding), but it changes the Constructor's scope from pure implementation to implementation-plus-verification. The Constructor's "Technical Accountability" philosophy supports this: owning what ships means owning the internal quality proof. (`plugins/trippin/agents/constructor.md` lines 48-51)
- The Architect's prohibition on running tests may feel restrictive when the Architect discovers a potential issue during code review that could be quickly verified by running a test. The rationale is that the Architect's value comes from its unique perspective (structural analysis), not from duplicating testing work that the Planner and Constructor already do. If the Architect suspects a test failure, it should note the concern in its review for the relevant agent (Planner or Constructor) to investigate. (`plugins/trippin/agents/architect.md` Coding Phase section)
- The Planner's E2E-only restriction means the Planner cannot catch issues that only manifest in unit tests (e.g., an edge case in a utility function). This is intentional: the Planner represents the business/user perspective and should only verify what users can observe. If a unit test failure does not manifest as observable behavior, it is the Constructor's responsibility to catch it. If it does manifest as observable behavior, the Planner's E2E tests will catch it. (`plugins/trippin/agents/planner.md` Coding Phase section)
- The trip-protocol Review and Testing section currently has two GATE markers (Architect review complete, then Planner testing complete). Adding a third GATE for Constructor internal test reporting changes the convergence pattern. An alternative is to keep the Constructor's internal testing as part of the implementation step (step 1 of concurrent launch) rather than adding a separate review/testing step. The patches above use both approaches: the Constructor runs tests during implementation and optionally reports additional results during review/testing. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 246-260)
- The iteration loop (Constructor revises, Architect re-reviews, Planner re-tests) needs updating to include the Constructor re-running internal tests after revision. Currently the iteration only mentions Constructor revising implementation, which implicitly includes re-running tests. Making this explicit strengthens the separation. (`plugins/trippin/skills/trip-protocol/SKILL.md` Iteration subsection)
- For projects that have no user-facing interface (libraries, configuration), the Planner's E2E testing does not apply (per the existing E2E Assurance Policy "When to Apply" clause). In these cases, the Planner may need an alternative quality assurance approach, such as reviewing documentation, verifying API contracts, or checking configuration validity. The ticket does not address this edge case -- the E2E Assurance Policy's existing "skip E2E for library/configuration projects" clause still applies. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 326-332)
- The Architect's "model checking" responsibility (verifying Direction -> Model -> Implementation translation fidelity) is a new explicit capability. Previously the Architect only reviewed "structural integrity against the Model." Model checking adds a richer verification dimension: the Architect traces the business intent from the Planner's Direction through the Model and into the implementation, checking for translation losses at each step. (`plugins/trippin/agents/architect.md` Coding Phase section)

## Final Report

### Changes

- `plugins/trippin/agents/planner.md` — Refactored to symmetric structure (67 lines). Added QA role: E2E/external testing only. Added Review Policy based on business value protection. Merged Protocol/Review Output/Synchronization into unified Rules section.
- `plugins/trippin/agents/constructor.md` — Refactored to symmetric structure (62 lines). Added QA role: internal testing (unit tests, compiler checks, linters). Added Review Policy based on engineering quality protection. Added step 2 for internal quality checks after implementation.
- `plugins/trippin/agents/architect.md` — Refactored to symmetric structure (61 lines). Added QA role: analytical review only (no test execution). Added Review Policy based on structural integrity protection. Clarified step 2 as code review + architectural review + model checking.
- `plugins/trippin/skills/trip-protocol/SKILL.md` — Added Quality Assurance Differentiation table with non-overlap rules. Updated Concurrent Launch, Review and Testing, Iteration sections. Fixed E2E Assurance Policy preamble to reflect exclusive Planner domain. Updated commit points.
- `plugins/trippin/commands/trip.md` — Updated Coding Phase instructions with QA role summary and differentiated agent responsibilities.

### Insights

- Symmetric syntax (identical headings) across agent files makes it easy to compare roles side-by-side and ensures no agent gets special treatment in structure.
- The "careless mistake" clause in Review Policy prevents agents from completely ignoring issues outside their domain while maintaining role focus.
