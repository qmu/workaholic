---
title: Accessibility Policy
description: Internationalization, localization, and content accessibility practices
category: developer
modified_at: 2026-03-10T12:00:00+00:00
commit_hash: f76bde2
---

[English](accessibility.md) | [Japanese](accessibility_ja.md)

# Accessibility Policy

This document describes the accessibility and internationalization practices implemented in the Workaholic repository. As a CLI-based developer tool, accessibility primarily concerns language support, documentation clarity, and content structure rather than UI accessibility standards.

## Internationalization

### Bilingual Documentation Requirement

Every document in `.workaholic/` must have a corresponding `_ja.md` Japanese translation when English is the primary language (`plugins/drivin/skills/translate/SKILL.md`, lines 121-127: "CRITICAL RULE: When creating or editing any `.md` file in `.workaholic/`, you MUST check the consumer project's root CLAUDE.md to determine the primary written language"). This requirement is enforced through the `translate` skill preloaded by all documentation writer subagents.

### Primary Language Detection Logic

The translation system determines which translations to produce based on the consumer project's primary language (`plugins/drivin/skills/translate/SKILL.md`, lines 123-127):

- If primary is English or bilingual English/Japanese: produce `_ja.md` translations
- If primary is Japanese only: do NOT produce `_ja.md` files (would duplicate primary content); produce `_en.md` if secondary language declared
- If primary is another language: produce translations for declared secondary languages with appropriate suffix

This logic prevents duplicate content when the primary language matches a potential translation target (`plugins/drivin/rules/i18n.md`, lines 58-59: "Never duplicate the primary language as a translation").

### Translation Guidelines

The `translate` skill (`plugins/drivin/skills/translate/SKILL.md`) provides comprehensive policies for Japanese translation:

- Preserve unchanged: code blocks, frontmatter keys, file paths, URLs, markdown structure, HTML tags
- Translate: prose content, frontmatter values (title, description), table cells, image alt text
- Keep technical terms in English for developer documentation (plugin, command, skill, rule, ticket, workflow, etc.)
- Use formal/polite tone (desu/masu style for Japanese)
- Preserve original meaning over literal translation

### Language Boundary

Content language is determined by location (`CLAUDE.md`, lines 9-16):

- `.workaholic/` directory: English or Japanese (i18n enforced)
- All other content: English only (code, comments, commit messages, pull requests, documentation outside `.workaholic/`)

This boundary is documented as a project-level policy and enforced through documentation review processes.

### README Link Mirroring

Each language's README must link to documents in the same language (`plugins/drivin/skills/translate/SKILL.md`, lines 143-149). `README.md` links to English documents while `README_ja.md` links to `_ja.md` translations, maintaining parallel navigation structures. This ensures users stay within their language context when navigating documentation.

## Supported Languages

| Code | Language | Coverage | Implementation |
| --- | --- | --- | --- |
| en | English | Primary language for all content | Full |
| ja | Japanese | Full translation of `.workaholic/` documentation | Full |
| zh | Chinese | Listed in translate skill | Not implemented |
| ko | Korean | Listed in translate skill | Not implemented |
| de | German | Listed in translate skill | Not implemented |
| fr | French | Listed in translate skill | Not implemented |
| es | Spanish | Listed in translate skill | Not implemented |

Japanese translations are comprehensive, covering guides, specs, terms, stories, and policies (43 `_ja.md` files observed in `.workaholic/` directory out of 395 total markdown files, representing 10.9% coverage for bilingual content).

## Translation Workflow

### File Naming Convention

Translations use suffix-based naming in the same directory as the original (`plugins/drivin/rules/i18n.md`, lines 14-21, 38-39):

```
.workaholic/specs/
  feature.md           # English
  feature_ja.md        # Japanese translation
  README.md            # English index
  README_ja.md         # Japanese index
```

ISO 639-1 language codes (two-letter codes) are used as suffixes.

### Manual Translation Process

Translation is performed manually following the `translate` skill guidelines. No automated translation tools or services are integrated. The workflow is (`plugins/drivin/skills/translate/SKILL.md`, lines 152-156):

1. Create or update primary language document first
2. Create or update translation counterpart (if applicable per decision logic)
3. Update all README files to maintain parallel link structure

### Technical Term Preservation

Technical terms remain in English even in Japanese translations (`plugins/drivin/skills/translate/SKILL.md`, lines 79-83). Core concepts (plugin, command, skill, rule, ticket, workflow), git terms (repository, branch, commit), and programming concepts (function, class, module, component) are kept in English to maintain technical precision and avoid ambiguity.

## Accessibility Testing

### Configuration Validation

GitHub Actions workflow (`.github/workflows/validate-plugins.yml`) validates:

- JSON syntax for marketplace and plugin configuration files (lines 23-29, 32-59)
- Required fields in plugin manifests (name, version)
- Skill file existence (lines 61-79)
- Marketplace-directory consistency (lines 81-102)

This runs on every push and pull request to the main branch.

### Ticket Format Validation

A validation hook (`plugins/drivin/hooks/validate-ticket.sh`) enforces ticket file standards:

