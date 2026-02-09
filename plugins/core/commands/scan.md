---
name: scan
description: Full documentation scan - update all .workaholic/ documentation (changelog, specs, terms, policies).
skills:
  - gather-git-context
  - select-scan-agents
  - write-spec
  - validate-writer-output
---

# Scan

**Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

Run a full documentation scan by invoking all 14 documentation agents directly, providing real-time progress visibility for each agent.

## Instructions

### Phase 1: Gather Context

1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
2. Get commit hash: `git rev-parse --short HEAD`

### Phase 2: Select Agents

Run the preloaded select-scan-agents skill:

```bash
bash .claude/skills/select-scan-agents/sh/select.sh full
```

Parse the JSON output to get the list of all 14 agents.

### Phase 3: Invoke All Agents in Parallel

Invoke all 14 agents in a single message with parallel Task tool calls (each `model: "sonnet"`):

| Agent slug | `subagent_type` | Prompt context |
| --- | --- | --- |
| `communication-lead` | `core:communication-lead` | Pass base branch |
| `model-analyst` | `core:model-analyst` | Pass base branch |
| `infra-lead` | `core:infra-lead` | Pass base branch |
| `architecture-lead` | `core:architecture-lead` | Pass base branch |
| `db-lead` | `core:db-lead` | Pass base branch |
| `test-lead` | `core:test-lead` | Pass base branch |
| `security-lead` | `core:security-lead` | Pass base branch |
| `quality-lead` | `core:quality-lead` | Pass base branch |
| `a11y-lead` | `core:a11y-lead` | Pass base branch |
| `observability-lead` | `core:observability-lead` | Pass base branch |
| `delivery-lead` | `core:delivery-lead` | Pass base branch |
| `recovery-lead` | `core:recovery-lead` | Pass base branch |
| `changelog-writer` | `core:changelog-writer` | Pass repository URL |
| `terms-writer` | `core:terms-writer` | Pass branch name |

All invocations MUST be in a single message to run concurrently. Each Task call MUST use `run_in_background: false` (the default).

**CRITICAL: Do NOT use `run_in_background: true`.** Agents need Write/Edit permissions which require interactive prompt access. Background agents cannot receive prompts, causing all file writes to be auto-denied. Normal parallel Task calls in a single message already run concurrently.

### Phase 4: Validate Output

Validate viewpoint analyst output:

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
```

Validate policy analyst output:

```bash
bash .claude/skills/validate-writer-output/sh/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md
```

### Phase 5: Update Index Files

- If spec validation passed: Update `.workaholic/specs/README.md` and `README_ja.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
- If policy validation passed: Update `.workaholic/policies/README.md` and `README_ja.md` to list all 7 policy documents.

### Phase 6: Stage and Commit

```bash
git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"
```

### Phase 7: Report Results

Report per-agent status showing which agents succeeded, failed, or were skipped, along with validation results.
