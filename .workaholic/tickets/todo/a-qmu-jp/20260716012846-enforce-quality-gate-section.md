---
created_at: 2026-07-16T01:28:46+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
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
