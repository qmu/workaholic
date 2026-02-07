---
title: Quality Policy
description: Code quality standards, linting, formatting, and review processes
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](quality.md) | [Japanese](quality_ja.md)

# 1. Quality Policy

This document describes the code quality practices observed in the Workaholic repository. Quality enforcement in Workaholic relies on architectural conventions, rule files, and AI-driven review rather than traditional linting and formatting tools.

## 2. Architectural Quality Standards

### 2-1. Design Principles

[Explicit] The architecture follows a "thin commands and subagents, comprehensive skills" principle documented in `CLAUDE.md`. Commands are approximately 50-100 lines, subagents 20-40 lines, and skills 50-150 lines. This enforces separation of concerns between orchestration (commands, agents) and knowledge (skills).

### 2-2. Nesting Policy

[Explicit] A strict component nesting hierarchy prevents circular dependencies: commands can invoke skills and subagents; subagents can invoke skills and subagents; skills can only invoke skills. This is enforced by documentation convention rather than runtime checks.

### 2-3. Shell Script Principle

[Explicit] Complex inline shell commands are prohibited in agent and command markdown files. All multi-step or conditional shell operations must be extracted to bundled scripts in `skills/<name>/sh/<script>.sh`. This ensures consistency, testability, and permission-free execution.

## 3. Formatting Standards

### 3-1. Heading Numbering

[Explicit] H2 and H3 headings use numbered format: `## 1. Section`, `### 1-1. Subsection`. H4 headings are numbered only when it helps identify topics. This applies to specs, terms, stories, and skills but not READMEs or configuration docs.

### 3-2. File Naming

[Explicit] Files use kebab-case naming (`getting-started.md`, `command-reference.md`) with exceptions for `README.md` and `README_ja.md`. Translation files use `_ja` suffix.

### 3-3. Written Language

[Explicit] All code, code comments, commit messages, pull requests, and documentation outside `.workaholic/` must be in English. The `.workaholic/` directory allows English or Japanese (i18n).

## 4. Review Processes

### 4-1. Human-in-the-Loop Approval

[Explicit] Every ticket implementation in `/drive` requires explicit developer approval before committing. This serves as a manual code review step.

### 4-2. Performance Analysis

[Explicit] The `performance-analyst` subagent evaluates decision-making quality during `/report`, providing automated review of development patterns.

### 4-3. Section Review

[Explicit] The `section-reviewer` subagent reviews story sections 5-8 during report generation.

## 5. Lint Configuration

Not observed. No ESLint, Prettier, Biome, EditorConfig, or other linting/formatting tools are configured. This is consistent with the project being pure markdown, JSON, and shell scripts rather than application code.

## 6. Observations

- [Explicit] Quality is enforced through architectural conventions and documentation rules rather than automated tooling.
- [Explicit] The general rule requires markdown files to be linked when referenced, improving navigability.
- [Explicit] Mermaid diagrams are required for visual documentation, prohibiting ASCII art.
- [Inferred] The reliance on AI-driven review (performance-analyst, section-reviewer) rather than traditional code review tools reflects the project's nature as an AI-augmented development workflow.

## 7. Gaps

- Not observed: No shellcheck or shell script linting for the 28+ bundled scripts.
- Not observed: No markdown linting (markdownlint, remark-lint).
- Not observed: No JSON schema validation beyond basic `jq empty` checks in CI.
- Not observed: No automated checks for the nesting policy or size constraints on commands/agents/skills.
