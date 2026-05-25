---
created_at: 2026-05-25T20:55:30+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260525205529-package-core-standards-cross-agent-skills.md]
---

# Audit and Fix Claude-Code-Specific References in Portable core/standards Skills

## Overview

Once the portable subset of `core` and `standards` skills is selected and packaged for cross-agent distribution (companion ticket `20260525205529-package-core-standards-cross-agent-skills.md`), each exposed `SKILL.md` body must be audited for Claude-Code-specific references that will not resolve on Cursor, OpenCode, OpenAI Codex, or Pi. Three reference classes break on non-Claude agents:

1. **`${CLAUDE_PLUGIN_ROOT}` expansions** — Claude Code expands this to the installed plugin dir; other agents do not, so any `bash ${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/<script>.sh` invocation fails. Confirmed present in **12 of 14** core skills (`branching`, `check-deps`, `commit`, `create-ticket`, `discover`, `drive`, `gather`, `report`, `ship`, `system-safety`, `trip-protocol`, `validate-writer-output`). The two without it are `review-sections` and `write-release-note`.
2. **Cross-plugin `../` path references** — `plugins/core/skills/check-deps/scripts/check.sh` builds `${plugin_root}/../core`, and `plugins/core/skills/drive/scripts/archive.sh` calls `../../../../core/skills/commit/scripts/commit.sh`. These assume the `plugins/<plugin>/` sibling layout that does not exist under a flat `~/.cursor/skills/` install.
3. **`core:` / `standards:` / `work:` namespaced skill preloads** — Claude-Code-only frontmatter `skills:` references. Confirmed in `create-ticket`, `drive`, `report` frontmatter (e.g. `standards:leading-validity`, `core:trip-protocol`) and inline throughout `discover`, `trip-protocol`. Other agents have no namespaced skill-resolution mechanism.

