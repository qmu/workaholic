---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-02-12
commit_hash: f385117
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# Core Concepts

Fundamental building blocks of the Workaholic plugin system.

## plugin

A plugin packages related Claude Code extensions into a single distributable unit containing commands, skills, rules, and agents. Each plugin has its own directory under `plugins/` (e.g., `plugins/core/`) with a `.claude-plugin/plugin.json` metadata file. Plugins are referenced as "Install the core plugin" or "Core plugin commands" in documentation. Related terms: command, skill, rule, agent.

## command

A command is a user-invocable slash action that performs a specific task, serving as the primary user interface for plugins. Users invoke commands with a slash prefix (e.g., `/ticket`, `/drive`, `/report`). Each command is defined by a markdown file in `plugins/<name>/commands/` such as `ticket.md` or `drive.md`. Related terms: skill, plugin.

## skill

A skill is a helper sub-routine that is not directly user-invocable, supporting commands or other operations internally. Skills are defined in `plugins/<name>/skills/<skill-name>/` directories, each containing a `SKILL.md` definition and optional `sh/` directory with shell scripts. Skills can be preloaded by agents via the `skills:` frontmatter field. Current utility skills include archive-ticket, branching, create-pr, discover-history, and drive-workflow. Content skills include write-story, write-spec, write-terms, write-changelog, and create-ticket. Cross-cutting principle skills include managers-principle and leaders-principle. Related terms: command, plugin, agent, principle.

## rule

A rule provides persistent guidelines and constraints that shape Claude's behavior within a plugin's scope, defining coding standards, documentation requirements, or behavioral constraints. Rules are stored in `plugins/<name>/rules/` with files like `general.md` or `typescript.md`. Related terms: plugin, command.

## agent

An agent (or subagent) is a specialized AI subprocess that runs with specific prompts and tools in its own context window, preserving the parent conversation's context while handling focused tasks. Agents are defined in `plugins/<name>/agents/` with files like `spec-writer.md`, `story-writer.md`, `ticket-organizer.md`, or hierarchical agents like `architecture-manager.md` and `quality-lead.md`. Commands invoke agents via the Task tool. Common types include writer agents (documentation generation), analyst agents (evaluation), creator agents (external operations), search agents (finding related work), and hierarchical agents (managers and leads). The agent hierarchy includes managers (strategic outputs), leads (domain-specific implementation), and general-purpose agents. Related terms: plugin, command, skill, orchestrator, manager, lead.

## ticket-organizer

The ticket-organizer is a subagent that handles the complete ticket creation workflow during `/ticket`. It receives a feature description, performs parallel discovery tasks (searching archived tickets, exploring source code, checking for duplicates), and writes a new ticket file with proper structure and related history links. Defined in `plugins/<name>/agents/ticket-organizer.md`, it preloads branching, create-ticket, discover-history, and discover-source skills. Related terms: command, skill, ticket.

## orchestrator

An orchestrator is a command that coordinates multiple agents to complete complex workflows, delegating specialized work rather than performing tasks inline. The orchestrator gathers initial context, invokes agents (potentially in parallel), and consolidates outputs. For example, `/report` orchestrates changelog-writer, story-writer, spec-writer, terms-writer, and release-readiness concurrently, then pr-creator sequentially. This is a pattern, not a storage location. Related terms: command, agent, concurrent-execution.

## deny

A deny rule is a permission configuration in `.claude/settings.json` under `permissions.deny` that blocks specific command patterns across the entire project, including subagents. Unlike agent-specific prohibitions, deny rules are enforced centrally before execution. Example: `"Bash(git -C:*)"` blocks all `git -C` command variations. Related terms: rule, agent.

## preload

Preloading is the mechanism by which agents gain access to skill content at initialization time. By specifying skills in the agent's `skills:` frontmatter field (e.g., `skills: [story-metrics, i18n]`), the skill's SKILL.md content is included in the agent's context when spawned, providing access to reusable instructions, scripts, or formatting rules. Related terms: skill, agent, frontmatter.

## branching

The branching skill provides utility operations for checking current git branch state and creating timestamped topic branches when needed. Defined in `plugins/core/skills/branching/` with bundled shell scripts (`sh/check.sh`, `sh/create.sh`, `sh/check-version-bump.sh`), it replaced the previous manage-branch skill to avoid naming collision with the manager tier's manage- prefix convention. The skill is preloaded by ticket-organizer and referenced in report command for version bump detection. Related terms: skill, ticket-organizer, manager.

## constraint

A constraint is a prescriptive boundary that narrows decision space for lead agents, produced by manager agents following the Constraint Setting workflow defined in managers-principle. Constraints are stored in `.workaholic/constraints/<domain>.md` where domain matches the manager's territory (project, architecture, quality). Each constraint file follows a structured template with frontmatter, summary, and constraint entries that specify what is bounded, rationale, which leaders are affected, falsifiable criteria, and review triggers. Constraints differ semantically from policies: constraints are manager-generated strategic boundaries, while policies are leader-generated observational documentation of implemented practices stored in `.workaholic/policies/`. Related terms: manager, lead, managers-principle, policy.

