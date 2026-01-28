# Workaholic

In-repository Ticket-Driven Development (TiDD) for Claude Code.

Tickets live alongside code as git-tracked artifacts, not in external tools. Each ticket captures what was planned and what was implemented—the context, decisions, and rationale behind every change. This shared history becomes searchable documentation that future sessions can reference and build upon.

Multiple sessions can create tickets in parallel while one session implements them serially, with confirmation at each step. When ready to deliver, commit messages, changelogs, and PR descriptions are generated from the accumulated ticket history. Small commits with clear intent preserve semantics across the project's lifetime.

## Installation

```bash
claude
/plugin marketplace add qmu/workaholic
```

## Quick Start

| Command   | What it does                         |
| --------- | ------------------------------------ |
| `/branch` | Create timestamped topic branch      |
| `/ticket` | Plan a change with context and steps |
| `/drive`  | Implement queued tickets one by one  |
| `/story`  | Generate docs and create PR          |

### Typical Session

```bash
/branch                           # create topic branch
/ticket add login page            # plan first change
/ticket add session management    # plan another change
/drive                            # implement both, commit each
/ticket fix logout redirect       # discover issue mid-development
/drive                            # implement the fix
/story                            # ready to deliver: docs + PR
```

## Documentation

Deep dives and working artifacts live in [.workaholic/](.workaholic/README.md):

- **specs/** - Current state reference
- **stories/** - Development narratives per branch
- **terms/** - Consistent terminology
- **tickets/** - Work queue and archives

## Author

tamurayoshiya <a@qmu.jp>
