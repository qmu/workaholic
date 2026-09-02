---
created_at: 2026-09-02T19:00:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
---

# Classify the layout by repository root, not by path text

## Overview

`validate-ticket.sh` decides whether a written file lives inside `.workaholic/` by looking for
that segment **anywhere in the absolute path**. Since 2026-09-02 the loops run in clones under
`$WORKAHOLIC_LOOPS_HOME` (default `~/.workaholic/loops/<repo>/<loop>`), so **every** path in a
loop clone contains `.workaholic/` before the repository root is even reached, and the hook reads
the clone's own directory name as an undesignated area.

**Measured this run** (`work-20260902-193702`): an `Edit` to
`plugins/workaholic/skills/drive/scripts/lib/claims.sh` — a file with nothing to do with
`.workaholic/` — was answered with

```
Workaholic layout: undesignated subdirectory 'loops/'.
Got: /home/ec2-user/.workaholic/loops/workaholic/implement/.worktrees/<unit>/plugins/workaholic/skills/drive/scripts/lib/claims.sh
```

It did not block the write here, but it fires on **every** `Edit` and `Write` a loop session
makes, so the one signal that is supposed to mean *you wrote outside the layout* now means
nothing, and a session that trusted it would stop. The defect is the classifier's, not the loop's:
`/spawn-loops` chose a reasonable home and the hook reads a path as if it were repository-relative.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` — the classifier that reads the path.
- `plugins/workaholic/hooks/layout-doctor.sh` — the other reader of the same allowlist; check
  whether it shares the defect before repairing only one.
- `plugins/workaholic/skills/loops/scripts/lib/loop-table.sh` — where the clone home is decided,
  so the cost of moving it instead is visible beside the cost of fixing the classifier.

## Implementation Steps

1. Reproduce it offline: a throwaway repository placed under a directory literally named
   `.workaholic/loops/<x>/<y>`, and a write to a path outside `.workaholic/` inside it.
2. Make the classification **repository-relative**: resolve the repository root
   (`git rev-parse --show-toplevel`, which the working-directory guard already does) and test the
   path's position relative to that root, never the absolute string. A path that cannot be
   resolved to a root keeps today's answer rather than passing silently.
3. Check `layout-doctor.sh` and any other reader of the allowlist for the same string test, and
   repair them in the same change or state why they are unaffected.
4. Rule explicitly on whether moving the loop home is a repair: it is not, because a clone may
   sit anywhere a developer puts it and the next such path would reopen this.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A write outside `.workaholic/` inside a clone whose absolute path contains `.workaholic/`
  raises nothing.
- A write to an undesignated `.workaholic/` subdirectory **inside the repository** is still
  refused, with the same message.
- A path whose repository root cannot be resolved is answered as it is today, never passed.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` over a throwaway repository created under
  a `.workaholic/loops/...` path, one per case above.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The false positive is gone and the true positive is unchanged, both demonstrated rather than
  asserted.

## Considerations

- The hook is a **backstop**; the primary rule lives in `rules/general.md`. Repairing it must not
  widen it — a classifier that resolves a root should refuse more precisely, never less.
- This was found while driving an unrelated mission, so nothing here is urgent in itself; what
  makes it worth a ticket is that a guard which fires on every edit is a guard nobody reads.
