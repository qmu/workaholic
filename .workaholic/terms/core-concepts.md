---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-02-02
commit_hash: 3c87e62
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# Core Concepts

Fundamental building blocks of the Workaholic plugin system.

## plugin

A modular collection of commands, skills, rules, and agents that extends Claude Code functionality.

### Definition

A plugin packages related functionality into a single distributable unit. Each plugin has its own directory under `plugins/` containing a `.claude-plugin/` configuration folder with `plugin.json` metadata. Plugins can define commands (user-invocable), skills (helper routines), rules (guidelines), and agents (specialized subagents).

### Usage Patterns

- **Directory names**: `plugins/core/`
- **File names**: `plugins/<name>/.claude-plugin/plugin.json`
- **Code references**: "Install the core plugin", "Core plugin commands"

### Related Terms

- command, skill, rule, agent

## command

A user-invocable slash command that performs a specific task.

### Definition

Commands are the primary user interface for plugins. Users invoke them with a slash prefix (e.g., `/ticket`, `/drive`). Each command has a markdown file in the plugin's `commands/` directory that defines its behavior and instructions.

### Usage Patterns

- **Directory names**: `plugins/<name>/commands/`
- **File names**: `ticket.md`, `drive.md`, `report.md`
- **Code references**: "Run `/drive` to...", "The `/ticket` command..."

### Related Terms

- skill, plugin

## skill

A helper sub-routine that is not directly user-invocable.

### Definition

Skills are internal routines that support commands or other operations. Unlike commands, users cannot invoke skills directly with a slash prefix. They are typically called by commands or triggered automatically. Skills are defined in a plugin's `skills/` directory, each in its own subdirectory containing a `SKILL.md` definition and optional `sh/` directory with POSIX shell scripts.

Skills can be preloaded by agents via the `skills:` frontmatter field, providing reusable functionality (e.g., bash scripts for data gathering or formatting) that the agent can invoke during execution.

### Usage Patterns

- **Directory names**: `plugins/<name>/skills/<skill-name>/`
- **File names**: `SKILL.md`, `sh/generate.sh`, `sh/calculate.sh`
- **Code references**: "The archive-ticket skill handles...", "Preload the changelog skill"

### Current Skills

Utility skills (with bundled shell scripts):
- **archive-ticket**: Moves completed tickets to branch archive, formats commits
- **create-branch**: Creates timestamped topic branches (e.g., `feat-20260128-001720`)
- **create-pr**: PR creation workflow, title derivation, and shell script for GitHub operations
- **discover-history**: Searches archived tickets by keywords to find related historical context
- **discover-source**: Guidelines for exploring source code to understand context
- **format-commit-message**: Structured commit message format with UX and Arch sections
- **handle-abandon**: Handles abandoned implementations with failure analysis
- **request-approval**: User approval flow with selectable options
- **write-final-report**: Final report and discovered insights documentation
- **drive-workflow**: Implementation workflow orchestration for processing tickets

Content skills (instructions and templates):
- **write-story**: Story content structure, formatting, metrics calculation, and translation requirements
- **write-spec**: Spec file format, content guidelines, and context gathering for updates
- **write-terms**: Term entry format, documentation guidelines, and context gathering for updates
- **write-changelog**: Changelog formatting and entry guidelines
- **analyze-performance**: Performance evaluation framework
- **create-ticket**: Ticket file structure, frontmatter, related history, and creation workflow
- **translate**: Translation policies and `.workaholic/` i18n enforcement

### Related Terms

- command, plugin, agent

## rule

Guidelines and constraints that shape Claude's behavior within a plugin context.

### Definition

Rules provide persistent guidelines that Claude follows when working within a plugin's scope. They define coding standards, documentation requirements, or behavioral constraints. Rules are stored in a plugin's `rules/` directory.

### Usage Patterns

- **Directory names**: `plugins/<name>/rules/`
- **File names**: `general.md`, `typescript.md`
- **Code references**: "Following the general rule..."

### Related Terms

- plugin, command

## agent

A specialized subagent that can be spawned to handle focused tasks in its own context window.

### Definition

Agents (also called subagents) are AI subprocesses that run with specific prompts and tools to perform focused work. They execute in their own context window, preserving the parent conversation's context while handling extensive file reads or complex analysis. Commands invoke agents via the Task tool and receive structured output. Agents can also invoke other agents (subagent chaining). Agents are defined in a plugin's `agents/` directory.

Common agent types:
- **Writer agents**: Generate documentation (spec-writer, terms-writer, story-writer, changelog-writer)
- **Analyst agents**: Evaluate and analyze (performance-analyst, release-readiness)
- **Creator agents**: Perform external operations (pr-creator, ticket-organizer)
- **Search agents**: Find and analyze related work (history-discoverer, source-discoverer)

