---
created_at: 2026-08-04T20:05:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: make-the-feedback-loop-actually-propose
merge_policy:
---

# Record work requests as instructions at the FB capture seam

## Overview

The propose judgment bar is deliberate: `kind: instruction` (and a substantial
`insight` naming concrete work) can originate a proposal; a lone `concern` never
can. But the capture seam is not aligned with it — Slack asks that plainly
request work have been recorded as `concern` or `insight` (e.g.
`20260804143009`, a "please fix this stale doc" ask recorded as `concern`), so
even a correctly running batch judges them to silence. Fix the entry, not the
bar: loosening the bar to read concerns would reopen the false-positive channel
the asymmetry exists to prevent.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / data-handling policies — a record's classification is decided where the context exists (at capture), not re-guessed downstream

## Key Files

- `plugins/workaholic/skills/feedback/SKILL.md` — the `kind` enum's semantics; add the deciding rule
- `plugins/workaholic/commands/fb.md` — the interactive capture surface
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the routine capture surface (Slack asks)
- `plugins/workaholic/skills/propose/SKILL.md` — the judgment bar, which should cross-reference the capture rule instead of silently depending on it

## Implementation Steps

1. State the deciding rule once in `feedback/SKILL.md`: **"does the reporter ask
   for something to be done? then `kind: instruction`"** — a concern is a worry
   about existing work with no ask attached; an insight is an observation or
   conclusion; material/answer are inputs. Include `20260804143009` as the
   measured miss (an ask with a "How to Fix" section, recorded as `concern`).
2. Reference that rule from `commands/fb.md` and the [FB] routine template's
   prompt, so both capture surfaces classify identically — refer, never restate.
3. In `propose/SKILL.md`'s judgment bar, add one line naming the dependency:
   the bar's trigger set assumes the capture rule; a misclassified ask is fixed
   at capture, and re-registering an ask as an `instruction` (via `supersedes`)
   is the sanctioned correction for a record already misfiled.
4. If the hermetic suite covers `feedback/scripts/create.sh` kind validation,
   no schema change is needed — `instruction` is already in the enum; this
   ticket changes guidance, not validation.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The deciding rule exists in exactly one place and both capture surfaces reference it
- The judgment bar names its dependency on the capture rule and the supersedes-based correction path

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "instruction" plugins/workaholic/skills/feedback/SKILL.md plugins/workaholic/commands/fb.md plugins/workaholic/skills/workaholify/routines/fb.md` shows one statement, two references

**Gate** — what must pass before approval:

- `verify.mjs` clean (feedback skill ships in the built bundle — rebuild `outputs/` if its SKILL.md changed); docs consistent in the same change

## Considerations

- Existing misfiled records stay immutable; the correction path is a new record
  with `supersedes`, and this ticket only documents that, never rewrites
  history.
- The routine template edit overlaps ticket
  `20260804200555-give-the-proposal-batch-a-routine-seat-and-retire-the-cron-premise.md`'s
  fb.md edit — drive them in the mission's order and rebase the later edit on
  the earlier one.