## principle

A principle is a cross-cutting behavioral rule that applies to all agents in a tier (managers or leads), encoded in principle skills rather than generated as output documents. Two principle skills exist: managers-principle (Constraint Setting workflow, Strategic Focus) and leaders-principle (Prior Term Consistency, Vendor Neutrality). The term "principle" distinguishes these fundamental behavioral rules from "policy" which refers to leader-generated output artifacts documenting implemented practices in `.workaholic/policies/`. This terminology shift resolved semantic ambiguity when the managers-policy and leaders-policy skills were renamed to managers-principle and leaders-principle. Related terms: managers-principle, leaders-principle, policy, skill.

## nesting-policy

The nesting policy defines allowed and prohibited invocation patterns between commands, subagents, and skills, ensuring clean separation between orchestration and knowledge. Allowed: Command→Skill (preload), Command→Subagent (Task tool), Subagent→Skill (preload), Subagent→Subagent (Task tool), Skill→Skill (preload). Prohibited: Skill→Subagent, Skill→Command, Subagent→Command. The guiding principle is "thin commands and subagents (~20-100 lines), comprehensive skills (~50-150 lines)". Multi-level nesting (e.g., scanner→spec-writer→architecture-analyst) is acceptable when child invocations are parallel. Documented in root CLAUDE.md under Architecture Policy. Related terms: command, agent, skill, orchestrator.

## viewpoint

A viewpoint is a predefined architectural lens for analyzing a repository from a specific perspective. Workaholic defines 8 viewpoints: stakeholder, model, usecase, infrastructure, application, component, data, and feature. Each viewpoint has analysis prompts, a Mermaid diagram type, and output sections. During `/scan`, the spec-writer orchestrates 8 parallel architecture-analyst subagents, one per viewpoint, producing `.workaholic/specs/<slug>.md` and `<slug>_ja.md`. Viewpoint definitions live in the spec-writer agent (the caller), while the analyze-viewpoint skill provides the generic analysis framework. Related terms: spec, architecture-analyst, analyze-viewpoint, scan.

## viewpoint-analyst

A viewpoint-analyst (e.g., stakeholder-analyst, model-analyst) is a thin subagent that analyzes the repository from a specific viewpoint perspective. It uses the analyze-viewpoint skill to gather context, read overrides from the user's CLAUDE.md, and write a viewpoint spec document with Mermaid diagrams and an Assumptions section distinguishing `[Explicit]` from `[Inferred]` knowledge. Each of the 8 viewpoints has its own dedicated analyst agent defined in `plugins/core/agents/<slug>-analyst.md`. Invoked directly by the scanner rather than through an intermediate writer. Related terms: viewpoint, scanner, analyze-viewpoint.

## policy-analyst

A policy-analyst (e.g., test-policy-analyst, security-policy-analyst) is a thin subagent that analyzes the repository from a specific policy domain perspective. It uses the analyze-policy skill to gather context and document only policies that are actually implemented and executable in the codebase. Each policy statement must cite its enforcement mechanism (CI check, git hook, linter rule, automated script, or test). Aspirational practices documented only in README or CLAUDE.md without code enforcement are excluded. Gaps where no evidence is found are marked as "Not observed" rather than omitted. Each of the 7 policy domains has its own dedicated analyst agent defined in `plugins/core/agents/<slug>-policy-analyst.md`. Invoked directly by the `/scan` command rather than through an intermediate subagent. Related terms: policy, scan, analyze-policy.

## scanner (Deprecated)

The scanner was a subagent that orchestrated 17 documentation agents in parallel. This orchestration has been migrated directly into the `/scan` command to provide real-time per-agent progress visibility. The scanner agent file (`plugins/core/agents/scanner.md`) has been removed, and the `/scan` command now invokes all 17 agents (8 viewpoint analysts, 7 policy analysts, changelog-writer, terms-writer) directly using parallel Task tool calls. This flattening from 2-level to 1-level nesting improves user transparency while maintaining the same parallel execution pattern. Related terms: scan, orchestrator, concurrent-execution.

## run_in_background

The run_in_background parameter is a Bash tool option that controls whether commands execute in the background. When set to `true`, the command runs asynchronously and the user is notified upon completion. However, background execution has a critical constraint: agents running in background mode automatically have Write and Edit tool permissions denied, preventing file operations. For scan agents and other documentation writers that require Write/Edit permissions, `run_in_background` must be explicitly set to `false` (the default). The `/scan` command includes explicit constraints that all 17 agent Task calls must use `run_in_background: false` to preserve Write/Edit permissions. Related terms: agent, Task tool, scan.

## hook

A hook is a callback mechanism that executes code at specific points in the Claude Code tool lifecycle. Workaholic uses PostToolUse hooks to validate file operations. Hooks are configured in `plugins/<name>/hooks/hooks.json` and can execute shell scripts based on matching criteria. Claude Code automatically loads hooks.json from the standard location without requiring a manifest entry. Related terms: rule, plugin, PostToolUse.

## PostToolUse

