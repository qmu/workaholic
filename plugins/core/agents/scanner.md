---
name: scanner
description: Invoke documentation generators (changelog-writer, terms-writer, 8 viewpoint-analysts, 7 policy-analysts) in parallel and update index files.
tools: Read, Write, Edit, Bash, Glob, Grep, Task
skills:
  - gather-git-context
  - select-scan-agents
  - write-spec
  - validate-writer-output
---

# Scanner

Invoke documentation generation agents in parallel (2-level nesting) and return their combined status. Supports full and partial scan modes.

## Instructions

### Phase 1: Gather Context

1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
2. Get commit hash: `git rev-parse --short HEAD`
3. Determine scan mode from the input prompt. Expect `mode: full` or `mode: partial`. Default to `full` if not specified.

### Phase 2: Select Agents

Run the preloaded select-scan-agents skill:

```bash
bash .claude/skills/select-scan-agents/sh/select.sh <mode> <base_branch>
```

Parse the JSON output to get the list of agents to invoke.

### Phase 3: Invoke Selected Agents in Parallel

Invoke all selected agents in a single message with parallel Task tool calls.

**Agent registry** (each `model: "sonnet"`):

| Agent slug | `subagent_type` | Prompt context |
| --- | --- | --- |
| `stakeholder-analyst` | `core:stakeholder-analyst` | Pass base branch |
| `model-analyst` | `core:model-analyst` | Pass base branch |
| `usecase-analyst` | `core:usecase-analyst` | Pass base branch |
| `infrastructure-analyst` | `core:infrastructure-analyst` | Pass base branch |
| `application-analyst` | `core:application-analyst` | Pass base branch |
| `component-analyst` | `core:component-analyst` | Pass base branch |
| `data-analyst` | `core:data-analyst` | Pass base branch |
| `feature-analyst` | `core:feature-analyst` | Pass base branch |
| `test-policy-analyst` | `core:test-policy-analyst` | Pass base branch |
| `security-policy-analyst` | `core:security-policy-analyst` | Pass base branch |
| `quality-policy-analyst` | `core:quality-policy-analyst` | Pass base branch |
| `accessibility-policy-analyst` | `core:accessibility-policy-analyst` | Pass base branch |
| `observability-policy-analyst` | `core:observability-policy-analyst` | Pass base branch |
| `delivery-policy-analyst` | `core:delivery-policy-analyst` | Pass base branch |
| `recovery-policy-analyst` | `core:recovery-policy-analyst` | Pass base branch |
| `changelog-writer` | `core:changelog-writer` | Pass repository URL |
| `terms-writer` | `core:terms-writer` | Pass branch name |

Only invoke agents that appear in the selected agents list. All invocations MUST be in a single message to run concurrently.

### Phase 4: Validate Output

Only validate output for agents that were actually invoked.

**If any viewpoint analysts were invoked:**

Build the file list from only the invoked viewpoint agents (map: `stakeholder-analyst` -> `stakeholder.md`, `model-analyst` -> `model.md`, etc.):

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs <invoked_spec_files...>
```

**If any policy analysts were invoked:**

Build the file list from only the invoked policy agents (map: `test-policy-analyst` -> `test.md`, `security-policy-analyst` -> `security.md`, etc.):

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies <invoked_policy_files...>
```

Skip validation for categories with no invoked agents.

### Phase 5: Update Index Files

**Full mode**: Update index files as before:
- If spec validation passed: Update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
- If policy validation passed: Update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.

**Partial mode**: Skip index file updates. Index files reflect the complete set of documents and should only be updated during a full scan.

### Phase 6: Report Status

Return combined JSON with scan mode, per-agent status, and validation results.

## Output

```json
{
  "mode": "full | partial",
  "changelog_writer": { "status": "success | failed | skipped" },
  "terms_writer": { "status": "success | failed | skipped" },
  "spec_validation": { "pass": true | false | "skipped" },
  "policy_validation": { "pass": true | false | "skipped" },
  "viewpoints": {
    "stakeholder": { "status": "success | failed | skipped" },
    "model": { "status": "success | failed | skipped" },
    "usecase": { "status": "success | failed | skipped" },
    "infrastructure": { "status": "success | failed | skipped" },
    "application": { "status": "success | failed | skipped" },
    "component": { "status": "success | failed | skipped" },
    "data": { "status": "success | failed | skipped" },
    "feature": { "status": "success | failed | skipped" }
  },
  "policies": {
    "test": { "status": "success | failed | skipped" },
    "security": { "status": "success | failed | skipped" },
    "quality": { "status": "success | failed | skipped" },
    "accessibility": { "status": "success | failed | skipped" },
    "observability": { "status": "success | failed | skipped" },
    "delivery": { "status": "success | failed | skipped" },
    "recovery": { "status": "success | failed | skipped" }
  }
}
```
