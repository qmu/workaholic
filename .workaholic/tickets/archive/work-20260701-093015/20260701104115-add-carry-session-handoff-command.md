---
created_at: 2026-07-01T10:41:15+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort: 2h
commit_hash: 386af5e
category: Added
depends_on: [20260701104114-rename-carryover-to-deferred-concerns.md]
---

# Add /carry: hand off in-progress work to a fresh session

## Overview

Add a `/carry` command (thin command + comprehensive `workaholic:carry` skill) that checkpoints in-progress work to durable disk state so a **fresh** Claude Code session can continue it via `/drive`, instead of relying on in-session compaction (which loses fidelity). When the developer notices the token window getting short, they run `/carry`; it summarizes the remaining work and the current position and writes it where the executors already look:

- **Drive/ticket case** — write a **resumption ticket** under `.workaholic/tickets/todo/<user>/`. A brand-new session running `/drive` finds it via `list-todo.sh`, the Navigator orders it, and the Workflow implements the remaining steps.
- **Trip case** — checkpoint the in-progress trip by updating `.workaholic/trips/<name>/plan.md` (frontmatter position + a Plan Amendment recording remaining work, mirroring the existing "Night Park" amendment) and appending a carry event to `event-log.md` via `log-event.sh`. Coding-phase remainders already live as tickets in `todo/<user>/`, so mid-implementation trip carry converges on the same ticket channel.

**Trigger is user-invoked, by design.** Discovery confirmed there is no hook, setting, statusline, or API by which a command can read the remaining token/context budget, and a `PreCompact` hook is a plain shell script with no model access, so it cannot summarize the conversation into a ticket. `/carry` therefore cannot auto-fire on window exhaustion — it is an explicit command the developer runs when they notice the window is short (analogous to `/drive night` and `/trip night` being explicit invocations, not sensed states). Auto-detection is out of scope; if desired later, a non-blocking `PreCompact` nudge that merely prints "consider running /carry" could be a follow-up.

**Naming:** this uses the "carry" verb freed up by [20260701104114-rename-carryover-to-deferred-concerns.md](.workaholic/tickets/todo/a-qmu-jp/20260701104114-rename-carryover-to-deferred-concerns.md) (which renames the old "carry-over" concerns pipeline to "deferred concerns"). This ticket `depends_on` that one so the vocabulary is unambiguous.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — carried artifacts land ONLY in the fixed `.workaholic/` tree (`tickets/todo/<user>/`, `trips/<name>/`); the command/skill/script follow the plugin's conventional layout
- `workaholic:implementation` / `policies/coding-standards.md` — the bundled script and any manifest edits follow house style (posix-lint checked)
- `workaholic:implementation` / `policies/objective-documentation.md` — the carried state is documentation for a future agent: concrete ticket path, exact remaining steps, files touched, current position — verifiable and machine-actionable, not aspirational prose
- `workaholic:implementation` / `policies/operational-planning.md` — `/carry` is a recovery/continuity procedure shaped from the "context exhaustion" scenario: a durable checkpoint securing continuity of work-in-progress; keep it simple (write state, resume)
- `workaholic:implementation` / `policies/command-scripts.md` — the multi-step state capture (locate active ticket/trip, compute position, write queue entry) is consolidated into a bundled runnable script, not inline tribal logic
- `workaholic:design` / `policies/self-explanatory-ui.md` — the resume path needs no manual: the carried ticket / trip note must, on its own, tell a fresh `/drive` what the priority is and where implementation stopped, in resume vocabulary (not internal token/compaction terms)
- `workaholic:design` / `policies/modeless-design.md` — `/carry` is a modeless checkpoint available any time and composable with the executors (carry then resume is ordinary interrupt/continue usage), not a special mode or wizard
- `workaholic:design` / `policies/interaction-design-standard.md` — define the command's nothing-to-carry / carried-successfully / error states consistently with the other workaholic commands

## Key Files

