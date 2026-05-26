---
created_at: 2026-05-25T20:55:30+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 2h
commit_hash: 82a9597
category: Changed
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

**3. Claude Code is the same family — confirmed by an empirical probe (2026-05-26).** A throwaway probe skill referenced a bundled script as bare `scripts/probe.sh` and instructed the model to run it verbatim. Result on Claude Code:
- The skill's absolute directory **is** injected to the model as text: `Base directory for this skill: /…/.claude/skills/relpath-probe` (identical to OpenCode's "Base directory", Codex's `<path>`, Pi's `<location>`).
- The shell **CWD stays at the project root**; Claude Code does **not** `cd` into the skill dir.
- Running `bash scripts/probe.sh` verbatim **failed with exit 127** — the bare relative path resolved against the project root, not the skill dir.

So Claude Code is the same model-mediated family as the other three: the harness hands the model the base directory, and **the model must prepend it**. The `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` tokens are Claude-specific **deterministic** expansion (no model judgment), which is why they are robust.

**Conclusion:** there is no env-var/CWD auto-resolution on ANY agent — all four rely on the model prepending the injected base dir. The spec-relative form (`scripts/X.sh`) is therefore portable **only insofar as the model reliably prepends**, which the probe showed it does **not** do by default. Consequences:
- **Pure-prose skills (no script resolution) are the only zero-risk exposures.** `write-release-note` is the sole clean case.
- **Rewriting a script-bearing skill to spec-relative downgrades it from deterministic token-expansion to non-deterministic model-prepend on Claude Code** — unacceptable for skills workaholic itself runs in its Claude-Code `/drive`/`/ship` critical path (e.g. `system-safety`). Those keep `${CLAUDE_PLUGIN_ROOT}` and stay `internal: true`.
- No npx package, no magic dual-resolving string — and no blanket relative rewrite either.

## Disposition Table (per-skill, grounded in reference density)

Reference counts: `${CLAUDE_PLUGIN_ROOT}` / cross-plugin `../` / namespaced (`core:`,`standards:`,`work:`).

Post-verification, the disposition collapses: **expose pure-prose skills only; keep every script-bearing skill on the deterministic `${CLAUDE_PLUGIN_ROOT}` token and `internal: true`.**

| Skill | PR | ../ | ns | scripts? | Disposition |
| ----- | -- | --- | -- | -------- | ----------- |
| write-release-note | 0 | 0 | 0 | no | **Expose** — flip internal flag (no script resolution; only clean case) |
| system-safety | 1 | 0 | 0 | yes | Keep internal — general-purpose, but used in Claude `/drive`; rewriting downgrades its reliability |
| gather / validate-writer-output / commit / branching / discover | 1–12 | 0 | 0–1 | yes | Keep internal — script-bearing + workaholic-internal helpers |
| review-sections | 0 | 0 | 1 | no | Keep internal — no frontmatter; story/carryover-coupled |
| create-ticket | 3 | 0 | 17 | no | Keep internal — heavy `standards:leading-*` coupling + ticket mechanics |
| check-deps | 1 | 1 | 0 | yes | Keep internal — `../core` cross-plugin work-dep check |
| drive / ship / report / trip-protocol | 10–19 | 0–1 | 0–15 | yes | Keep internal — describe subagent/command/hook/Agent-Teams mechanics; unrunnable elsewhere |

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

1. **(DONE) Verify Claude Code's script resolution.** Result recorded in Findings #3: Claude Code injects the skill base dir as text but runs the shell in the project CWD and does not auto-resolve bare relative paths — same as the other agents. This collapses the plan: no blanket relative rewrite.

2. **Expose `write-release-note`.** Remove `metadata.internal: true` from `plugins/core/skills/write-release-note/SKILL.md`. It is pure prose with no script and no namespaced reference, so it resolves on every agent and exposing it cannot break Claude Code.

3. **Keep every script-bearing, namespaced, and mechanism-bound skill `internal: true`.** Do NOT rewrite their `${CLAUDE_PLUGIN_ROOT}` calls — on Claude Code that token is the deterministic, reliable form, and several of these skills run in workaholic's own Claude-Code `/drive`/`/ship` critical path. No `../core` fixes are needed because those skills stay internal.

