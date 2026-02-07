---
name: scanner
description: Invoke documentation generators (changelog-writer, terms-writer, 8 viewpoint-analysts, 7 policy-analysts) in parallel and update index files.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - gather-git-context
  - write-spec
  - validate-writer-output
---

# Scanner

Invoke all documentation generation agents in parallel (2-level nesting) and return their combined status.

## Instructions

### Phase 1: Gather Context

1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
2. Get commit hash: `git rev-parse --short HEAD`

### Phase 2: Invoke All Agents in Parallel

Invoke all 17 agents in a single message with 17 Task tool calls:

**8 Viewpoint Analysts** (each `model: "sonnet"`):

- **stakeholder-analyst** (`subagent_type: "core:stakeholder-analyst"`): Pass base branch.
- **model-analyst** (`subagent_type: "core:model-analyst"`): Pass base branch.
- **usecase-analyst** (`subagent_type: "core:usecase-analyst"`): Pass base branch.
- **infrastructure-analyst** (`subagent_type: "core:infrastructure-analyst"`): Pass base branch.
- **application-analyst** (`subagent_type: "core:application-analyst"`): Pass base branch.
- **component-analyst** (`subagent_type: "core:component-analyst"`): Pass base branch.
- **data-analyst** (`subagent_type: "core:data-analyst"`): Pass base branch.
- **feature-analyst** (`subagent_type: "core:feature-analyst"`): Pass base branch.

**7 Policy Analysts** (each `model: "sonnet"`):

- **test-policy-analyst** (`subagent_type: "core:test-policy-analyst"`): Pass base branch.
- **security-policy-analyst** (`subagent_type: "core:security-policy-analyst"`): Pass base branch.
- **quality-policy-analyst** (`subagent_type: "core:quality-policy-analyst"`): Pass base branch.
- **accessibility-policy-analyst** (`subagent_type: "core:accessibility-policy-analyst"`): Pass base branch.
- **observability-policy-analyst** (`subagent_type: "core:observability-policy-analyst"`): Pass base branch.
- **delivery-policy-analyst** (`subagent_type: "core:delivery-policy-analyst"`): Pass base branch.
- **recovery-policy-analyst** (`subagent_type: "core:recovery-policy-analyst"`): Pass base branch.

**2 Documentation Writers** (each `model: "sonnet"`):

- **changelog-writer** (`subagent_type: "core:changelog-writer"`): Pass repository URL.
- **terms-writer** (`subagent_type: "core:terms-writer"`): Pass branch name.

All 17 invocations MUST be in a single message to run concurrently. Wait for all to complete before proceeding.

### Phase 3: Validate Spec Output

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
```

Parse the JSON result. If `pass` is `false`, do NOT update spec index files. Report failure with missing/empty files.

### Phase 4: Validate Policy Output

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
```

Parse the JSON result. If `pass` is `false`, do NOT update policy index files. Report failure with missing/empty files.

### Phase 5: Update Index Files

Spec and policy validation are independent. Update each index only if its validation passed.

**If spec validation passed**: Update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.

**If policy validation passed**: Update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.

### Phase 6: Report Status

Return combined JSON with per-agent status and validation results.

## Output

```json
{
  "changelog_writer": { "status": "success" | "failed" },
  "terms_writer": { "status": "success" | "failed" },
  "spec_validation": { "pass": true | false },
  "policy_validation": { "pass": true | false },
  "viewpoints": {
    "stakeholder": { "status": "success" | "failed" },
    "model": { "status": "success" | "failed" },
    "usecase": { "status": "success" | "failed" },
    "infrastructure": { "status": "success" | "failed" },
    "application": { "status": "success" | "failed" },
    "component": { "status": "success" | "failed" },
    "data": { "status": "success" | "failed" },
    "feature": { "status": "success" | "failed" }
  },
  "policies": {
    "test": { "status": "success" | "failed" },
    "security": { "status": "success" | "failed" },
    "quality": { "status": "success" | "failed" },
    "accessibility": { "status": "success" | "failed" },
    "observability": { "status": "success" | "failed" },
    "delivery": { "status": "success" | "failed" },
    "recovery": { "status": "success" | "failed" }
  }
}
```
