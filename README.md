# Workaholic

Private marketplace for Claude Code plugins. Discover and enable plugins that add structured workflows to your Claude Code sessions, from ticket-driven development to AI-collaborative exploration.

> [!WARNING]
> **This plugin drives git on your behalf.** Workaholic lets Claude Code autonomously create branches, commit, amend, push, and open pull requests. Review the plugin descriptions below before installing so you know what to expect.

## Quick Start

```bash
claude
/plugin marketplace add qmu/workaholic
```

Enable the plugins you want after installation. Auto update is recommended.

## Plugins

### Core

Shared commands that work across all workflows. Auto-detects your development context from the current branch pattern.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/report`  | Context-aware: generate story or journey report and create PR |
| `/ship`    | Context-aware: merge PR, deploy, and verify           |

### Standards

Repository structuring policy, qualitative agents, and documentation standards. This plugin has no commands — it provides agents and skills referenced by other plugins. Includes lead agents (a11y, db, delivery, infra, observability, quality, recovery, security, test, ux), manager agents (architecture, project, quality), and documentation writers (changelog, terms, specs, release notes).

### Work

Unified development workflow combining ticket-driven development (TiDD) and AI-collaborative exploration. Write implementation tickets, implement them serially with confirmation, generate PR stories, or launch Agent Teams for collaborative design.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/ticket`  | Plan a change with context and steps                  |
| `/drive`   | Implement queued tickets one by one                   |
| `/scan`    | Full documentation scan                               |
| `/trip`    | Launch Agent Teams session for collaborative design   |

> [!NOTE]
> `/trip` requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to be set in your environment.

**Typical drive session:**

```bash
/ticket add dark mode toggle to settings page
/ticket support system preference detection
/drive                            # implement both, confirm each
/ticket fix flash of light theme on page load
/drive                            # fix discovered issue
/report                           # generate story + create PR
/ship                             # merge, deploy, verify
```

**Typical trip session:**

```bash
/trip design a real-time notification system for our web app
# Three agents collaborate:
#   Planner  — defines direction from user/stakeholder perspective
#   Architect — models system structure and boundaries
#   Constructor — designs implementation with engineering trade-offs
# All work happens in an isolated worktree branch
/report                           # generate journey report + create PR
/ship                             # merge, clean up worktree, verify
```

## How It Works

### Ticket-Driven Development

A ticket is a markdown file describing a change you want to make — the context, plan, and rationale. Run `/ticket your change request` and a coding agent explores both codebase and history, then writes the ticket for you. Committed alongside the code, tickets become searchable history for future coding agents.

Once tickets are queued, `/drive` implements them one by one with confirmation at each step. While one agent drives, others can keep creating tickets — no worktree overhead, just serial execution with clear commits.

When ready to deliver, `/report` generates changelogs and PR descriptions from the accumulated ticket history. Then `/ship` merges the PR, deploys following your project's `cloud.md` instructions, and verifies the deployment.

> [!NOTE]
> **A flavor of Spec-Driven Development**
>
> This follows [Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) principles with distinct terminology:
>
> - **Ticket**: A change request describing what should be different (flowing, temporal)
> - **Spec**: Current state documentation describing what exists now (snapshot, persistent)
>
> Tickets drive implementation; specs document the result. Both are markdown, both are versioned, but they serve complementary purposes.

### AI-Collaborative Exploration

The `/trip` command launches an Agent Teams session where three agents with different perspectives collaborate to explore and develop a concept:

- **Planner** (Progressive) — Non-tech perspective: user value, stakeholder clarity, explanatory accountability
- **Architect** (Neutral) — Structural perspective: system coherence, abstraction quality, boundary integrity
- **Constructor** (Conservative) — Tech perspective: implementation feasibility, performance, maintainability

The session runs in two phases inside an isolated git worktree:
1. **Specification** — Agents produce direction, model, and design artifacts through mutual review
2. **Implementation** — Agents build, review, and test the agreed specification

## Documentation

Working artifacts live in [.workaholic/](.workaholic/README.md):

- **guides/** - User documentation
- **specs/** - Technical specifications
- **stories/** - Development narratives per branch
- **terms/** - Consistent term definitions
- **tickets/** - Work queue and archives

## Author

tamurayoshiya <a@qmu.jp>
