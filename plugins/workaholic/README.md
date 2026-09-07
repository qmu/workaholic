# Core

Shared commands and skills for cross-workflow operations. Provides context-aware commands and shared utilities used by other plugins.

## Commands

| Command | Description |
| ------- | ----------- |
| `/story` | Context-aware branch story generation and PR creation (`/report` is a deprecated alias for it) |
| `/ship` | Context-aware: merge PR, deploy, and verify |

## Skills

| Skill | Description |
| ----- | ----------- |
| branching | Context detection and branch pattern matching for unified commands |
| runtime | Shared typed config, state, planning, and context contracts for agentic loops |
| transport | Bound QFS, parent connector, and existing-token communication with durable outbox evidence |
| ship | Ship workflow: PR merge, CLAUDE.md deploy, and production verify |

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["core"]
}
```

### Portable distribution verification

The build follows nested script and reference dependencies, together with explicit entries in
`scripts/build-plugins/skill-dependencies.json`. Portable consumer and legacy contract regressions
run with `node --test scripts/tests/agentic-loop/*.test.mjs`; see
[the contract map](../../docs/agentic-loop-contracts.md). Generated `outputs/` are rebuilt from source.
