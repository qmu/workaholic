---
type: enhancement
layer: [Domain]
effort: 1h
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

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the read path stays in the mission skill's `scripts/`; no parsing leaks into the hook or the command.
- `workaholic:implementation` / `policies/coding-standards.md` — the predicate keeps its contract: `summary.sh` answers "is this mission not somebody else's", not "does this mission's assignee string equal mine".
- `workaholic:implementation` / `policies/domain-layer-separation.md` — "who may see this mission" is domain logic and belongs in one reader both the command and the lens call, rather than being re-derived by each.
- `workaholic:implementation` / `policies/objective-documentation.md` — `summary.sh`'s header defines "assigned to me" and documents `[]`; the code and its documented contract are reconciled in the same change.
- `workaholic:implementation` / `policies/test.md` — the boundary condition to target deliberately: absent and empty `assignee` must behave identically, and another developer's mission must still be excluded.
- `workaholic:design` / `policies/history-structures.md` — the lens speaks on every prompt; what it says about unclaimed work must invite claiming rather than read as an error.

## Quality Gate

**Developer decisions (elicited 2026-07-16):** the JSON gains an **`assignee` field** (empty = unassigned) so both consumers read one payload and neither re-derives it from frontmatter; and the **lens follows the summary**, surfacing unassigned missions phrased as claimable, still subject to its existing location and signal gates.

**Acceptance criteria** (assertions in `scripts/test-workflow-scripts.mjs`, hermetic temp repos):

| case | must hold |
| --- | --- |
| Active mission with **absent** `assignee` | appears in `summary.sh` output, carrying `assignee: ""` |
| Active mission with **empty** `assignee:` (field present, no value) | identical behaviour to absent — no distinction the schema does not have |
| Active mission assigned to **another** developer | still **excluded**. This half of the gate works and must not regress |
| Active mission assigned to **the current user** | appears, carrying their email, and **sorts before** unassigned ones |
| Ordering | a developer with real assigned work sees it first; unassigned missions never crowd it out |
| Mission lens | surfaces an unassigned mission subject to its **existing** location and signal gates (worktree focus and at-least-one-acceptance-criterion are unchanged), worded as an invitation to claim |
| `list.sh` | unchanged — it already reported every mission; the contrast with `summary.sh` was the bug |

**Verification method:** hermetic temp repos, no network, driving the real `summary.sh` and the real lens with fixture missions covering absent / empty / mine / another's.

**The gate:**

1. **Watch it fail first.** Back the file up, then `git checkout HEAD -- plugins/workaholic/skills/mission/scripts/summary.sh` (never `git stash` — it takes the tests away and the check passes vacuously), confirm the unassigned assertions go RED, restore from the backup.
2. Full suite green, 0 failed; `posix-lint.sh` conforming; `verify.mjs`, `validate-metadata.mjs` pass.
3. `node scripts/build-plugins/build.mjs` — the mission skill **is** bundled — then `git status --porcelain outputs/` shows only this change's intended diff.
4. **Drive the real thing:** run `/mission summary` in a repo holding an unassigned active mission and confirm it is reported, distinguishably from a claimed one.

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

## Final Report

Development completed as planned, against a gate that was **backfilled by the driving ticket `20260716012846`** — this ticket originally had no `## Policies` and no `## Quality Gate`, and was the live offender that ticket's new hook rejects. Both were written before implementation, with the two design forks elicited from the developer rather than chosen unilaterally.

**The developer's two decisions, and why they hold:**

- **The JSON gained an `assignee` field** (empty = unassigned) rather than an `unassigned` boolean or per-caller re-reads. One payload, so `commands/mission.md` and `hooks/mission-lens.sh` read the fact from one place instead of each re-deriving it from frontmatter — the duplication pattern this repo keeps paying for (three `slugify()` copies, two enforcement layers encoding one path rule).
- **The lens follows the summary.** Its assignee gate now reads "not somebody else's"; its **other two gates are untouched** — worktree focus and the at-least-one-acceptance-criterion signal gate still apply, so an unassigned `0/0` mission stays silent in the lens while `/mission summary` still shows it. That deliberate threshold divergence survives intact.

**Ordering** is two passes rather than a sort key: mine first, unassigned after, each already slug-sorted by `$DIRS`. A developer with real assigned work is never crowded out by an offer, in both the summary and the lens.

**Docs reconciled in the same commit**, all three places that stated the old rule: `mission/SKILL.md` (the schema's `assignee` semantics), `commands/mission.md` (the `summary` presentation contract, which now tells the command to render an unassigned mission distinguishably by reading the payload field rather than the file), and `CLAUDE.md` (which documented the lens's assignee gate as a strict email match, twice).

**Gate results.** Watched it fail first — 8 assertions red across both scripts, backing the files up before reverting. Full suite 721 passed / 0 failed. `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; the rebuild touched the six bundled `summary.sh` copies plus the bundled `mission/SKILL.md` (the lens is a hook and has no `outputs/` footprint).

**Gate step 4 was approximated, and that is worth stating plainly.** It asked to run `/mission summary` in a repo holding an unassigned active mission. This repository has **no missions at all**, and the two real ones live in a consumer repo that repository-confinement forbids me from entering. So I reproduced the exact reported shape in a throwaway repo — both documented routes (a pre-`a7166555` legacy mission and a hand-authored one), plus a claimed mission and a colleague's — and confirmed the claimed one lists first, both unassigned ones surface marked `[unclaimed — yours to take]`, and the colleague's stays hidden. That is the closest honest check available here; it is a faithful reproduction, not the literal repository the ticket observed.

### Discovered Insights

- **Insight**: My first attempt at that real-shape probe was **silently wrong, and it took a known-positive to catch it**. `printf '%s'` does not expand `\n`, so every fixture carried literal backslash-n: the claimed mission's frontmatter was malformed and it vanished from the output, while `next` read `Claim me\n`. Had I only asserted "the unassigned missions appear", the probe would have passed while measuring garbage.
  **Context**: The tell was the *known-positive* — the claimed mission was missing when it had every reason to be there. This repo's own story (`work-20260715-112717.md` §7) already records this exact lesson twice: "assert a known-positive and a known-negative before trusting a probe", after a harness silently reported no-hit for every input. It is the same failure mode as an empty `## Quality Gate` heading and the `leak` rule that matched nothing: a check that passes vacuously. The suite's fixtures were never affected — JS template literals interpolate properly — so this only ever threatened the ad-hoc verification, which is precisely where nobody is watching.

- **Insight**: The bug's shape is worth naming: an equality test against a field that can be **empty** is not a filter, it is a **disappearance**. `"" == $EMAIL` is false for every developer who could ever run the command, so the mission was excluded universally rather than merely "not matched for you".
  **Context**: The asymmetry with `list.sh` is what kept it invisible — the mission was plainly there when listed and simply absent when summarized, so nothing ever looked broken. Any predicate keyed on an optional field should answer "is this excluded *from someone*" and be tested with the field absent, which is exactly the boundary the new tests target. The same reading applies to the `gate_*` fields the ticket notes are missing from that hand-authored mission.

- **Insight**: `create.sh`'s self-assignment default was a real fix that could not close this, because **it is not the only writer**. The second real mission was hand-authored two days *after* that default shipped and still arrived unassigned.
  **Context**: This is the same structural lesson as the `## Quality Gate` hook driven immediately before it: a default on the sanctioned creation path does not constrain the other paths, so the *read* side has to tolerate what the write side failed to guarantee. The ticket scoped a mission frontmatter validator out, deliberately, and that remains the open follow-up — it would also recover the missing `gate_*` fields, which this change does not address.
