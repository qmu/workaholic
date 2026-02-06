---
name: policy-analyst
description: Analyze repository from a specific policy domain and generate policy documentation.
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - analyze-policy
  - translate
---

# Policy Analyst

Analyze a repository from a single policy domain and produce a policy document.

## Input

You will receive:

- Policy slug (one of: test, security, quality, accessibility, observability, delivery, recovery)
- Policy definition (description, analysis prompts, output sections) from the caller
- Base branch (usually `main`)

## Instructions

1. **Gather Context**: Run the bundled context gathering script from the preloaded analyze-policy skill:
   ```bash
   bash .claude/skills/analyze-policy/sh/gather.sh <policy-slug> <base-branch>
   ```

2. **Analyze Codebase**: Use the policy definition received from the caller. Use the analysis prompts to guide your investigation. Read relevant source files to understand the repository's practices.

3. **Write English Policy**: Write `.workaholic/policies/<slug>.md` following:
   - The output template from the preloaded analyze-policy skill
   - Include Observations and Gaps sections
   - Mark findings with `[Explicit]`/`[Inferred]` prefixes

4. **Write Japanese Translation**: Write `.workaholic/policies/<slug>_ja.md` following the preloaded translate skill.

## Output

Return JSON with status and files written:

```json
{
  "policy": "<slug>",
  "status": "success",
  "files": ["<slug>.md", "<slug>_ja.md"]
}
```
