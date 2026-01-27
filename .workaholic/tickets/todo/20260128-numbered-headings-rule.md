---
title: Add numbered headings rule to general rules
category: Enhance
layer: Rule
---

## Overview

Document the numbered headings convention as a formal rule in `plugins/core/rules/general.md`. The convention is already used consistently in stories and skills but not documented as a requirement.

## Current State

The project follows numbered headings in practice:
- Stories use `## 1. Overview`, `## 2. Motivation`, `### 4.1. Change title`, etc.
- Skills use similar patterns

But `general.md` only has three rules:
1. Never commit without explicit user request
2. Never use `git -C`
3. Link markdown files when referenced

## Desired State

Add a fourth rule documenting the numbered headings convention:

- **H2 (##)**: Always numbered - `## 1. Purpose`, `## 2. Details`
- **H3 (###)**: Always numbered with parent - `### 1.1. Subsection`, `### 2.3. Another`
- **H4 (####)**: Optional - number only when it helps readers identify topics

## Implementation

### File to Modify

`plugins/core/rules/general.md`

### Changes

Add a new rule after the existing three:

```markdown
- **Number headings in documentation** - Use numbered headings for h2 and h3 levels: `## 1. Section`, `### 1.1. Subsection`. For h4, number only when it helps identify topics. Applies to specs, terms, stories, and skills. Exceptions: READMEs and configuration docs.
```

## Notes

- This formalizes an existing convention rather than introducing a new one
- Exceptions for READMEs preserve flexibility for top-level documentation
- The h4 guidance ("only when helpful") avoids over-numbering nested content
