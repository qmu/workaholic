---
created_at: 2026-08-10T21:30:07+09:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260810212924-precondition-stops-should-post-calm-escalating-to-red-only-on-persistence.md]
merge_policy:
claim: work-20260810-164914
---

# Post precondition stops calm, escalate to red only on persistence

## Overview

PROPOSED. A scheduled run that terminates `pending` at a known, self-healing precondition — `unbound_in_claude_session` (the first tick in a fresh container after a plugin release) or `loaded_version_behind_registry` (a superseded binding) — currently reports that failure with the red-alert shape, the same alarming form a genuine block wears. The developer's ruling (FB `20260810212924`): these stops are the loop's expected cost — the bootstrap has already repaired the environment by the time the post is read, and the next tick proceeds — so the **first** report of such a condition must read calm (a neutral/pause shape, e.g. `⚪`), and the alarming red form is reserved for **persistence**: the same failure signature recurring on a consecutive tick, which is exactly the case that does not self-heal (a stale container image reproducing the condition every tick, measured four-in-a-row on 2026-08-05). The visibility guarantee is unchanged in both directions — a broken fleet must never read as healthy idle, and a known one-tick condition must never read as an emergency.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the red-alert dedup rule (*Post shapes, mentions, and the red-alert dedup*) is where the first-report severity is decided; the escalation rule joins it.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the post-shape catalog; the calm precondition-stop shape and its escalation form are documented here.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — *the prompt is the ceiling*: a session may post only shapes its routine prompt names, so the `[Implement]` template must name the new shape or it can never be posted.
- `plugins/workaholic/skills/workaholify/routines/fb.md` — check whether the `[Propose]` template names a failure shape; amend only if it does.
- `CLAUDE.md` — the `/workaholify` row's interim-safety sentence ("a persisting failure stops reading as a healthy idle tick") describes the red-alert behavior; keep it truthful.
- `outputs/workflows/` — rebuild with `node scripts/build-plugins/build.mjs` if the notify skill is in the drive bundle's closure.

## Implementation Steps

1. Define the **precondition-stop class** in `workaholic:notify` as a named, closed list — the pre-survey gate terminations that are known self-healing conditions (`unbound_in_claude_session`, `loaded_version_behind_registry`; extending the list is a deliberate edit, never a model judgment at post time).
2. Amend the red-alert rule: a **first** report of a precondition-stop signature posts a calm shape (e.g. `⚪ Paused — <signature>`, with the session URL as every post carries); it is still keyed by the same failure signature and still lands as a top-level root so persistence has something to thread onto.
3. Add the **escalation rule**: when the same signature is found in the channel's recent history (the ~50-message read the dedup already performs — no new state), the next report escalates once to the red-alert form (top-level 🔴 or a red threaded reply on the calm root — decide in-change and record why), and from there the existing 24-hour cool-down and `↳ still failing` threaded replies apply unchanged.
4. Leave every genuine-failure shape untouched: a `secret` hard stop, a `blocked` unit finish (`🔴`), and every other outcome shape keep their current severity; an unreadable channel history still posts (silence must never be produced by the mechanism that decides to be silent) — at the calm tier for a first-class precondition stop, red otherwise.
5. Name the calm shape and the escalation in the `[Implement]` routine template (and `[Propose]` only if it names a failure shape), keeping the template a thin pointer that defers the rules here.
6. Update the affected docs in the same change (`CLAUDE.md`, the notify reference) and rebuild `outputs/` if the closure carries notify.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A first-occurrence precondition stop (`unbound_in_claude_session`, `loaded_version_behind_registry`) is specified to post the calm shape, never `🔴`, and the shape is named in the `[Implement]` routine template (the prompt-is-the-ceiling rule).
- The same signature recurring on a later tick is specified to escalate exactly once to the red form, after which the existing dedup/cool-down applies unchanged.
- Every genuine-failure shape (`🔴` blocked finish, secret hard stop) and the `↳ still failing` threaded reply are byte-unchanged in the reference catalog.

**Verification method** — the commands/tests/probes that prove them:

- Read `notify/SKILL.md`, `notify/reference/notifications.md`, and both routine templates side by side and confirm the class list, the first-report shape, and the escalation are stated once (in notify) and only pointed to from the templates.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — clean rebuild, no `outputs/` drift.
- `node scripts/test-workflow-scripts.mjs` — unchanged scripts still pass.

**Gate** — what must pass before approval:

- `Outputs Freshness` and `Validate Plugins` CI green; affected docs updated in the same change.

## Considerations

- The class boundary must stay a **named list**: deciding "is this failure self-healing" at post time from prose is the exact judgment-in-a-notification-path the fuzzy-matching prohibition exists to prevent.
- Under-alerting risk: a calm post the operator skims past delays reaction by one tick at most, because persistence escalates — that bound is the design and should be stated in the notify prose.
- This changes only the notification model (prose); no script emits these posts today, so no script change is expected — if one is found emitting a shape, that is a separate defect to report, not to fix silently here.

## Final Report

Development completed as planned. Defined the precondition-stop class (`unbound_in_claude_session`,
`loaded_version_behind_registry`) as a named, closed list in `workaholic:notify`'s SKILL.md, next to
the red-alert dedup rule it narrows. Added the calm `⚪ Paused - <signature>` shape (top-level root,
carries the session URL) for a first-occurrence report of a class signature, and the escalation rule:
the same signature found again in the dedup's existing ~50-message history read becomes an ordinary
`🔴 Blocked` red alert from that point on, after which the standing 24-hour cool-down and
`↳ still failing` threaded replies apply unchanged. Every genuine-failure shape (`🔴` blocked finish,
a `secret` hard stop, `🟢`/`🚀`/`🟡`) is untouched — verified by diffing the edit against the prior
version, no existing block was altered, only new prose inserted. Documented the exact shape in
`notify/reference/notifications.md`'s new *Precondition-stop* subsection, and named it in the
`[Implement]` routine template (`workaholify/routines/implement.md`) per *the prompt is the ceiling*
rule, since a session may only post a shape its own routine prompt names. Checked `[Propose]`'s
template (`fb.md`) for any existing failure-shape mention per the ticket's scope note — it names none,
so it needed no change. `outputs/workflows` carries neither `notify` nor `workaholify` in its bundle
(verified: `node scripts/build-plugins/build.mjs` produced no `outputs/` diff), so no rebuild was
needed for this ticket's content, though the routine version bump below still regenerated it for its
own reason. `CLAUDE.md`'s `/workaholify` row interim-safety sentence ("a persisting failure stops
reading as a healthy idle tick") was checked against the new model and remains truthful as written —
persistence still surfaces as a red alert with a threaded reply, just via the escalation path now.

### Discovered Insights

- **Insight**: `commit.sh`'s `git add -u` sweeps in every tracked-file modification present in the worktree at commit time, not just the files named in its trailing `[files...]` argument.
  **Context**: A separate "Bump version" commit swept this ticket's content edits in with it (both were tracked-file changes already in the worktree), so the ticket's archive commit ends up as a housekeeping move with no content diff of its own — the actual implementation commit is the version-bump commit immediately before it. Worth knowing when tracing a ticket's changes back through `ticket-commits.sh`, which resolves the archive-time commit, not necessarily the one that carries the content.
