---
created_at: 2026-08-05T19:40:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
feedback: [20260805191634-a-persistent-drive-failure-goes-silent-for-a-day-under-the-alert-dedup-cool-down.md]
merge_policy:
claim: work-20260805-224001
---

# Repair a superseded plugin binding, not just report it

## Overview

`claude plugin update` unpacks the new version **beside** the old one and deletes nothing,
so a cloud session can bind a superseded cache directory — and because a `SessionStart` hook
may not refresh a running session, nothing repairs it. `check-deps/scripts/check.sh` reports
it as `loaded_version_behind_registry` and `/drive` terminates `pending` on it before
surveying. That gate is correct and must stay: a stale binding silently changes the survey's
*answer*, and on 2026-08-04 it made a tick claim an already-driven ticket.

But reporting is where it currently ends, and the cost of ending there was measured on
2026-08-05: four consecutive hourly ticks stopped at the gate with a claimable queue,
producing nothing. A gate that a runner cannot clear is an outage, however correctly it is
detected — and this one is self-inflicted, because the container's own `plugin update` left
the superseded directory in place for the session to bind.

This ticket asks for the repair half. The condition to satisfy is narrow and worth stating
before any mechanism is chosen: **the next tick must bind the current version**, and
**nothing may swap a plugin under an already-running session**.

## Policies

- `workaholic:operation` / `policies/failure-recovery.md` — a detected failure with a known repair should be repaired, not only reported
- `workaholic:implementation` / `policies/failure-design.md` — degrade loudly, and never let a repair introduce a worse failure than the one it fixes
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the canonical hook. Its
  header already records the two decided limits (no mid-session refresh; `WANTED` read from a
  checkout that can itself be stale); whatever this ticket adds must be consistent with both
  and extend that header rather than contradict it.
- `plugins/workaholic/skills/check-deps/scripts/check.sh` — the detector. It reads the
  harness's binding against the harness's registry, and **neither operand is plugin content**,
  which is what makes it trustworthy at any plugin age. Do not make the repair an operand of
  the detection.
- `plugins/workaholic/skills/drive/SKILL.md` — §1 terminates `pending` on the condition. If a
  repair lands, what `/drive` does on detection may need restating; if it does not, this
  stays exactly as it is.
- `docs/drive-loop-runbook.md` — the operational account of what an hourly tick does and what
  a developer should expect to see.

## Implementation Steps

1. **Establish where the superseded binding comes from in the cloud container**, before
   choosing a mechanism. The candidates are a baked-in image install, a `plugin update` that
   left the old directory, and a registry/cache disagreement; they need different repairs and
   the ticket should not guess. Record what is actually observed, with the version pair and
   the paths, in the branch story.
2. **Choose the repair against the two constraints above.** Removing superseded cache
   directories after a successful `plugin update` is the obvious candidate; it is also the
   one that can destroy a directory a *running* session is bound to, which is precisely the
   failure the no-mid-session-refresh rule exists to prevent. If it is chosen, it must be
   safe for a session already bound to the directory being removed — or it must be scoped to
   run only when no session is bound.
3. **Keep the detector independent of the repair.** `check.sh` must go on answering "is this
   session's binding current" from the harness's own state; a repair that also reports its own
   success would make the gate trust the thing it exists to catch.
4. Update the bootstrap hook's header with what was decided and, if a limit is lifted, say
   which and why. Update `CLAUDE.md`'s `/workaholify` row, which carries this contract in
   prose today.
5. If no safe repair exists, **say so in the branch story and close the ticket that way**.
   "We looked and the repair is unsafe" is a real outcome and is worth recording; the
   companion ticket makes the unrepaired condition visible in the meantime.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The origin of the superseded binding in the cloud container is recorded with observed
  evidence, not inferred.
- Either a repair is in place and a session started after it binds the version the registry
  names, or the branch story records why no safe repair exists.
- No mechanism swaps or removes a plugin directory that a running session is bound to.
- `check.sh` still reports the condition from the harness's binding versus the harness's
  registry, with neither operand being plugin content.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/check-deps/scripts/check.sh` in a session started after the
  change reports `loaded_version_behind_registry: false` with a non-empty `registry_version`.
- `node scripts/test-workflow-scripts.mjs` — the existing check-deps assertions must still
  pass unchanged; the detector's contract is not what this ticket changes.
- An hourly tick after the change reaches its survey rather than terminating at §1 (observed
  in the run report, not asserted by a test — this is a property of the cloud container).

**Gate** — what must pass before approval:

- The `/drive` `pending` termination on a stale binding is still present. This ticket removes
  the *cause*, never the gate.

## Considerations

- **The gate is not the bug.** Both prior decisions behind it were measured and are recorded
  in `CLAUDE.md`'s `/workaholify` row: a superseded binding changes the survey's answer, and a
  mid-turn plugin swap is worse than being one version behind. This ticket must not weaken
  either. The bug is that a runner detects a repairable condition and has no repair.
- **This may not be repairable from inside the plugin at all.** The binding is the harness's,
  the cache layout is the harness's, and a plugin editing either is reaching outside its own
  boundary. If that is the conclusion, the honest outcome is a recorded finding plus an ask
  to the harness — not a workaround that half-works and is trusted as though it worked.
- **The companion ticket is what makes the interim safe**: while this is unrepaired, a
  persisting failure must stop reading as a healthy idle tick. Neither ticket depends on the
  other landing first.

## Final Report

Completed as the ticket's step 5 anticipated: **no safe repair exists inside the plugin**,
and the finding is recorded with its evidence rather than a workaround shipped. The origin
was observed, not inferred, and the obvious candidate repair was investigated and rejected
on the evidence.

**One acceptance criterion cannot be met as written**, and the reason is a separate defect
rather than this work: the ticket asks that `check.sh` report
`loaded_version_behind_registry: false` **with a non-empty `registry_version`**. It reports
an empty one, because the whole registry axis is computed only when `${CLAUDE_PLUGIN_ROOT}`
is present in the shell environment — and it never is, since the harness expands that token
inside plugin markdown at load time rather than exporting it. Minted as
`20260805225604-make-the-superseded-binding-gate-reachable.md`; the silence is a decided,
test-pinned behavior, so re-deciding it does not belong in a change about repair.

### Discovered Insights

- **Insight**: The superseded binding is **not a wrong choice among directories**.
  `~/.claude/plugins/cache/workaholic/workaholic/` holds 25 version directories side by
  side (1.0.100 … 1.0.133) while `installed_plugins.json` carries exactly **one** entry,
  naming 1.0.133. The registry is never ambiguous; the session binds whatever it named **at
  startup**, which is strictly before the SessionStart hook can run.
  **Context**: This kills the obvious repair. Sweeping superseded directories would fix
  nothing and would be actively unsafe — a running session is bound to a directory that
  becomes "superseded" the instant an update lands, which is the precise failure the
  no-mid-session-refresh rule exists to prevent.

- **Insight**: The condition **does not self-heal on a cloud runner**, because every tick is
  a fresh container off the same image: the baked-in install is stale again, the hook
  updates the registry again, and the session is behind again. That is why four consecutive
  ticks stopped rather than one.
  **Context**: The runbook's advice — "the repair is a fresh session" — is true locally and
  wrong for the hourly loop. Corrected in the same commit.

- **Insight**: What would actually fix it is outside the plugin's boundary: a container
  image whose baked install is not behind, or a harness that rebinds after SessionStart.
  The binding, the cache layout and the registry are all the harness's.
  **Context**: Recorded as an ask rather than worked around. A workaround that half-works
  and is trusted as though it worked is worse than the detected, unrepaired condition.
