---
created_at: 2026-05-14T13:09:51+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Move standards rules to work plugin

## Overview

Relocate every file currently under `plugins/standards/rules/` into `plugins/work/rules/`. Three rules files move: `diagrams.md` (Mermaid-over-ASCII rule, applies to `**/*.md`), `shell.md` (POSIX-sh conventions, applies to `**/*.sh`), `typescript.md` (TypeScript style rules, applies to `**/*.ts` and `**/*.tsx`). After this ticket lands, `plugins/standards/` contains only `.claude-plugin/` and `skills/` -- matching the user's stated goal that the standards plugin should "only have the skills directory".

The rules being moved are coding-style conventions (path-scoped rules consumed by Claude Code when editing matching files). They are policy in the broad sense, but the user explicitly excluded `rules/` from what remains in standards. Two destinations were considered:

- **(a) Move them to `plugins/work/rules/`** alongside `general.md` and `workaholic.md`. Mechanical, low-risk, and aligns with the literal request.
- **(b) Convert each rule into a `leading-*` skill** (e.g., `leading-typescript`, `leading-shell`). Larger refactor, changes how the rules are consumed (path-based auto-load vs. agent-preload), and the user did not request this. Flagged as a future option.

This ticket implements option (a). Option (b) is recorded in Considerations as a possible future ticket.

Companion tickets:

- `20260514130949-move-standards-agents-to-work.md` -- relocates the agents. Independent of this ticket; touches a disjoint set of files except for `CLAUDE.md` (which both edit in disjoint regions).
- `20260514130950-move-non-leading-skills-to-core.md` -- relocates the non-leading skills. Independent of this ticket; same `CLAUDE.md` reconciliation note applies.

## Key Files

### Rule files to move (each entire file)

- `plugins/standards/rules/diagrams.md` -> `plugins/work/rules/diagrams.md` - Mermaid-over-ASCII rule, path scope `**/*.md`
- `plugins/standards/rules/shell.md` -> `plugins/work/rules/shell.md` - POSIX-sh shebang and style rules, path scope `**/*.sh`
- `plugins/standards/rules/typescript.md` -> `plugins/work/rules/typescript.md` - TypeScript style and import conventions, path scope `**/*.ts`, `**/*.tsx`

### Path-scope frontmatter

Each rule file's frontmatter declares which file globs it applies to (via `paths:`). The globs are repository-relative, not plugin-relative, so the move does not affect what they match. **No frontmatter edits are required.**

### Caller updates

Claude Code loads rules from any plugin's `rules/` directory automatically based on the `paths:` glob in each rule's frontmatter. There are no `${CLAUDE_PLUGIN_ROOT}` paths or `skills:` preloads that name a rule file. No frontmatter or path-rewrite edits are needed outside the three moved files themselves.

`grep -rn 'rules/\(diagrams\|shell\|typescript\)' plugins/ CLAUDE.md` returns zero matches, confirming the rules are auto-loaded by Claude Code and not explicitly referenced by name in any skill, agent, or command.

### Manifest updates

- `plugins/work/.claude-plugin/plugin.json` -- `dependencies: ["core"]` is unchanged. Rules are a passive plugin asset; they require no dependency declaration.
- `plugins/standards/.claude-plugin/plugin.json` -- `dependencies: []` is unchanged.

### Documentation updates

- `CLAUDE.md` lines 21-23 - the standards block currently has no explicit `rules/` line (rules are not listed in the Project Structure block for any plugin currently except work, and even the work entry lists files in a comment). The standards block needs no edit *for the rules removal* -- nothing currently mentions `plugins/standards/rules/` in `CLAUDE.md`. (Verified by `grep -n 'standards/rules\|rules/.*standards' CLAUDE.md`.)
- `CLAUDE.md` lines 25-30 - the work block already lists `rules/ # general, workaholic`. After this ticket, the comment expands to `rules/ # general, workaholic, diagrams, shell, typescript`.
- `.workaholic/specs/*.md` - none reference `plugins/standards/rules/` (verified by `grep -rn 'standards/rules' .workaholic/specs/`).

## Related History

This is the smallest of the three standards-reduction tickets. It is a mechanical move with no cross-references to update, equivalent in scope to the earlier `plugins/<plugin>/rules/` reorganizations that established the `paths:` glob convention.

Past tickets that touched similar areas:

- [20260514121259-move-work-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514121259-move-work-skills-to-core.md) - The same `git mv`-plus-`CLAUDE.md`-update playbook on a much larger set of files; the rules move is a stripped-down version of the same operation.
- [20260514121300-move-report-ship-commands-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514121300-move-report-ship-commands-to-work.md) - Companion-ticket pattern (multiple disjoint moves sharing only `CLAUDE.md` edits).
- [20260128001720-add-rules-typescript-and-shell.md or similar] -- the original introduction of `typescript.md` and `shell.md` as rule files documents the `paths:`-glob auto-load behavior that this ticket relies on (no explicit referencing needed). If absent in archive, the rule frontmatter itself is self-documenting.

## Implementation Steps

