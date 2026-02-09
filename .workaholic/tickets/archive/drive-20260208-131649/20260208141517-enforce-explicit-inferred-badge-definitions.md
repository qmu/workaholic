---
created_at: 2026-02-08T14:15:17+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: f2e651a
category:
---

# Enforce Explicit/Inferred Badge Definitions Based on Code Enforcement

## Overview

Strengthen the `[Explicit]`/`[Inferred]` badge system in policy documents so that badges carry meaningful, verifiable semantics. Currently, the analyze-policy skill says "Prefix findings with `[Explicit]` or `[Inferred]`" without defining what qualifies for each badge. Policy analysts freely mark statements as `[Explicit]` based on documentation references or configuration conventions, even when no actual code enforcement (linter rule, CI check, hook, script, test) exists. The result is that 125 `[Explicit]` badges appear across 7 policies, but many describe conventions enforced only by documentation -- not by code. This change defines `[Explicit]` as "has verifiable enforcement in code" and `[Inferred]` as "best-practice observation without enforcement," making policies honest about which standards are truly living.

## Key Files

- `plugins/core/skills/analyze-policy/SKILL.md` - The shared skill used by all 7 policy-analyst subagents; contains the Inference Guidelines section where badge definitions live (line 66)
- `plugins/core/agents/test-policy-analyst.md` - One of 7 policy analysts; step 3 references `[Explicit]`/`[Inferred]` prefixes (line 30)
- `plugins/core/agents/security-policy-analyst.md` - Same pattern as test-policy-analyst (line 30)
- `plugins/core/agents/quality-policy-analyst.md` - Same pattern (line 30)
- `plugins/core/agents/accessibility-policy-analyst.md` - Same pattern (line 30)
- `plugins/core/agents/observability-policy-analyst.md` - Same pattern (line 30)
- `plugins/core/agents/delivery-policy-analyst.md` - Same pattern (line 30)
- `plugins/core/agents/recovery-policy-analyst.md` - Same pattern (line 30)

## Related History

The badge system was introduced alongside the policy-analyst infrastructure. The analyze-policy skill was created as a thin framework with inference guidelines, and the 7 individual policy-analyst subagents were split from a generic policy-analyst to fix invocation issues. Badge usage has been consistent but semantically loose since inception.

Past tickets that touched similar areas:

- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Created the analyze-policy skill with the original inference guidelines (same file: analyze-policy/SKILL.md)
- [20260207033431-fix-writer-analyst-invocation.md](.workaholic/tickets/archive/drive-20260205-195920/20260207033431-fix-writer-analyst-invocation.md) - Restructured policy-writer to ensure analysts are actually invoked (same layer: Config)
- [20260207113721-implement-full-partial-scan-modes.md](.workaholic/tickets/archive/drive-20260205-195920/20260207113721-implement-full-partial-scan-modes.md) - Implemented scan modes that trigger policy analysts (same agents)

## Implementation Steps

1. **Remove the badge system entirely from `plugins/core/skills/analyze-policy/SKILL.md`**: Replace the `[Explicit]`/`[Inferred]` badge guidelines with a clear rule: only document what is actually implemented and executable in the codebase. Conventions, aspirations, and documentation-only practices do not belong in policies. Each statement must cite its enforcement mechanism.

2. **Update all 7 policy-analyst subagent files** to remove badge references and instead instruct: "Only document implemented and executable policies. Cite the enforcement mechanism for each statement."

## Patches

### `plugins/core/skills/analyze-policy/SKILL.md`