- `plugins/workaholic/commands/ticket.md` - Thin-command template to mirror for `commands/carry.md`: `skills:` frontmatter preload, the `workaholic:policy-lens` sentinel comment, Notice / Plugin-boundary headers, orchestration-only body. Like `/ticket` (which never implements code), `/carry` is capture-only — it never implements a ticket.
- `plugins/workaholic/commands/drive.md` - The consumer side: shows how the fresh session resumes (`/drive` reads `todo/<user>/`, prioritizes). Model for how `carry.md` delegates to its skill.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - The resumption ticket MUST conform to this skill's File Structure + frontmatter so `validate-ticket.sh` accepts it (mandatory `## Policies`, `## Quality Gate`). Its **Trip Origin** convention (lines ~39-41) is the model for a `**Carry Origin:**` back-link to the interrupted ticket/session.
- `plugins/workaholic/skills/drive/SKILL.md` - Navigator (`list-todo.sh`, `depends_on` topo-sort, severity) shows how a carried ticket is found and ordered. **Critical constraint**: the Workflow (Step 1, "Read and Understand the Ticket") implements ALL `## Implementation Steps` with no notion of "already done" — so a resumption ticket must list ONLY remaining work as its steps, with completed work described as context in the Overview, or `/drive` will redo finished work.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Trip artifacts (`plan.md` frontmatter phase/step/iteration + Plan Amendments/Progress; `event-log.md`; step-identifier vocabulary; the "Night Park" amendment). The in-trip carry surface: write current position into `plan.md` as a Night-Park-style amendment and log a carry event.
- `plugins/workaholic/skills/gather/scripts/ticket-metadata.sh` - `/carry` MUST use this (not inline git/date) for the resumption ticket's `created_at`/`author`/`filename_timestamp`/`user_slug` and the `todo/<user>/` write path.
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` - Canonical email→slug; determines the `todo/<user>/` subdir so the same developer's fresh `/drive` finds the ticket.
- `plugins/workaholic/skills/trip-protocol/scripts/log-event.sh` - Reused as-is to append a "carry checkpoint" event to a trip's `event-log.md`.
- `plugins/workaholic/hooks/validate-ticket.sh` - Hard gate: the resumption ticket write must satisfy filename pattern, `.workaholic/tickets/todo/<user>/` location, and required frontmatter, or the Write is blocked (exit 2). `/carry` cannot invent a new `.workaholic/carry/` dir without allowlisting.
- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` - Governs allowed `.workaholic/` subdirs; the safe, hook-clean channels are `tickets/todo/<user>/` and the already-allowed `trips/` paths.
- `plugins/workaholic/skills/catch/SKILL.md` - Reusable summarization discipline: factual, names files/hashes/tickets, extracts open threads — exactly the "capture remaining work + position" step, aimed at a WRITE (ticket) instead of a printed report.
- `scripts/build-plugins/build.mjs` - Commands are NOT built to `outputs/` (skills-only targets), so `commands/carry.md` is Claude-only and needs no rebuild. `/carry` is session-handoff-specific (like `/trip`) and should NOT be added to `DEFAULT_TARGETS` / cross-agent build. Because the carry skill bundles a script, its SKILL.md MUST carry `metadata.internal: true`.

## Related History

No prior `/carry` or session-handoff checkpoint exists. The closest precedents are trip's `plan.md`/`event-log.md` lifecycle state (the durable "where we are" substrate this reuses) and the trip worktree resume-or-create prompt.

Past tickets that touched similar areas:

- [20260312010257-trip-worktree-resume-or-create-prompt.md](.workaholic/tickets/archive/drive-20260312-102414/20260312010257-trip-worktree-resume-or-create-prompt.md) - Closest existing "resume an interrupted session" behavior (worktree granularity); `/carry` complements it by recording the in-flight position resume should pick up from
- [20260125113309-drive-approve-and-stop-option.md](.workaholic/tickets/archive/feat-20260124-200439/20260125113309-drive-approve-and-stop-option.md) - Existing controlled interruption point in `/drive`; `/carry` targets the same drive/ticket-queue as the resumption surface