### Usage Patterns

- **Directory names**: `plugins/<name>/agents/`
- **File names**: `performance-analyst.md`, `release-readiness.md`, `spec-writer.md`, `story-writer.md`, `changelog-writer.md`, `pr-creator.md`, `ticket-organizer.md`, `history-discoverer.md`, `source-discoverer.md`
- **Code references**: "Invoke the story-writer agent", "The changelog-writer agent handles...", "Spawn the agent via Task tool"

### Related Terms

- plugin, command, skill, orchestrator

## ticket-organizer

A subagent that discovers context and writes implementation tickets during the `/ticket` command workflow.

### Definition

The ticket-organizer subagent handles the complete ticket creation workflow. It receives a feature description and target directory, then performs three discovery tasks in parallel: searching archived tickets for related history and patterns, exploring source code for context, and checking for duplicate tickets. Based on these findings, it writes a new ticket file with proper structure, related history links, and frontmatter. The subagent preloads create-ticket, discover-history, and discover-source skills to access comprehensive guidelines for each discovery phase.

### Usage Patterns

- **Directory names**: `plugins/<name>/agents/`
- **File names**: `ticket-organizer.md`
- **Code references**: "Invoke the ticket-organizer agent", "The ticket-organizer discovers context and writes tickets"

### Related Terms

- command, skill, ticket, create-ticket, discover-history, discover-source

## orchestrator

A command that coordinates multiple agents to complete a complex workflow.

### Definition

An orchestrator is a command that delegates specialized work to multiple agents rather than performing tasks inline. The orchestrator gathers initial context, invokes agents (potentially in parallel for performance), and consolidates their outputs. This pattern preserves the main conversation's context window while enabling complex multi-step workflows.

Examples:
- `/report` orchestrates changelog-writer, story-writer, spec-writer, terms-writer, and release-readiness concurrently, then pr-creator sequentially

### Usage Patterns

- **Directory names**: N/A (pattern, not storage)
- **File names**: N/A
- **Code references**: "The command acts as an orchestrator", "Orchestrate the agents in parallel"

### Related Terms

- command, agent, concurrent execution

## deny

A permission rule that blocks specific command patterns from being executed.

### Definition

Deny rules are configured in `.claude/settings.json` under `permissions.deny` to prohibit certain command patterns across the entire project, including subagents. Unlike embedding prohibitions in individual agent instructions (which subagents do not inherit), deny rules are enforced centrally before any execution. This pattern is more maintainable than duplicating instructions in each agent file.

Example: `"Bash(git -C:*)"` blocks all `git -C` command variations that would trigger permission prompts.

### Usage Patterns

- **Directory names**: N/A (configuration, not storage)
- **File names**: `.claude/settings.json`
- **Code references**: "Add a deny rule for...", "Block the command via settings.json deny"

### Related Terms

- rule, agent, settings

## preload

Load skill content into an agent's context via frontmatter.

### Definition

Preloading is the mechanism by which agents gain access to skill content at initialization time. By specifying skills in the agent's `skills:` frontmatter field, the skill's `SKILL.md` content is included in the agent's context when spawned. This ensures the agent has access to reusable instructions, bash scripts, or formatting rules without needing to read additional files during execution.

Example frontmatter:
```yaml
---
name: story-writer
skills: [story-metrics, i18n]
---
```

### Usage Patterns

- **Directory names**: N/A (mechanism, not storage)
- **File names**: N/A
- **Code references**: "Preload the skill via frontmatter", "The agent preloads changelog skill"

### Related Terms

- skill, agent, frontmatter

## nesting-policy

Architectural rules governing which component types can invoke which others.

### Definition

The nesting policy defines allowed and prohibited invocation patterns between commands, subagents, and skills. This policy ensures a clean separation between orchestration (commands, subagents) and knowledge (skills).

**Allowed invocations:**
- Command -> Skill (preload via `skills:` frontmatter)
- Command -> Subagent (via Task tool)
- Subagent -> Skill (preload via `skills:` frontmatter)
- Skill -> Skill (preload via `skills:` frontmatter for composable knowledge)

**Prohibited invocations:**
- Skill -> Subagent (skills are passive knowledge, not orchestrators)
- Skill -> Command (skills cannot invoke user-facing commands)
- Subagent -> Subagent (prevents deep nesting and context explosion)
- Subagent -> Command (subagents are invoked by commands, not the reverse)

