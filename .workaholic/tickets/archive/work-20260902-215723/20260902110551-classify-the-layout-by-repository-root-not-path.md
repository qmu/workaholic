---
created_at: 2026-09-02T19:00:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260902-215723
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

## Final Report

Development completed as planned, and a second instance of the same defect was found and repaired
in the same change.

**Reproduced first**, offline, before anything moved: a throwaway repository under a directory
literally named `.workaholic/loops/wh/implement`, and a write to
`plugins/workaholic/skills/drive/scripts/lib/claims.sh` inside it — answered
`Workaholic layout: undesignated subdirectory 'loops/'`, exactly the measured failure.

**The classifier is now repository-relative.** `rel_path` is derived once, near the top of
`validate-ticket.sh`: the nearest existing ancestor directory is resolved to a repository root
through `git rev-parse --show-toplevel`, and the path is expressed relative to it. All three tests
that ask *where does this file sit inside the repository* — the ticket-shape check, the layout gate
and the ticket-location check — read `rel_path`; the `Got:` line keeps the absolute path, which is
what a person needs. **A path whose root cannot be resolved keeps today's answer**: a hook that
fell silent there would trade a noisy false positive for a quiet false negative.

**The same defect, one layer down.** `missions_root_from_artifact` (`mission/scripts/lib/resolve.sh`)
used `${1%%.workaholic/*}` — longest-suffix removal, which cuts at the **earliest** occurrence —
so an artifact inside a loop clone resolved to `/home/<user>/.workaholic`, a tree that is not a
repository at all, and every mission lookup for it read the wrong root. `%` cuts at the last
occurrence; for a path with one occurrence the two are identical, so no ordinary checkout changes
behaviour. It is reached from this very hook and from `archive.sh`, so repairing only the hook
would have left the loop's own archive path wrong.

**The other allowlist readers are unaffected, and this was checked rather than assumed.**
`layout-doctor.sh` takes a root and enumerates its children — it never classifies an absolute path
by string. The sibling validators anchor on a **designated area name**
(`*.workaholic/missions/*/mission.md`, `*.workaholic/stories/*.md`, …), which a loop clone's outer
path cannot match; only `validate-ticket.sh` matched on the bare `*.workaholic/*`.

**Moving the loop home is not the repair**, and that is a ruling rather than an omission: a clone
may sit anywhere a developer puts it, so the next such path would reopen this.

### Discovered Insights

- **Insight**: `${x%%pattern}` and `${x%pattern}` differ exactly when a path segment repeats —
  which is what a nested clone makes routine rather than exotic.
  **Context**: Both forms read as "strip from `.workaholic/`" and are identical on every ordinary
  checkout, so the defect is invisible to review and to tests until a fixture nests. Worth grepping
  for `%%.workaholic` and `#*.workaholic` as a class rather than one site at a time.
- **Insight**: A guard that fires on every edit is worse than one that never fires.
  **Context**: The false positive did not block anything, so it looked harmless — but it makes the
  one signal that means *you wrote outside the layout* mean nothing, and a session that trusted it
  would stop.
