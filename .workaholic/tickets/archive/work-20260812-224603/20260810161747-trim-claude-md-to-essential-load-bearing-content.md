---
created_at: 2026-08-10T16:17:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260810161713-claude-md-is-too-long.md]
merge_policy:
claim: work-20260812-224603
---

# Trim CLAUDE.md to essential, load-bearing content

## Overview

PROPOSED, from GitHub issue #355 ("CLAUDE.md is too long"). At the time of
this proposal `CLAUDE.md` is 373 lines / ~125 KB — almost entirely dense,
decision-history prose (`decision I1`, `J4`, `K1`, `P5`, `P8`, …, each argued
out in full paragraphs) rather than terse, load-bearing instruction. As
project instructions loaded into every session's context, that length works
against the file's own purpose: it raises context overhead per session and
buries the actionable rules (paths, command contracts, gate behavior) inside
narrative that reads like a changelog. The ask is to trim it to essential,
load-bearing content — cutting redundant, stale, or overly verbose passages —
while keeping every instruction a session actually needs to act correctly.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — where decision history belongs when it is not restated inline

## Key Files

- `CLAUDE.md` — the file to trim.
- `docs/loop-engineering-workflow.md` and `docs/proposal-loop-runbook.md` — existing docs that already carry decision narrative; the natural destination for history currently duplicated inline in `CLAUDE.md`.
- `plugins/workaholic/rules/workaholic.md` — the other side of the `.workaholic/` layout lockstep; any CLAUDE.md structural table it mirrors must stay in sync with it.
- `.workaholic/README.md`, `README.md` — per the "Update the docs in the same change" rule, check these describe the trimmed sections consistently after the cut.

## Implementation Steps

1. Measure the current baseline (line count, byte size) and read `CLAUDE.md` end to end, tagging each paragraph as either **load-bearing instruction** (a rule, contract, path, or gate a session must follow) or **decision narrative** (the argued history of why the current rule exists — dated decisions, measured incidents, rejected alternatives).
2. For each decision-narrative passage, either cut it outright (when it explains only how a retired approach failed) or compress it to a single clause plus a pointer to where the fuller account already lives (`docs/loop-engineering-workflow.md`, `docs/proposal-loop-runbook.md`, or a new doc section if none exists yet) — never delete a load-bearing rule while trimming its justification.
3. Rewrite each remaining section to state current behavior directly (what a session must do now), not the sequence of decisions that arrived at it.
4. Preserve verbatim: the Project Structure tree, the Commands table's factual contract per command, the Component Nesting Rules table, the `.workaholic/` layout lockstep table, the Version Management steps, and every `${CLAUDE_PLUGIN_ROOT}` / script-path rule — these are the parts other tooling and sessions rely on operationally.
5. Cross-check `plugins/workaholic/rules/workaholic.md`, `.workaholic/README.md`, and `README.md` still tell the truth about anything reworded or relocated, per the "Update the docs in the same change" rule already stated in `CLAUDE.md` itself.
6. Re-measure the trimmed file and record the before/after line count and byte size in the PR description.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md`'s line count and byte size are measurably smaller than the baseline recorded in step 1 (a concrete percentage or target should be set at drive time, not invented here).
- Every command contract, script path, gate, and structural table currently in `CLAUDE.md` is still present and still accurate after the trim — nothing load-bearing was cut, only its narrative justification.
- No other doc (`README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/workaholic.md`) is left contradicting the trimmed `CLAUDE.md`.

**Verification method** — the commands/tests/probes that prove them:

- `wc -l CLAUDE.md` and `wc -c CLAUDE.md` before and after, diffed in the PR description.
- A manual read-through comparing the trimmed file against the original section by section, confirming no operational rule (a path, a command's argument contract, a gate's pass/fail condition) was silently dropped.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` and the existing `## Local Verification` commands in `CLAUDE.md` (build/verify/validate-metadata/test-workflow-scripts), since none of them should regress from a docs-only change.

**Gate** — what must pass before approval:

- The measured size reduction and the section-by-section no-content-lost check both pass, and the PR body states the before/after numbers.

## Considerations

- This is a judgment-heavy edit, not a mechanical one: distinguishing "load-bearing" from "narrative" requires reading the whole file, and an overly aggressive cut risks silently dropping a rule a hook or script depends on being followed (even though nothing parses `CLAUDE.md` programmatically, sessions do rely on it behaving as instruction).
- Consider whether a firm target (e.g. a line-count or byte-size ceiling, analogous to the mission-size norm already established for `mission.md`) is worth adopting here too, so this does not regrow to its current size — that ceiling, if any, is a decision for whoever drives this ticket or a follow-up mission, not settled by this proposal.
- Relocating history into `docs/` rather than deleting it keeps the "knowledge is never deleted" norm this repository otherwise follows for its own artifacts.

## Final Report

**Outcome: implemented.**

- Baseline measured: 375 lines / 129,674 bytes. Trimmed: **195 lines / 27,962 bytes** (−48% lines, **−78% bytes**).
- Every paragraph was tagged instruction-vs-narrative; the narrative (dated decisions, measured incidents, rejected alternatives) was cut or compressed to a clause, with a standing pointer block at the top naming where fuller accounts live (`docs/loop-engineering-workflow.md`, the runbooks, each skill's `reference/`, the feedback stream, git history) — relocation over deletion, per the knowledge norm.
- Preserved operationally verbatim: the Component Nesting Rules table, the Local Verification command block, the Version Management steps, both branch-name literals, every script path and `${CLAUDE_PLUGIN_ROOT}` rule, the closed-layout lockstep rule, and each command's factual contract (rewritten terse, no contract dropped). The Project Structure tree kept its shape with the hooks annotation moved to a compact "Hooks" list.
- Sections were restated as current behavior ("what a session must do now"); decision IDs and dates were dropped except where a rule's scope depends on them.
- Cross-checked `README.md`, `.workaholic/README.md`, `plugins/workaholic/rules/workaholic.md`, and the test suite for references to renamed headings — none exist (the prose-pinning tests that once referenced CLAUDE.md headings were removed earlier the same day).
- Verified: `layout-doctor.sh .` conforming, `verify.mjs` clean, `test-workflow-scripts.mjs` 2238 passed / 0 failed.
- The Considerations' size-ceiling question is left open deliberately — a follow-up decision for the operator, not settled here.
