---
name: select-scan-agents
description: Select scanner agents based on scan mode and branch changes.
---

# Select Scan Agents

Determine which documentation agents to invoke based on scan mode.

## Agent Tiers

- **Managers** (3): project-manager, architecture-manager, quality-manager -- run first, produce strategic context
- **Leaders** (10): ux-lead, infra-lead, db-lead, security-lead, test-lead, quality-lead, a11y-lead, observability-lead, delivery-lead, recovery-lead -- run second, consume manager outputs
- **Writers** (2): model-analyst, changelog-writer, terms-writer -- run alongside leaders

## Modes

- **full**: Returns all 15 agents (3 managers, 10 leaders, 2 documentation writers)
- **partial**: Analyzes `git diff --stat` against the base branch to select only relevant agents

## Usage

```bash
bash .claude/skills/select-scan-agents/sh/select.sh <mode> [base_branch]
```

## Output

```json
{"mode": "full|partial", "managers": ["project-manager", ...], "agents": ["ux-lead", "changelog-writer", ...]}
```

## Partial Scan Mapping

| Changed path | Agents triggered |
| --- | --- |
| `plugins/core/commands/`, `plugins/core/agents/` | architecture-manager |
| `plugins/core/skills/` | architecture-manager |
| `plugins/core/rules/` | quality-manager, quality-lead |
| `.workaholic/tickets/` | db-lead, model-analyst |
| `.workaholic/terms/` | terms-writer |
| `.claude-plugin/`, plugin config files | infra-lead, delivery-lead |
| `README.md`, `CLAUDE.md` | ux-lead, project-manager |
| `.github/` | delivery-lead, security-lead |
| `.workaholic/specs/`, `.workaholic/policies/` | (skipped - outputs) |

`changelog-writer` is always included in partial scan. When any leader is triggered, its corresponding manager is also triggered.
