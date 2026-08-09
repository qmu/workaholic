---
created_at: 2026-08-07T08:26:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260807082554-agents-must-not-add-slack-notifications-beyond-the-routine-prompt-s-specified-format.md]
merge_policy:
claim: work-20260809-201846
---

# Forbid agents from self-authorizing notification formats beyond the routine prompt

## Overview

**PROPOSED**, from `#298` (assignee `tamurayoshiya`) and its Slack thread. While running `/implement`, a session posted a Slack notification (a "🟣 Merged by" line on PR merge) that its routine prompt never specified, justifying the addition on its own by citing the `workaholic:notify` skill's documentation and its own earlier in-session reasoning — without confirming with the developer first. `workaholic:notify`'s *The bright line — what earns a post* section already states which events earn a post, but nowhere does it say who gets to decide the exact wording/shape used for a given routine — the shapes in `reference/notifications.md` read as available options rather than as the ceiling. This ticket adds the missing rule: an agent may only emit the notification events and shapes its own routine prompt (or the calling command) explicitly specifies; a shape not named there — even one documented elsewhere in the skill, even one the session itself used earlier in the same run — requires developer confirmation before becoming standing behavior, and citing a skill's own documentation as authorization is not a substitute for that confirmation. Merging the pull request this was published on is what turns this from a proposal into queued work.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the runtime notification model; needs an explicit standing rule that a routine session may only use the notification events/shapes named by its own routine prompt or invoking command, never a shape it independently derives from this skill's own documentation or from prior in-session reasoning.
- `plugins/workaholic/skills/notify/reference/notifications.md` — carries the exact post shapes; should be framed as the catalog a template *may* draw from when it explicitly names an event, not as blanket authorization for a session to add one.
- `plugins/workaholic/skills/workaholify/routines/` — the `[Propose]`/`[Implement]` routine templates; confirm each already states its own postable events exhaustively (per "A template is a thin pointer, not a procedure") and does not rely on a session inferring the rest from `workaholic:notify`.
- `outputs/workflows/` — regenerate via `node scripts/build-plugins/build.mjs` since `workaholic:notify` and `workaholic:drive`/`workaholic:propose` (which reference it) ship into the cross-agent bundle.

## Implementation Steps

1. In `workaholic:notify`'s `SKILL.md`, add an explicit constraint (near *The bright line — what earns a post* or as its own subsection): a session may emit only the notification events and post shapes its own routine prompt or invoking command names; a shape documented elsewhere in this skill (or used earlier in the same session) is not itself authorization, and adding one requires developer confirmation before it becomes standing behavior.
2. Update `reference/notifications.md`'s framing so the shapes read as a catalog a template draws from when it explicitly opts in, not as a menu a session may pick from unprompted.
3. Skim the `[Propose]` and `[Implement]` routine templates (`skills/workaholify/routines/`) to confirm each names its postable events exhaustively; tighten wording if either currently reads as deferring "the rest" to `workaholic:notify`.
4. Regenerate `outputs/workflows/` (`node scripts/build-plugins/build.mjs`) and run `node scripts/build-plugins/verify.mjs` so the cross-agent bundle stays in lockstep.
5. Update any doc referencing the notify skill's scope if the new constraint changes its one-line description.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:notify`'s `SKILL.md` states, in prose a reviewer can point to, that a session may emit only the notification events/shapes its own routine prompt or invoking command names, and that neither this skill's own documentation nor prior in-session reasoning is itself authorization to add one.
- `outputs/workflows/` is rebuilt and carries the same wording (`node scripts/build-plugins/build.mjs`).

**Verification method** — the commands/tests/probes that prove them:

- Read the new section of `plugins/workaholic/skills/notify/SKILL.md` and confirm the rule is unambiguous and testable by a reviewer without cross-referencing another document.
- `node scripts/build-plugins/verify.mjs` passes (generated skills self-contained, no `outputs/` drift).
- `git diff` shows no unrelated behavior change — this is a documentation-only ticket.

**Gate** — what must pass before approval:

- The new rule reads as a constraint on the *agent*, not a new post shape, and does not contradict or duplicate the existing *bright line* / *post shapes* sections.
- `verify.mjs` and `validate-metadata.mjs` both pass.

## Considerations

- This is a **documentation-only** change: it adds a standing rule, it does not change which events already earn a post (`workaholic:notify`'s *bright line*) or their shapes. Do not use this ticket to redesign the notification model.
- Keep the wording generic to "any notification shape not named by the routine prompt/command", not scoped only to the PR-merge line that triggered #298 — the same failure mode (citing a skill's own docs as self-authorization) could recur for any event.
- The routine templates (`skills/workaholify/routines/`) already claim to name their postable events exhaustively (per *A template is a thin pointer, not a procedure*); if reading them surfaces a gap, note it here rather than silently expanding this ticket's scope — file a follow-up feedback record instead.
