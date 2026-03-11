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

Shared commands that work across both Drivin and Trippin workflows. Auto-detects your development context from the current branch pattern.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/report`  | Context-aware: generate story or journey report and create PR |
| `/ship`    | Context-aware: merge PR, deploy, and verify           |

### Drivin

Ticket-driven development (TiDD) workflow. Write implementation tickets, implement them serially with confirmation at each step, then generate PR stories automatically. All context is stored in `.workaholic/` for better AI decisions.

| Command    | What it does                                  |
| ---------- | --------------------------------------------- |
| `/ticket`  | Plan a change with context and steps          |
| `/drive`   | Implement queued tickets one by one           |
| `/scan`    | Full documentation scan                       |

**Typical session:**

```bash
/ticket add dark mode toggle to settings page
/ticket support system preference detection
/drive                            # implement both, confirm each
/ticket fix flash of light theme on page load
/drive                            # fix discovered issue
/report                           # generate story + create PR
/ship                             # merge, deploy, verify
```

### Trippin

AI-collaborative exploration workflow using Agent Teams. Three agents with distinct perspectives (Planner, Architect, Constructor) collaborate in an isolated worktree to produce specifications and implementations through structured dialectic.

| Command    | What it does                                          |
| ---------- | ----------------------------------------------------- |
| `/trip`    | Launch Agent Teams session for collaborative design   |

> [!NOTE]
> Trippin requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to be set in your environment.

**Example session:**

```bash
/trip design a real-time notification system for our web app
# Three agents collaborate:
#   Planner  — defines direction from user/stakeholder perspective
#   Architect — models system structure and boundaries
#   Constructor — designs implementation with engineering trade-offs
# All work happens in an isolated worktree branch
```

## How It Works

### Drivin: Ticket-Driven Development

A ticket is a markdown file describing a change you want to make — the context, plan, and rationale. Run `/ticket your change request` and a coding agent explores both codebase and history, then writes the ticket for you. Committed alongside the code, tickets become searchable history for future coding agents.

Once tickets are queued, `/drive` implements them one by one with confirmation at each step. While one agent drives, others can keep creating tickets — no worktree overhead, just serial execution with clear commits.

When ready to deliver, `/report` generates changelogs and PR descriptions from the accumulated ticket history. Then `/ship` merges the PR, deploys following your project's `cloud.md` instructions, and verifies the deployment.

> [!NOTE]
> **A flavor of Spec-Driven Development**
>
> Drivin follows [Spec-Driven Development](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) principles with distinct terminology:
>
> - **Ticket**: A change request describing what should be different (flowing, temporal)
> - **Spec**: Current state documentation describing what exists now (snapshot, persistent)
>
> Tickets drive implementation; specs document the result. Both are markdown, both are versioned, but they serve complementary purposes.

### Trippin: AI-Collaborative Exploration

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
