---
created_at: 2026-02-10T12:49:53+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add leaders-policy Skill for Cross-Cutting Lead Policies

## Overview

Create a new `leaders-policy` skill that encodes project-wide policies shared by all lead sub-agents. Unlike the `define-lead` schema enforcement rule (which governs the structural format of lead definitions), `leaders-policy` governs behavioral policies that every lead must follow during execution.

Start with two policies:

1. **Prior Term Consistency** -- Respect the original use of terms and cultivate ubiquitous language. Prefer 1 word to express an idea, 2 words if 1 cannot express it, 3 words as a last resort. Intuitiveness and conciseness matter.
2. **Vendor Neutrality** -- Fewer dependencies are better at every layer (app, middleware, infra, dev process). Implement by ourselves unless using a library is reasonable. When depending on external libraries, manage the dependency deliberately (DI, security observation, sustainability).

## Key Files

- `plugins/core/skills/lead-architecture/SKILL.md` - Existing lead skill that will add `leaders-policy` to preloaded skills
- `plugins/core/skills/lead-security/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-quality/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-test/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-a11y/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-communication/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-db/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-delivery/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-infra/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-observability/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/skills/lead-recovery/SKILL.md` - Existing lead skill that will add `leaders-policy`
- `plugins/core/agents/architecture-lead.md` - Lead agent that will add `leaders-policy` to its skills list
- `plugins/core/agents/security-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/quality-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/test-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/a11y-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/communication-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/db-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/delivery-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/infra-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/observability-lead.md` - Lead agent that will add `leaders-policy`
- `plugins/core/agents/recovery-lead.md` - Lead agent that will add `leaders-policy`
- `.claude/rules/define-lead.md` - Lead schema enforcement rule; update Agent Template to include `leaders-policy` as a required skill

## Related History

Historical tickets show a pattern of term renaming and consolidation for conciseness, plus the recent lead architecture migration that established the skill-per-lead pattern. The `define-lead` rule was recently moved to `.claude/rules/` for automatic enforcement.

- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/feat-20260126-214833/20260127010716-rename-terminology-to-terms.md) - Renamed "terminology" to "terms" for brevity (same principle: Prior Term Consistency, 1-word preference)
- [20260123161440-rename-philosophy-to-design-policy.md](.workaholic/tickets/archive/feat-20260123-032323/20260123161440-rename-philosophy-to-design-policy.md) - Renamed "Philosophy" to "Design Policy" for actionability (term consistency evolution)
- [20260209181813-move-define-lead-to-claude-rules.md](.workaholic/tickets/archive/drive-20260208-131649/20260209181813-move-define-lead-to-claude-rules.md) - Moved define-lead to `.claude/rules/` for path-scoped enforcement (established how shared lead concerns are managed)
- [20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md](.workaholic/tickets/archive/drive-20260208-131649/20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md) - Consolidated four analysts into architecture-lead (established the current set of 11 lead agents)

## Implementation Steps

1. **Create `plugins/core/skills/leaders-policy/SKILL.md`**

   Create the skill file with two cross-cutting policies. This is NOT a lead definition (no Role/Responsibility/Goal sections). It is a shared policy document that leads preload alongside their domain-specific skill.

   Structure:
   ```markdown
   ---
   name: leaders-policy
   description: Cross-cutting policies that apply to all lead sub-agents.
   user-invocable: false
   ---

   # Leaders Policy

   Policies in this document apply to every lead sub-agent. Each lead MUST observe these
   policies in addition to its own domain-specific Default Policies.

   ## Prior Term Consistency

   Respect the original use of terms already established in the codebase and cultivate
   ubiquitous language across all artifacts.

   ### Rules

   - Before introducing a new term, search the codebase for an existing term that covers the
     same concept. Use the existing term.
   - Prefer 1 word to express an idea. Use 2 words only when 1 word cannot express the idea
     unambiguously. Use 3 words as a last resort.
   - When renaming or consolidating terms, update all references in the affected scope
     (code, documentation, configuration) in the same change.
   - Flag any inconsistency where the same concept is referred to by different terms in
     different files.
   - Terms in `.workaholic/terms/` are the canonical glossary. New terms SHOULD be reflected
     there.

   ## Vendor Neutrality

   Fewer dependencies are better at every layer -- application, middleware, infrastructure,
   and development process.

   ### Rules

   - Implement functionality ourselves unless using an external library is demonstrably
     reasonable (saves significant effort, is well-maintained, and has no viable simple
     alternative).
   - When depending on an external library, manage the coupling deliberately:
     - **DI**: Access the dependency through an interface or abstraction layer, not direct
       import throughout the codebase.
     - **Security observation**: Track the dependency for known vulnerabilities and license
       compatibility.
     - **Sustainability**: Evaluate maintenance activity, bus factor, and funding model
       before adopting.
   - Flag any new dependency introduction during review. Require justification for why
     in-house implementation is unreasonable.
   - Prefer standard library or platform-native solutions over third-party alternatives.
   - When evaluating a dependency, document the exit strategy: what would replacing it
     require?
   ```

