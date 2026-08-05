---
created_at: 2026-08-04T23:02:34+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260805-002647
---

# The version-drift check ships inside the artifact whose staleness it reports, so a stale enough plugin reports itself healthy

## Overview

A session can bind `${CLAUDE_PLUGIN_ROOT}` to a plugin version older than the one the
bootstrap installed. `CLAUDE.md` already records that as a **decided** limit — the
SessionStart hook "never refreshes a running session" — and names the answer: make the
drift **legible** rather than gate it, via `check-deps/scripts/check.sh` reporting
`checkout_version` and `version_drift`, which `/drive` prints in its run report.

That mitigation has a blind spot in exactly the case it was designed for. `check.sh` is
**part of the plugin**, so the run executes the *stale* copy of it — and a copy old
enough predates `version_drift` entirely. It then reports:

```json
{"ok": true, "version": "1.0.112", "guards_present": true, "missing_guards": []}
```

No `checkout_version`, no `version_drift`, and `ok: true`. The run reads as healthy. The
drift is invisible precisely when it is largest, because the reporter's own age is the
thing being reported.

## Measured, on the 2026-08-04T22:58Z hourly tick

The container's registry recorded the correct version, updated ~85 seconds *before* the
session's first commit:

```json
// /root/.claude/plugins/installed_plugins.json
"installPath": "/root/.claude/plugins/cache/workaholic/workaholic/1.0.129",
"version": "1.0.129", "lastUpdated": "2026-08-04T22:56:55.926Z"
```

The session nonetheless loaded `1.0.112` — the `/drive` command body expanded
`${CLAUDE_PLUGIN_ROOT}` to `/root/.claude/plugins/cache/workaholic/workaholic/1.0.112`.
Both version directories existed in the cache, unpacked in the same instant (22:56:55);
the update leaves the superseded directory in place and this session bound to it.

