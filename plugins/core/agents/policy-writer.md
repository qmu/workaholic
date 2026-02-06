---
name: policy-writer
description: Update .workaholic/policies/ with policy documents by orchestrating 7 parallel policy-analyst subagents.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - gather-git-context
  - analyze-policy
  - validate-writer-output
---

# Policy Writer

Orchestrate 7 parallel policy-analyst subagents to update `.workaholic/policies/` with policy documentation.

## Input

You will receive:

- Base branch (usually `main`)

## Policy Domains

### test

- **Description**: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
- **Analysis prompts**: What testing frameworks are used? What testing levels exist (unit, integration, e2e)? What coverage targets are defined? How are tests organized and run?
- **Output sections**: Testing Framework, Testing Levels, Coverage Targets, Test Organization

### security

- **Description**: The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place
- **Analysis prompts**: What authentication mechanisms exist? What authorization boundaries are enforced? What secrets management practices are used? What input validation is performed?
- **Output sections**: Authentication, Authorization, Secrets Management, Input Validation

### quality

- **Description**: Code quality standards, linting rules, review processes, and metrics used to maintain maintainability
- **Analysis prompts**: What linting and formatting tools are configured? What code review processes exist? What complexity or duplication thresholds are set? What type checking is enforced?
- **Output sections**: Linting and Formatting, Code Review, Quality Metrics, Type Safety

### accessibility

- **Description**: Compliance targets, i18n support, assistive technology considerations, and inclusive design practices
- **Analysis prompts**: What i18n/l10n support exists? What languages are supported? How is content translated? What accessibility testing is performed?
- **Output sections**: Internationalization, Supported Languages, Translation Workflow, Accessibility Testing

### observability

- **Description**: The observability strategy -- metrics collected, logging practices, tracing implementation, and alerting thresholds
- **Analysis prompts**: What logging practices are in place? What metrics are collected? What tracing or monitoring tools are used? What alerting thresholds exist?
- **Output sections**: Logging Practices, Metrics Collection, Tracing and Monitoring, Alerting

### delivery

- **Description**: The CI/CD pipeline stages, deployment strategies, and artifact promotion flow from source to production
- **Analysis prompts**: What CI/CD pipelines exist? What build steps are defined? How are artifacts produced and deployed? What release processes are followed?
- **Output sections**: CI/CD Pipeline, Build Process, Deployment Strategy, Release Process

### recovery

- **Description**: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
- **Analysis prompts**: What data persistence mechanisms exist? What backup or snapshot capabilities are available? What migration strategies are used? What recovery procedures are documented?
- **Output sections**: Data Persistence, Backup Strategy, Migration Procedures, Recovery Plan

## Instructions

1. **Gather Context**: Use the preloaded gather-git-context skill to get branch and base branch info.

2. **Invoke 7 Policy Analysts in Parallel**: Use a single message with 7 Task tool calls.

   For each policy domain above, invoke with `subagent_type: "core:policy-analyst"`, `model: "sonnet"` and pass the domain's full definition (description, analysis prompts, output sections) in the prompt along with the base branch.

   All 7 invocations must be in a single message to run concurrently.

3. **Validate Output**: After all analysts complete, verify that each expected output file exists and is non-empty:
   ```bash
   bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
   ```
   Parse the JSON result. If `pass` is `false`, do NOT proceed to step 4. Instead, report failure status with the list of missing/empty files.

4. **Update Index Files**: Only after validation passes, update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.

5. **Report Status**: Collect results from all 7 analysts and report per-domain status. Include validation results.

## Output

Return JSON with per-policy status:

```json
{
  "validation": { "pass": true },
  "policies": {
    "test": { "status": "success" },
    "security": { "status": "success" },
    "quality": { "status": "success" },
    "accessibility": { "status": "success" },
    "observability": { "status": "success" },
    "delivery": { "status": "success" },
    "recovery": { "status": "success" }
  }
}
```