The guiding principle is "thin commands and subagents, comprehensive skills":
- Commands: Orchestration only (~50-100 lines)
- Subagents: Orchestration only (~20-40 lines)
- Skills: Comprehensive knowledge (~50-150 lines)

Skills can preload other skills for composable knowledge (e.g., write-spec preloads translate for i18n enforcement).

### Usage Patterns

- **Directory names**: N/A (policy, not storage)
- **File names**: Documented in root `CLAUDE.md` under Architecture Policy
- **Code references**: "Follow the nesting policy", "This violates nesting policy"

### Related Terms

- command, agent, skill, orchestrator

## hook

A callback mechanism that executes code at specific points in the Claude Code tool lifecycle.

### Definition

Hooks are triggered at defined points in tool execution workflows to enforce policies or perform automatic actions. Workaholic currently uses PostToolUse hooks to validate file operations (e.g., checking that ticket files meet format requirements before they are saved). Hooks are configured in a plugin's `hooks/hooks.json` file and can execute shell scripts or other commands based on matching criteria.

Claude Code automatically loads `hooks/hooks.json` from the standard location (`plugins/<name>/hooks/hooks.json`) without requiring an explicit manifest entry. The `hooks` field in `plugin.json` is only needed for non-standard hook file locations. Do not declare standard-location hooks in the manifest, as this causes a "Duplicate hooks file detected" error.

### Usage Patterns

- **Directory names**: `plugins/<name>/hooks/`
- **File names**: `hooks.json` (configuration), `*.sh` (executable scripts)
- **Code references**: "Add a PostToolUse hook", "Hook validates before saving", "Hook configuration in hooks.json"

### Hook Types

- **PostToolUse**: Executes after a tool has been invoked, useful for validation or automatic processing

### Auto-loading Behavior

- Standard location `plugins/<name>/hooks/hooks.json` is automatically loaded by Claude Code
- No manifest entry (`hooks` field in `plugin.json`) is needed for standard-location hooks
- The `hooks` field is only required for non-standard hook file paths

### Related Terms

- rule, plugin, PostToolUse

## PostToolUse

A hook lifecycle event that triggers after Claude Code tool execution completes.

### Definition

PostToolUse is a hook trigger point that allows plugins to execute validation or side-effect code immediately after a tool (like Write or Edit) completes successfully. In Workaholic, PostToolUse hooks are used to validate ticket file operations, ensuring that newly created or modified ticket files meet format and location requirements before they are fully persisted.

### Usage Patterns

- **Directory names**: N/A (hook type, not storage)
- **File names**: Referenced in `hooks/hooks.json` matcher configurations
- **Code references**: "PostToolUse hook validates files", "PostToolUse configuration for Write|Edit"

### Related Terms

- hook, rule, plugin

## TiDD

Ticket-Driven Development: a methodology where tickets serve as the single source of truth for planned and completed work.

### Definition

TiDD (Ticket-Driven Development) is the core philosophy of Workaholic. It reframes development workflows around tickets as persistent, searchable records of intent and outcome. Rather than external issue trackers, tickets live in the repository alongside code, making full development history accessible and preserving semantic context. Each ticket captures what should change (Overview, Implementation Steps), what actually happened (Final Report, Discovered Insights), and what was learned (Discovered Insights). The workflow enforces a discipline: plan (create ticket), implement (drive), and document (story). This preserves the "why" behind decisions and transforms backlogs from transient task lists into historical assets.

### Usage Patterns

- **Directory names**: N/A (philosophy, not storage)
- **File names**: Referenced in README.md and project documentation
- **Code references**: "TiDD philosophy", "Ticket-Driven Development approach", "In-repository tickets"

### Related Terms

- ticket, drive, story, archive

## context-window

The isolated conversation context in which a subagent executes.

### Definition

A context window is the conversation memory available to an agent when it executes. When agents run in isolated contexts, they preserve the main conversation's context window for orchestration while handling implementation details in their own dedicated spaces. This prevents context pollution from extensive file reads or complex analysis.

### Usage Patterns

- **Directory names**: N/A (concept, not storage)
- **File names**: N/A
- **Code references**: "Preserve context window", "Run in isolated context", "Context window pollution"

### Related Terms

- agent, orchestrator

## driver (Deprecated)

Previous intermediate agent for implementing individual tickets during `/drive` workflow. See `drive-workflow` skill for current implementation pattern.

### Definition

The driver subagent was previously invoked by the `/drive` command to implement individual tickets in an isolated context. This pattern was removed to improve visibility and preserve modification history in the main conversation context. The `/drive` command now directly invokes the drive-workflow skill inline, eliminating context isolation issues and improving debugging capabilities.

### Related Terms

- drive, drive-workflow, agent