**The stale scripts then produced a wrong survey with full confidence.** `1.0.112`'s
`drive/scripts/lib/claims.sh` predates the rename-following resolution and the
`queue_drained` verdict, so the survey reported all five backlog tickets as fresh
backlog. Every one of them was in fact already driven and parked at an open pull request
(#222–#226, opened 04:47–05:16 JST). Run from the checkout instead, the same survey is
correct:

```json
"missions": [], "backlog": [],
"excluded": [ ...all five..., "reason": "claimed_reported" ]
```

The tick claimed `batch-20260804225826` on `work-20260804-225829` — a **double-pick** of
PR #223's ticket, which is the exact failure the claim protocol exists to prevent. It was
caught only because the runner cross-checked against the checkout by hand.

## Consequences

1. **A double-pick reaches a pushed ref.** The unattended runner's next action after the
   survey is `claim.sh`, which pushes. The wrong answer does not stop at a log line.
2. **`ok: true` is reported for a run that was materially broken.** The one signal an
   operator has for this class of fault is the signal the fault suppresses.
3. **It recurs every tick until a human intervenes**, and each fresh container reproduces
   it identically, because the stale directory is baked into the image.

## Policies

- `workaholic:implementation` / observability — a computed verdict reported with no
  indication that the reporter itself may be stale is the silent-wrong-answer class this
  policy exists to prevent.
- `workaholic:operation` — the consumer is an unattended runner whose next action on this
  output is a push to a shared remote.

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` — the drift reporter that
  cannot report its own drift
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the bootstrap
  whose version gate is correct and still cannot help a session already loaded
- `plugins/workaholic/skills/drive/SKILL.md` — the Unified Run, which must refuse to
  survey on unresolved drift rather than print it
- `CLAUDE.md` — the `/workaholify` entry states the current contract ("the bootstrap
  makes the install correct at session start; check-deps makes it honest afterwards"),
  which this ticket narrows

## Implementation Steps

1. **Move the drift verdict out of the plugin.** Compare the *loaded* path against the
   *registry*, which needs no plugin code to read: the basename of
   `${CLAUDE_PLUGIN_ROOT}` versus `version` in
   `~/.claude/plugins/installed_plugins.json` for `workaholic@workaholic`. Both are facts
   about the environment, so the comparison is trustworthy at any plugin age.
2. Report it as a distinct reason — `loaded_version_behind_registry` — separate from the
   existing `version_drift` (loaded vs checkout). They have different causes and
   different fixes: this one means the session bound a superseded cache directory, not
   that the checkout moved.
3. **Make `/drive` terminate `pending` on it rather than print it.** A survey computed by
   scripts of unknown age has not established that nothing claimable remains — the same
   standard already applied to `current: false`. Printing was the right call while the
   only known drift was checkout-vs-loaded; it is not sufficient for a drift that
   silently changes the survey's answer.
4. Keep a **fallback that assumes the worst**: when `installed_plugins.json` is
   unreadable or names no install path, report `registry_unreadable` and refuse `ok`. An
   unanswerable question must not render as agreement.
5. Update `CLAUDE.md`'s `/workaholify` entry and `docs/drive-loop-runbook.md` in the same
   commit — the "check-deps makes it honest afterwards" contract is what this narrows.

## Quality Gate

1. With `${CLAUDE_PLUGIN_ROOT}` pointed at a fixture cache directory whose basename is
   older than the version in a fixture `installed_plugins.json`, the check reports
   `loaded_version_behind_registry` — **verified with a `check.sh` fixture that predates
   `version_drift`**, since a check that only works in the current version reproduces the
   very defect.
2. `/drive` terminates `pending` on that condition and does **not** reach `claim.sh`.
3. With loaded, registry and checkout all equal, the check reports no drift and `/drive`
   surveys normally — the fix must not buy safety by refusing to run.
4. With `installed_plugins.json` absent or malformed, the verdict is
   `registry_unreadable` and `ok` is refused.

## Considerations

- Step 1 is the whole point: **any** check living inside the plugin inherits the plugin's
  age. A guard that can be disabled by the condition it guards against is not a guard.
  The registry comparison was chosen because both operands are environment facts.
- This does not supersede the decided limit that a SessionStart hook cannot refresh a
  running session. It accepts that limit and makes the resulting state *terminal* rather
  than *advisory*, which is the part the measured double-pick shows was too weak.
- Deleting superseded cache directories after an update would also close this, but that
  is Claude Code harness behavior this repository does not own. The registry comparison
  is the part workaholic can fix.
- This ticket was minted by the hourly unattended runner as an unqueued problem met
  mid-run, per `/drive`'s failure contract. The runner released its duplicate claim; the
  remote branch delete was refused with HTTP 403 by this environment, so
  `work-20260804-225829` needs a manual `git push origin --delete`.

## Final Report

Development completed as planned. All four Quality Gate conditions are asserted in
`testCheckDepsRegistryDrift`, including the pre-fix reporter fixture that gate 1 demands.

Implemented as specified: the verdict's two operands are the harness's binding
(`${CLAUDE_PLUGIN_ROOT}`) and the harness's registry (`installed_plugins.json`), neither
of which is plugin content; `/drive` §1 terminates `pending` before surveying rather than
printing the drift; and `CLAUDE.md`, `check-deps/SKILL.md`, `drive/SKILL.md`,
`commands/drive.md` and `docs/drive-loop-runbook.md` all moved in the same commit.

### Discovered Insights

- **Insight**: The load-bearing change is not the new fields — it is that `version` now
  reads the manifest at `${CLAUDE_PLUGIN_ROOT}` instead of the manifest beside `check.sh`.
  The old source answers "where is this file", which is a different question from "what is
  this session running".
  **Context**: This is why the defect survived a reporter that already printed a version.
  Running `check.sh` from the checkout while the session ran a stale cache produced a
  confident, matching pair — the reporter agreeing with itself. Any future diagnostic
  about the loaded plugin must take the harness's binding as its input, not its own path.

- **Insight**: "Behind" had to be an *ordered* comparison, not inequality. A loaded version
  ahead of the registry is a developer running a local build, and flagging that as the
  failure would have made the stop fire on exactly the people best placed to ignore it —
  which is how a gate gets disabled.
  **Context**: `sort -V` gives the ordering in POSIX sh; the test pins the ahead case
  explicitly so a later simplification to `!=` fails loudly.

- **Insight**: The absence of `loaded_version_behind_registry` in the output has to count
  as the condition, and that rule cannot live in the script — only in the consumer.
  **Context**: A build too old to emit the field is by construction the stale build the
  field exists to catch, so a consumer reading a missing key as "no drift" lets the defect
  suppress its own alarm. It is stated in `drive/SKILL.md` §1, `commands/drive.md`, the
  runbook, and asserted by the legacy-reporter fixture. This is the one part of the fix
  that is a *contract* rather than code, and it is the part most likely to be dropped by a
  future refactor.

- **Insight**: This session reproduced the ticket's scenario live before fixing it — its
  own `${CLAUDE_PLUGIN_ROOT}` expanded to `.../cache/workaholic/workaholic/1.0.112` while
  the registry recorded `1.0.129`, both directories present from the same unpack.
  **Context**: Useful for anyone reproducing: the two cache directories coexist, so
  binding the old path by hand is enough to exercise the whole path without a fixture.
