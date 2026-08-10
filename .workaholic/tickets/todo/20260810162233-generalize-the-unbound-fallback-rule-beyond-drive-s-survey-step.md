---
created_at: 2026-08-10T16:22:33+00:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
depends_on:
feedback: [20260810162113-routines-should-keep-going-when-the-plugin-is-unbound.md]
merge_policy:
---

# Generalize the unbound-fallback rule beyond /drive's survey step

## Overview

Issue #356 reports two live routine failures caused by the `unbound_in_claude_session`
condition (`Skill(...)` fails "Unknown skill", `ListSkills` returns empty, though
`ListPlugins` reports the plugin installed): an `[Implement]` schedule tick, and a
separate **merge-announcement run triggered by a PR closing**. CLAUDE.md already
documents a fix for the first shape — `/drive` (ticket `20260810090005`) now warns
and continues on `unbound_in_claude_session` by driving the rest of its tick from
checkout-relative script paths instead of `${CLAUDE_PLUGIN_ROOT}`. That fix is scoped
to `/drive`'s own pre-survey `check-deps` gate. The second failure instance in #356 —
a merge-announcement run, which is `workaholic:notify`/the `[Consent]` routine's
territory, not `/drive`'s — is not covered by it: nothing generalizes the
warn-and-continue behaviour to routine steps outside `/drive`'s survey gate.

This ticket generalizes the rule: whenever a routine's skill surface is unreachable
mid-task (unbound), the default is to read the needed scripts directly (Read/Bash,
checkout-relative paths) and carry the task out, rather than halting and only
posting a notification. Stopping stays correct when the step genuinely cannot
proceed without the skill surface (an `AskUserQuestion`-driven flow, or logic too
risky to hand-reconstruct from source) — only the blanket "unbound → stop" default
changes, and only for the steps that don't need it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — routine/runtime recovery behaviour under a degraded harness binding

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` — already emits `unbound_in_claude_session`; the signal this ticket's fallback reacts to.
- `plugins/workaholic/skills/drive/SKILL.md` (and its scripts) — the existing scoped precedent (ticket `20260810090005`) to generalize from.
- `plugins/workaholic/skills/notify/SKILL.md` — owns the merge-announcement/`[Consent]` path named as the second failing instance in issue #356; needs the same fallback.
- `plugins/workaholic/rules/general.md` or `plugins/workaholic/rules/workaholic.md` — the always-loaded rule surface where a generalized "unbound → fall back to reading scripts directly, unless AskUserQuestion-dependent" statement belongs, so every routine step (not just `/drive`'s) inherits it.
- `plugins/workaholic/skills/workaholify/routines/` (`fb`, `implement` templates) — verify neither template's own prose contradicts the generalized fallback.

## Implementation Steps

1. Read `check-deps/scripts/check.sh` and `/drive`'s existing `unbound_in_claude_session` handling (ticket `20260810090005`'s diff / current SKILL.md text) to confirm the exact mechanics being generalized.
2. Add a general rule (in `rules/general.md` or `rules/workaholic.md`, always-loaded) stating: when the skill surface is unreachable mid-task, fall back to reading the plugin's scripts directly from the checkout path and complete the step, **except** where the step is `AskUserQuestion`-driven or otherwise too risky to hand-reconstruct from source — those keep failing safe and stop.
3. Apply the same fallback to the merge-announcement / `[Consent]` path (`workaholic:notify`) named in issue #356, and to any other routine step outside `/drive`'s survey gate that currently stops unconditionally on an unreachable skill.
4. Update CLAUDE.md's `/workaholify` entry (and any other doc naming the current `/drive`-scoped behaviour) to describe the generalized rule, per the "update the docs in the same change" project rule.
5. Note in the ticket/PR which steps remain fail-safe-stop (the `AskUserQuestion` / too-risky-to-reconstruct exceptions) so the narrowing is explicit, not implicit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A routine step outside `/drive`'s survey gate (e.g. the merge-announcement/`[Consent]` path) that hits an unreachable skill surface falls back to reading scripts directly and completes the task, instead of halting with only a notification.
- An `AskUserQuestion`-driven or otherwise unreconstructable step still fails safe and stops on the same condition.
- CLAUDE.md and the relevant skill docs describe the generalized rule, not just `/drive`'s scoped case.

**Verification method** — the commands/tests/probes that prove them:

- Re-read the updated rule/skill text against issue #356's two named failure instances and confirm both are now covered.
- `node scripts/build-plugins/verify.mjs` (if any touched skill/rule changes ship through the generated bundle).

**Gate** — what must pass before approval:

- The generalized rule is stated in the always-loaded `rules/` surface (not just restated per-skill), consistent with the project's "thin commands, comprehensive skills" and single-source-of-truth conventions.

## Considerations

- Scope judgment call: this ticket treats the ask as atomic (one generalized rule
  statement plus applying it to the one other named instance), rather than
  decomposing into a mission. If, on inspection, applying the fallback to `notify`
  and to other routine surfaces turns out to need materially different mechanics
  per surface, splitting into a small mission may be warranted at implementation
  time.
- The existing `/drive` fix reads scripts via checkout-relative paths specifically
  because `${CLAUDE_PLUGIN_ROOT}` is empty when unbound; the same substitution
  applies wherever this fallback is added.