```diff
--- a/plugins/core/skills/analyze-policy/SKILL.md
+++ b/plugins/core/skills/analyze-policy/SKILL.md
@@ -62,10 +62,30 @@
 ## Inference Guidelines

 - **Document what exists**: Describe observable practices, configurations, and patterns
 - **Mark gaps clearly**: Use "Not observed" for policy areas with no codebase evidence
-- **Explicit vs Inferred**: Prefix findings with `[Explicit]` or `[Inferred]`
 - **No invention**: Never fabricate policies that do not exist in the codebase
 - **Recommendations are separate**: If suggesting improvements, place them in a distinct "Recommendations" section
+- **Explicit vs Inferred**: Prefix every policy statement with `[Explicit]` or `[Inferred]` following the badge definitions below
+
+### Badge Definitions
+
+**`[Explicit]`** -- The statement has verifiable enforcement in the codebase. Enforcement means at least one of:
+- CI check (GitHub Actions workflow step that validates or rejects)
+- Git hook (pre-commit, PostToolUse, or other hook that runs automatically)
+- Linter or formatter rule (ESLint, shellcheck, Prettier, etc.)
+- Automated script that validates, rejects, or prevents violations
+- Test that asserts the expected behavior
+
+After each `[Explicit]` statement, cite the enforcement mechanism in parentheses:
+`[Explicit] Statement here (enforced by: validate-plugins.yml step 2).`
+
+**`[Inferred]`** -- The statement describes an observed practice or convention with no automated enforcement. It may be documented in CLAUDE.md, README, or skill files, but no code path checks or rejects violations. These are aspirational policies.
+`[Inferred] Statement here.`
+
+**Examples:**
+- `[Explicit]` -- CI validates plugin.json required fields (enforced by: `.github/workflows/validate-plugins.yml`)
+- `[Explicit]` -- Ticket frontmatter is validated on every Write/Edit (enforced by: PostToolUse hook `validate-ticket.sh`)
+- `[Inferred]` -- Commands are approximately 50-100 lines (documented in CLAUDE.md, no automated size check)
+- `[Inferred]` -- Shell scripts use `set -eu` for strict error handling (convention, no linter enforces this)

 ## Comprehensiveness Policy
```

### `plugins/core/agents/quality-policy-analyst.md`

> **Note**: This patch applies the same pattern to all 7 policy-analyst subagent files. Only quality-policy-analyst.md is shown; apply the same change to the other 6.

```diff
--- a/plugins/core/agents/quality-policy-analyst.md
+++ b/plugins/core/agents/quality-policy-analyst.md
@@ -28,7 +28,7 @@

 2. **Analyze Codebase**: Use the analysis prompts above. Read relevant source files to understand the repository's quality practices.

-3. **Write English Policy**: Write `.workaholic/policies/quality.md` following the preloaded analyze-policy skill. Include Observations and Gaps sections. Mark findings with `[Explicit]`/`[Inferred]` prefixes.
+3. **Write English Policy**: Write `.workaholic/policies/quality.md` following the preloaded analyze-policy skill. Include Observations and Gaps sections. Mark findings with `[Explicit]`/`[Inferred]` badges following the badge definitions in the analyze-policy skill. Cite enforcement mechanisms for `[Explicit]` badges.

 4. **Write Japanese Translation**: Write `.workaholic/policies/quality_ja.md` following the preloaded translate skill.
```

## Considerations

- The existing 7 policy documents (125 `[Explicit]` + 16 `[Inferred]` badges) will not be retroactively updated by this ticket. The next `/scan` run will regenerate all policies with the new badge definitions, at which point many current `[Explicit]` badges may be reclassified to `[Inferred]` (e.g., "The architecture follows thin commands/comprehensive skills" is documented in CLAUDE.md but has no automated size enforcement) (`.workaholic/policies/quality.md` line 19)
- The `set -eu` convention in shell scripts is an interesting edge case: it is present in every script but there is no linter or CI check that enforces its presence. Under the new definitions, it would be `[Inferred]` since a developer could omit it without any automated check failing (`plugins/core/skills/analyze-policy/sh/gather.sh` line 1)
- The enforcement citation format (`enforced by: <mechanism>`) adds a small amount of verbosity to policy documents but provides crucial traceability. Users can verify any `[Explicit]` claim by checking the cited mechanism (`.workaholic/policies/` all files)
- The analyze-policy skill is shared by all 7 policy-analyst subagents, so updating the skill alone would be sufficient for behavior change. However, updating the subagent instruction text reinforces the requirement at the point of invocation, reducing the chance of badge misuse (`plugins/core/agents/*-policy-analyst.md`)
- This change does not affect the spec-analyst subagents or any other documentation agents -- only the 7 policy-analyst subagents that use the analyze-policy skill (`plugins/core/agents/`)
- The pending ticket for migrating scanner into the scan command (`.workaholic/tickets/todo/20260208131751-migrate-scanner-into-scan-command.md`) changes how policy analysts are invoked but does not affect their internal behavior or the analyze-policy skill. These tickets are independent.

## Final Report

Removed the `[Explicit]`/`[Inferred]` badge system entirely. Policies now only document what is actually implemented and executable in the codebase. The analyze-policy skill's Inference Guidelines were rewritten to enforce this rule, and all 7 policy-analyst agents were updated to instruct analysts to only document implemented policies with enforcement citations. The next `/scan` run will regenerate all policy documents under the new guidelines.
