---
created_at: 2026-03-10T23:49:32+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Add E2E Assurance Policy to Planner's Testing Step

## Overview

Extend the Planner agent in the Trippin plugin to support end-to-end (E2E) testing as part of its Phase 2 testing responsibility. Currently, the Planner's test plan and validation steps are described generically ("create a test plan", "validate through testing") without specifying what kinds of testing the Planner should perform. For projects with a user-facing interface (e.g., a web application), the Planner should be able to run E2E tests using CLI-based tools like Playwright to validate the full user experience, not just unit-level or structural checks. Without this capability, the Planner cannot fulfill its "Explanatory Accountability" responsibility -- it cannot demonstrate to stakeholders that the system works as a whole.

The enhancement adds an "E2E Assurance Policy" to the trip-protocol skill and updates the Planner agent to include E2E testing in its Phase 2 testing workflow. The policy should be tool-agnostic (not locked to Playwright specifically) but use Playwright as the canonical example, since it provides a CLI interface (`npx playwright test`) that an AI agent can invoke directly.

## Key Files

- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining Phase 2 testing workflow; needs an E2E Assurance Policy section and updated testing steps
- `plugins/trippin/agents/planner.md` - Planner agent definition; Phase 2 section needs E2E testing guidance added to its test planning and validation responsibilities
- `plugins/trippin/commands/trip.md` - Trip command orchestration; Phase 2 Agent Teams instruction block references "create a test plan" and "validate through testing" which should mention E2E scope

## Related History

The trip workflow was recently implemented and has been iterated on with phase gate synchronization, model-before-design dependency enforcement, commit message rules, and deterministic review conventions. This ticket extends the Planner's Phase 2 testing capability, which has not been addressed by any previous ticket.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command, agents, and protocol including the Planner's generic Phase 2 testing role (direct predecessor)
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Added Phase 2 gate markers between test planning, implementation, review, and testing (same workflow area)
- [20260310221350-enforce-model-before-design-dependency-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221350-enforce-model-before-design-dependency-in-trip.md) - Enforced artifact dependencies in Phase 1; the test plan in Phase 2 should similarly reference all upstream artifacts

## Implementation Steps

1. **Add an E2E Assurance Policy section to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Place this after the Phase 2 section (or as a subsection within it). The policy should define:
   - **Purpose**: The Planner validates the full user experience, not just individual components. This closes the accountability loop -- the Planner who defined the direction also verifies the delivered experience matches it.
   - **When to apply**: When the project has a user-facing interface (web app, CLI tool, API with consumer workflows). Projects that are purely library/configuration may skip E2E.
   - **Tool guidance**: The Planner should use the project's E2E testing framework if one exists (detect by checking for `playwright.config.*`, `cypress.config.*`, or similar). If none exists, the Planner may propose adding one as part of the test plan. Playwright is the recommended default for web projects due to its CLI interface (`npx playwright test`).
   - **Scope**: E2E tests validate user-visible workflows end-to-end: navigation, form submission, data persistence, error states. They complement the Architect's structural review (which checks code quality) with experiential validation (which checks user outcomes).
   - **Constraint**: E2E tests must be runnable from the command line without a GUI. The Planner operates in a terminal environment and cannot interact with browser windows manually.

2. **Update the Planner's Phase 2 section** (`plugins/trippin/agents/planner.md`): Expand the two current Phase 2 items to include E2E awareness:
   - Item 1 ("Create a test plan"): Specify that the test plan should include E2E test scenarios when the project has a user-facing interface. The test plan artifact should list: which user workflows to cover, which E2E tool to use, and the CLI command to run tests.
   - Item 2 ("Validate through testing"): Specify that validation includes running E2E tests via CLI and interpreting results. If E2E tests fail, the Planner reports failures to the team lead with specific workflow breakdowns.

3. **Update the Phase 2 Step 1 (Test Planning) in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Add a note that the test plan should address both unit/integration testing scope and E2E testing scope. The Planner should assess the project type and determine appropriate E2E coverage.

4. **Update the Phase 2 Step 4 (Testing) in the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Add a note that testing validation may include running E2E test suites and reporting results. If E2E tests are part of the test plan, the Planner runs them here.

5. **Update the Agent Teams instruction block in the trip command** (`plugins/trippin/commands/trip.md`): In the Phase 2 instructions, expand step 1 ("Ask Planner to create a test plan") to mention that the test plan should include E2E scenarios where applicable. Expand step 4 ("Ask Planner to validate through testing") to mention E2E test execution.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -199,6 +199,32 @@
 - Planner re-tests → **GATE**: Leader confirms re-test complete
 - Continue until all pass

