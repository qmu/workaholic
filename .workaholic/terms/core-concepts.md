---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-01-27
commit_hash: 4938294
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

- **archive-ticket**: Moves completed tickets to branch archive
- **changelog**: Generates changelog entries from archived tickets
- **story-metrics**: Calculates commit counts, duration, velocity
- **spec-context**: Gathers codebase context for spec updates
- **terms-context**: Gathers context for terminology updates
- **pr-ops**: Creates or updates GitHub pull requests
- **ticket-format**: Defines ticket file structure and frontmatter
- **drive-workflow**: Implementation workflow for processing tickets
- **command-prohibition**: Git command restrictions for subagents
- **i18n**: Translation requirements for `.workaholic/` documentation

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
- **Analyst agents**: Evaluate and analyze (performance-analyst)
- **Creator agents**: Perform external operations (pr-creator)

### Usage Patterns

- **Directory names**: `plugins/<name>/agents/`
- **File names**: `performance-analyst.md`, `spec-writer.md`, `story-writer.md`, `changelog-writer.md`, `pr-creator.md`, `terms-writer.md`
- **Code references**: "Invoke the story-writer agent", "The changelog-writer agent handles...", "Spawn the agent via Task tool"

### Related Terms

- plugin, command, skill, orchestrator

## orchestrator

A command that coordinates multiple agents to complete a complex workflow.

### Definition

An orchestrator is a command that delegates specialized work to multiple agents rather than performing tasks inline. The orchestrator gathers initial context, invokes agents (potentially in parallel for performance), and consolidates their outputs. This pattern preserves the main conversation's context window while enabling complex multi-step workflows.

Examples:
- `/report` orchestrates changelog-writer, story-writer, spec-writer, terms-writer concurrently, then pr-creator sequentially

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
