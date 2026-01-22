# Core

Core development commands for Claude Code projects.

## Commands

| Command         | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `/branch`       | Create a topic branch with timestamp (e.g., feat-20260120-205418) |
| `/commit`       | Commit all changes in logical units with meaningful messages      |
| `/pull-request` | Create or update a pull request with CHANGELOG-based summary      |

## Rules

| Rule            | Description                                              |
| --------------- | -------------------------------------------------------- |
| `general.md`    | General development rules (commit confirmation required) |
| `typescript.md` | TypeScript coding conventions                            |

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["core"]
}
```
