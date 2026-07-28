---
created_at: 2026-07-28T21:03:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 4h
commit_hash:
category: Added
depends_on: 20260728210301-merge-concern-corpus-into-feedback-stream.md
mission: loop-engineering-proposal-loop
---

# Add the proposal batch command and skill

## Overview

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3, decisions C2–C4, B1): a **headless, non-interactive** `/propose` command that reads feedback newly merged to main and either stays silent (a valid outcome) or registers **draft** missions with full traceability back to their source feedback.

The mechanism, per the decided defaults:

- **Cursor (C2/A3)** — a git-ignored local file `.workaholic/proposal-cursor` holding the last-processed main commit. Feedback records are immutable, so "new" is exactly "feedback files added between cursor and `origin/main`". Bootstrap: when the cursor is absent, initialize it to the current `origin/main` HEAD and propose nothing — pre-existing feedback is treated as already-seen (safe cold start; a developer can backdate the cursor by hand to replay).
- **Draft missions (B1/B4)** — scaffolded at `missions/active/<slug>/mission.md` with `status: draft`, **empty `assignees`** (a draft predates approval, so it has no approver yet), empty `drive_authorized`, and a `feedback: [<record filenames>]` relation. `status: draft` joins the schema as a first-class value in the **active area** (a draft is in-flight, not history); approval (phase 3) flips it.
- **Dedup (C4)** — before drafting, the union of `feedback:` refs across **all** missions (active + archive) is computed; feedback already referenced by any mission never spawns a second proposal, and the cursor bounds re-reading.
- **Judgment** — a model judgment with a conservative bar, written in the skill: propose a mission only when the new feedback contains **actionable direction warranting a bounded batch of tickets** (typically `kind: instruction`/`insight`); a lone `concern` or a purely informational record is left for humans or the phase-3 replan stage. Never propose from feedback that merely restates an existing mission — silence over noise.
- **Headless (F2)** — the command never prompts. In-repo it runs on **main** (fetch + ff-only pull first) and pushes its draft commit straight to main (the knowledge-commit pattern); an unclean tree or non-ff state aborts with a reported reason, touched nothing.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:implementation` / `policies/directory-structure.md` — conventional skill/command layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`, no bash (applies to all code work)
- `workaholic:planning` / `policies/modeling-centric-design.md` — the feedback→mission relation direction (mission records its sources; nothing stored on the feedback side) is stated in the SKILL before the scripts
- `workaholic:design` / `policies/history-structures.md` — proposals are append-only commits on main; the cursor is runner-local state, never a shared mutable artifact
- `workaholic:implementation` / `policies/objective-documentation.md` — the judgment bar is written as testable criteria, not vibes

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — NEW internal skill (`metadata.internal: true`, `user-invocable: false`): the loop's model, the judgment bar, the cursor contract, the draft schema, script contracts, and the headless principle (no `AskUserQuestion`, ever — this skill runs where nobody can answer).
- `plugins/workaholic/skills/propose/scripts/cursor.sh` — `read` (prints commit or `{"initialized": true}` after bootstrapping to `origin/main`) / `advance <commit>`; stores `.workaholic/proposal-cursor` (git-ignored via `branching/scripts/lib/ensure-git-excludes.sh`, same pattern as the leak denylist).
- `plugins/workaholic/skills/propose/scripts/new-feedback.sh` — feedback records added on main since the cursor (`git diff --name-only <cursor>..origin/main -- .workaholic/feedbacks/`, `index.md` excluded), each with its frontmatter summary; `[]` when none.
- `plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh` — the union of `feedback:` refs across every mission (both areas), one filename per line — the dedup set.
- `plugins/workaholic/skills/propose/scripts/read-feedback-relation.sh` — the single reader of a mission's `feedback:` field (list + bare forms; mirror of `mission/scripts/read-relation.sh`).
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh "<title>" <feedback-file>...` — writes the draft `mission.md` (`status: draft`, empty `assignees`, `feedback:` list, the four body sections scaffolded), refreshes OKF indexes, git-stages. Refuses an existing slug.
- `plugins/workaholic/commands/propose.md` — thin orchestration: guard (main + clean + ff-only pull, abort loudly otherwise) → cursor → new feedback → dedup filter → judgment (the model writes each draft's Goal/Scope/Experience and a **proposed** Acceptance sketch into the scaffold) → commit via the commit skill (`Propose mission <slug>`) → push → notify (the notifier ticket's script, tolerated absent) → advance cursor **only after** a successful push (a failed run must re-read the same window).
- `plugins/workaholic/skills/mission/SKILL.md` + `scripts/lib/resolve.sh` + `list.sh` + `hooks/validate-mission.sh` — `status: draft` documented and mapped to the active area (the living migration's status→area keying treats only `achieved|abandoned|carried` as archive — verify, don't fork); `list.sh` reports drafts with `ready_reason: "not_active"`-class handling (surface a distinct `draft` reason); the scaffold tier of the validator already passes drafts (verify).
- `plugins/workaholic/hooks/validate-ticket.sh` (root-file list) + `hooks/layout-doctor.sh` + `plugins/workaholic/rules/workaholic.md` — register `proposal-cursor` as an allowed `.workaholic/` root file (lockstep, same commit that first writes it).
- `scripts/test-workflow-scripts.mjs` — hermetic coverage (below).
- `CLAUDE.md` (commands table + structure), `README.md`, `.workaholic/README.md` — document `/propose` and the draft state in the same change.

## Implementation Steps

1. Write `propose/SKILL.md` (model → judgment bar → contracts; the feedback→mission relation direction stated first).
2. Implement `cursor.sh`, `new-feedback.sh`, `read-feedback-relation.sh`, `list-proposed-refs.sh`, `scaffold-draft.sh` — POSIX `sh -eu`, JSON out, gather-skill metadata, `mission/scripts/slug.sh` reuse.
3. Register `proposal-cursor` in the root-file allowlist + rules table; wire the git-exclude.
4. Document `status: draft` across the mission skill/validator/list surfaces; add the `draft` ready-reason.
5. Write `commands/propose.md` (headless orchestration; cursor advances only after push).
6. Hermetic tests: cursor bootstrap-to-HEAD + advance; new-feedback windowing; dedup via refs; scaffold conformance (draft passes the validator, lands in active/, `feedback:` reads back through the single reader); a full silent run (no new feedback → cursor advanced, nothing written).
7. Docs; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record C2–C4/B1/F2); verification depth ruling: hermetic suite + in-session demo, per repo precedent.

**Acceptance criteria**

- A cold-start `/propose` run initializes the cursor to `origin/main` and proposes nothing; a run over new feedback either drafts missions (committed, pushed, `feedback:`-linked) or records silence — and the cursor advances **only** on success.
- The same feedback filename can never be referenced by two proposals (dedup set covers both areas), and a draft never carries `drive_authorized` or owners.
- `status: draft` lives in the active area, passes the validator's scaffold tier, and surfaces distinctly in `list.sh`; the mission lens stays silent on `0/0` drafts (signal gate — verify, no change expected).
- `proposal-cursor` is registered in both layout sources of truth in the same commit that first writes it; `layout-doctor.sh .` conforming.
- The command contains no `AskUserQuestion` and no interactive fallback; every abort path reports a machine-readable reason.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the new propose cases; build/verify/validate-metadata green; posix-lint conforming.

**Gate**

- Suite green, and an in-session demo in a hermetic repo: seed a feedback record → run the propose scripts end to end → a conformant draft mission exists with the `feedback:` ref, and a second run is silent.

## Considerations

- The cursor is **runner-local by design** (C1: one server runs the batch); the phase-3 claim protocol is the multi-runner answer — do not build shared cursor state here.
- `scaffold-draft.sh` deliberately does not reuse `mission/scripts/create.sh` (which seeds the creator as owner — an approver a draft does not have; recorded in create.sh's usage comment on 2026-07-28). Keep the two scaffolds' section layout aligned by hand; a divergence is a doc-drift defect.
- The judgment bar errs toward silence: a false negative costs one cron cycle (humans can always `/mission` by hand); a false positive spams Slack and erodes trust in the loop. Write that asymmetry into the SKILL.
- Do not touch `/monitor`/`/drive` eligibility: a draft is invisible to executors until phase 3's approval flip — only `drive_authorized` runs unattended, and drafts never carry it.

