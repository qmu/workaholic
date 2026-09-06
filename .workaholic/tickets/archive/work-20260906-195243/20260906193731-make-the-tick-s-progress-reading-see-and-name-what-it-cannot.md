---
created_at: 2026-09-06T19:37:31+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260906193712-tick-progress-sh-resolves-its-sibling-readers-against-the-consuming-repo-so-every-mission-row-is-null-and-propose-gate-answers-open.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
merge_policy:
verification_handoff: 
claim: work-20260906-195243
---

# Make the tick's progress reading see, and name what it cannot

## Overview

`plugins/workaholic/skills/loops/scripts/tick-progress.sh` resolves its two sibling readers
against the **consuming** repository instead of against its own location. On any repository
that does not vendor the plugin, `$S` names a directory that does not exist, both reader
calls fail, `|| echo '{}'` swallows the failure, and the jq `// null` defaults render "I
could not run the reader" as `null`.

Two of the resulting fields are wrong answers rather than absent ones, and both are
load-bearing: `draining` is `(.[1].archive // 0) > 0`, so an unreadable archive count reads
as *nothing has ever landed here*; and `gating` increments only on `.todo // 0 > 0`, so a
`null` todo can never gate — `gating_missions` is structurally pinned at 0 and `propose_gate`
always chooses `open`. A caller acting on `open` originates new work against a queue that is
not draining, which is the exact state the gate exists to prevent.

Measured by the operator over eight consecutive readings, ~50 minutes, two active missions:
every per-mission field `null`, `draining: false` against six archived tickets,
`gating_missions: 0` against 2, `propose_gate: open` against `work_waiting`. `queue_total`
was correct throughout — it reads `$ROOT/.workaholic/tickets/todo` directly and touches no
sibling script, which is the control that makes the defect easy to miss.

