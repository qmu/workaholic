---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-01-27
commit_hash: b262207
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

Commands are the primary user interface for plugins. Users invoke them with a slash prefix (e.g., `/commit`, `/ticket`). Each command has a markdown file in the plugin's `commands/` directory that defines its behavior and instructions.

### Usage Patterns

- **Directory names**: `plugins/<name>/commands/`
- **File names**: `commit.md`, `pull-request.md`, `sync-work.md`
- **Code references**: "Run `/commit` to...", "The `/ticket` command..."

### Related Terms

- skill, plugin

## skill

A helper sub-routine that is not directly user-invocable.

### Definition

Skills are internal routines that support commands or other operations. Unlike commands, users cannot invoke skills directly with a slash prefix. They are typically called by commands or triggered automatically. Skills are defined in a plugin's `skills/` directory.

### Usage Patterns

- **Directory names**: `plugins/<name>/skills/`
- **File names**: `archive-ticket.md`
- **Code references**: "The archive-ticket skill handles..."

### Related Terms

- command, plugin

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
- **Writer agents**: Generate documentation (spec-writer, terminology-writer, story-writer, changelog-writer)
- **Analyst agents**: Evaluate and analyze (performance-analyst)
- **Creator agents**: Perform external operations (pr-creator)

### Usage Patterns

- **Directory names**: `plugins/<name>/agents/`
- **File names**: `performance-analyst.md`, `spec-writer.md`, `story-writer.md`, `changelog-writer.md`, `pr-creator.md`, `terminology-writer.md`
- **Code references**: "Invoke the story-writer agent", "The changelog-writer agent handles...", "Spawn the agent via Task tool"

### Related Terms

- plugin, command, skill, orchestrator

## orchestrator

A command that coordinates multiple agents to complete a complex workflow.

### Definition

An orchestrator is a command that delegates specialized work to multiple agents rather than performing tasks inline. The orchestrator gathers initial context, invokes agents (potentially in parallel for performance), and consolidates their outputs. This pattern preserves the main conversation's context window while enabling complex multi-step workflows.

Examples:
- `/pull-request` orchestrates changelog-writer, story-writer, spec-writer, terminology-writer concurrently, then pr-creator sequentially

### Usage Patterns

- **Directory names**: N/A (pattern, not storage)
- **File names**: N/A
- **Code references**: "The command acts as an orchestrator", "Orchestrate the agents in parallel"

### Related Terms

- command, agent, concurrent execution
