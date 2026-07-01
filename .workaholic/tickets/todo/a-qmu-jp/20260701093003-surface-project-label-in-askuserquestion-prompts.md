---
created_at: 2026-07-01T09:30:03+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort:
commit_hash:
category:
depends_on:
---

# Surface the project label in every workaholic AskUserQuestion prompt

## Overview

When a workaholic command asks the developer something via `AskUserQuestion`, the dialog names only the decision (e.g. `Approve`, `Worktree`, `Deploy`) and never the repository it belongs to. A developer running several Claude Code sessions across tmux panes — each in a different repo — switches to a pane, finds a waiting dialog, and cannot tell which project is asking. The Claude Code session name and the tmux pane/window title are owned by the harness, not by workaholic, so the plugin cannot rename them; the one surface workaholic fully controls is the text it authors into each `AskUserQuestion`.

The fix: derive a short **project label** — the basename of the git repository root (e.g. `workaholic`) — from a shared gather script, and render it in the `header` chip of **every** `AskUserQuestion` workaholic issues (per developer decision: identity = repo/dir name; placement = header chip only; coverage = every call site). The `header` chip is the most glanceable element of the dialog, so a developer scanning panes reads the owning repo at a glance. The decision word that the chip carries today (`Approve`, `Deploy`, …) moves fully into the `question` body, which every prompt already phrases as a full sentence, so no decision context is lost.

This mirrors the precedent set by ticket `20260212222003` (show-ticket-context-in-drive-approval-prompt), which made contextual identity *structurally unavoidable* by embedding it directly in the `header`/`question` fields rather than relying on freeform text the agent can skip. Here the same technique carries repo identity instead of ticket identity, and is applied uniformly across all prompts rather than one call site.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — TypeScript/style conventions (applies to all code work)
- `workaholic:design` / `policies/self-explanatory-ui.md` — the waiting dialog must reveal which repo is asking from the element itself; needing external knowledge (which pane, which cwd) is exactly the ambiguity this policy names as a redesign trigger
- `workaholic:design` / `policies/interaction-design-standard.md` — the label must be standardized across every workaholic `AskUserQuestion` (ticket/drive/report/ship/commit/trip) so the developer learns the convention once, not per-prompt
- `workaholic:design` / `policies/modeless-design.md` — the label annotates the existing blocking prompt for orientation; it must add no extra step, question, or friction to answering
- `workaholic:implementation` / `policies/accessibility-first.md` — identity lives in readable prompt text reachable by both a human scanning panes and an AI operator, never a visual/color-only cue
- `workaholic:implementation` / `policies/command-scripts.md` — the repo name is produced by one shared runnable script and consumed identically everywhere, not re-derived ad hoc per command
- `workaholic:planning` / `policies/terminology.md` — pick and use one consistent term for the surfaced identity (settle on "project" label) across all prompts, scripts, and docs

## Key Files

Every place workaholic issues `AskUserQuestion` (the command/main-agent level — leaf subagents never prompt), plus the gather context layer that will supply the label:

