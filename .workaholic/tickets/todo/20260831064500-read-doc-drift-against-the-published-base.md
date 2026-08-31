---
created_at: 2026-08-31T06:45:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Read doc drift against the published base

## Overview

MINTED MID-RUN (2026-08-31, while `/story` ran for mission
`notify-the-person-a-directed-question-addresses`). `story/scripts/doc-drift.sh`
defaults its base to the **local `main` ref** (`BASE="${1:-main}"`). Every
`/story` run happens inside a **claim worktree**, where that ref is whatever the
clone happened to fetch when it was created and is never advanced afterwards —
so the backstop reports drift from commits that are **not on this branch**.

Measured on `work-20260831-044223`: the default read returned
`structural_changes: [{"kind":"hook_removed","path":"plugins/workaholic/hooks/mission-lens.sh"}]`
and `README.md: {"changed": true}`, while `git diff --name-only origin/main...HEAD`
matched **neither** file. Local `main` stood at `b4a21000` against `origin/main`
at `979d02d8`. Re-run as `doc-drift.sh origin/main`, the same branch reported
`structural_changes: []` and `README.md: {"changed": false}`.

Both directions are wrong, and the second is the dangerous one: a stale base
**over**-reports somebody else's merge as this branch's drift, and — for any file
that changed on the base *and* on the branch in the same region — it can also
**under**-report, because the comparison is against a tree that is not the one
this branch will merge into.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a reading that cannot be trusted is worse than none

## Key Files

- `plugins/workaholic/skills/story/scripts/doc-drift.sh` — line 27,
  `BASE="${1:-main}"`; the default is what changes.
- `plugins/workaholic/skills/story/scripts/area-freshness.sh` — check whether it
  resolves a base at all before assuming this is one script's defect.
- `plugins/workaholic/skills/story/SKILL.md` — where `/story` reads both
  backstops; a caller-side fix belongs here instead if the default is deliberate.

## Implementation Steps

1. **Confirm the default is the defect and not the caller's omission.** Read
   whether `/story` is supposed to pass a base and does not, or whether the
   script's default is what every caller relies on. Fix the one that is wrong;
   do not fix both.
2. Resolve the base the way the rest of the loop does — the published base, not a
   local ref — and keep the positional argument working for a caller that names
   its own.
3. Report when the base could not be resolved rather than silently falling back
   to a local ref: a drift reading nobody can trust is exactly the shape this
   ticket exists to remove.
4. Check `area-freshness.sh` for the same assumption in the same pass, since
   `/story` reads the two together.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Run from a claim worktree whose local `main` is behind, the reading names only
  files this branch actually changed.
- A caller passing an explicit base still gets that base.
- An unresolvable base is named, never silently replaced by a local ref.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic row in `scripts/test-workflow-scripts.mjs` over a throwaway
  repository whose local `main` is deliberately left behind its origin.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes with the new row, and the row
  is proved able to fail against the current default.

## Considerations

- The consequence is bounded: `doc-drift.sh` **reports** and never writes, and
  `/story` treats it as a backstop rather than a gate. What it costs is a story
  whose Concerns name another merge's changes as this branch's — which is a
  documentation defect by this repository's own rule.
- This ticket carries **no `feedback:` refs and no `mission:`**, deliberately: it
  was observed while driving a mission about notification identity and is
  genuinely unrelated to it. Carrying that mission's refs would attribute a
  reader defect to a direction it does not answer, and `workaholic:drive`'s
  failure contract says a wrong thread is worse than none. The stated cost is
  that its own finish line will have no thread to land in.
