---
created_at: 2026-07-16T01:28:46+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Enforce the mandatory ## Quality Gate section in validate-ticket.sh

## Motivation

`create-ticket/SKILL.md` §4b is unambiguous: the Quality Gate interrogation *"always runs — it is not skippable"*, and the resulting `## Quality Gate` section is **mandatory**. The same file says `## Policies` is mandatory too.

Nothing checks either. `hooks/validate-ticket.sh` (309 lines) validates the ticket's *shape and location* and its frontmatter fields (`created_at`, `author`, `type`, `layer`, `effort`, `commit_hash`, `category`, `depends_on`) — and greps for **no body section at all**. The gap is already recorded as the moderate active concern `quality-gate-is-prose-mandated-not`, and it is not theoretical: `20260715215008-summary-unassigned-missions.md`, written this week and sitting in the queue right now, has **no `## Policies`, no `## Quality Gate`, and no `## Implementation Steps`** — and passed every gate.

**Today that gap is tolerable.** A human approves each ticket at `/drive` Step 2.2 against its gate; a missing or vague gate is visible right there, and the developer is the backstop.

**Ticket `20260716012847` removes that backstop.** Once a mission-authorized queue drives without the per-ticket prompt, the ticket's `## Quality Gate` stops being what a human approves against and becomes **the only bar the agent holds itself to, unattended**. An omitted gate then means a ticket that drives itself unjudged — and nothing says so.

That is why this ships **before** the approval-free drive, not after. `development/qa-engineering`'s Responsibility names the failure precisely: changes "released without anyone looking through it… flowing forward as having passed checks". The gate is the thing doing the looking once the human steps out of the loop. It has to exist.

## Policies

- `implementation/coding-standards` — the validator keeps its contract: "mandatory" in the skill and "unchecked" in the hook cannot both be true.
- `implementation/objective-documentation` — the skill states the section is mandatory; code and documented contract are reconciled in the same change.
- `implementation/test` — the affirmation this whole direction rests on ("the ground on which the AI itself can take over the checking of completeness will broaden") is **conditional** on the tickets carrying real verification. This hook is what makes the condition hold.
- `development/qa-engineering` — the non-delegable limit: nothing may be released with nobody looking through it. Unattended, the gate is the looking.
- `implementation/directory-structure` — the check belongs in the existing hook, not a new one.

## Implementation Steps

1. Add a body-section check to `hooks/validate-ticket.sh` for **`## Quality Gate`** and **`## Policies`** — present and non-empty (a heading with nothing under it is the same defect as no heading).
2. **Decide the blast radius deliberately and record it.** The hook is `PostToolUse(Write|Edit)` on every ticket write. Answer explicitly in the ticket's Final Report:
   - Does it **block** (exit 2) or **warn**? Blocking is the point — a warning is what the prose already is — but a blocking hook that fires mid-authoring, before the section is written, would be hostile. Consider validating only on a ticket in `todo/` (the finished location), which is where the sections must exist.
   - **Legacy tickets**: `20260715215008-summary-unassigned-missions.md` is in the queue and would fail. Archived tickets must not be re-validated. Scope the check so a historical ticket is never retro-blocked.
3. Add the smoke test the concern already names: a ticket missing `## Quality Gate` is rejected; one missing `## Policies` is rejected; a complete one passes; an archived/legacy path is untouched.
4. **Fix the one live offender or exempt it deliberately** — `20260715215008-summary-unassigned-missions.md` has neither section. Either backfill them (it is a real ticket that will be driven) or record why it is exempt. Do not leave the queue in a state the new gate rejects.
5. Update `create-ticket/SKILL.md` and `CLAUDE.md`'s hook description to say the sections are now machine-checked, not prose-mandated. The concern `quality-gate-is-prose-mandated-not` should be closable by this change — say so in the Final Report.
6. `hooks/` has **no `outputs/` footprint** (hooks are not bundled), so no rebuild is needed for the hook itself — but `create-ticket/SKILL.md` **is** bundled, so a rebuild is required if you touch it. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (assertions in `scripts/test-workflow-scripts.mjs`, driven against the real hook with JSON on stdin, as the existing `validate-ticket.sh` tests do):

| case | must hold |
| --- | --- |
| Ticket in `todo/<user>/` with both sections, non-empty | accepted (exit 0) |
| Ticket in `todo/<user>/` missing `## Quality Gate` | **rejected**, message naming the section |
| Ticket in `todo/<user>/` missing `## Policies` | **rejected** |
| `## Quality Gate` present but **empty** (heading, no body) | **rejected** — an empty gate is the defect, not a technicality |
| A ticket under `archive/<branch>/` missing the sections | **accepted** — history is never retro-blocked |
| The existing frontmatter/location assertions | all still green — no regression in a 309-line hook |

**Verification method:** hermetic, same shape as the existing `validate-ticket.sh` coverage (§ around `l.3012`, which already asserts the optional `mission:` field) — pipe `{"tool_input":{"file_path":…}}` to the hook and assert exit status + stderr.

**The gate:** all six rows; the live offender resolved (backfilled or exempted, stated either way); full suite green; `posix-lint` conforming; `git status --porcelain outputs/` empty after a rebuild.

