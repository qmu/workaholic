# Workaholic

AI-powered development workflow that turns Claude Code into your 10x pair programmer.

## Why Workaholic?

Write specs with AI exploration, implement with AI assistance, ship with AI-generated documentation. Four commands that unlock high-velocity development through ergonomic AI pair programming.

## Motivation

- **Backlog as Historical Assets** - Tickets live in the repository, not external tools. AI and developers access the same searchable history. Decisions and context are preserved as git-tracked artifacts.

- **Parallel Generation, Serial Execution** - Single repository, single worktree (no git worktree complexity). Multiple Claude Code sessions can generate tickets with `/ticket` in parallel. One session runs `/drive` to implement, asking for confirmation.

- **AI-Powered Explanations** - AI generates commit messages, documentation, and PR descriptions via `/report`. Developer focuses on decisions, AI handles the writing.

- **Cultivating Semantics** - Commands map to natural development phases for intuitivity. Same structure everywhere for consistency. AI captures the "why" for describability. Small commits with clear intent for density.

## Installation

```bash
claude
/plugin marketplace add qmu/workaholic
```

## Quick Start

| Command   | What it does                      |
| --------- | --------------------------------- |
| `/branch` | Create timestamped topic branch   |
| `/ticket` | Write implementation spec with AI |
| `/drive`  | Implement specs one by one        |
| `/report` | Generate docs and create PR       |

### Typical Session

```bash
/branch                           # feat-20260127-210800
/ticket add user authentication   # AI explores, writes spec
/drive                            # implement, commit, repeat
/report                           # changelog, story, PR
```

## Documentation

Deep dives and working artifacts live in [.workaholic/](.workaholic/README.md):

- **specs/** - Current state reference
- **stories/** - Development narratives per branch
- **terms/** - Consistent terminology
- **tickets/** - Work queue and archives

## Author

tamurayoshiya <a@qmu.jp>
