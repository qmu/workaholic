---
name: select-scan-agents
description: Select scanner agents based on scan mode and branch changes.
---

# Select Scan Agents

Determine which documentation agents to invoke based on scan mode.

## Modes

- **full**: Returns all 17 agents (8 viewpoint analysts, 7 policy analysts, 2 documentation writers)
- **partial**: Analyzes `git diff --stat` against the base branch to select only relevant agents

## Usage

```bash
bash .claude/skills/select-scan-agents/sh/select.sh <mode> [base_branch]
```

## Output

```json
{"mode": "full|partial", "agents": ["stakeholder-analyst", "changelog-writer", ...]}
```

## Partial Scan Mapping

| Changed path | Agents triggered |
| --- | --- |
| `plugins/core/commands/`, `plugins/core/agents/` | application-analyst, usecase-analyst, component-analyst |
| `plugins/core/skills/` | component-analyst, feature-analyst |
| `plugins/core/rules/` | quality-policy-analyst, component-analyst |
| `.workaholic/tickets/` | data-analyst, model-analyst |
| `.workaholic/terms/` | terms-writer |
| `.claude-plugin/`, plugin config files | infrastructure-analyst, delivery-policy-analyst |
| `README.md`, `CLAUDE.md` | stakeholder-analyst, feature-analyst |
| `.github/` | delivery-policy-analyst, security-policy-analyst |
| `.workaholic/specs/`, `.workaholic/policies/` | (skipped - outputs) |

`changelog-writer` is always included in partial scan.
