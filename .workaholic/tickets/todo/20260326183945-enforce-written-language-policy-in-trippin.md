---
created_at: 2026-03-26T18:39:45+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Enforce Written Language Policy in Trippin Plugin

## Overview

The trippin plugin's agents (Planner, Architect, Constructor) do not respect the written language rules defined in the project's `CLAUDE.md`. The policy states that `.workaholic/` directory content can be English or Japanese (i18n), but ALL other content -- code, code comments, commit messages, pull requests, documentation outside `.workaholic/` -- must be English only. During trip workflows, agents sometimes produce content in the wrong language: commit messages, PR descriptions, code comments, review artifacts, or agent-generated documentation may appear in Japanese when they should be English-only.

The root cause is that the trippin plugin has no language enforcement whatsoever. The `plugins/trippin/rules/` directory is empty. None of the three agent definitions mention language policy. The trip command's Agent Teams instructions do not include language rules. The trip-protocol skill mentions English only once, in the commit convention section (line 120), but this is a single sentence buried in a large document and is easily overlooked by agents operating in separate context windows. The write-trip-report skill, which generates PR bodies, has no language guidance at all.

By contrast, the drivin plugin has an `i18n.md` rule file and its general rules reference CLAUDE.md language settings. The trippin plugin needs equivalent enforcement.

## Key Files

- `plugins/trippin/agents/planner.md` - Planner agent definition; has no language policy in Rules section
- `plugins/trippin/agents/architect.md` - Architect agent definition; has no language policy in Rules section
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; has no language policy in Rules section
- `plugins/trippin/commands/trip.md` - Trip command; Agent Teams instructions (Step 4) do not mention language policy
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill; only mentions English once in Commit Convention section (line 120), no broader language enforcement
- `plugins/trippin/skills/write-trip-report/SKILL.md` - Report generation skill; no language guidance for PR title, body, or report content
- `plugins/trippin/rules/` - Empty directory; no rules exist for the trippin plugin
- `plugins/drivin/rules/i18n.md` - Drivin's i18n rule; serves as the reference pattern for what trippin needs

## Related History

The language policy has been a recurring concern across the codebase. The drivin plugin went through multiple iterations to enforce language boundaries -- from establishing multi-language documentation policy to adding bilingual `.workaholic/` support, fixing duplicate Japanese specs, and removing hardcoded Japanese translation from story-writer. The trip commit message rules ticket explicitly added English enforcement for commit messages, but that fix was narrow in scope (commit messages only) and did not address the broader language policy for all agent output.

Past tickets that touched similar areas:

- [20260310220756-trip-commit-message-rules.md](.workaholic/tickets/archive/drive-20260310-220224/20260310220756-trip-commit-message-rules.md) - Established English commit message format for trip agents with `[Agent]` prefix convention; addressed commit messages but not other language concerns (same plugin)
- [20260212123836-fix-duplicate-japanese-specs-in-workaholic.md](.workaholic/tickets/archive/drive-20260212-122906/20260212123836-fix-duplicate-japanese-specs-in-workaholic.md) - Fixed language duplication issue where Japanese-primary projects got redundant `_ja.md` files; demonstrates the pattern of language policy violations when enforcement is missing
- [20260204172657-remove-translator-from-story-writer.md](.workaholic/tickets/archive/drive-20260204-160722/20260204172657-remove-translator-from-story-writer.md) - Removed translation responsibility from story-writer to centralize i18n; shows the pattern of separating language concerns
- [20260311215505-enforce-planner-business-focus-in-planning-phase.md](.workaholic/tickets/archive/drive-20260311-125319/20260311215505-enforce-planner-business-focus-in-planning-phase.md) - Added behavioral guardrails to Planner agent; demonstrates the pattern of adding explicit rules to agent definitions to prevent unwanted behavior
- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Rewrote all three agent personalities; same agent files being modified

## Implementation Steps

1. **Create `plugins/trippin/rules/i18n.md`** with a written language enforcement rule for the trippin plugin. This rule should:
   - State that ALL agent output outside `.workaholic/` must be English only: commit messages, PR descriptions, code, code comments, review artifacts written outside `.workaholic/`, documentation
   - State that `.workaholic/` directory content follows the consumer project's CLAUDE.md language setting (English or Japanese)
   - Explicitly list the content types that must be English: commit messages, PR titles and bodies, code and code comments, branch names, agent-generated documentation outside `.workaholic/`
   - Use the `paths` frontmatter to scope to all files (`**/*`) since this is a cross-cutting concern
   - Follow the pattern established by `plugins/drivin/rules/i18n.md` but focused on trippin-specific content types (artifacts, reviews, event logs)