## Implementation Steps

1. **Create the thin command** `plugins/workaholic/commands/carry.md`: frontmatter `skills:` preloading `workaholic:carry` plus reuse skills (`workaholic:gather`, `workaholic:create-ticket`, `workaholic:drive`, `workaholic:trip-protocol`); the `workaholic:policy-lens` sentinel comment; Notice + Plugin-boundary headers; an orchestration-only body that (a) detects whether the session is mid-drive or mid-trip, (b) runs the `workaholic:carry` skill's capture, (c) issues any `AskUserQuestion` at the command level. Capture-only: never implements or archives.
2. **Create the comprehensive skill** `plugins/workaholic/skills/carry/SKILL.md` (frontmatter `metadata.internal: true`, `user-invocable: false`): document the capture procedure for both cases — how to summarize remaining work + current position factually (catch-style), the resumption-ticket template (Carry Origin back-link, remaining-work-only Implementation Steps, carried-forward Quality Gate, `depends_on` the original when it must finish first), and the trip checkpoint (plan.md amendment + `log-event.sh`).
3. **Bundle a checkpoint script** `plugins/workaholic/skills/carry/scripts/carry-checkpoint.sh` (POSIX `#!/bin/sh -eu`) for the deterministic parts: derive frontmatter/filename/slug via `ticket-metadata.sh`, assemble the `todo/<user>/` path, and (trip case) call `log-event.sh`. Keep all conditionals/text-processing in the script, not the markdown. Reference every script via `${CLAUDE_PLUGIN_ROOT}`.
4. **Guarantee resumability**: the resumption ticket lists ONLY remaining steps as `## Implementation Steps` (completed work is Overview context), so `/drive` continues rather than redoes. Include a `**Carry Origin:**` line under `## Overview` linking the interrupted ticket/trip.
5. **Register the command**: add `/carry` to the Commands table in `CLAUDE.md` and the plugin's command list; confirm it is Claude-Code-only (no `outputs/` footprint, not in `DEFAULT_TARGETS`).
6. **Add a smoke test** for `carry-checkpoint.sh` in `scripts/test-workflow-scripts.mjs` (hermetic throwaway repo: assert it emits a valid resumption-ticket path/frontmatter and that a trip carry appends an event-log row).
7. **Verify**: `node scripts/build-plugins/build.mjs` (should NOT add carry to outputs), `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`, and `test-workflow-scripts.mjs` all green.

## Quality Gate

Developer-selected gate: **script smoke test + manual resume**.

**Acceptance criteria:**

- `carry-checkpoint.sh` is covered by a new hermetic smoke test in `scripts/test-workflow-scripts.mjs` that asserts: (a) it produces a resumption ticket under `.workaholic/tickets/todo/<user>/` with a `YYYYMMDDHHmmss-*.md` name and valid required frontmatter, and (b) a trip carry appends a row to `event-log.md`.
- The generated resumption ticket passes `validate-ticket.sh` (correct location, filename, frontmatter) and is found by `list-todo.sh` for the same user.
- The resumption ticket's `## Implementation Steps` contain ONLY remaining work (no completed step reappears), and it carries a `**Carry Origin:**` back-link.
- `/carry` adds no `outputs/` footprint (build does not emit a carry skill); the carry SKILL.md carries `metadata.internal: true`.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs` green including the new carry assertions; `posix-lint.sh` 0 findings; `build.mjs`/`verify.mjs`/`validate-metadata.mjs` green with `outputs/` unchanged by the carry addition.
- **Manual resume test**: in a drive session with a partially-done ticket, run `/carry`, then start a **fresh** Claude Code session and run `/drive` — confirm it finds the resumption ticket, orders it, and continues the remaining work without redoing completed steps. Repeat once for the trip case (carry mid-trip, confirm `plan.md` amendment + event-log row, and that a fresh session picks up the decomposed tickets).

**Gate:** the smoke suite + posix-lint + build/verify are green with no `outputs/` drift, AND the manual fresh-session resume (drive case, and trip case) demonstrably continues from the carried position.

## Considerations

- **No auto-trigger (accepted).** Without a token-budget signal, `/carry` is user-invoked; a `PreCompact` warning nudge is a possible non-blocking follow-up but cannot perform the carry itself (`plugins/workaholic/hooks/`).
- **Drive redoes all steps.** The single biggest correctness risk: `/drive` implements every `## Implementation Steps` entry with no "already done" concept (`plugins/workaholic/skills/drive/SKILL.md` Workflow Step 1). The resumption ticket MUST encode only remaining work as steps, or completed work is re-run.
- **Ticket is per-user scoped.** `list-todo.sh` reads only the current user's `todo/<user>/`; the carried ticket must belong to the same developer who will resume (`plugins/workaholic/skills/drive/scripts/user-slug.sh`).
- **No new `.workaholic/` dir without allowlisting.** Stay within `tickets/todo/<user>/` and `trips/` (`plugins/workaholic/hooks/workaholic-layout-allowlist.txt`); do not invent `.workaholic/carry/`.
- **Depends on the rename.** Document `/carry` only after ticket 20260701104114 frees the "carry" vocabulary, or the docs will conflate it with deferred concerns.