4. **Update `CLAUDE.md` Cross-Agent Skill Exposure** to record that `write-release-note` is an intentionally exposed core skill (pure prose), and to state the verified reason the rest stay internal: Claude Code resolves bundled scripts via deterministic `${CLAUDE_PLUGIN_ROOT}` expansion, while spec-relative paths would force non-deterministic model-prepend. The "every new core skill MUST carry `metadata.internal: true`" rule still holds for any script-bearing skill.

5. **Re-verify the exposed set** via `npx skills add . --list` — expect the 4 `standards` skills plus `write-release-note`; `INSTALL_INTERNAL_SKILLS=1` still shows everything. `standards` skills ship unchanged.

## Considerations

- **Dual resolution is the hard constraint.** Every rewrite must keep Claude Code working while resolving on other agents. The spec-relative form is the common denominator, but step 1 gates it; do not ship a rewrite that breaks Claude Code to satisfy portability.
- **Technical portability ≠ useful exposure.** Several rewrite candidates (`gather`, `validate-writer-output`, `branching`, `commit`) are workaholic-internal plumbing with little standalone value to a Cursor/Codex user. The developer should choose which technically-portable skills are actually worth exposing; `system-safety` (provisioning detection) is the clearest general-purpose win, `write-release-note` the clearest zero-cost one.
- **Excluding is the correct outcome for most of core.** `drive`/`ship`/`report`/`trip-protocol`/`create-ticket`/`check-deps` describe Claude-Code mechanics or reach across plugins; path fixes cannot make them runnable elsewhere. Keep them `internal: true`.
- **Do not edit archived tickets or the `work` plugin.** Scope is the exposed portable subset of `core` only.
- **Any new `core` skill must carry `metadata.internal: true`** unless it is deliberately spec-clean and exposed — otherwise it leaks into cross-agent discovery in a broken state (companion ticket's documented invariant).

## Final Report

Completed, with the original "rewrite core to relative paths" premise replaced by an evidence-grounded conclusion. The Agent Skills spec mandates skill-root-relative paths, and source-reads of OpenCode/Codex/Pi plus an empirical Claude Code probe proved all four agents resolve bundled scripts the same way: shell runs in the project CWD, the skill's base directory is injected to the model as text, and the model must prepend it — no agent `cd`s into the skill dir, and Claude Code's `${CLAUDE_PLUGIN_ROOT}` is deterministic token-expansion. Therefore rewriting a script-bearing skill to spec-relative would trade deterministic resolution for non-deterministic model-prepend on Claude Code — unacceptable for skills used in workaholic's own `/drive`/`/ship` path. Outcome: exposed only `write-release-note` (pure prose; removed `metadata.internal`), kept every script-bearing/namespaced/mechanism-bound skill internal, and recorded the verified rationale in CLAUDE.md. `npx skills add . --list` now reports 5 skills (4 standards + write-release-note); `standards` unchanged.

### Discovered Insights

- **Insight**: The cross-agent skill ecosystem has no script-path auto-resolution — every agent (Claude Code, OpenCode, Codex, Pi) injects the skill's base directory as *text* and relies on the model to prepend it; none sets the shell CWD to the skill dir or expands a relative path. Claude Code's `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` are the only deterministic mechanism, and they are Claude-specific.
  **Context**: This is why a skill that runs bundled scripts cannot be made portable without accepting model-prepend fragility. Verified by source reads (`opencode tool/skill.ts`, `codex core-skills/src/render.rs`, `pi core/skills.ts`) and a live Claude Code probe (bare `scripts/probe.sh` → exit 127 with "Base directory" injected as text).
- **Insight**: `metadata.internal: true` should be read as "script-bearing or Claude-mechanism-coupled," not "core." `write-release-note` (pure prose) is exposed without it; the rule in CLAUDE.md now keys off whether the skill invokes a bundled script rather than which plugin it lives in.
  **Context**: Future portable-skill candidates must be pure prose (or accept the model-prepend tradeoff); the per-skill flag, not a per-plugin rule, governs exposure.
