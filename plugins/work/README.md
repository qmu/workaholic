# Work

Unified development workflow for Claude Code projects: ticket-driven development and AI-collaborative exploration.

## Why Documentation?

This plugin intentionally generates extensive documentation artifacts (tickets, changelogs, archives) as **cognitive investments**. Developer cognitive load is the primary bottleneck in software productivity - context-switching, onboarding, and understanding past decisions consume significant mental energy.

Each artifact reduces this load:

- **Tickets** capture intent before implementation, preventing "what was I trying to do?"
- **Specs** provide authoritative reference for current state, eliminating guesswork
- **Stories** preserve the narrative of how decisions were made across a feature
- **Changelogs** explain what changed and why, enabling quick catch-up

The upfront cost of documentation pays dividends when you (or a teammate) return to code weeks later.

## Commands

| Command                 | Description                                                                      |
| ----------------------- | -------------------------------------------------------------------------------- |
| `/ticket <description>` | Explore codebase and write implementation ticket (auto-creates branch on main)   |
| `/drive`                | Implement tickets from .workaholic/tickets/ one by one, commit each, and archive |
| `/trip <instruction>`   | Launch Agent Teams session with Planner, Architect, and Constructor              |

## Agents

The drive, ticket, and report workflows do **not** use per-workflow agent files. Each command spawns `subagent_type: "general-purpose"` subagents whose prompts preload the relevant `core` skill (`core:drive`, `core:create-ticket`, `core:discover`, `core:report`, `core:review-sections`, `core:write-release-note`) and run a named section. All fan-out and user interaction stay at the command level (one-level fan-out — see the root `CLAUDE.md` Architecture Policy).

The only agent files in this plugin are the Agent Teams members `/trip` launches:

### Trip Agents

| Agent          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `planner`      | Progressive agent for business vision and stakeholder advocacy |
| `architect`    | Neutral agent bridging business vision and technical implementation |
| `constructor`  | Conservative agent for technical ownership and delivery |

## Skills

| Skill              | Description                                                              |
| ------------------ | ------------------------------------------------------------------------ |
| `create-ticket`    | Ticket creation guidelines, format, and conventions                      |
| `discover`         | Context discovery: historical tickets, source code, and repository standards  |
| `drive`            | Implementation workflow, approval, final report, archive, and frontmatter |
| `report`           | Story writing, PR creation, and release readiness assessment             |
| `trip-protocol`    | Two-phase collaborative workflow protocol and artifact conventions       |

## Rules

| Rule            | Description                                              |
| --------------- | -------------------------------------------------------- |
| `general.md`    | General development rules (commit confirmation required) |
| `workaholic.md` | Workaholic-specific conventions                          |

## Workflows

### Drive: Ticket-Driven Development

1. **Plan work**: Use `/ticket` to write implementation specs (auto-creates branch on main)
2. **Implement tickets**: Use `/drive` to implement and commit each ticket
3. **Create PR**: Use `/report` to generate story and create PR
4. **Ship**: Use `/ship` to merge PR, deploy, and verify

### Trip: AI-Collaborative Exploration

1. **Launch session**: Use `/trip <instruction>` to start an Agent Teams session
2. **Three agents collaborate**: Planner, Architect, and Constructor produce artifacts
3. **Create PR**: Use `/report` to generate journey report and create PR
4. **Ship**: Use `/ship` to merge PR, clean up worktree, and verify

## Feedback Loop

When reviewing an implementation and requesting changes:

1. **Update the ticket first** - Add/modify steps based on feedback
2. **Then implement** - Make the requested changes
3. **Review again** - Ask for approval once more

**Why this matters**: Archived tickets become project documentation. Keeping tickets updated ensures accurate history of what was built and helps future developers understand the full scope of changes.

## Ticket Storage

- Active tickets: `.workaholic/tickets/todo/`
- Icebox (deferred): `.workaholic/tickets/icebox/`
- Archived: `.workaholic/tickets/archive/<branch-name>/`

## Installation

Requires the `core` plugin. Add to your Claude Code configuration:

```json
{
  "plugins": ["core", "work"]
}
```
