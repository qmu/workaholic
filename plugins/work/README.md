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
| `/scan`                 | Full documentation scan (all agents)                                             |
| `/trip <instruction>`   | Launch Agent Teams session with Planner, Architect, and Constructor              |
| `/ship`                 | Context-aware: merge PR, deploy, and verify (with worktree cleanup)              |

## Agents

### Drive Agents

| Agent                 | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `drive-navigator`     | Route and prioritize tickets for /drive                 |
| `history-discoverer`  | Find related historical tickets                         |
| `source-discoverer`   | Find related source files and analyze code flow         |
| `ticket-discoverer`   | Analyze tickets for duplicates, merge, and split        |
| `ticket-organizer`    | Discover context, check duplicates, and write tickets   |
| `story-writer`        | Generate branch story for PR description                |
| `pr-creator`          | Create or update GitHub PR from story file              |
| `release-readiness`   | Analyze branch changes for release readiness            |

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
| `discover`         | Context discovery: historical tickets, source code, and ticket overlaps  |
| `drive`            | Implementation workflow, approval, final report, archive, and frontmatter |
| `report`           | Story writing, PR creation, and release readiness assessment             |
| `ship`             | Ship workflow: PR merge, cloud.md deploy, and production verify          |
| `trip-protocol`    | Two-phase collaborative workflow protocol and artifact conventions       |
| `write-trip-report`| Generate trip journey report from agent artifacts                        |

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