+## E2E Assurance Policy
+
+The Planner's testing responsibility extends beyond unit and integration checks to include **end-to-end (E2E) validation** of the full user experience. This is the mechanism through which the Planner fulfills Explanatory Accountability: demonstrating that the delivered system satisfies the stakeholder-facing direction, not just the technical model and design.
+
+### When to Apply
+
+E2E testing applies when the project has a user-facing interface:
+- Web applications (browser-based UI)
+- CLI tools (terminal-based interaction)
+- API services with consumer-facing workflows
+
+Projects that are purely library or configuration may skip E2E testing. The Planner assesses applicability during test planning.
+
+### Tool Selection
+
+The Planner should detect the project's existing E2E framework by checking for configuration files (e.g., `playwright.config.*`, `cypress.config.*`, `wdio.conf.*`). If no framework exists, the Planner may propose one in the test plan. **Playwright** is the recommended default for web projects due to its headless CLI interface.
+
+### Constraints
+
+- E2E tests must be runnable from the command line (`npx playwright test`, `npx cypress run`, etc.) without requiring a GUI
+- The Planner operates in a terminal environment and cannot interact with browser windows manually
+- E2E test results must be interpretable from CLI output (exit codes, test report summaries)
+
+### Scope
+
+E2E tests validate user-visible workflows end-to-end: navigation, form submission, data persistence, authentication flows, error states. They complement the Architect's structural review (which checks code integrity) with experiential validation (which checks user outcomes). The Planner defines which workflows to cover in the test plan and runs them during the testing step.
+
 ## Moderation Protocol
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -31,8 +31,10 @@
 ## Phase 2: Implementation

-1. Create a test plan aligned with the approved Direction, Model, and Design
-2. Validate the Constructor's implementation through testing
+1. Create a test plan aligned with the approved Direction, Model, and Design. When the project has a user-facing interface, include E2E test scenarios specifying: which user workflows to cover, which E2E tool to use (detect existing framework or propose Playwright), and the CLI command to run tests.
+2. Validate the Constructor's implementation through testing. This includes running E2E tests via CLI when the test plan includes them. Report failures with specific workflow breakdowns to the team lead.
+
+Refer to the **E2E Assurance Policy** in the trip-protocol skill for tool selection, scope, and constraints.
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -82,9 +82,9 @@
 > **Phase 2 - Implementation (Outer Loop)**:
-> 1. Ask Planner to create a test plan → **commit**
+> 1. Ask Planner to create a test plan (including E2E scenarios if the project has a user-facing interface) → **commit**
 > 2. Ask Constructor to implement the program → **commit**
 > 3. Ask Architect to review structural integrity → **commit**
-> 4. Ask Planner to validate through testing → **commit**
+> 4. Ask Planner to validate through testing (including E2E test execution if included in the test plan) → **commit**
 > 5. Iterate until all agents approve → **commit each iteration**
```

## Considerations

- The E2E Assurance Policy is intentionally tool-agnostic but recommends Playwright as the default. If a project uses a different framework (Cypress, WebdriverIO, etc.), the Planner should detect and use it. The detection heuristic (checking for config files) may miss non-standard setups. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The Planner agent operates within an AI context window and invokes tools via Bash. Running `npx playwright test` requires that the project's dependencies are installed and that a headless browser is available in the environment. If the environment lacks browser binaries, Playwright's `npx playwright install` must run first. The Planner should handle this in the test plan or during test execution. (`plugins/trippin/agents/planner.md`)
- E2E tests can be slow and flaky. The policy should acknowledge that test failures need triage -- a failing E2E test may indicate a real bug, an environment issue, or a test fragility problem. The Planner should distinguish between deterministic failures (real bugs) and non-deterministic failures (flakiness) when reporting results. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The scope of E2E testing overlaps with the Architect's Phase 2 review (structural integrity). The boundary should be clear: the Architect reviews code structure and type safety, while the Planner validates user-visible behavior. There should be no expectation that the Architect runs E2E tests. (`plugins/trippin/agents/architect.md`, `plugins/trippin/agents/planner.md`)
- For projects that are purely configuration or plugin development (like this workaholic repository itself), E2E testing does not apply. The "When to Apply" clause handles this, but the Planner should not feel obligated to force E2E testing into every trip session. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- Phase 2 currently does not specify where the test plan artifact is stored. It should likely go in the directions area (since the Planner authors it) or a new `tests/` directory under the trip path. This is a pre-existing gap not specific to this ticket but worth noting. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 175-205)
