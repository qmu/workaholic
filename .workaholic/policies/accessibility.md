---
title: Accessibility Policy
description: Internationalization, localization, and content accessibility practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](accessibility.md) | [Japanese](accessibility_ja.md)

# 1. Accessibility Policy

This document describes the accessibility and internationalization practices observed in the Workaholic repository. As a CLI-based developer tool, accessibility primarily concerns language support and documentation clarity rather than UI accessibility standards.

## 2. Internationalization (i18n)

### 2-1. Bilingual Documentation

[Explicit] Every document in `.workaholic/` must have a corresponding `_ja.md` Japanese translation. This is enforced as a critical rule in the `translate` skill: "This is not optional. Every document change in `.workaholic/` requires its translation counterpart."

### 2-2. Translation Policy

[Explicit] The `translate` skill provides comprehensive policies for Japanese translation:
- Preserve code blocks, frontmatter keys, file paths, URLs, and markdown structure unchanged
- Translate prose content, frontmatter values (title, description), table cells, and image alt text
- Keep technical terms in English for developer documentation (plugin, command, skill, rule, ticket, etc.)
- Use formal/polite tone (desu/masu style)

### 2-3. README Mirroring

[Explicit] Each language's README must link to documents in the same language. `README.md` links to English documents while `README_ja.md` links to `_ja.md` translations, maintaining parallel navigation structures.

### 2-4. Language Boundary

[Explicit] Only `.workaholic/` directory content may contain Japanese. All code, code comments, commit messages, pull requests, and documentation outside `.workaholic/` must be in English.

## 3. Content Accessibility

### 3-1. Documentation Structure

[Explicit] Numbered headings (`## 1. Section`, `### 1-1. Subsection`) provide clear document hierarchy. Mermaid diagrams replace ASCII art for better rendering across platforms.

### 3-2. Self-Contained Definitions

[Explicit] Term definitions in `.workaholic/terms/` are written as self-contained paragraphs that incorporate definition, usage context, examples, and related concepts, making each entry readable without cross-referencing.

### 3-3. Onboarding Documentation

[Explicit] User guides in `.workaholic/guides/` cover getting started, commands, and workflow. The root `README.md` provides a quick start with a concrete session example.

## 4. Supported Languages

| Code | Language | Coverage |
| --- | --- | --- |
| en | English | Primary language for all content |
| ja | Japanese | Full translation of `.workaholic/` documentation |

The `translate` skill lists additional supported languages (zh, ko, de, fr, es) but no translations for these languages currently exist.

## 5. Observations

- [Explicit] Bilingual documentation is comprehensive, covering guides, specs, terms, stories, and policies.
- [Explicit] Technical terms are deliberately kept in English even in Japanese translations to maintain precision.
- [Explicit] The i18n rule is loaded as a rule file (`i18n.md`) applying to relevant paths.
- [Inferred] The extensive i18n infrastructure (dedicated translate skill, i18n rule, _ja suffix convention) suggests the primary developer audience includes Japanese speakers.

## 6. Gaps

- Not observed: No right-to-left (RTL) language support.
- Not observed: No screen reader optimization or ARIA attributes (not applicable for CLI tool).
- Not observed: No automated translation quality checks or consistency validation between English and Japanese versions.
- Not observed: Translations for the 4 additional languages listed in the translate skill (zh, ko, de, fr, es).
