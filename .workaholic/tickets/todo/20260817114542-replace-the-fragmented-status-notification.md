---
created_at: 2026-08-17T11:45:42+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114541-implement-the-daily-note-generation-cadence.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Replace the fragmented status notification

## Overview

Expected action 6, and the mission's closing unit: replace the current "fragmented
notifications into each Slack channel" with the design the previous six tickets build. The
note becomes the artifact; the notification, if any survives, points at it.

What exactly is being replaced comes from the diagnosis ticket, not from this one. Today the
only sanctioned post in this area is the `📦 Release status` root — one gated line per
repository, keyed on `deploy:<digest>`, posted only when something is actionable and the
same digest has not been posted before. If that is what the reporter means by fragmented,
the replacement is a change to its shape and cadence; if it is something else, this ticket's
plan changes with the diagnosis.

## Policies

- `workaholic:operation` / `policies/observability.md` — a notification's job is to bring a human to the artifact
- `workaholic:design` / `policies/interaction.md` — what earns an interruption
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — **The bright line** (an event earns a post by
  needing a human's action or awareness; the tie goes to silence), *The repository tick's
  status line* (the current shape and its two gates), and *The prompt is the ceiling* (a
  shape may be emitted only if the routine's own prompt names it).
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape catalog. Any new
  or changed shape lives here and is mirrored byte-identically in the routine template;
  `scripts/test-workflow-scripts.mjs` pins the pair.
- `plugins/workaholic/skills/workaholify/routines/release-status.md` — the prompt that names
  the current shape.
- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` — the digest and the
  actionable flag behind the current gates.

## Implementation Steps

1. Take the diagnosis ticket's answer to "which posts are the fragmented ones" and state the
   replacement per post: removed, reshaped, or kept.
2. Where a post survives, keep **both** gates — actionable, and content-keyed dedup finding
   no earlier post. They are what let a recurring post exist at all under the bright line,
   and a daily note does not weaken the argument for them.
3. Point the post at the note. A line that links the target's current draft gives a reader
   somewhere to go; a line that restates the note's contents makes the note redundant and
   re-creates the fragmentation.
4. Update the shape in `notifications.md` **and** in the routine prompt, byte-identically,
   in the same commit.
5. Remove any post the diagnosis found to have no owner and no gate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every post named by the diagnosis is removed, reshaped, or explicitly kept with a reason.
- Every surviving post keeps both gates; an idle tick posts nothing.
- Every shape emitted is named verbatim in the routine's own prompt and mirrored in
  `notifications.md`.
- No post carries a Claude mention token.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the template/notifications drift pin.
- Two consecutive ticks with unchanged state: the second posts nothing.
- `sh scripts/e2e/loop-drill.sh verify-status`

**Gate** — what must pass before approval:

- The diagnosis ticket's localization is cited in the Final Report for each post changed.

## Considerations

- The safest outcome may be **fewer posts, not different ones**: if the note is generated
  daily and lives in GitHub Releases, a human already has a place to look, and the bright
  line's tie-goes-to-silence rule argues for keeping only the "something needs your hand"
  line.
- "Fragmented across each Slack channel" may be an artifact of running the routine in
  several repositories at once rather than of the shape itself. If the diagnosis finds that,
  the repair is a scope and configuration matter, not a notify-shape change — and this
  ticket should say so rather than reshape a post that was never wrong.
