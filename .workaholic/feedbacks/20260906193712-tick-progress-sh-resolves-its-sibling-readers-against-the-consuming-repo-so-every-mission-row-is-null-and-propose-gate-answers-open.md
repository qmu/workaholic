---
type: Feedback
title: tick-progress.sh resolves its sibling readers against the consuming repo, so every mission row is null and propose_gate answers open
kind: instruction
source: development
subject: person:TAMURA Yoshiya
created_at: 2026-09-06T19:37:12+09:00
author: a@qmu.jp
supersedes: 
---

# tick-progress.sh resolves its sibling readers against the consuming repo, so every mission row is null and propose_gate answers open

Source: https://github.com/qmu/workaholic/issues/1038

`plugins/workaholic/skills/loops/scripts/tick-progress.sh` resolves its sibling readers
against the **consuming** repository rather than against its own location, so on any
repository that does not vendor the plugin every per-mission field comes back `null` — and
`propose_gate` then answers `open` when the truth is `work_waiting`.

## What the operator reported

Line 22 reads `S="$ROOT/plugins/workaholic/skills"`, where `ROOT` is the repository the loop
is *running on*. Lines 31-32 then call `progress.sh` and `queue-size.sh` through `$S`. When
the plugin is not checked out inside the consumer, `$S` names a directory that does not
exist, both calls fail, `|| echo '{}'` swallows the failure, and the jq `// null` defaults on
lines 35-36 render "I could not run the reader" as `null`.

Two of the resulting fields are **wrong answers rather than absent ones**, and both are
load-bearing:

- `draining` is computed as `(.[1].archive // 0) > 0`, so an unreadable archive count becomes
  `false` — "nothing has ever landed here" — on a mission with six archived tickets. The
  script's own header calls `draining` "a FACT ABOUT THIS MISSION'S OWN ARCHIVE".
- `gating` increments only when `.todo // 0` is `> 0`, so a `null` todo can never gate:
  `gating_missions` is structurally pinned at 0 and `propose_gate` always chooses `open`.

Measured by the operator over eight consecutive readings, roughly 50 minutes, two active
missions: every `checked`/`total`/`todo`/`archived` `null`, `draining: false` against six
archived tickets, `gating_missions: 0` against 2, `propose_gate: open` against
`work_waiting`, and `queue_total: 8` correct — line 25 reads `$ROOT/.workaholic/tickets/todo`
directly, touches no sibling script, and is the control that makes the defect easy to miss.

The operator's proposed fix is to resolve `$S` against the script's own location
(`S="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"`), to stop the swallowing being
silent, and to grep for the same shape elsewhere.

## What the diagnosis pass established

Reproduced hermetically on a scratch consumer repository with no `plugins/` directory, one
active mission at acceptance 1/3 with 2 queued and 3 archived tickets: `tick-progress.sh`
answered `checked`/`total`/`todo`/`archived` all `null`, `draining: false`,
`gating_missions: 0`, `propose_gate: open`, `queue_total: 2`. The same two readers run from
the plugin checkout against the same tree answered `{"checked": 1, "total": 3}` and
`{"todo": 2, "archive": 3}`. The report is accurate in every particular.

**The proposed fix is necessary and not sufficient, and applying it alone makes one half of
the failure worse.** `queue-size.sh` takes `<mission-slug> [workaholic-root]`, and
`tick-progress.sh` passes only the slug; with no root the script resolves one from
`git rev-parse --show-toplevel` **at the process cwd**. With the `$S` repair applied and the
process cwd pointed anywhere other than `ROOT`, the reproduction answered `checked: 1`,
`total: 3` (correct — `progress.sh` is handed an absolute path) but `todo: 0`,
`archived: 0`, `draining: false`, `gating_missions: 0`, `propose_gate: open`. Those zeros are
*plausible*, where the current nulls are visibly absent, so the fix as proposed deepens
precisely the "a degraded read rendered as a healthy zero" failure the ask is about. The
second half of the repair is to pass the root the script already accepts:
`queue-size.sh "$slug" "$ROOT/.workaholic"`. `mission/scripts/lib/resolve.sh`'s own header
states the rule this violates — "RESOLUTION IS A FUNCTION OF (ROOT, arg) WITH NO AMBIENT
INPUT ... never from the process cwd".

That divergence is not hypothetical for this caller: `tick-progress.sh` takes `[repo-root]`
as an argument precisely because `ROOT` and cwd are expected to differ, and the loop's own
subagents run in claim worktrees and publish trees where they routinely do.

**The grep the ask asks for was run, and it returns nothing.** Across
`plugins/workaholic/skills/`, `hooks/` and `scripts/`, line 22 of `tick-progress.sh` is the
only place a script composes `"$ROOT/plugins/workaholic/..."` as an executable path. Every
other hit is a path pattern, a documentation reference, or `check-deps/scripts/plugin-src.sh`,
which probes for a vendored checkout deliberately as one of its two sanctioned candidates.
`loops/scripts/claimable-units.sh` — the newest script in the same directory — already uses
the correct idiom (`SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)`), so
`tick-progress.sh` is a lone outlier against an established local convention rather than a
class of defect.

`tick-progress.sh` has no coverage in `scripts/test-workflow-scripts.mjs`.

## Why it matters

`propose_gate` is the tick's own reading of whether the origination gate should be holding.
A caller acting on `open` while twelve tickets sit queued across two missions would originate
new work against a queue that is not draining — the exact state the gate exists to prevent —
and `commands/infinite-development.md` names "a degraded read is named by its reason and
never rendered as a healthy zero" in three separate places. This script is the one that does
not follow them.
