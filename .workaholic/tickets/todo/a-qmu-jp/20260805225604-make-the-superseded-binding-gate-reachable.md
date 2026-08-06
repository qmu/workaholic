---
created_at: 2026-08-05T22:56:04+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805191634-a-persistent-drive-failure-goes-silent-for-a-day-under-the-alert-dedup-cool-down.md]
merge_policy:
claim: work-20260806-145355
---

# Make the superseded-binding gate reachable

## Overview

Minted mid-run on 2026-08-05 while driving *Repair a superseded plugin binding, not just
report it*, whose Quality Gate asks that `check.sh` report
`loaded_version_behind_registry: false` **with a non-empty `registry_version`**. It does
not, and the reason is structural rather than environmental.

`check.sh` computes the whole loaded-vs-registry axis only inside
`if [ -n "$loaded_root" ]`, where `loaded_root` is `${CLAUDE_PLUGIN_ROOT:-}` — read from
the **shell environment**. Measured on Claude Code 2.1.222: that variable is **not present
in the environment of a Bash tool call** (`env | grep -i CLAUDE` lists
`CLAUDE_CODE_ENTRYPOINT`, `CLAUDECODE`, `CLAUDE_CODE_SESSION_ID` and others, and no
`CLAUDE_PLUGIN_ROOT`). `${CLAUDE_PLUGIN_ROOT}` is expanded by the harness **inside plugin
markdown at load time** — it becomes a literal path in the command body, never an exported
variable — so every sanctioned invocation lands in the silent branch:

```
{"ok": true, "version": "1.0.133", …, "registry_version": "", "registry_unreadable": false,
 "loaded_version_behind_registry": false, …}
```

`/drive` §1 reads that as "no drift" and surveys.

**Narrowed 2026-08-06 by evidence from the cloud runner: the gate is LOCAL-ONLY broken.**
Step 1 below asked for exactly this measurement and it arrived on its own. At 02:59 JST the
hourly `[Drive]` routine posted `🔴 drive blocked - stale-plugin-binding: loaded cache dir
behind registry — Session bound plugin cache v1.0.112 while the registry records v1.0.133;
terminated before surveying to avoid a double-pick`. So in the Claude Code Web container
`CLAUDE_PLUGIN_ROOT` **is** present in a Bash tool call's environment, the axis computes,
and the stop fires as designed — including on the very condition it was written for. The
defect is confined to a **local** session, where a developer running `/drive` gets a
silently unguarded pre-flight. That is still worth fixing (a local `/drive` writes to the
same pushed refs a cloud tick does), but it is one environment rather than every one, and
the fix must not disturb the path that demonstrably works.

**The silence is a decided behavior, which is why this is a ticket and not a patch.**
`test-workflow-scripts.mjs` pins it ("no plugin root means no registry verdict at all"),
with the recorded reason that a non-Claude agent or a direct checkout invocation must not
be accused of drift it cannot have. That reason is sound; what it did not anticipate is
that the *intended* caller also arrives without the variable, so "silent when we cannot
know" became "silent always". Re-deciding it is a design change with a real cost on the
other side, and it belongs in its own change rather than riding into one about repair.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a monitoring signal that cannot distinguish healthy from broken is not a monitoring signal
- `workaholic:implementation` / `policies/objective-documentation.md` — a stated guarantee must be checkable
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` — the `loaded_root` read and the
  `if [ -n "$loaded_root" ]` guard around the registry axis
- `scripts/test-workflow-scripts.mjs` — `testCheckDepsRegistryDrift`, which pins the
  silence, and `testPluginRootPathVsRead`, which pins the bare read reaching the bundle
- `plugins/workaholic/skills/drive/SKILL.md` — §1, the consumer that treats the condition
  as its only stop
- `plugins/workaholic/commands/drive.md` — step 0, the literal invocation measured above

## Implementation Steps

1. ~~Confirm the measurement on the cloud runner.~~ **Answered 2026-08-06**: it is
   present there — the hourly `[Drive]` tick fired this exact gate at 02:59 JST. Scope the
   fix to the local path and leave the cloud path untouched.
2. **Decide what stands in for the binding when the variable is absent.** The strongest
   candidate is the script's own resolved path: `/drive` invokes check.sh through a path
   the harness produced by expanding `${CLAUDE_PLUGIN_ROOT}`, so in that invocation the
   script's location *is* the binding. State the rule and its blast radius rather than
   silently widening the axis.
3. **Keep the false-accusation case answered**, which is what the current silence buys: a
   developer running check.sh out of an old checkout, and a non-Claude agent running the
   generated bundle, must not be reported as behind. Reporting *how* the root was
   determined — an explicit `loaded_root_source` — is the obvious way to keep both.
4. Update `testCheckDepsRegistryDrift`, which currently asserts the silence, and say in
   the assertion why the rule changed.
5. Update `CLAUDE.md`'s `/workaholify` row and `docs/drive-loop-runbook.md`, both of which
   describe the gate as active today.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `bash <plugin-root>/skills/check-deps/scripts/check.sh`, invoked exactly as
  `commands/drive.md` step 0 invokes it, reports a **non-empty** `registry_version`.
- A superseded binding is reported as `loaded_version_behind_registry: true` through that
  same invocation, proven by a fixture rather than by reasoning.
- A non-Claude agent running the generated bundle, and a direct checkout invocation, are
  still not accused of drift they cannot have — and the output says which case it is in.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, with `testCheckDepsRegistryDrift` extended to
  the no-env-var invocation
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs`
- The step-0 invocation run by hand in a live session, output recorded in the story

**Gate** — what must pass before approval:

- The gate stays a **stop** in `/drive` §1; this ticket makes it reachable, never weaker.
- The absence-of-the-field rule is untouched: a build too old to emit the fields still
  counts as the condition.

## Considerations

- **A reachable gate will stop runs that today proceed.** That is the point, and it is
  also a real operational change: the first tick after this lands may terminate `pending`
  where yesterday it surveyed. Worth saying in the release note rather than discovering.
- The companion finding is that no repair exists inside the plugin for the condition
  itself (recorded in `bootstrap/session-start.sh`'s header). A reachable gate on an
  unrepairable condition is exactly why the threaded-reply alert rule shipped alongside:
  the run stops, and the operator has to be able to see that it kept stopping.
- Step 1's branch is settled: the variable **is** present in the cloud container, so this
  is local-only. The remaining question is whether a local session should be guarded by
  standing in the script's own resolved path for the binding, or whether the honest answer
  is that a local `/drive` simply reports `registry_version: ""` and says why.