2. **Add `leaders-policy` to all 11 lead agent `skills:` lists**

   Each lead agent file in `plugins/core/agents/` has a `skills:` array in its frontmatter. Add `leaders-policy` as the first entry in each list so it is preloaded before the domain-specific skill.

   Files to update (11 agents):
   - `plugins/core/agents/architecture-lead.md`
   - `plugins/core/agents/a11y-lead.md`
   - `plugins/core/agents/communication-lead.md`
   - `plugins/core/agents/db-lead.md`
   - `plugins/core/agents/delivery-lead.md`
   - `plugins/core/agents/infra-lead.md`
   - `plugins/core/agents/observability-lead.md`
   - `plugins/core/agents/quality-lead.md`
   - `plugins/core/agents/recovery-lead.md`
   - `plugins/core/agents/security-lead.md`
   - `plugins/core/agents/test-lead.md`

3. **Update `.claude/rules/define-lead.md` Agent Template to include `leaders-policy`**

   Update the Agent Template section so that future lead agents created using the template will automatically include `leaders-policy`. In the template's `skills:` frontmatter example, add `leaders-policy` as the first skill entry.

## Patches

### `plugins/core/agents/architecture-lead.md`

```diff
--- a/plugins/core/agents/architecture-lead.md
+++ b/plugins/core/agents/architecture-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-architecture
   - analyze-viewpoint
   - write-spec
```

### `plugins/core/agents/a11y-lead.md`

```diff
--- a/plugins/core/agents/a11y-lead.md
+++ b/plugins/core/agents/a11y-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-a11y
   - analyze-policy
   - translate
```

### `plugins/core/agents/communication-lead.md`

```diff
--- a/plugins/core/agents/communication-lead.md
+++ b/plugins/core/agents/communication-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-communication
   - analyze-viewpoint
   - write-spec
```

### `plugins/core/agents/db-lead.md`

```diff
--- a/plugins/core/agents/db-lead.md
+++ b/plugins/core/agents/db-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-db
   - analyze-viewpoint
   - write-spec
```

### `plugins/core/agents/delivery-lead.md`

```diff
--- a/plugins/core/agents/delivery-lead.md
+++ b/plugins/core/agents/delivery-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-delivery
   - analyze-policy
   - translate
```

### `plugins/core/agents/infra-lead.md`

```diff
--- a/plugins/core/agents/infra-lead.md
+++ b/plugins/core/agents/infra-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-infra
   - analyze-viewpoint
   - write-spec
```

### `plugins/core/agents/observability-lead.md`

```diff
--- a/plugins/core/agents/observability-lead.md
+++ b/plugins/core/agents/observability-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-observability
   - analyze-policy
   - translate
```

### `plugins/core/agents/quality-lead.md`

```diff
--- a/plugins/core/agents/quality-lead.md
+++ b/plugins/core/agents/quality-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-quality
   - analyze-policy
   - translate
```

### `plugins/core/agents/recovery-lead.md`

```diff
--- a/plugins/core/agents/recovery-lead.md
+++ b/plugins/core/agents/recovery-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-recovery
   - analyze-policy
   - translate
```

### `plugins/core/agents/security-lead.md`

```diff
--- a/plugins/core/agents/security-lead.md
+++ b/plugins/core/agents/security-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-security
   - analyze-policy
   - translate
```

### `plugins/core/agents/test-lead.md`

```diff
--- a/plugins/core/agents/test-lead.md
+++ b/plugins/core/agents/test-lead.md
@@ -4,6 +4,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-test
   - analyze-policy
   - translate
```

### `.claude/rules/define-lead.md`

```diff
--- a/.claude/rules/define-lead.md
+++ b/.claude/rules/define-lead.md
@@ -114,6 +114,7 @@
 tools: Read, Write, Edit, Bash, Glob, Grep
 skills:
+  - leaders-policy
   - lead-<speciality>
   - <other skills needed for execution>
 ---
```

## Considerations

- This skill is a cross-cutting behavioral policy, not a lead definition. It intentionally does NOT follow the define-lead schema (no Role/Responsibility/Goal/Default Policies sections). The `define-lead` rule at `.claude/rules/define-lead.md` has path globs scoped to `plugins/core/skills/lead-*/SKILL.md` and `plugins/core/agents/*-lead.md`, so it will not enforce the lead schema on `leaders-policy/SKILL.md` (`plugins/core/skills/leaders-policy/SKILL.md`)
- The `leaders-policy` skill is added to agent files rather than lead skill files because skills cannot invoke other skills via `skills:` frontmatter (per Architecture Policy: skills can only invoke skills, but the `skills:` frontmatter dependency declaration is an agent/subagent capability). The agent is the orchestration layer that preloads all needed skills (`plugins/core/agents/*-lead.md`)
- Future policies can be added to this skill as new `## PolicyName` sections without changing any agent wiring. The skill acts as a growing policy registry (`plugins/core/skills/leaders-policy/SKILL.md`)
- The Prior Term Consistency policy aligns with the project's history of term consolidation (terminology to terms, philosophy to design policy). Leads should now proactively flag term drift rather than waiting for a dedicated refactoring ticket (`.workaholic/terms/`)
- The Vendor Neutrality policy is particularly relevant for leads that evaluate external tools: infra-lead (CI/CD tools), delivery-lead (deployment platforms), security-lead (security scanning tools), test-lead (test frameworks). Each lead should apply this policy within their domain-specific context (`plugins/core/agents/infra-lead.md`, `plugins/core/agents/delivery-lead.md`)
