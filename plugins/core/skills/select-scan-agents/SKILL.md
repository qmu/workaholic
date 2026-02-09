---
name: select-scan-agents
description: Select scanner agents based on scan mode and branch changes.
---

# Select Scan Agents

Determine which documentation agents to invoke based on scan mode.

## Modes

- **full**: Returns all 14 agents (5 viewpoint leads, 7 policy leads, 2 documentation writers)
- **partial**: Analyzes `git diff --stat` against the base branch to select only relevant agents

## Usage

```bash
bash .claude/skills/select-scan-agents/sh/select.sh <mode> [base_branch]
```

## Output

```json
{"mode": "full|partial", "agents": ["communication-lead", "changelog-writer", ...]}
```

## Partial Scan Mapping

| Changed path | Agents triggered |
| --- | --- |
| `plugins/core/commands/`, `plugins/core/agents/` | architecture-lead |
| `plugins/core/skills/` | architecture-lead |
| `plugins/core/rules/` | quality-lead, architecture-lead |
| `.workaholic/tickets/` | db-lead, model-analyst |
| `.workaholic/terms/` | terms-writer |
| `.claude-plugin/`, plugin config files | infra-lead, delivery-lead |
| `README.md`, `CLAUDE.md` | communication-lead, architecture-lead |
| `.github/` | delivery-lead, security-lead |
| `.workaholic/specs/`, `.workaholic/policies/` | (skipped - outputs) |

`changelog-writer` is always included in partial scan.