## Final Report

Development completed as planned. Built `commands/carry.md` (thin, capture-only), `skills/carry/SKILL.md` (`metadata.internal: true`, numbered headings, drive + trip cases), and `skills/carry/scripts/carry-checkpoint.sh` (POSIX; emits the resumption-ticket path + dynamic frontmatter metadata + trip detection). Reused the existing `user-slug.sh` and `log-event.sh` rather than reinventing them. Added `/carry` to the CLAUDE.md Commands table and structure listings, and an 8-assertion smoke test to `test-workflow-scripts.mjs`. Verified Claude-only: `outputs/` contains no `carry` skill (not added to `DEFAULT_TARGETS`), the skill stays internal, and the command is never built. Suite: 248 passed / 0 failed; posix-lint 0 findings; build/verify/policy-index in lockstep.

The one carried-forward manual criterion (per the agreed script-tests-plus-manual gate) is the fresh-session resume: run `/carry` mid-work, then start a new session and `/drive` to confirm it continues from the carried position without redoing completed steps.

### Discovered Insights

- **Insight**: The correctness crux of the whole feature is that `/drive`'s per-ticket Workflow implements EVERY `## Implementation Steps` entry with no "already done" concept, so a resumption ticket must list only *remaining* work — completed work goes in the Overview as context. This single rule is what makes a fresh `/drive` continue rather than restart, and it is stated as the first Writing Guideline in the skill.
  **Context**: Any future change to how `/drive` reads Implementation Steps (e.g. adding a "completed" marker) would let `/carry` carry richer state; until then, the remaining-only discipline is load-bearing.
- **Insight**: There is genuinely no programmatic token-budget signal available to a command or hook (a `PreCompact` hook has no model access), so a "carry automatically before compaction" design is infeasible with current Claude Code — `/carry` is necessarily user-invoked. This was validated by grepping the whole plugin/settings surface for any token/context/statusline signal and finding none.
  **Context**: If Claude Code later exposes a context-budget signal or a model-capable pre-compaction hook, an auto-nudge (or auto-carry) becomes possible; the ticket records this as a deliberate scope boundary, not an oversight.
- **Insight**: The resumption ticket rides the existing per-user `todo/<user>/` channel and the `validate-ticket.sh` hook unchanged — no new `.workaholic/` subdirectory or allowlist entry was needed, which kept the feature entirely within the sanctioned artifact surface.
  **Context**: Keeping carry output inside `tickets/todo/<user>/` (and trips/) is why a fresh `/drive` finds it automatically; inventing a `.workaholic/carry/` dir would have required an allowlist change and made the artifact invisible to `list-todo.sh`.