**This ticket also carries a second defect the report did not name**, established by the
proposal's diagnosis pass: `queue-size.sh` takes `<mission-slug> [workaholic-root]` and
`tick-progress.sh` passes only the slug, so the root is resolved from `git rev-parse
--show-toplevel` at the **process cwd**. Repairing `$S` alone leaves that in place and turns
the visible `null`s into plausible `0`s — deepening the very failure the ask is about.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/loops/scripts/tick-progress.sh` — the defect. Line 22 composes
  `$S` from `$ROOT`; lines 31-32 call the siblings through it; lines 35-38 turn the swallowed
  failure into `null`, an inverted `draining` and a pinned `gating`.
- `plugins/workaholic/skills/loops/scripts/claimable-units.sh` — the correct idiom already in
  the same directory (`SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)`, then
  `"${SCRIPT_DIR}/../../<skill>/scripts/..."`). Follow it rather than inventing a spelling.
- `plugins/workaholic/skills/mission/scripts/queue-size.sh` — takes `[workaholic-root]` as its
  second argument; read its resolution block before changing the call.
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — its header states the rule the
  current call violates: "RESOLUTION IS A FUNCTION OF (ROOT, arg) WITH NO AMBIENT INPUT ...
  never from the process cwd".
- `plugins/workaholic/commands/infinite-development.md` — the one call site (§2b) and the
  place that already says three times that a degraded read is named by its reason and never
  rendered as a healthy zero. The §3 report clause is where a named degradation must surface.
- `scripts/test-workflow-scripts.mjs` — `tick-progress.sh` has no coverage there today.

## Implementation Steps

1. **Reproduce first, before changing anything.** Build a scratch consumer repository with a
   `.workaholic/` tree, at least one active mission with a linked acceptance item, some queued
   tickets and some archived ones, and **no `plugins/` directory**. Run `tick-progress.sh
   <that root>` and record the object. Then run `mission/scripts/progress.sh` and
   `mission/scripts/queue-size.sh` from the plugin checkout against the same tree with an
   explicit root, and record their answers. The two must disagree exactly as the Overview
   describes; if they do not, stop and re-localize rather than applying the fix.
2. **Localize both halves.** With the reproduction in hand, confirm (a) that `$S` names a
   missing directory, and (b) — separately — that `queue-size.sh` called with only a slug
   resolves its root from the process cwd. Test (b) by running the reproduction with cwd set
   somewhere other than the consumer root; the todo/archive counts must go wrong on their own,
   independently of `$S`.
3. **Resolve the siblings against the script's own location.** Follow `claimable-units.sh`'s
   spelling exactly. `ROOT` keeps its current meaning and stays what the `.workaholic/` paths
   on lines 23 and 25 are built from — those are correct today and must not change.
4. **Pass the root that `queue-size.sh` already accepts**, so its resolution stops depending on
   the process cwd. Confirm `progress.sh` is still handed an absolute mission path derived from
   `ROOT`; if `ROOT` can arrive relative, absolutize it once where it is assigned rather than at
   each use.
5. **Stop rendering a failed read as data.** A row whose reader could not run must say so by its
   own reason rather than carrying `null` counts and a computed `false`. Decide and record which
   shape the row takes — the repository's existing convention is a `readable: false` with a named
   reason and null counts (`strategy/scripts/*`, `cadence-state.sh`), and this script should
   match it rather than invent a third. `draining` must not be `false` on a row whose archive
   count was never read, and `gating` must not silently skip such a row.
6. **Make `propose_gate` honest about a degraded read.** Today it is `work_waiting` or `open`.
   A tick that could not read any mission row knows neither. Choose between a third word and an
   accompanying `readable`/`reason` field, and state the choice in the script's header with its
   cost; do not leave a caller unable to tell "the gate is open" from "the gate could not be
   read". Whatever is chosen, an unreadable row must never be able to produce `open`.
7. **Surface it at the call site.** Update `commands/infinite-development.md` §2b/§3 so a
   degraded progress reading is named by its reason in the tick report, consistent with the
   allocation and machine lines that already do this.
8. **Add coverage** in `scripts/test-workflow-scripts.mjs`: a hermetic consumer tree with no
   vendored plugin must produce correct per-mission counts and the correct `propose_gate`, and
   the same tree read with cwd elsewhere must produce the identical object. Pin the degradation
   shape too, so a future change cannot quietly return to a healthy-looking zero.
9. **Re-run the grep and record the result.** Across `plugins/workaholic/skills/`, `hooks/` and
   `scripts/`, no other script composes `"$ROOT/plugins/workaholic/..."` as an executable path
   (established by this proposal). Confirm it still holds after the change and note it, so a
   later reader does not re-open the question.
10. Run `node scripts/build-plugins/build.mjs`, `node scripts/build-plugins/verify.mjs` and
    `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- On a repository with no vendored `plugins/` directory, `tick-progress.sh` reports each active
  mission's real `checked`, `total`, `todo` and `archived`.
- `draining` is `true` exactly when that mission's archive count was **read** and is non-zero;
  it is never `false` on a row whose archive count could not be read.
- `propose_gate` answers `work_waiting` whenever any readable mission carries queued work, and
  can never answer `open` on the strength of a row that could not be read.
- The object is identical whether the process cwd is the target repository root or elsewhere.
- A row whose reader failed carries a named reason, not null counts alone.
- `queue_total` is unchanged in meaning and value.

**Verification method** — the commands/tests/probes that prove them:

- The hermetic case added in step 8, run via `node scripts/test-workflow-scripts.mjs`.
- The step 1 reproduction re-run after the change: `tick-progress.sh <consumer root>` must now
  agree with `progress.sh` / `queue-size.sh` run directly with an explicit root.
- The same reproduction run twice with different process cwds, outputs diffed.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the new coverage.
- `node scripts/build-plugins/verify.mjs` passes (`outputs/` regenerated if the skill changed).
- The degradation shape chosen in steps 5-6 is stated in the script's own header with its cost.

## Considerations

- **The reporter's proposed fix, as a hypothesis rather than the design.** The ask proposes
  `S="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"`. The diagnosis pass confirms this is
  necessary and **not sufficient**: applied alone with cwd pointed away from `ROOT`, the
  reproduction answered `checked: 1, total: 3` correctly but `todo: 0, archived: 0,
  draining: false, gating_missions: 0, propose_gate: open` — plausible zeros where there had
  been visible nulls, which is a worse failure than the one being cured. Take the spelling from
  `claimable-units.sh` and pair it with step 4; do not adopt the one-line change on its own.
- **`../..` from `skills/loops/scripts/` is `skills/`, which is what `$S` means today.** The
  arithmetic in the ask is correct. It is the *sufficiency* that is not.
- **The divergence between `ROOT` and cwd is the designed case, not an edge case.**
  `tick-progress.sh` takes `[repo-root]` precisely so a caller can name a tree it is not
  standing in, and the loop's own subagents run in claim worktrees and publish trees. A repair
  that is correct only when cwd happens to equal `ROOT` re-introduces the bug for the caller the
  argument exists for.
- **Do not remove the `|| echo '{}'` guards without replacing them.** They exist so a single
  unreadable mission does not abort the whole reading. The defect is that a swallowed failure is
  then rendered as data, not that failures are caught. Convert them into a named reason on that
  row; keep the walk completing.
- **`queue_total` is the control and must stay one.** It reads the ticket directory directly and
  was correct throughout the measured failure. Resist folding it into the same reader path for
  tidiness — its independence is what made the defect diagnosable.
- **Cost of the call site's design is unchanged.** §2b starts this reading in the background and
  renders the *previous* tick's, so the numbers are up to one tick old by design. This ticket
  does not touch that; it only makes the numbers true when they arrive.
- **Performance.** `queue-size.sh` walks every queued ticket through `read-relation.sh`, measured
  ~60s on this repository. On a consumer where the reading currently fails instantly, fixing it
  makes the call take real time for the first time. That is expected, and §2b's background start
  is what absorbs it — but confirm the background invocation genuinely does.

## Final Report

Development completed as planned. **Both** halves were repaired; the reproduction was built
and run before anything changed, and the second half was proved to matter by measuring the
one-line fix on its own.

### 1. The defect, reproduced before any change

A scratch consumer repository — a `.workaholic/` tree with one active mission (acceptance
1/3), 2 queued and 6 archived tickets, and **no `plugins/` directory**:

```
$ sh tick-progress.sh <consumer>
{"queue_total": 2,
 "missions": [{"slug":"demo-mission","checked":null,"total":null,"todo":null,
               "archived":null,"draining":false}],
 "gating_missions": 0, "wip_limit": 3, "propose_gate": "open"}

$ sh mission/scripts/progress.sh   <consumer>/.workaholic/missions/active/demo-mission/mission.md
{"checked": 1, "total": 3, "unlinked": 0}
$ sh mission/scripts/queue-size.sh demo-mission <consumer>/.workaholic
{"slug":"demo-mission","todo":2,"archive":6,"total":8,"floor":2,"meets_floor":true}
```

The two disagree exactly as the Overview describes: every per-mission field `null`,
`draining: false` against six archived tickets, `gating_missions: 0` against a mission
carrying queued work, and `propose_gate: open` where it must read `work_waiting`.
`queue_total: 2` was correct throughout — the control.

### 2. Both halves localized, independently

**(a)** `$S` named a directory that does not exist on the consumer:
`<consumer>/plugins/workaholic/skills` — MISSING.

**(b)** measured **separately**, with `$S` untouched — `queue-size.sh` called with only a slug:

```
$ ( cd <consumer> && queue-size.sh demo-mission )   -> {"todo":2,"archive":6,...}
$ ( cd <plugin checkout> && queue-size.sh demo-mission ) -> {"todo":0,"archive":0,...}
```

Its root comes from `git rev-parse --show-toplevel` at the **process cwd**.

### 3. The half fix, measured — why step 4 is not optional

With the siblings resolved correctly and the root **not** passed, read from a foreign cwd:

```
{"checked":1,"total":3,"todo":0,"archived":0,"draining":false},
 "gating_missions":0, "propose_gate":"open"
```

Plausible zeros, no `readable: false`, and the gate still wrongly `open` — a **worse** failure
than the visible nulls, exactly as the ticket's Considerations predicted. This is the breaker
the new coverage is written against.

### 4. The repair

- Siblings resolve against the script via `SCRIPT_DIR` — the spelling copied verbatim from
  `claimable-units.sh` in the same directory, not invented.
- `queue-size.sh` is handed `"$WORKAHOLIC"`, the root it already accepts.
- `ROOT` is absolutized **once** where it is assigned, so a relative argument reads the same
  tree; `ROOT` keeps its meaning and the `.workaholic/` paths built from it are unchanged.
- `set -eu` is now explicit in the body. The shebang carried `-eu`, which does nothing when the
  script is invoked as `sh <path>` — which is how every caller invokes it.

### 5. The degradation shape, and the choice step 6 asked for

A row whose reader could not run carries `readable: false`, a named reason and **null** counts,
with `draining: null` rather than `false`. Four reasons name which half failed —
`progress_reader_missing` / `queue_reader_missing` (which is what the measured failure would
have said, pointing straight at the resolution) and `progress_unreadable` / `queue_unreadable`.
`readable` is **absent** on a row that was read, the repository's existing convention.

**`propose_gate` is three-valued** — `work_waiting` / `open` / **`unreadable`**. Chosen over an
accompanying `readable` field because folding an unreadable walk into `work_waiting` is
deriving a degradation into a verdict, which this repository's standing rule forbids;
`cadence-state.sh` and `direction-state.sh` already answer `unreadable` as its own word, so this
invents no third convention. The precedence is deliberately **not symmetric**: a readable row
with queued work still answers `work_waiting` (a positive fact an unreadable row cannot
overturn); otherwise any unreadable row answers `unreadable`; only a fully-read walk with
nothing queued answers `open`. An unreadable row can therefore never produce `open`.

**Cost, stated in the header**: a caller switching on two words meets an unfamiliar third — and
falls through rather than originating, which is the safe direction. `unreadable_missions` rides
beside `gating_missions` so the skip is visible in the counts rather than silent.

The `|| echo '{}'` guards are **kept** in effect (the walk still completes past one bad row);
what changed is that a caught failure is no longer rendered as a count.

### 6. Verification

| Check | Result |
| ----- | ------ |
| consumer tree, foreign cwd | `checked 1, total 3, todo 2, archived 6, draining true, gating 1, work_waiting` |
| identical with cwd = tree | byte-identical (`cmp`) |
| identical with a relative root | byte-identical (`cmp`) |
| only an unreadable mission | `readable:false`, `progress_unreadable`, null counts, `draining:null`, gate `unreadable` |
| unreadable **beside** a readable gating row | `work_waiting` (precedence holds) |
| readable, empty queue | `open` |
| `queue_total` | unchanged in meaning and value |

`node scripts/test-workflow-scripts.mjs` — **6755 passed, 0 failed**, including 13 new
assertions under *loops/tick-progress.sh: the reading sees a consumer tree, and names what it
cannot*. `build.mjs`, `verify.mjs`, `validate-metadata.mjs` all clean; `outputs/` unchanged
(the `loops` skill is not in the bundle's allowlist). `layout-doctor.sh` → `conforming: true`.

### 7. Step 9 — the grep, re-run and recorded

Across `plugins/workaholic/skills/`, `hooks/` and `scripts/`, **no script composes an
executable path from the root of a tree it is reading.** The remaining matches for
`ROOT}/plugins/workaholic` are `scripts/codex-loop.sh` and `scripts/e2e/loop-drill.sh`, which
use **`REPO_ROOT`** — a different variable naming *this* repository, which for a launcher and a
drill harness genuinely is the tree the scripts live in. They are correct and are not
instances of this defect. The one match inside `tick-progress.sh` is its own header comment
quoting the retired line. Recorded here so a later reader does not re-open the question.

### 8. Call site

`commands/infinite-development.md` §2b now states the degradation shape and the third gate
word; §3's Progress bullet names a degraded row by its own reason and forbids rendering
`unreadable` as `open` — consistent with the allocation and machine lines above it.
