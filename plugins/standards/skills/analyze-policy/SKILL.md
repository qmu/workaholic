---
name: analyze-policy
description: Generic framework for policy-based repository analysis. Provides output templates, inference guidelines, and context gathering scripts.
allowed-tools: Bash
skills: []
user-invocable: false
---

# Analyze Policy

Generic framework for analyzing a repository from a specific policy domain. Policy domain definitions (prompts, sections) are provided by the caller.

## Gather Context

Run the bundled script to collect policy-specific information:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/analyze-policy/scripts/gather.sh <policy-slug> [base-branch]
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

- **Only document what is implemented**: Every policy statement must describe something that is actually implemented and executable in the codebase -- a CI check, hook, script, linter rule, or test. Do not document conventions, aspirations, or practices that exist only in documentation.
- **Cite the implementation**: After each statement, cite the mechanism that implements it (e.g., workflow file, hook script, linter config).
- **Mark gaps clearly**: Use "Not observed" for policy areas with no codebase evidence
- **No invention**: Never fabricate policies that do not exist in the codebase
- **No badges**: Do not use `[Explicit]`/`[Inferred]` or any other badge prefixes. If something is documented here, it is implemented. If it is not implemented, it does not belong here.

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
- All files reside in `.workaholic/policies/`
