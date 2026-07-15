---
type: enhancement
layer: [Domain]
created_at: 2026-07-15T21:50:08+09:00
author: a@qmu.jp
depends_on: []
---

# Report unassigned active missions in the mission summary and lens

## Motivation

An active mission with no `assignee` is invisible to every developer, and nothing
says so. `summary.sh:47` filters with

```sh
[ "$(fm_field "$f" assignee)" = "$EMAIL" ] || continue
```

and `fm_field` returns `""` when the field is absent. An empty assignee therefore
matches no `git config user.email` that could ever exist, so the mission is
skipped for everybody — not just for the developer running the command. The same
gate backs the always-on mission lens, so an unassigned mission also never
orients anyone at prompt time. `list.sh` still reports it, which is what makes the
gap silent rather than loud: the mission is plainly there when listed, and simply
absent when summarized.

This is not hypothetical, and it is not one stale file. A repository using the
plugin has two active missions, both unassigned, reaching that state by two
different routes:

- One was scaffolded on 2026-07-12, before `a7166555` (2026-07-13) added the
  `assignee` field to `create.sh`. Legacy data, as expected.
- The other was created on 2026-07-15 — two days *after* that commit — because it
  was hand-authored directly in a commit rather than scaffolded through
  `create.sh`. It is missing `gate_type`/`gate_target`/`gate_assert` for the same
  reason.

So backfilling old files does not close this. As long as `create.sh` is one of
several ways a `mission.md` comes into existence, missions will keep arriving
without an assignee, and each one will silently drop out of the summary that is
supposed to surface it. The second mission above sat invisible from the day it was
written, in the same repository whose owner wrote it.

Between the two readings of "assigned to me" — *mine* versus *not somebody
else's* — the second is the one that matches what the summary is for. An
unassigned mission is unclaimed work, which is closer to the developer's business
than a mission explicitly assigned to a colleague. Dropping it is the one outcome
that helps nobody.

## Scope

Report unassigned active missions alongside the developer's own, distinguishably —
an unassigned mission should not read as one the developer has claimed. Missions
assigned to *another* developer stay filtered out; that part of the gate is
working as intended.

The mission lens (prompt-time) reads the same gate and should follow the summary,
so an unassigned mission orients its repository's developers instead of staying
silent until someone runs `list.sh`.

Out of scope: changing `create.sh`'s self-assignment default, and adding a
frontmatter validator for hand-authored `mission.md` files. Both are defensible,
but this ticket is about the read path not hiding what exists. A validator is
worth its own ticket — the hand-authored mission above also lost its `gate_*`
fields, which the summary gap hides but does not cause.

## Key Files

- `plugins/workaholic/skills/mission/scripts/summary.sh:47` — the equality gate.
  An absent field yields `""`, which is not "no match for me", it is "no match for
  anyone".
- `plugins/workaholic/skills/mission/scripts/summary.sh:1-11` — the header defines
  "assigned to me" as the email match and documents `[]` as "no active mission is
  assigned to the current user". Both need to state where unassigned missions land.
- `plugins/workaholic/skills/mission/scripts/list.sh` — already reports every
  mission with an `assignee` field (empty when absent); the contrast with
  `summary.sh` is the whole bug.
- `plugins/workaholic/skills/mission/scripts/create.sh:43-46` — self-assignment
  default, added in `a7166555`. Correct, and not sufficient, because it is not the
  only writer.
- `plugins/workaholic/commands/mission.md` — the `summary` mode's presentation
  contract; if unassigned missions surface, the command must render them as such.
- `plugins/workaholic/skills/mission/SKILL.md` — the mission schema, where
  `assignee` semantics (including absent) belong.

## Considerations

- Decide whether the JSON gains a field (e.g. `assignee`, or an `unassigned` flag)
  or whether the caller re-reads the frontmatter. The array is consumed by
  `commands/mission.md` and by the lens; a field in the payload keeps both honest
  without either re-deriving it.
- Sort or group so unassigned missions do not crowd out assigned ones. A developer
  with real assigned work should still see it first.
- The lens fires on every prompt. Whatever it says about an unassigned mission
  gets said constantly, so it should read as an invitation to claim it, not as an
  error.
- Absent versus empty (`assignee:` with no value) should behave identically.
  `fm_field` already collapses them; keep it that way rather than growing a
  distinction the schema does not have.