1. **Move rule files.** Use `git mv` for each of the three files to preserve history:
   ```
   git mv plugins/standards/rules/diagrams.md   plugins/work/rules/diagrams.md
   git mv plugins/standards/rules/shell.md      plugins/work/rules/shell.md
   git mv plugins/standards/rules/typescript.md plugins/work/rules/typescript.md
   ```
   Confirm `plugins/standards/rules/` is empty. Remove the empty directory if desired (`rmdir plugins/standards/rules` -- harmless either way).

2. **Update `CLAUDE.md` Project Structure.** Edit the work block at lines 25-30: expand the `rules/ # general, workaholic` comment to `rules/ # diagrams, general, shell, typescript, workaholic` (alphabetized). No standards-block edit is needed (the block does not currently mention `rules/`).

3. **Verification pass.**
   - `ls plugins/standards/rules/ 2>/dev/null` must show no files (directory absent or empty).
   - `ls plugins/work/rules/` must show `diagrams.md general.md shell.md typescript.md workaholic.md` (the five rules).
   - `grep -rn 'standards/rules' plugins/ CLAUDE.md .workaholic/` must return zero matches.
   - Open a `.ts` file in Claude Code and confirm the TypeScript rule frontmatter is still loaded (the loader picks up rules by `paths:` glob from any plugin's `rules/` directory).

## Considerations

- **Rules are passive plugin assets.** Unlike skills, commands, and agents, rules are not invoked by name; Claude Code auto-loads any rule file in any plugin's `rules/` directory whose `paths:` glob matches the file being edited. Moving a rule file between plugins changes only the rule's plugin-ownership metadata, not its applicability or content. No callers, no frontmatter prefixes, no `${CLAUDE_PLUGIN_ROOT}` paths are affected. (`plugins/standards/rules/`, `plugins/work/rules/`)
- **Alternative not chosen: convert rules to `leading-*` skills.** Each of the three rules could be reformulated as a leading skill (e.g., `leading-typescript`, `leading-shell`, `leading-mermaid`), preloaded by agents that touch those file types. This would change auto-load (path glob) behavior to opt-in preloads, and would invert the consumption model: skills are pulled in by name; rules are pushed in by path. The user did not request this reformulation, and it would shift the rules from "ambient policy" to "explicit agent context", which is a behavior change rather than a structural one. Flagged as a possible future ticket if the team wants the rules to become first-class lead policies. (`plugins/standards/skills/leading-validity/SKILL.md` for the schema)
- **No behavior change for existing rule consumption.** Path globs are repository-relative (`**/*.ts`), not plugin-relative, so the move does not affect what files the rules apply to. Any developer editing a `.ts` file after this ticket lands will see the same TypeScript rule loaded, only from `plugins/work/rules/typescript.md` instead of `plugins/standards/rules/typescript.md`. (`plugins/standards/rules/typescript.md` frontmatter `paths:`)
- **Disjoint from companion tickets.** This ticket touches only the three rule files and one line in `CLAUDE.md`. The companion `20260514130949-move-standards-agents-to-work.md` touches the agents directory and a different line in `CLAUDE.md` (the standards `agents/` listing). The companion `20260514130950-move-non-leading-skills-to-core.md` touches the skills directories and the standards/core `skills/` listings in `CLAUDE.md`. Whichever of the three lands last has trivial reconciliation -- the four affected blocks in the Project Structure description are disjoint. `depends_on` is left empty. (`CLAUDE.md` lines 18-30)
- **No dependency-graph change.** Neither `standards` nor `work` gains or loses a declared dependency. Rules are not part of the `plugin.json` `dependencies` system. The dependency diagram in `CLAUDE.md` is unchanged. (`plugins/work/.claude-plugin/plugin.json`, `plugins/standards/.claude-plugin/plugin.json`, `CLAUDE.md` lines 45-52)
- **Validity lens (Ours/Theirs Layer Segregation, Ubiquitous Language).** After all three reduction tickets land, `plugins/standards/` consists of `.claude-plugin/plugin.json` and `skills/leading-{accessibility,availability,security,validity}/`. This is the maximally segregated form: standards owns "policy lenses we use to evaluate work" and nothing else. Rule files (which are tactical coding conventions, not policy lenses) belong with the workflow that applies them -- work. Naming stays stable; no file is renamed. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **Availability lens (Vendor Neutrality, Observability).** `git mv` preserves history and blame on the three rule files. No CI/CD pipeline change is required because rule loading is keyed on directory structure within a plugin, which is unchanged. (`plugins/standards/skills/leading-availability/SKILL.md`)

## Patches

### `plugins/work/rules/diagrams.md`, `shell.md`, `typescript.md`

> **Note**: No content changes are required in any of the three moved files; their frontmatter `paths:` globs are repository-relative and remain correct in their new home. The `git mv` operation in step 1 is the entire file-level change.

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -27,7 +27,7 @@
     agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
     commands/            # ticket, drive, trip, report, ship
     hooks/               # ticket validation
-    rules/               # general, workaholic
+    rules/               # diagrams, general, shell, typescript, workaholic
 ```

 ## Architecture Policy
```