2. **Add language rule to each agent definition** (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`):
   - Add a language rule to the existing Rules section of each agent
   - State: "All output must be in English unless writing inside `.workaholic/` where the consumer project's CLAUDE.md language setting applies. This includes: artifact content (directions, models, designs), review files, code, code comments, commit descriptions, and any generated documentation."
   - This is necessary in addition to the rule file because Agent Teams agents operate in isolated context windows and may not have visibility into plugin rules

3. **Add language enforcement to the Agent Teams instructions in `plugins/trippin/commands/trip.md`** (Step 4):
   - Add a language policy line to the team lead instruction block, after the existing instructions
   - State: "Language policy: All agent output must be English. The only exception is `.workaholic/` directory content, which follows the consumer project's CLAUDE.md language setting."
   - This ensures the team lead propagates the language requirement when coordinating agents

4. **Strengthen language guidance in `plugins/trippin/skills/trip-protocol/SKILL.md`**:
   - Add a dedicated "Written Language Policy" section (before or after the existing Commit Convention section)
   - State the rule clearly: all trip artifacts (directions, models, designs, reviews, event log entries, plan.md content) must be written in English
   - Note the exception: `.workaholic/` content follows the consumer project's CLAUDE.md
   - The existing English mention in Commit Convention (line 120) should reference this new section or be made more prominent

5. **Add language guidance to `plugins/trippin/skills/write-trip-report/SKILL.md`**:
   - Add a note in the report structure section that the report, PR title, and PR body must be written in English
   - This ensures the report generation step also follows the language policy

## Patches

### `plugins/trippin/agents/planner.md`

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -29,3 +29,4 @@ Review Model and Design in `reviews/round-1-planner.md`. Respond to feedback in
 - Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
+- All output must be in English (artifacts, reviews, code, commit descriptions). The only exception is `.workaholic/` content, which follows the consumer project's CLAUDE.md language setting
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
```

### `plugins/trippin/agents/architect.md`

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -29,3 +29,4 @@ Review Direction and Design in `reviews/round-1-architect.md`. Respond to feedba
 - Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
+- All output must be in English (artifacts, reviews, code, commit descriptions). The only exception is `.workaholic/` content, which follows the consumer project's CLAUDE.md language setting
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
```

### `plugins/trippin/agents/constructor.md`

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -31,3 +31,4 @@ Review Direction and Model in `reviews/round-1-constructor.md`. Respond to feedb
 - Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
 - Run system-safety detection before any implementation that may touch system configuration
+- All output must be in English (artifacts, reviews, code, commit descriptions). The only exception is `.workaholic/` content, which follows the consumer project's CLAUDE.md language setting
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -117,6 +117,12 @@ Before implementation, Constructor runs: `bash ${CLAUDE_PLUGIN_ROOT}/../drivin/s

+## Written Language Policy
+
+All trip output must be written in English. This applies to: artifact content (directions, models, designs), review files, event log entries, plan.md content, commit messages, PR titles and bodies, code and code comments, and any agent-generated documentation. The only exception is content written inside the `.workaholic/` directory, which follows the consumer project's CLAUDE.md language setting (English or Japanese). When the consumer's CLAUDE.md specifies Japanese for `.workaholic/`, trip artifacts stored in `.workaholic/.trips/` may use Japanese.
+
 ## Commit Convention

 Format: `[Agent] Descriptive summary of what was accomplished`. Description must be a clear English sentence (not file names or terse labels). Every discrete workflow step produces a commit.
```

> **Note**: These patches are speculative - verify exact line numbers and surrounding context before applying.

## Considerations

- Agent Teams agents operate in separate context windows and may not reliably inherit plugin rules from the `rules/` directory. This is why the language rule needs to be stated in three places: the rule file (for general plugin enforcement), each agent definition (for isolated agent contexts), and the team lead instructions (for coordination propagation). Redundancy is intentional. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- Trip artifacts stored in `.workaholic/.trips/` occupy an ambiguous position: they are inside `.workaholic/` (which allows Japanese) but they are also agent-generated artifacts (which should be English). The implementation should clarify that trip artifacts in `.workaholic/.trips/` follow the same i18n rule as other `.workaholic/` content -- the consumer project's CLAUDE.md determines the language. (`plugins/trippin/skills/trip-protocol/SKILL.md` Artifact Storage section)
- The existing commit convention in trip-protocol SKILL.md (line 120) already states "Description must be a clear English sentence." The new Written Language Policy section provides broader coverage but should not contradict this existing rule. The commit convention can reference the new section for consistency. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 119-120)
- The drivin plugin's `i18n.md` rule file is scoped with `paths` to documentation patterns (`**/*README*.md`, `.workaholic/**/*.md`, `docs/**/*.md`). The trippin rule should use `**/*` since the language policy applies to all content types, not just documentation files. (`plugins/drivin/rules/i18n.md`, `plugins/trippin/rules/i18n.md`)
- The write-trip-report skill generates PR descriptions from trip artifacts. If the source artifacts are in the wrong language, the report will also be in the wrong language. Fixing the language at the artifact generation level (agents) prevents downstream propagation. The report skill guidance is a safety net. (`plugins/trippin/skills/write-trip-report/SKILL.md`)