**Watch it fail first:** revert `validate-ticket.sh` alone via `git checkout HEAD -- <path>` (never `git stash` — it removes the tests with the fix and the check passes vacuously), confirm the new rejections go red, restore.

## Considerations

- **This hook is `PostToolUse`, so it speaks after the file exists.** It cannot prevent the write, only reject it loudly. That is the same posture it already has for frontmatter, so it is consistent — but it means the check is a *review*, not a *guard*. Do not over-claim it in the docs.
- **Do not grow it toward judging gate quality.** "Present and non-empty" is syntax and a hook does that well. Whether a gate is *good* is semantic and belongs to the interrogation (§4b) and the developer. The repo already learned this distinction the hard way with the `leak` rule's deleted internal-hostname pattern.
- Related but distinct: `two-enforcement-layers-encode-one-rule` (active) warns that `validate-ticket.sh` and `guard-ticket-structure.sh` re-encode the ticket path rules independently. This change adds no path logic, so it does not worsen that — but if it grows a path component, extract the shared helper that concern asks for.

## Final Report

Development completed as planned. All six gate rows hold, plus a seventh case the ticket did not anticipate.

**Step 2's blast radius, decided and recorded** (the ticket required both answers explicitly):

- **It blocks (exit 2), not warns.** A warning is what the prose already is, and the reason this ships before `20260716012847` is that the gate becomes the only bar an unattended drive holds itself to. A warning would leave that bar optional.
- **Scoped to `todo/<user>/`** — the finished location, where a ticket must be complete before `/drive` reads it. `archive/<branch>/` is history and is never retro-blocked; `icebox/` and `abandoned/` are parking rather than a queue, so a ticket already there is not re-judged (it must pass again on its way back into `todo/` via promote). All three are asserted, because "no regression in a 309-line hook" is the row most likely to bite.

**Step 4, the live offender, backfilled rather than exempted.** `20260715215008-summary-unassigned-missions.md` is a real ticket that will be driven next, so exempting it would have been an excuse. Its `## Quality Gate` is **developer-elicited, not invented**: the two design forks its own Considerations posed went back to the developer, who chose the `assignee` field in the JSON (one payload, so neither consumer re-derives it) and the lens following the summary. The queue is now green under the new gate.

**Step 5's concern is closable.** `quality-gate-is-prose-mandated-not` (moderate, active, origin PR #63) says: *"if hard enforcement is wanted, add a body-section grep to `validate-ticket.sh` plus a smoke test."* That is exactly what landed — grep plus seven assertions. It should be closed at the next `/report` triage. `create-ticket/SKILL.md` and `CLAUDE.md` now say machine-checked rather than prose-mandated, in this commit.

### Discovered Insights

- **Insight**: The gap is minting offenders **in real time**, and the proof arrived mid-session. Verifying the hook against the live queue rejected `20260716021000-gate-sh-worktree-port-resolution.md` — an **untracked** ticket stamped 02:10 today, written outside this session while this session fixed the gap, carrying the identical offender shape (Motivation/Scope/Key Files/Considerations, no `## Policies`, no `## Quality Gate`).
  **Context**: Two tickets in one week from the same authoring path, one of them *during the fix*, retires the "one stale file" reading. It also falsifies the assumption I used to justify blocking — that `create-ticket` writes a complete ticket in a single Write (SKILL.md l.460), so the hook could never fire mid-authoring. That is the sanctioned path, not the only one; hand-authored tickets reach `todo/` too, and for them this hook *is* a mid-authoring block. The developer weighed that and kept blocking, on the ground that an unattended drive with an optional gate is the worse failure. Left untouched deliberately — it belongs to another session.

- **Insight**: An **empty** heading is the interesting case, not a missing one. A ticket with `## Quality Gate` and nothing under it satisfies any grep for the heading while promising nothing at all — it is strictly worse than an absent section, because it looks compliant to a reader skimming for the heading.
  **Context**: This is why the check tests for a non-blank line before the next `## `, and why three of the seven assertions target emptiness rather than absence. The same shape recurs across this repo's gates: the `leak` rule that matched nothing, the round-trip assertion that was never written. A check that can pass vacuously is the failure mode to design against, not the missing check.

- **Insight**: The hook is `PostToolUse`, so it is a **review that rejects loudly, not a guard that prevents**. It cannot stop the file existing; the ticket is already written when it speaks.
  **Context**: That posture is consistent with what the hook already does for frontmatter, so it is not new — but it must not be over-claimed in the docs, and the docs now say so. The distinction matters for the deferred question of whether an unattended drive should *also* check the gate before starting, rather than trusting that a write-time review was never bypassed.

- **Insight**: The check deliberately stops at "present and non-empty" — syntax, which a hook does well. Whether a gate is *good* is semantic and stays with the §4b interrogation and the developer.
  **Context**: The repo already paid for this lesson once: the `leak` rule's internal-hostname pattern was deleted after it was measured to catch none of five real leaks while misfiring on `metadata.internal`. A matcher that reaches for semantics fails quietly and expensively. The honest division is that the hook proves a gate *exists*; only a person can say it is worth anything.
