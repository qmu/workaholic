---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-02-04
commit_hash:
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# Core Concepts

Fundamental building blocks of the Workaholic plugin system.

## plugin

A plugin packages related Claude Code extensions into a single distributable unit containing commands, skills, rules, and agents. Each plugin has its own directory under `plugins/` (e.g., `plugins/core/`) with a `.claude-plugin/plugin.json` metadata file. Plugins are referenced as "Install the core plugin" or "Core plugin commands" in documentation. Related terms: command, skill, rule, agent.

## command

A command is a user-invocable slash action that performs a specific task, serving as the primary user interface for plugins. Users invoke commands with a slash prefix (e.g., `/ticket`, `/drive`, `/report`). Each command is defined by a markdown file in `plugins/<name>/commands/` such as `ticket.md` or `drive.md`. Related terms: skill, plugin.

## skill

A skill is a helper sub-routine that is not directly user-invocable, supporting commands or other operations internally. Skills are defined in `plugins/<name>/skills/<skill-name>/` directories, each containing a `SKILL.md` definition and optional `sh/` directory with shell scripts. Skills can be preloaded by agents via the `skills:` frontmatter field. Current utility skills include archive-ticket, create-branch, create-pr, discover-history, format-commit-message, and drive-workflow. Content skills include write-story, write-spec, write-terms, write-changelog, and create-ticket. Related terms: command, plugin, agent.

## rule

A rule provides persistent guidelines and constraints that shape Claude's behavior within a plugin's scope, defining coding standards, documentation requirements, or behavioral constraints. Rules are stored in `plugins/<name>/rules/` with files like `general.md` or `typescript.md`. Related terms: plugin, command.

## agent

An agent (or subagent) is a specialized AI subprocess that runs with specific prompts and tools in its own context window, preserving the parent conversation's context while handling focused tasks. Agents are defined in `plugins/<name>/agents/` with files like `spec-writer.md`, `story-writer.md`, or `ticket-organizer.md`. Commands invoke agents via the Task tool. Common types include writer agents (documentation generation), analyst agents (evaluation), creator agents (external operations), and search agents (finding related work). Related terms: plugin, command, skill, orchestrator.

## ticket-organizer

The ticket-organizer is a subagent that handles the complete ticket creation workflow during `/ticket`. It receives a feature description, performs parallel discovery tasks (searching archived tickets, exploring source code, checking for duplicates), and writes a new ticket file with proper structure and related history links. Defined in `plugins/<name>/agents/ticket-organizer.md`, it preloads create-ticket, discover-history, and discover-source skills. Related terms: command, skill, ticket.

## orchestrator

An orchestrator is a command that coordinates multiple agents to complete complex workflows, delegating specialized work rather than performing tasks inline. The orchestrator gathers initial context, invokes agents (potentially in parallel), and consolidates outputs. For example, `/report` orchestrates changelog-writer, story-writer, spec-writer, terms-writer, and release-readiness concurrently, then pr-creator sequentially. This is a pattern, not a storage location. Related terms: command, agent, concurrent-execution.

## deny

A deny rule is a permission configuration in `.claude/settings.json` under `permissions.deny` that blocks specific command patterns across the entire project, including subagents. Unlike agent-specific prohibitions, deny rules are enforced centrally before execution. Example: `"Bash(git -C:*)"` blocks all `git -C` command variations. Related terms: rule, agent.

## preload

Preloading is the mechanism by which agents gain access to skill content at initialization time. By specifying skills in the agent's `skills:` frontmatter field (e.g., `skills: [story-metrics, i18n]`), the skill's SKILL.md content is included in the agent's context when spawned, providing access to reusable instructions, scripts, or formatting rules. Related terms: skill, agent, frontmatter.

## nesting-policy

The nesting policy defines allowed and prohibited invocation patterns between commands, subagents, and skills, ensuring clean separation between orchestration and knowledge. Allowed: Command→Skill (preload), Command→Subagent (Task tool), Subagent→Skill (preload), Skill→Skill (preload). Prohibited: Skill→Subagent, Skill→Command, Subagent→Subagent, Subagent→Command. The guiding principle is "thin commands and subagents (~20-100 lines), comprehensive skills (~50-150 lines)". Documented in root CLAUDE.md under Architecture Policy. Related terms: command, agent, skill, orchestrator.

## hook

A hook is a callback mechanism that executes code at specific points in the Claude Code tool lifecycle. Workaholic uses PostToolUse hooks to validate file operations. Hooks are configured in `plugins/<name>/hooks/hooks.json` and can execute shell scripts based on matching criteria. Claude Code automatically loads hooks.json from the standard location without requiring a manifest entry. Related terms: rule, plugin, PostToolUse.

## PostToolUse

PostToolUse is a hook lifecycle event that triggers after a Claude Code tool (like Write or Edit) completes successfully. In Workaholic, PostToolUse hooks validate ticket file operations, ensuring files meet format and location requirements. Referenced in `hooks/hooks.json` matcher configurations. Related terms: hook, rule, plugin.

## TiDD

TiDD (Ticket-Driven Development) is Workaholic's core philosophy where tickets serve as the single source of truth for planned and completed work. Rather than external issue trackers, tickets live in the repository alongside code, capturing what should change (Overview, Implementation Steps), what happened (Final Report), and what was learned (Discovered Insights). The workflow enforces: plan (create ticket), implement (drive), document (story). Referenced in README.md and project documentation. Related terms: ticket, drive, story, archive.

## context-window

A context window is the isolated conversation memory available to an agent during execution. When agents run in isolated contexts, they preserve the main conversation's context window for orchestration while handling implementation details in dedicated spaces, preventing context pollution from extensive file reads or complex analysis. Related terms: agent, orchestrator.

## driver (Deprecated)

The driver was a previous intermediate subagent for implementing individual tickets during `/drive` workflow, now replaced by the drive-workflow skill. The pattern was removed to improve visibility and preserve modification history in the main conversation context. The `/drive` command now directly invokes drive-workflow inline. Related terms: drive, drive-workflow, agent.