- `plugins/workaholic/skills/gather/scripts/git-context.sh` - Already computes the repo root (`git rev-parse --show-toplevel`) and `repo_url`, but emits **no bare project-name field**. It also runs `git remote show origin` (network), so it is too heavy to call just to label a prompt — the label needs a cheaper dedicated home (see step 1).
- `plugins/workaholic/skills/gather/scripts/ticket-metadata.sh` - Pattern reference: a small POSIX `#!/bin/sh -eu` script emitting JSON, delegating to `user-slug.sh`. The new label script should follow this shape.
- `plugins/workaholic/skills/gather/SKILL.md` - Documents the gather scripts; the new label script must be documented here (CLAUDE.md "Common Operations" mandates git/project context flow through gather).
- `plugins/workaholic/commands/drive.md` - Issues the per-ticket approval dialog (the highest-frequency prompt) plus order-confirmation, icebox/stop, and abandonment prompts.
- `plugins/workaholic/commands/ticket.md` - Issues worktree-guard, moderation merge/split, Quality-Gate interrogation, and ambiguity prompts.
- `plugins/workaholic/commands/ship.md` - Issues the no-confirmation-method halt (a high-stakes deploy/merge decision).
- `plugins/workaholic/commands/commit.md` - Issues the confirm-staging-untracked-files prompt.
- `plugins/workaholic/commands/report.md` - Report flow prompts (workspace-not-clean, worktree selection, unknown drive/trip context) are issued here / described in the report skill.
- `plugins/workaholic/commands/trip.md` - Night mode issues zero `AskUserQuestion`; interactive-mode trip prompts flow through the trip-protocol skill. Bounds scope: night-mode paths need no label.
- `plugins/workaholic/skills/drive/SKILL.md` - Carries the shared **"User interaction"** convention bullet (~L25) — the DRY single-source anchor to state the label rule once for drive.
- `plugins/workaholic/skills/ship/SKILL.md` - Shared user-interaction bullet (~L20); ship-side convention anchor.
- `plugins/workaholic/skills/report/SKILL.md` - Shared user-interaction bullet (~L27); report-side convention anchor.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Shared clarifications bullet (~L24); ticket-side convention anchor. The Quality-Gate grill is a long multi-round interrogation — a prime case for losing track of which project is asking.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Interactive-mode worktree-setup / copy-back / ship-selection prompts; night mode asks nothing (out of scope).
- `plugins/workaholic/skills/catch/SKILL.md` - Explicitly issues no `AskUserQuestion` — confirmed out of scope, no change.
- `outputs/workflows/skills/**` - **Generated, never hand-edited.** The build rewrites `AskUserQuestion` to "the agent's selection prompt"; the label convention text must still read sensibly after that rewrite. Regenerate via `scripts/build-plugins/build.mjs` (CI "Outputs Freshness" fails on any diff).

## Related History

No prior ticket has surfaced repo/project/session identity in workaholic's prompts — this is novel. The closest prior art is a cluster that shaped *what content* goes into `AskUserQuestion`: embedding ticket title/overview into the `header`/`question` fields, enforcing selectable `options`, and the workspace-guard prompt. They establish the exact injection surface this change touches without carrying the identity goal.

Past tickets that touched similar areas:

- [20260212222003-show-ticket-context-in-drive-approval-prompt.md](.workaholic/tickets/archive/drive-20260212-122906/20260212222003-show-ticket-context-in-drive-approval-prompt.md) - Made contextual identity structurally unavoidable by embedding it in `header`/`question` (strongest design precedent; subject was ticket context, not repo identity)
- [20260131134135-enforce-selectable-options-in-drive.md](.workaholic/tickets/archive/feat-20260131-125844/20260131134135-enforce-selectable-options-in-drive.md) - Governs how `AskUserQuestion` must be invoked (selectable `options`) — the label change must stay consistent with it
- [20260131194500-per-ticket-approval-in-drive-loop.md](.workaholic/tickets/archive/feat-20260131-125844/20260131194500-per-ticket-approval-in-drive-loop.md) - Defines the high-frequency per-ticket approval prompt the label most benefits

## Implementation Steps

1. **Add a cheap project-label gather script** (`plugins/workaholic/skills/gather/scripts/`): create `project-label.sh` (POSIX `#!/bin/sh -eu`, following `user-slug.sh`) that emits `{"project": "<label>"}`, where `<label>` is the basename of `git rev-parse --show-toplevel`, truncated to **≤12 characters** so it fits the `AskUserQuestion` `header` chip. Keep it network-free (do NOT reuse `git-context.sh`, which calls `git remote show origin`). All basename/truncation logic lives in the script — never inline in command markdown (Shell Script Principle).

2. **Document the script in gather** (`plugins/workaholic/skills/gather/SKILL.md`): add `project-label.sh` to the documented scripts with its JSON shape, so commands discover it the sanctioned way.

3. **State the convention once per skill** (drive/ship/report/create-ticket/trip-protocol `SKILL.md`): in each skill's shared "User interaction" bullet, add the rule: *every `AskUserQuestion` this workflow issues sets `header` to the project label from `project-label.sh`; the decision word moves into the `question` body.* This is the DRY anchor so the rule is authored once per workflow, not per prompt.

