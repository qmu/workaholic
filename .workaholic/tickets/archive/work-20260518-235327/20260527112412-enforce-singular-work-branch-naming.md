---
created_at: 2026-05-27T11:24:12+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: 144220f
category: Changed
depends_on:
---

# Enforce singular `work-<timestamp>` branch naming across agents

## Overview

Non-Claude agents using the workflow skills create branches with **invalid names** — a trailing feature/description suffix (e.g. `work-20260527-...-add-foo`) or a non-`work-` prefix (`drive-...`, `trip/...`). The expected and only valid format is **`work-YYYYMMDD-HHMMSS`** (the `work-` prefix plus a timestamp, nothing else).

Root cause is **not** the generator: `plugins/core/skills/branching/scripts/create.sh` correctly produces `work-$(date +%Y%m%d-%H%M%S)` with no suffix or alternate prefix, and the workflow prose says "create a topic branch via `create.sh`." The problem is that the framework (a) **never asserts `work-<timestamp>` as the sole, mandatory format** and (b) **advertises legacy alternatives** — `core:branching` SKILL.md lists `work-*`, `drive-*`, `trip/*` together as work-context "Branch Patterns" and labels `drive-*`/`trip/*` as recognized. A non-Claude agent, reading the skill to decide how to make a branch and finding no rule forbidding it from naming one itself, falls back to the default LLM git habit (a descriptive, feature-named branch) — sometimes picking up the advertised `drive-`/`trip-` forms. Claude Code happens to run `create.sh` deterministically; other agents improvise.

This ticket makes the branch-naming rule **singular and emphatic** — branches are *only ever* `work-<timestamp>` from `create.sh`; agents MUST NOT invent a name, add a suffix, or use another prefix — and demotes `drive-*`/`trip/*` to clearly-labeled historical **detection-only** patterns (recognized for backward compat, never created anew).

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` — **`### 1. Check Branch`** (the step shipped to Codex/other agents). Add an emphatic rule: the ONLY way to create a branch is `create.sh`; the name is ALWAYS `work-<timestamp>`; never invent, suffix, or re-prefix. This is the highest-leverage fix because it rides into the built Codex artifact.
- `plugins/core/skills/branching/SKILL.md` — `### Output Format` table (line ~24, lists `work-*`, `drive-*`, `trip/*`), the "Legacy `drive-*` and `trip/*`" note (line ~46), `work_count` description (line ~68), "Topic branch patterns: `work-*`" (line ~205), and **`## Create Topic Branch`** (line ~207). State the sole-format rule in Create Topic Branch and relabel `drive-*`/`trip/*` everywhere as "historical, detection-only — never created."
- `plugins/core/skills/drive/SKILL.md` — the "Trip branch compatibility" note (line ~56) mentions operating on `trip/*`; keep as detection/back-compat but ensure it does not read as a creatable pattern.
- `plugins/core/skills/branching/scripts/create.sh` — already correct; cite as the single source of truth. No change expected.
- `codex/workflows/` — **regenerate** after editing the source prose, since the create-ticket artifact carries the Check Branch text. Run `node tools/build-portable-skills/build.mjs && node tools/build-portable-skills/verify.mjs`.

## Related History

- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Shipped the workflow skills to Codex; this is where the invalid-branch behavior on other agents surfaced. Establishes that the create-ticket Check Branch prose is what reaches other agents.

## Implementation Steps

1. **Make `core:create-ticket` Step 1 emphatic and singular.** Rewrite Check Branch to: "If on main, create the topic branch ONLY by running `create.sh` — do not name a branch yourself. The branch name is always `work-YYYYMMDD-HHMMSS`; never add a feature/description suffix and never use any other prefix (`drive-`, `trip/`, etc.)."
2. **State the sole-format rule in `core:branching` Create Topic Branch** and relabel the legacy patterns. The Output Format / context table should show `work-*` as the created pattern and mark `drive-*`/`trip/*` explicitly as "legacy, detection-only — never created."
3. **Audit `drive`/`ship`/`report` prose** for any wording implying a descriptive or prefixed branch name; align to the singular rule.
4. **Regenerate the Codex artifacts** (`node tools/build-portable-skills/build.mjs`) and `verify.mjs`, so the shipped create-ticket carries the new Check Branch rule.
5. **Confirm** `create.sh` is unchanged and remains the only branch-creation path.

## Considerations

- **The fix is prose, not code** — `create.sh` is already correct. The leverage is making the instruction unambiguous so agents don't improvise. Keep it emphatic and singular.
- **Don't break legacy detection.** `detect-context.sh`, `list-worktrees.sh`, `check-worktrees.sh` still need to RECOGNIZE existing `drive-*`/`trip/*` branches (backward compat). Only the *creation* guidance and the *advertising* of those as patterns change; detection scripts stay.
- **Regeneration is mandatory** — the create-ticket prose is shipped to Codex via `codex/workflows/`; the source edit has no cross-agent effect until the artifacts are rebuilt (and the committed `codex/` tree updated).
- **`Config`-layer**; engages `standards:leading-validity` (a single, total branch-name format with no ambiguous alternatives).

## Final Report

Development completed as planned. `create.sh` was already correct, so the fix is entirely prose. `core:create-ticket` Step 1 now states a mandatory, singular rule: the branch name is always `work-<YYYYMMDD-HHMMSS>` via `create.sh`, with explicit prohibitions on self-naming, feature suffixes, and other prefixes. `core:branching` Create Topic Branch states the sole-format rule, and the pattern table + backward-compat note now mark `drive-*`/`trip/*` as legacy detection-only (never created). Regenerated `codex/workflows/` so the new Check Branch rule rides into the built `create-ticket` artifact; `verify.mjs` passes. Legacy detection scripts untouched. `drive`'s trip-branch-compatibility note was left as-is — it describes *operating on* existing branches, not creating them.

### Discovered Insights

- **Insight**: The branch-naming bug was a documentation-leverage problem, not a code bug. Deterministic Claude Code masked it (it always runs `create.sh`); model-driven agents only do what the prose makes unambiguous. The same dynamic underlies the whole portability effort — anything the framework leaves implicit, a non-Claude agent fills in with default LLM habits.
  **Context**: For cross-agent correctness, every behavior that must be exact (branch names, file locations, script invocation) needs an explicit, emphatic, singular instruction in the *shipped* skill prose — implicit conventions and "preloaded skill does it" do not survive the jump to other agents.