For each portable skill the audit must decide, per reference, whether to: rewrite to an agent-neutral form, gate it as Claude-Code-only guidance, or conclude the skill cannot be made portable and remove it from the exposed set (feeding back into the companion ticket's classification).

The `work` plugin is out of scope.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Frontmatter `skills:` lists `gather` + four `standards:leading-*`; body references `standards:leading-*` in the Lead Lens (lines ~141, 324-330), `${CLAUDE_PLUGIN_ROOT}` script calls (lines ~32, ~57). Heavy namespaced coupling.
- `plugins/core/skills/discover/SKILL.md` - `${CLAUDE_PLUGIN_ROOT}/skills/discover/scripts/search.sh` (line ~21); references the four `standards:leading-{validity,availability,security,accessibility}` lenses (lines ~304, 331).
- `plugins/core/skills/commit/SKILL.md` - 4 `${CLAUDE_PLUGIN_ROOT}` script references; strong portable candidate if scripts are bundled relative.
- `plugins/core/skills/system-safety/SKILL.md` - 1 `${CLAUDE_PLUGIN_ROOT}` reference (`scripts/detect.sh`); portable candidate.
- `plugins/core/skills/check-deps/SKILL.md` + `scripts/check.sh` - The cross-plugin `${plugin_root}/../core` reference (`check.sh` line 11) is a work-dependency check; likely not portable.
- `plugins/core/skills/drive/scripts/archive.sh` - `COMMIT_SCRIPT="${SCRIPT_DIR}/../../../../core/skills/commit/scripts/commit.sh"` (line 58); cross-plugin traversal.
- `plugins/core/skills/{drive,ship,report,trip-protocol}/SKILL.md` - Highest `${CLAUDE_PLUGIN_ROOT}` density (9-18 occurrences each) plus namespaced preloads; most likely excluded rather than fixed.
- `plugins/standards/skills/*/SKILL.md` - The 4 leading-* skills: verified clean (no `${CLAUDE_PLUGIN_ROOT}`, no `../`, no namespaced refs). Audit confirms no changes needed — they are the reference for "what portable looks like."

## Related History

This is the same class of path-resolution failure that has recurred in this repo, now generalized from "wrong path within Claude Code" to "path/reference that has no meaning outside Claude Code." The prior audits established the find-and-classify-then-fix discipline this ticket reuses.

Past tickets that touched similar areas:

- [20260213131505-audit-replace-relative-skill-script-paths.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131505-audit-replace-relative-skill-script-paths.md) - Audited and replaced relative skill-script paths across 39 files; same mechanical-audit shape and the same self-referential vs. cross-referential distinction (same class of bug).
- [20260213131504-enforce-absolute-paths-for-skill-scripts.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131504-enforce-absolute-paths-for-skill-scripts.md) - Codified the Skill Script Path Rule that introduced `${CLAUDE_PLUGIN_ROOT}` — the very expansion this ticket now finds non-portable (the rule's foundation).
- [20260328152057-create-standards-plugin.md](.workaholic/tickets/archive/drive-20260326-183949/20260328152057-create-standards-plugin.md) - Its Final Report documents that moving skills between plugins requires fixing BOTH frontmatter namespaced preloads AND inline bash `../sibling/` paths — the exact two-front fix this audit faces.

## Implementation Steps

1. **Enumerate references per exposed skill.** For each skill in the portable subset, grep its `SKILL.md` and bundled `scripts/` for the three reference classes: `${CLAUDE_PLUGIN_ROOT}`, `../` cross-plugin paths, and `core:`/`standards:`/`work:` namespaced tokens. Produce a per-skill table of references with a disposition (rewrite / gate / exclude).

2. **Rewrite `${CLAUDE_PLUGIN_ROOT}` script invocations to an agent-neutral form.** Under a flat `~/<agent>/skills/<name>/` install the skill's own `scripts/` sit beside `SKILL.md`. Replace absolute-via-`${CLAUDE_PLUGIN_ROOT}` calls with a portable relative form the `npx skills` install layout guarantees, or inline the trivial commands. Keep Claude Code working — confirm the chosen form still resolves under `${CLAUDE_PLUGIN_ROOT}` expansion.

3. **Eliminate or gate cross-plugin `../` references.** A skill that reaches into a sibling plugin (`../core`, `.../core/skills/commit/...`) cannot stand alone. Either bundle the needed script copy into the skill, drop the cross-plugin step behind a Claude-Code-only note, or exclude the skill from the portable set (and record that back in the companion ticket's classification).

4. **Resolve namespaced skill preloads.** For `standards:leading-*` references inside portable core skills (e.g. the `create-ticket` Lead Lens), replace the namespaced token with an agent-neutral pointer to the now-co-installed `leading-*` skill, or restate the needed guidance inline. For `core:`/`work:` references that only make sense inside the Claude-Code orchestration, gate them as Claude-Code-only.

5. **Confirm `standards` needs no body changes.** Re-verify the 4 leading-* skills remain free of all three reference classes after any shared-content edits. They ship unchanged.

6. **Regression-check Claude Code.** After rewrites, exercise the affected skills under Claude Code to confirm script resolution and skill preloads still work — the goal is dual-resolution (Claude Code AND other agents), not replacing one breakage with another.

## Considerations

- **Type-driven / explicit-handling lens** (`plugins/standards/skills/leading-validity/SKILL.md`): treat the three reference classes as an exhaustive domain — every reference in every exposed skill must land in exactly one disposition (rewrite/gate/exclude). A skill with an unclassified reference is not ready to expose.
- **Dual resolution is the hard constraint.** Edits must keep Claude Code working (it is the primary consumer) while also resolving on other agents. A relative `scripts/` path is the most likely common form, but verify it against how `${CLAUDE_PLUGIN_ROOT}` resolves so this audit does not reintroduce the exit-code-127 failures the prior tickets fixed.
- **Some skills will fail the audit, and that is the correct outcome.** `drive`, `ship`, `report`, `trip-protocol`, `branching` encode subagent/command/hook/worktree mechanics; fixing path syntax does not make them runnable on Cursor/Codex. Excluding them feeds back into the companion ticket's exposed-set classification rather than forcing a fragile rewrite.
- **Do not edit archived tickets or the `work` plugin.** Scope is the exposed portable subset only.
- **Depends on the companion ticket** for the authoritative list of exposed skills — auditing a skill that will not be exposed wastes effort, and the exclude disposition here updates that list, so the two tickets iterate together.

## Patches

> **Note**: Speculative — illustrates the `${CLAUDE_PLUGIN_ROOT}` → relative rewrite for a portable-candidate skill. The exact relative depth depends on the `npx skills` install layout chosen in the companion ticket. Verify both Claude Code and flat-install resolution before applying.

### `plugins/core/skills/system-safety/SKILL.md`

```diff
@@
-bash ${CLAUDE_PLUGIN_ROOT}/skills/system-safety/scripts/detect.sh
+# Portable form: scripts/ ships beside this SKILL.md in every agent's skills dir.
+# Claude Code still resolves this via ${CLAUDE_PLUGIN_ROOT} when installed as a plugin.
+bash "$(dirname "$0")/scripts/detect.sh"   # confirm resolution under both layouts
```
