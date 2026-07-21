---
created_at: 2026-07-21T02:07:59+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Extend artifact format enforcement to stories, trips, and always-on mission floor

## Overview

Only two artifact types have a PostToolUse validation hook: tickets (`validate-ticket.sh`) and missions (`validate-mission.sh`). Every other `.workaholic/` artifact — stories, trip artifacts, release notes, concerns — has **no format validator at all**. This ticket proposes closing that gap: add `validate-story.sh` and `validate-trip.sh`, add a `type:` presence check to the release-note and concern writers, and make the mission floor **always-on** rather than engaging only when `drive_authorized: true`.

The motivation is a measured one. A cross-repo audit this session found that schema conformance tracks enforcement almost perfectly. The two artifacts that have a validator conform; the ones that do not, collapse:

| Artifact | Has validator? | Carries the expected OKF `type` |
| --- | --- | --- |
| Ticket | yes (blocking) | ~99% (post-enforcement window) |
| Mission | yes (partial) | 100% |
| Concern | no | 39% (many carry rich frontmatter but omit `type`) |
| Release note | no | 24% (most have no frontmatter at all) |
| Story | no | 21% (a few use a lowercase `story`) |
| Trip | no | 4% (most sub-artifacts have no frontmatter) |

The mission validator itself has two gaps worth fixing in the same effort:

1. **The always-on floor is only the `assignee:` KEY**, and even that is not universally met — 27 of 32 active missions (84%) carry it; 5 slipped through (created before the check, or via un-updated plugins / script writes). The stronger floor (non-empty assignee, `## Experience` non-comment body, ≥1 `## Acceptance` item) engages **only** when a mission is `drive_authorized: true`. All currently-authorized missions meet that floor — but a mission is unguarded until the moment it is authorized.
2. **Template drift**: 18 of 32 active missions have no `## Experience` section (they use `## Goal` / `## Scope` / `## Acceptance` / `## Changelog`). The validator checks `## Experience`, so the body template and the validator's expectation have diverged. Either the validator or the emitted template should move so they agree.

## Policies

The standard engineering policies that govern this ticket. The implementing session MUST read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — the validators are POSIX `#!/bin/sh -eu` scripts under `hooks/`, matching the existing validators
- `workaholic:implementation` / `policies/objective-documentation.md` — a hook checks presence/shape (syntax), never quality (semantics); keep the split the ticket/mission validators already honor
- `workaholic:operation` / `policies/ci-cd.md` — new hooks join the PostToolUse validation surface; the reproducible, script-only contract must hold

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` and `plugins/workaholic/hooks/validate-mission.sh` — the two existing validators to mirror (scoping, exit-2-on-fail, archive-excluded, todo-scoped body checks)
- `plugins/workaholic/hooks/hooks.json` — register the new PostToolUse hooks here
- `plugins/workaholic/hooks/mission-lens.sh` and `plugins/workaholic/skills/mission/scripts/` — the mission floor's shared readers; the always-on change belongs alongside them
- `plugins/workaholic/skills/report/` and `plugins/workaholic/skills/write-release-note/` — story / release-note writers whose emitted frontmatter should carry `type`
- `plugins/workaholic/skills/okf/` — the OKF index expects a non-empty `type`; the new checks make that expectation enforced rather than regenerated-around
- `CLAUDE.md` (`### Always-on mission lens`, hook inventory) and the relevant `SKILL.md` files — update docs in the same change

## Implementation Steps

1. `validate-story.sh` (PostToolUse Write|Edit, scoped to `.workaholic/stories/`, excluding `index.md`/`README*`): require frontmatter with `type: Story` and the story's mandatory numbered sections. Non-blocking-vs-blocking severity is a decision — mirror the ticket validator's blocking stance unless there is reason not to.
2. `validate-trip.sh` (scoped to `.workaholic/trips/`): trip artifacts are heterogeneous (Direction / Model / Design / Review / Rollback / Trip Plan / Event Log). Derive the expected `type` from the file's role/location and require it. Decide explicitly what to do with the many existing frontmatter-less sub-artifacts (grandfather archive, enforce only new writes).
3. Make the mission floor always-on: the non-empty-assignee / `## Experience` / `## Acceptance` checks should run regardless of `drive_authorized`, OR document why the graduated floor is intentional and instead tighten the always-on rule. Resolve the `## Experience` vs `## Goal/## Scope` template drift so the validator and the emitted template agree.
4. Add a `type:` presence/value check to the release-note and concern writers (they already emit rich frontmatter — this is a small addition, not a new hook, unless a hook is preferred for parity).
5. Register every new hook in `hooks.json`; keep them Claude-Code-only, POSIX, no `outputs/` footprint (validators live in `hooks/`, not built).
6. Update `CLAUDE.md` and the affected `SKILL.md` files in the same change.

## Quality Gate

**Acceptance criteria**

- A story/trip artifact missing its required `type` (or mandatory section) produces a validation failure with a `file:line`-style message, mirroring the ticket validator's output.
- Grandfathering is explicit: archive/history artifacts are never retro-blocked (as `validate-ticket.sh`/`validate-mission.sh` already do).
- The mission floor's chosen behavior (always-on, or a documented graduated rationale) is covered by a test, and the `## Experience` vs `## Goal/## Scope` divergence is resolved in one direction.
- `hooks.json` registers each new hook; existing ticket/mission validation is unchanged.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with new hermetic cases per validator (a conformant artifact passes; a missing-`type` / missing-section artifact fails; an archive artifact is not retro-blocked).
- `node scripts/build-plugins/verify.mjs` passes; POSIX-lint conformance for every new script.
- Docs-in-lockstep: `CLAUDE.md` and touched `SKILL.md` updated in the same change (the repo's `doc-drift` backstop is clean).

**Gate**

- Suite green, lint conforming, the new validators demonstrated on throwaway artifacts in-session, and the grandfathering decision explicitly recorded before approval.

## Considerations

- **Grandfathering is the crux.** Most existing stories/trips/release-notes predate the `type` convention; a blocking validator must only judge new writes (scope to the finished/`todo`-equivalent location, exclude archive) or it will fire on history it cannot fix — the same reasoning that scopes the ticket validator's body checks to `todo/<user>/`.
- **Severity choice** per artifact: a hard block may be too strong for a trip event-log; consider warn-mode with an opt-in strict toggle (as the `.workaholic/` layout gate already does) so adoption is gradual.
- **Enforcement only reaches repos that enable the plugin.** The audit found conformance gaps concentrated in repos on an older/un-updated plugin; the validators help only where `workaholic@workaholic` is enabled (ideally user-level), a limitation to state, not solve here.
- The mission always-on change interacts with the mission-lens signal gate — a `0/0` mission is deliberately surfaced-but-not-blocked; keep those two behaviors coherent.