4. **Thread the label through each command's prompts** (`commands/{drive,ticket,ship,commit,report}.md`): near the top of each command, run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh` once and reuse `project` for every `AskUserQuestion` in that command. For each existing call site, set `header` to the project label and confirm the `question` body still names the decision (e.g. "Approve this ticket?"). Cover: drive per-ticket approval, order, icebox/stop, abandonment; ticket worktree-guard, moderation, Quality-Gate, ambiguity; ship no-confirmation halt; commit staging-untracked; report workspace/worktree/unknown-context.

5. **Bound the exclusions**: leave `trip` night mode and `catch` unchanged (no prompts), and note in trip-protocol that only its interactive-mode prompts are labeled.

6. **Regenerate and verify outputs** (`outputs/workflows/`): run `node scripts/build-plugins/build.mjs`, then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs`. Confirm the label-convention prose still reads sensibly after the build's `AskUserQuestion → "the agent's selection prompt"` rewrite. `node scripts/test-workflow-scripts.mjs` must stay green (and ideally gains a smoke test for `project-label.sh`, though the agreed gate is manual — see Quality Gate).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `bash plugins/workaholic/skills/gather/scripts/project-label.sh` emits valid JSON `{"project":"workaholic"}` from within this repo, and the value is ≤12 characters (truncated for a longer repo name).
- Triggering each workflow shows the project label in the `AskUserQuestion` **header chip**, and the decision remains legible in the question body:
  - `/drive` per-ticket approval dialog → header reads `workaholic`.
  - `/ship` no-confirmation-method halt → header reads `workaholic`.
  - `/report` worktree/workspace prompt → header reads `workaholic`.
  - `/ticket` moderation or Quality-Gate prompt → header reads `workaholic`.
  - `/commit` staging-untracked prompt → header reads `workaholic`.
- `trip` night mode and `/catch` still issue no prompt (unchanged).

**Verification method** — the commands/tests/probes that prove them:

- Run `project-label.sh` directly and inspect the JSON (criterion 1).
- Manually run each workflow above and **eyeball the dialog header** (developer-selected gate) to confirm the label renders and the decision is still clear.
- `node scripts/build-plugins/build.mjs` produces no unexpected diff; `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs` are all green; `posix-lint` passes for the new script.

**Gate** — what must pass before approval:

- The five dialogs above visibly carry the `workaholic` header label (manual confirmation), `project-label.sh` returns the expected ≤12-char JSON, and the build/verify/metadata/smoke suite plus posix-lint are green with `outputs/` in lockstep (CI "Outputs Freshness" clean).

## Considerations

- **Header chip length.** The `AskUserQuestion` `header` is ~12 characters; `workaholic` (10) fits, but longer repo names must be truncated in `project-label.sh`, not at each call site. Decide truncation policy (hard cut vs. keep a trailing marker) inside the script (`plugins/workaholic/skills/gather/scripts/project-label.sh`).
- **The decision word leaves the chip.** Placement is header-chip-only, so the chip no longer shows `Approve`/`Deploy`/etc. Every affected `question` body must state the decision as a full sentence; audit each call site to ensure none relied on the chip alone to convey the action.
- **Prompt phrasing is prose, not machine-checked.** The developer chose the manual-eyeball gate over a `verify.mjs` assertion, so nothing enforces that a *future* new `AskUserQuestion` carries the label — the shared "User interaction" bullet in each skill is the only guard. If prompts later drift, revisit adding a coverage check (`scripts/build-plugins/verify.mjs`).
- **Outputs rewrite.** The build turns `AskUserQuestion` into "the agent's selection prompt" in `outputs/workflows/`; word the convention so it still reads correctly there (`outputs/workflows/skills/**`), and never hand-edit the generated files.
- **Network cost.** Deliberately avoid extending `git-context.sh` for the label because it performs a network `git remote show origin`; a per-prompt label must stay fast and offline (`plugins/workaholic/skills/gather/scripts/git-context.sh`).
