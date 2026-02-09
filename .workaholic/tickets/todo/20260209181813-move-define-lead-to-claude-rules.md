---
created_at: 2026-02-09T18:18:13+08:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Move define-lead Skill to .claude/ Rules for Local Enforcement

## Overview

Move the `define-lead` skill from `plugins/core/skills/define-lead/` to `.claude/rules/` so that Claude Code automatically enforces the lead agent schema template whenever editing lead skill files in this repository. Currently, `define-lead` is only loaded when explicitly declared in an agent or skill's `skills:` frontmatter. By converting it to a path-scoped rule, the schema validation and authoring guidelines become automatically active whenever Claude Code touches `lead-*.md` or `*-lead` skill files, preventing schema drift without requiring explicit preloading.

## Key Files

- `plugins/core/skills/define-lead/SKILL.md` - Current location of the define-lead skill (source to move)
- `plugins/core/skills/lead-quality/SKILL.md` - Example lead skill that references `define-lead` via `skills:` frontmatter
- `plugins/core/skills/lead-security/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-test/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-a11y/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-infra/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-communication/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-db/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-delivery/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-observability/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/skills/lead-recovery/SKILL.md` - Another lead skill with `skills: [define-lead]` dependency
- `plugins/core/rules/general.md` - Example of existing rule file with `paths:` frontmatter glob
- `plugins/core/rules/shell.md` - Example of path-scoped rule (`**/*.sh`)
- `CLAUDE.md` - Project instructions; states "Edit `plugins/` not `.claude/` unless explicitly requested" -- this is an explicit request

## Related History

The define-lead skill was recently created as part of the lead architecture migration. Multiple analyst agents have been transformed into leads using this schema. The skill is referenced by all 10 existing lead skills as a `skills:` dependency, but enforcement is passive (only loaded when an agent explicitly preloads it).

- [20260209160336-create-define-lead-skill.md](.workaholic/tickets/archive/drive-20260208-131649/20260209160336-create-define-lead-skill.md) - Created the define-lead skill as a schema template for lead agents
- [20260209162249-transform-a11y-analyst-to-lead-architecture.md](.workaholic/tickets/archive/drive-20260208-131649/20260209162249-transform-a11y-analyst-to-lead-architecture.md) - First lead migration that used define-lead schema
- [20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md](.workaholic/tickets/todo/20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md) - Queued ticket that will create more lead skills depending on this schema

## Implementation Steps

1. **Create `.claude/rules/define-lead.md` from the skill content**

   Create a new rule file at `.claude/rules/define-lead.md` with a `paths:` frontmatter glob that targets lead skill files. The glob should match `plugins/core/skills/lead-*/SKILL.md` and `plugins/core/agents/*-lead.md` so the rule activates when editing either lead skills or lead agent files.

   The body content should be adapted from `plugins/core/skills/define-lead/SKILL.md`:
   - Remove the skill-specific frontmatter (`name`, `description`, `user-invocable`)
   - Add rule-specific frontmatter with `paths:` glob
   - Keep all schema template sections, guidelines, validation checklist, and agent template
   - Reframe the content slightly as enforcement rules (e.g., "Every lead skill file MUST contain..." rather than "Every lead agent markdown file must contain...")

2. **Remove `skills: [define-lead]` from all lead skill frontmatters**

   Since the rule will be automatically loaded by path matching, the explicit `skills:` dependency is no longer needed. Remove the `skills:` line (or just `define-lead` from the list) from all 10 lead skill SKILL.md files:
   - `plugins/core/skills/lead-a11y/SKILL.md`
   - `plugins/core/skills/lead-communication/SKILL.md`
   - `plugins/core/skills/lead-db/SKILL.md`
   - `plugins/core/skills/lead-delivery/SKILL.md`
   - `plugins/core/skills/lead-infra/SKILL.md`
   - `plugins/core/skills/lead-observability/SKILL.md`
   - `plugins/core/skills/lead-quality/SKILL.md`
   - `plugins/core/skills/lead-recovery/SKILL.md`
   - `plugins/core/skills/lead-security/SKILL.md`
   - `plugins/core/skills/lead-test/SKILL.md`

3. **Delete the original skill directory**

   Remove `plugins/core/skills/define-lead/` entirely since the content now lives in `.claude/rules/define-lead.md`.

4. **Update CLAUDE.md Project Structure section**

   Add `.claude/rules/` to the Project Structure diagram to reflect the new rule file:
   ```
   .claude/                 # Local Claude Code configuration
     rules/                 # Repository-scoped rules
       define-lead.md       # Lead agent schema enforcement
   ```

## Considerations

- The `.claude/rules/` directory does not currently exist in the repo; it will be created by this change. The existing `.claude/` directory only contains `commands/release.md` and settings files (`plugins/core/rules/` is the plugin source, not `.claude/rules/`)
- CLAUDE.md says "Edit `plugins/` not `.claude/`" but also says "unless explicitly requested" -- this ticket IS an explicit user request to place content in `.claude/` (`CLAUDE.md` line 7)
- The `paths:` glob in the rule frontmatter must be carefully scoped. Using `plugins/core/skills/lead-*/SKILL.md` ensures it only fires when editing lead skill files, not unrelated files. Also include `plugins/core/agents/*-lead.md` to enforce the agent template when creating new leads (`plugins/core/rules/define-lead.md`)
- After this change, `define-lead` will no longer appear in the installed plugin skills directory (`~/.claude/plugins/marketplaces/workaholic/plugins/core/skills/`). This is intentional -- it becomes a repo-level rule instead of a plugin skill
- The queued ticket for consolidating viewpoint analysts into `architecture-lead` (`20260209175934-consolidate-viewpoint-analysts-into-architecture-lead.md`) references `define-lead` as a skill dependency. If that ticket is implemented after this one, it should not add `skills: [define-lead]` to the new `lead-architecture` skill since enforcement will be automatic via the rule