- Filename format: `YYYYMMDDHHmmss-*.md` (lines 49-54)
- YAML frontmatter presence (lines 65-69)
- Required fields with format validation: `created_at` (ISO 8601), `author` (email), `type`, `layer`, `effort`, `commit_hash`, `category` (lines 83-186)
- Directory location constraints (todo/, icebox/, archive/) (lines 32-43)
- Author email validation rejecting anthropic.com addresses (lines 111-116)

This hook is invoked by Write/Edit operations targeting `.workaholic/tickets/` files.

### Context-Aware Rule Loading

The i18n rule (`plugins/drivin/rules/i18n.md`) uses path-based activation:

```yaml
---
paths:
  - '**/README*.md'
  - '.workaholic/**/*.md'
  - 'docs/**/*.md'
---
```

This ensures i18n policies apply only to relevant documentation files, not to code or configuration files.

### Diagram Syntax Validation

The diagrams rule (`plugins/drivin/rules/diagrams.md`) enforces Mermaid diagram syntax:

- Prohibits ASCII art diagrams with box-drawing characters (lines 18-22)
- Requires quoted labels containing special characters (`/`, `{`, `}`, `[`, `]`) to prevent GitHub rendering errors (lines 34-48)
- Applies to all markdown files via `paths: ['**/*.md']`

## Content Accessibility

### Structured Headings

Numbered headings provide clear document hierarchy. Policy documents use `## 1. Section`, `### 1-1. Subsection` format. This convention makes document structure explicit and improves navigation through table-of-contents tools.

### Visual Diagram Format

Mermaid diagrams replace ASCII art for better cross-platform rendering (`plugins/drivin/rules/diagrams.md`, lines 8-21):

- Renders natively in GitHub, VS Code, and most documentation systems
- Version-controllable and diffable
- Consistent rendering across platforms
- Interactive (zoomable, clickable)

ASCII art diagrams using box-drawing characters are prohibited (`plugins/drivin/rules/diagrams.md`, lines 18-22).

### Self-Contained Definitions

Term definitions in `.workaholic/terms/` are written as comprehensive single paragraphs incorporating definition, usage context, examples, and related concepts (`plugins/drivin/skills/write-terms/SKILL.md`, lines 62-72). This makes each entry readable without requiring cross-references, reducing cognitive load and improving accessibility for readers.

### Onboarding Documentation

User guides in `.workaholic/guides/` cover:

- Getting started
- Commands reference
- Development workflow

The root `README.md` provides a quick start with concrete examples. These materials serve as entry points for new users. All guides have corresponding Japanese translations (`getting-started_ja.md`, `commands_ja.md`, `workflow_ja.md`).

### Terminology Consistency

The `.workaholic/terms/` directory maintains consistent term definitions across five category files:

- `core-concepts.md` - plugin, command, skill, rule, agent
- `artifacts.md` - ticket, spec, story, changelog
- `workflow-terms.md` - drive, archive, sync, release
- `file-conventions.md` - kebab-case, frontmatter, icebox, archive
- `inconsistencies.md` - Known terminology issues

Each term is documented with definition, usage context, and relationships to other terms (`plugins/drivin/skills/write-terms/SKILL.md`, lines 61-71).

### Multi-Plugin Accessibility Roles

The trippin plugin introduces an explicit accessibility responsibility within its three-agent collaborative workflow. The Architect agent is assigned "Accessibility & Accommodability" as a core responsibility (`plugins/trippin/skills/trip-protocol/SKILL.md`, line 17), ensuring that accessibility considerations are structurally embedded in specification review during the trip workflow.

## Observations

- Bilingual documentation is comprehensive, covering all `.workaholic/` subdirectories (guides, specs, terms, stories, policies)
- Technical terms are deliberately preserved in English even in Japanese translations to maintain technical precision
- The i18n rule uses path-based activation (`paths` frontmatter) to apply only to documentation files
- Validation mechanisms focus on structural integrity (JSON syntax, frontmatter format, file existence) rather than content quality
- Translation workflow is manual and human-driven with no automated consistency checks
- The extensive i18n infrastructure (dedicated translate skill, i18n rule, _ja suffix convention, mandatory translation requirements) indicates primary developer audience includes Japanese speakers
- Context-aware rules prevent i18n requirements from applying to code or configuration files
- Diagram validation prevents rendering errors by enforcing proper Mermaid syntax
- Primary language detection logic prevents creating duplicate translation files when primary language matches translation target
- The rename from `plugins/core/` to `plugins/drivin/` consolidates the development plugin under a distinct identity while preserving all i18n and accessibility infrastructure unchanged
- The trippin plugin assigns accessibility review as a structural responsibility to the Architect agent, embedding accessibility into the collaborative specification workflow

## Gaps

- Not observed: Automated translation quality checks or consistency validation between English and Japanese versions
- Not observed: Right-to-left (RTL) language support or bidirectional text handling
- Not observed: Screen reader optimization or ARIA attributes (not applicable for CLI tool)
- Not observed: Translations for additional languages listed in translate skill (zh, ko, de, fr, es)
- Not observed: Automated accessibility testing tools (axe, Pa11y, etc., not applicable for CLI tool)
- Not observed: Color contrast validation or terminal color scheme considerations
- Not observed: Font rendering or character encoding validation
- Not observed: Translation memory or terminology database for consistency across documents
- Not observed: Trippin plugin i18n support (no `_ja.md` translations exist for trippin plugin documentation)
