---
name: scan
description: Full documentation scan - update all .workaholic/ documentation (changelog, specs, terms, policies).
skills:
  - gather-git-context
  - standards:select-scan-agents
  - standards:write-spec
  - standards:validate-writer-output
---

# Scan

**Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

Run a full documentation scan by invoking 3 manager agents then 12 leader/writer agents, providing real-time progress visibility for each agent.

## Instructions

### Phase 1: Gather Context

1. Use the preloaded gather-git-context skill to get branch, base_branch, and repo_url.
2. Get commit hash: `git rev-parse --short HEAD`

### Phase 2: Select Agents

Run the preloaded select-scan-agents skill:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/select-scan-agents/scripts/select.sh full
```

Parse the JSON output to get the lists of managers, leads (with domain), and writers.

### Phase 3a: Invoke Manager Agents in Parallel

Invoke all 3 manager agents in a single message with parallel Task tool calls (each `model: "sonnet"`):

| Agent slug | `subagent_type` | Prompt context |
| --- | --- | --- |
| `project-manager` | `standards:project-manager` | Pass base branch |
| `architecture-manager` | `standards:architecture-manager` | Pass base branch |
| `quality-manager` | `standards:quality-manager` | Pass base branch |

Wait for all managers to complete before proceeding. Manager outputs must be available for leaders.

### Phase 3b: Invoke Lead and Writer Agents in Parallel

Invoke all lead and writer agents from the select output in a single message with parallel Task tool calls (each `model: "sonnet"`):

**For each entry in the `leads` array**, invoke `standards:lead` with the domain in the prompt:
- `subagent_type: "standards:lead"`, prompt includes `"Domain: <domain>."` and the base branch

**For each entry in the `writers` array**, invoke the writer by its slug:

| Writer slug | `subagent_type` | Prompt context |
| --- | --- | --- |
| `model-analyst` | `standards:model-analyst` | Pass base branch |
| `changelog-writer` | `standards:changelog-writer` | Pass repository URL |
| `terms-writer` | `standards:terms-writer` | Pass branch name |

All invocations MUST be in a single message to run concurrently. Each Task call MUST use `run_in_background: false` (the default).

**CRITICAL: Do NOT use `run_in_background: true`.** Agents need Write/Edit permissions which require interactive prompt access. Background agents cannot receive prompts, causing all file writes to be auto-denied. Normal parallel Task calls in a single message already run concurrently.

### Phase 4: Validate Output

Validate viewpoint spec output:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/validate-writer-output/scripts/validate.sh .workaholic/specs ux.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md
```

Validate policy output:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/../standards/skills/validate-writer-output/scripts/validate.sh .workaholic/policies test.md security.md quality.md accessibility.md recovery.md
```

### Phase 5: Update Index Files

- If spec validation passed: Update `.workaholic/specs/README.md` to list all 8 viewpoint documents. Follow the preloaded write-spec skill for index file rules.
- If policy validation passed: Update `.workaholic/policies/README.md` to list all 7 policy documents.

### Phase 6: Stage and Commit

```bash
git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ .workaholic/constraints/ && git commit -m "Update documentation"
```

### Phase 7: Report Results

Report per-agent status showing which agents succeeded, failed, or were skipped, along with validation results. Include both manager phase and leader phase results.
