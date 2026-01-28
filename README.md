# Workaholic

Claude Code plugin aiming at in-repository ticket-driven development (TiDD).

A ticket is a markdown file describing a change you want to make—the context, plan, and rationale. Run `/ticket your change request` and a coding agent explores both codebase and history, then writes the ticket for you. Committed alongside the code, tickets become searchable history for future coding agents.

Once tickets are queued, `/drive` implements them one by one with confirmation at each step. While one agent drives, others can keep creating tickets—no git worktree overhead, just serial execution with clear commits. The bottleneck is human cognition, not implementation speed.

When ready to deliver, `/story` generates changelogs and PR descriptions from the accumulated ticket history. No manual summarization—the intent behind each change is already documented, so the narrative writes itself.

## Quick Start

```bash
claude
/plugin marketplace add qmu/workaholic
```

Enable the plugin after installation. Auto update is recommended.

| Command   | What it does                         |
| --------- | ------------------------------------ |
| `/ticket` | Plan a change with context and steps |
| `/drive`  | Implement queued tickets one by one  |
| `/story`  | Generate docs and create PR          |

### Typical Session

```bash
/ticket add dark mode toggle to settings page
/ticket support system preference detection
/drive                            # implement both, confirm each
/ticket fix flash of light theme on page load
/drive                            # fix discovered issue
/story                            # PR with feature + fix documented
```

## Documentation

Working artifacts live in [.workaholic/](.workaholic/README.md):

- **guides/** - User documentation
- **specs/** - Technical specifications
- **stories/** - Development narratives per branch
- **terms/** - Consistent term definitions
- **tickets/** - Work queue and archives

## Author

tamurayoshiya <a@qmu.jp>