PostToolUse is a hook lifecycle event that triggers after a Claude Code tool (like Write or Edit) completes successfully. In Workaholic, PostToolUse hooks validate ticket file operations, ensuring files meet format and location requirements. Referenced in `hooks/hooks.json` matcher configurations. Related terms: hook, rule, plugin.

## TiDD

TiDD (Ticket-Driven Development) is Workaholic's core philosophy where tickets serve as the single source of truth for planned and completed work. Rather than external issue trackers, tickets live in the repository alongside code, capturing what should change (Overview, Implementation Steps), what happened (Final Report), and what was learned (Discovered Insights). The workflow enforces: plan (create ticket), implement (drive), document (story). Referenced in README.md and project documentation. Related terms: ticket, drive, story, archive.

## context-window

A context window is the isolated conversation memory available to an agent during execution. When agents run in isolated contexts, they preserve the main conversation's context window for orchestration while handling implementation details in dedicated spaces, preventing context pollution from extensive file reads or complex analysis. Related terms: agent, orchestrator.

## manager

A manager is a strategic agent that sits above leads in the agent hierarchy, producing high-level outputs that leaders depend on for context. Managers are defined by the define-manager schema in `.claude/rules/define-manager.md`, which requires Role, Responsibility, Goal, Outputs, and Default Policies sections. Three managers exist: project-manager (business context, stakeholders, timeline), architecture-manager (system structure, components, layers), and quality-manager (quality standards, assurance processes). Each manager has a corresponding `manage-<domain>` skill in `plugins/core/skills/` and a thin agent file in `plugins/core/agents/*-manager.md`. Managers preload the managers-principle skill for cross-cutting behavioral principles and follow a Constraint Setting workflow to produce structured constraint files at `.workaholic/constraints/<domain>.md`. Related terms: lead, define-manager, managers-principle, constraint, agent, skill.

## lead

A lead is a domain-specific agent responsible for a particular aspect of the project, consuming manager outputs to make informed domain decisions. Leads are defined by the define-lead schema in `.claude/rules/define-lead.md`, which requires Role, Responsibility, Goal, and Default Policies sections. Current leads include architecture-lead, security-lead, quality-lead, test-lead, a11y-lead, ux-lead, db-lead, delivery-lead, infra-lead, observability-lead, and recovery-lead. Each lead has a corresponding `lead-<speciality>` skill in `plugins/core/skills/` and a thin agent file in `plugins/core/agents/*-lead.md`. Leads preload the leaders-principle skill for cross-cutting behavioral principles including Prior Term Consistency. Related terms: manager, define-lead, leaders-principle, agent, skill.

## define-manager

Define-manager is a schema enforcement rule at `.claude/rules/define-manager.md` that validates manager skill and agent file structure. It applies to `plugins/core/skills/manage-*/SKILL.md` and `plugins/core/agents/*-manager.md` via path-scoped frontmatter. The schema requires five sections (Role, Responsibility, Goal, Outputs, Default Policies) and four policy subsections (Implementation, Review, Documentation, Execution). The Outputs section is unique to managers, defining structured artifacts that leaders consume. Related terms: manager, define-lead, schema, rule.

## define-lead

Define-lead is a schema enforcement rule at `.claude/rules/define-lead.md` that validates lead skill and agent file structure. It applies to `plugins/core/skills/lead-*/SKILL.md` and `plugins/core/agents/*-lead.md` via path-scoped frontmatter. The schema requires four sections (Role, Responsibility, Goal, Default Policies) and four policy subsections (Implementation, Review, Documentation, Execution). Unlike define-manager, leads do not have an Outputs section as they produce domain-specific documentation rather than strategic artifacts. Related terms: lead, define-manager, schema, rule.

## managers-principle

The managers-principle is a cross-cutting behavioral principle skill that all manager agents preload, parallel to leaders-principle. Defined in `plugins/core/skills/managers-principle/SKILL.md`, it contains two principle sections: Constraint Setting (workflow for identifying, proposing, and producing constraints) and Strategic Focus (managers produce actionable outputs consumable by leaders, not aspirational statements). Each manager agent lists managers-principle as its first preloaded skill in frontmatter. Related terms: manager, leaders-principle, skill, principle.

## leaders-principle

The leaders-principle is a cross-cutting behavioral principle skill that all lead agents preload, parallel to managers-principle. Defined in `plugins/core/skills/leaders-principle/SKILL.md`, it contains Prior Term Consistency and Vendor Neutrality principles. Prior Term Consistency requires leads to respect existing terms, prefer 1-word over multi-word expressions, and maintain ubiquitous language across artifacts. Each lead agent lists leaders-principle as its first preloaded skill in frontmatter. Related terms: lead, managers-principle, skill, principle.

## driver (Deprecated)

The driver was a previous intermediate subagent for implementing individual tickets during `/drive` workflow, now replaced by the drive-workflow skill. The pattern was removed to improve visibility and preserve modification history in the main conversation context. The `/drive` command now directly invokes drive-workflow inline. Related terms: drive, drive-workflow, agent.
