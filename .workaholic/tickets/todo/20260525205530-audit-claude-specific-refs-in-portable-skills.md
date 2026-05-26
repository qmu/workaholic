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

# Make Portable core Skills Resolve via Spec-Standard Relative Script Paths

## Overview

The companion ticket (`20260525205529`) packaged the cross-agent install at **standards-only scope** and deferred the `core` subset to this ticket. This ticket fixes the in-body references in `core` skills so the genuinely-portable subset resolves on non-Claude agents (Cursor, OpenCode, Codex, Pi), then flips those skills out of the `metadata.internal: true` exclusion.

The original framing of this ticket assumed we needed to invent a portable script-invocation mechanism. **A spec + source-code investigation (2026-05-26) proved otherwise** — the mechanism already exists and is uniform across the ecosystem. The corrected plan below is grounded in that evidence (see Findings).

## Findings (do not re-research — this is settled)

**1. The Agent Skills spec mandates relative paths from the skill root.** [agentskills.io/specification](https://agentskills.io/specification):
> "When referencing other files in your skill, use relative paths from the skill root: `scripts/extract.py`. Keep file references one level deep from `SKILL.md`."

There is no environment variable and no absolute-path mechanism in the spec. **`${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/X.sh` is the deviation; `scripts/X.sh` is the standard.**

**2. All three audited OSS agents resolve scripts identically (model-mediated).** Verified from source:
- **OpenCode** (`packages/opencode/src/tool/skill.ts:36-60`, `tool/shell.ts:612-615`): shell CWD = project dir; the skill tool injects the skill's absolute "Base directory" as text and lists bundled files as absolute paths; the **model** prepends. No cd, no path rewrite, no env var.
- **Codex** (`codex-rs/core-skills/src/render.rs:32`, `exec-server/src/fs_sandbox.rs:295`): exec CWD = session/project dir; prompt instructs the model "resolve [`scripts/foo.py`] relative to the skill directory listed above." No cd, no rewrite, no env var (the only related flag `SkillEnvVarDependencyPrompt` is dead).
- **Pi** (`packages/coding-agent/src/core/skills.ts:343-354`, `tools/bash.ts:79-82`): bash CWD = `process.cwd()` (project); system prompt injects the skill's absolute `<location>` and tells the model to resolve relative references against the skill dir. No cd, no rewrite, no env var.

**3. Claude Code is the same family.** It exposes `${CLAUDE_SKILL_DIR}` (the skill's own dir) — documented for **`!`-prefixed preprocessing injection** that runs *before the model* (so there's no model to resolve the path). For normal **model-invoked** scripts (what every `core` skill does), Claude Code follows the Agent Skills standard it claims to implement, so a bare relative `scripts/X.sh` is the portable, spec-correct form.

**Conclusion:** the portable authoring rule is simply **write `scripts/X.sh` (relative from skill root)** and let the model resolve it. No npx package, no magic dual-resolving string.

## Disposition Table (per-skill, grounded in reference density)

Reference counts: `${CLAUDE_PLUGIN_ROOT}` / cross-plugin `../` / namespaced (`core:`,`standards:`,`work:`).

| Skill | PR | ../ | ns | scripts? | Disposition |
| ----- | -- | --- | -- | -------- | ----------- |
| write-release-note | 0 | 0 | 0 | no | **Expose** — flip internal flag (already spec-clean; story-coupled content) |
| system-safety | 1 | 0 | 0 | yes | **Rewrite → expose** — relative path; genuinely general-purpose (provisioning detection) |
| gather | 2 | 0 | 0 | yes | Rewrite candidate — relative path; but workaholic-internal helper (low standalone value) |
| validate-writer-output | 1 | 0 | 0 | yes | Rewrite candidate — relative path; internal helper |
| commit | 4 | 0 | 0 | yes | Rewrite candidate — relative path; workaholic commit-format-specific |
| branching | 12 | 0 | 0 | yes | Rewrite candidate — relative path; workaholic branch-convention-specific |
| discover | 2 | 0 | 1 | yes | Rewrite + handle 1 namespaced ref; ticket-flow-coupled |
| review-sections | 0 | 0 | 1 | no | Exclude — no frontmatter; story/carryover-coupled |
| create-ticket | 3 | 0 | 17 | no | Exclude — heavy `standards:leading-*` coupling + ticket mechanics |
| check-deps | 1 | 1 | 0 | yes | **Exclude** — `../core` cross-plugin work-dep check |
| drive / ship / report / trip-protocol | 10–19 | 0–1 | 0–15 | yes | **Exclude** — describe subagent/command/hook/Agent-Teams mechanics; unrunnable elsewhere regardless of path syntax |

## Key Files

- `plugins/core/skills/*/SKILL.md` and their `scripts/` — targets of the `${CLAUDE_PLUGIN_ROOT}` → relative rewrite for the rewrite-candidate skills above.
- `plugins/core/skills/check-deps/scripts/check.sh` (`../core` at line ~11) and `plugins/core/skills/drive/scripts/archive.sh` (`../../../../core/skills/commit/scripts/commit.sh` at line ~58) — the two cross-plugin `../` references. Both belong to excluded skills, so no fix needed beyond confirming those skills stay `internal: true`.
- `plugins/core/skills/create-ticket/SKILL.md` — 17 `standards:leading-*` / `gather` namespaced refs in frontmatter + Lead Lens; excluded.
- `.claude-plugin/marketplace.json` — the `standards` entry's `skills` array; add the newly-exposed core skills' discovery grouping if needed.
- `plugins/standards/skills/*/SKILL.md` — the 4 leading-* skills; verified pure-prose/spec-clean. Ship unchanged; they are the portability reference.
- `CLAUDE.md` — the **Skill Script Path Rule** (currently mandates `${CLAUDE_PLUGIN_ROOT}` for ALL skill scripts) must be amended: portable/exposed skills use spec-relative `scripts/X.sh`; Claude-only internal skills may keep `${CLAUDE_PLUGIN_ROOT}`. Document the distinction.

## Related History

- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - Companion packaging ticket; landed standards-only and deferred core to this ticket. Its Final Report documents the `skills` CLI behavior and the `metadata.internal` exclusion mechanism this ticket toggles.
- [20260213131504-enforce-absolute-paths-for-skill-scripts.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131504-enforce-absolute-paths-for-skill-scripts.md) - Codified the `${CLAUDE_PLUGIN_ROOT}` Skill Script Path Rule — the rule this ticket must now carve an exception into for exposed skills.

## Implementation Steps

1. **Verify Claude Code resolves a bare relative script path for model-invoked scripts** (the one residual unknown). In a scratch skill, reference a bundled script as `bash scripts/probe.sh` and confirm Claude Code runs it against the skill dir. If Claude Code does NOT auto-resolve it, the fallback is to keep `${CLAUDE_SKILL_DIR}/scripts/X.sh` for Claude and accept that form is Claude-specific — but per the Agent Skills standard Claude claims to follow, bare relative is expected to work. Record the result; it determines the exact rewrite token.

2. **Rewrite `${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/X.sh` → `scripts/X.sh`** in the rewrite-candidate skills (start with `system-safety`, the strongest general-purpose candidate). Each skill's `scripts/` already sits beside its `SKILL.md`, so the relative form is spec-correct. Confirm Claude Code still resolves it (dual-resolution is the hard constraint — do not reintroduce exit-127).

3. **Confirm cross-plugin `../` references only live in excluded skills.** `check-deps` and `drive/archive.sh` reach into sibling plugins; both belong to excluded skills, so the action is to verify those skills retain `metadata.internal: true`, not to fix the paths.

4. **Handle namespaced preloads in rewrite candidates.** `discover` has one `core:`/`standards:` reference; restate the needed guidance inline or point to the co-installed skill by plain name. Skills with heavy namespaced coupling (`create-ticket`, the workflow skills) are excluded, not rewritten.

5. **Flip the exposed set.** Remove `metadata.internal: true` from the skills whose audit passed (at minimum `write-release-note`; plus `system-safety` and any other rewritten candidate the developer chooses to expose). Leave it on all excluded skills.

6. **Confirm `standards` needs no changes** and re-verify the exposed set via `npx skills add . --list` (expect the 4 standards skills + the newly-flipped core skills; `INSTALL_INTERNAL_SKILLS=1` still shows everything).

7. **Amend `CLAUDE.md` Skill Script Path Rule** to document the two regimes: exposed/portable skills use spec-relative `scripts/X.sh`; Claude-only internal skills may use `${CLAUDE_PLUGIN_ROOT}`.

8. **Regression-check Claude Code** end-to-end on the rewritten skills — script resolution must still work (Claude Code is the primary consumer).

## Considerations

- **Dual resolution is the hard constraint.** Every rewrite must keep Claude Code working while resolving on other agents. The spec-relative form is the common denominator, but step 1 gates it; do not ship a rewrite that breaks Claude Code to satisfy portability.
- **Technical portability ≠ useful exposure.** Several rewrite candidates (`gather`, `validate-writer-output`, `branching`, `commit`) are workaholic-internal plumbing with little standalone value to a Cursor/Codex user. The developer should choose which technically-portable skills are actually worth exposing; `system-safety` (provisioning detection) is the clearest general-purpose win, `write-release-note` the clearest zero-cost one.
- **Excluding is the correct outcome for most of core.** `drive`/`ship`/`report`/`trip-protocol`/`create-ticket`/`check-deps` describe Claude-Code mechanics or reach across plugins; path fixes cannot make them runnable elsewhere. Keep them `internal: true`.
- **Do not edit archived tickets or the `work` plugin.** Scope is the exposed portable subset of `core` only.
- **Any new `core` skill must carry `metadata.internal: true`** unless it is deliberately spec-clean and exposed — otherwise it leaks into cross-agent discovery in a broken state (companion ticket's documented invariant).
