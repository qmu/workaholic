---
name: select-scan-agents
description: Select scanner agents based on scan mode and branch changes.
---

# Select Scan Agents

Determine which documentation agents to invoke based on scan mode.

## Agent Tiers

- **Managers** (3): project-manager, architecture-manager, quality-manager -- run first, produce strategic context
- **Leads** (6): single `lead` agent invoked with domain parameter (ux, db, security, quality, observability, reliability) -- run second, consume manager outputs
- **Writers** (3): model-analyst, changelog-writer, terms-writer -- run alongside leads

## Modes

- **full**: Returns all agents (3 managers, 6 leads with domain, 3 writers)
- **partial**: Analyzes `git diff --stat` against the base branch to select only relevant agents

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/select-scan-agents/scripts/select.sh <mode> [base_branch]
```

## Output

```json
{"mode": "full|partial", "managers": ["project-manager", ...], "leads": [{"agent": "lead", "domain": "ux"}, ...], "writers": ["model-analyst", ...]}
```

## Partial Scan Mapping

| Changed path | Agents triggered |
| --- | --- |
| `plugins/work/commands/`, `plugins/work/agents/` | architecture-manager |
| `plugins/work/skills/` | architecture-manager |
| `plugins/work/rules/` | quality-manager, quality-lead |
| `.workaholic/tickets/` | db-lead, model-analyst |
| `.workaholic/terms/` | terms-writer |
| `.claude-plugin/`, plugin config files | reliability-lead |
| `README.md`, `CLAUDE.md` | ux-lead, project-manager |
| `.github/` | reliability-lead, security-lead |
| `.workaholic/specs/`, `.workaholic/policies/` | (skipped - outputs) |

`changelog-writer` is always included in partial scan. When any lead domain is triggered, its corresponding manager is also triggered.
