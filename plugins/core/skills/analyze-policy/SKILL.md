---
name: analyze-policy
description: Generic framework for policy-based repository analysis. Provides output templates, inference guidelines, and context gathering scripts.
allowed-tools: Bash
skills:
  - translate
user-invocable: false
---

# Analyze Policy

Generic framework for analyzing a repository from a specific policy domain. Policy domain definitions (prompts, sections) are provided by the caller.

## Gather Context

Run the bundled script to collect policy-specific information:

```bash
bash .claude/skills/analyze-policy/sh/gather.sh <policy-slug> [base-branch]
```

Default base branch is `main`.

## Output Template

Each policy produces a document following this structure:

```markdown
---
title: <Policy Name> Policy
description: <policy description>
category: developer
modified_at: <ISO 8601 datetime>
commit_hash: <from context>
---

[English](<slug>.md) | [Japanese](<slug>_ja.md)

# <Policy Name> Policy

<introductory paragraph explaining the policy's scope>

## <Section 1 from policy definition>

<content with analysis>

## <Section 2 from policy definition>

<content with analysis>

...

## Observations

<what was found in the codebase>

## Gaps

<areas where no evidence was found, marked as "not observed">
```

## Inference Guidelines

- **Document what exists**: Describe observable practices, configurations, and patterns
- **Mark gaps clearly**: Use "Not observed" for policy areas with no codebase evidence
- **Explicit vs Inferred**: Prefix findings with `[Explicit]` or `[Inferred]`
- **No invention**: Never fabricate policies that do not exist in the codebase
- **Recommendations are separate**: If suggesting improvements, place them in a distinct "Recommendations" section

## Comprehensiveness Policy

- Document everything discoverable in the codebase
- Do not judge any aspect as "not worth documenting"
- Mark absent areas as "not observed" rather than omitting them
- Each policy domain should produce substantive content even when evidence is sparse

## Frontmatter

Required for every policy file (follows write-spec conventions):

```yaml
---
title: <Policy Name> Policy
description: <brief description>
category: developer
modified_at: <ISO 8601 datetime>
commit_hash: <from context COMMIT section>
---
```

## File Naming

- Policy documents use their slug as filename: `test.md`, `security.md`
- Translations use `_ja` suffix: `test_ja.md`, `security_ja.md`
- All files reside in `.workaholic/policies/`
