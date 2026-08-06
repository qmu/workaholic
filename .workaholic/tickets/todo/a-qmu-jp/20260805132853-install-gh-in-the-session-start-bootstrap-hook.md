---
created_at: 2026-08-05T13:28:53+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805132840-install-gh-in-the-web-container-via-the-session-start-hook.md]
merge_policy:
claim: work-20260806-150951
---

# Install gh in the session-start bootstrap hook

## Overview

PROPOSED. Claude Code on the web starts each session in a container that has no `gh`, and
fourteen of this plugin's scripts shell out to it. The two that decide whether a cloud run
can finish are `branching/scripts/publish-tree-pr.sh`, which pushes the artifact branch and
then reports `no_gh` instead of opening the pull request, and `ship/scripts/merge-pr.sh`,
which cannot run at all — which is why a cloud `auto` unit is demoted to the PR path on
every run and every artifact a routine publishes waits for a human to open its PR by hand.

The ask is to install `gh` from `.claude/hooks/session-start.sh`, the hook that already runs
at every web session start and already repairs the plugin install. Measured in this
container: `apt-cache policy gh` offers 2.45.0 from Ubuntu noble universe, the session runs
as root, and `GH_TOKEN`/`GITHUB_TOKEN` are already injected — so the install is a package
away and the resulting `gh` has credentials to use. Two earlier records
(`20260801134606`, `20260801181923`) recorded the same absence but asked for the **container
image** to ship `gh`, which nobody in this repository can change; this ticket moves the
remedy to the one startup seam this repository does own.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/failure-design.md` — the hook must degrade, never block session start
- `workaholic:operation` / `policies/deployment.md` — the startup seam is how a cloud runner is provisioned

## Key Files

- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — the canonical hook and
  the file to edit. Its header records the two decided limits of the existing version gate
  (no mid-session refresh; `WANTED` read from a possibly-stale checkout); an install step
  must be consistent with both and must not extend either
- `.claude/hooks/session-start.sh` — this repository's installed copy, currently byte-identical
  to the canonical one. `check-bootstrap.sh` reports `hook_stale` when they diverge, so both
  change in the same commit
- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — the checker that
  compares the two copies; confirm it still passes after the edit
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the `no_gh` branch at
  line 119 is the behavior this ticket makes unreachable in a web container; leave it in place
  for environments that still lack `gh`

## Implementation Steps

1. Add an install step to the canonical hook, guarded on `command -v gh` so a container that
   already has it pays nothing and a second run in the same session is a no-op.
2. Make every part of it non-fatal — the hook deliberately has no `set -e`, and a failed
   package install must leave session start succeeding exactly as it does today. `gh` absent
   after the attempt is the status quo, not a regression.
3. Keep it quiet on the success path and legible on the failure path, so a container where the
   install cannot work (no root, no network, no `gh` in the archive) says so once rather than
   failing silently at the first `publish-tree-pr.sh` call.
4. Mirror the change into `.claude/hooks/session-start.sh` in the same commit and re-run
   `check-bootstrap.sh`.
5. Update the `/workaholify` row in `CLAUDE.md` and the `workaholify` SKILL's bootstrap section
   to say the hook now provisions `gh`, per the docs-in-the-same-change rule.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- After a fresh web session start, `command -v gh` succeeds.
- A session start in a container where the install cannot succeed still completes, and the
  session is usable.
- The canonical hook and `.claude/hooks/session-start.sh` remain identical
  (`check-bootstrap.sh` reports neither `hook_stale` nor `hook_missing`).

**Verification method** — the commands/tests/probes that prove them:

- Run the hook in a container without `gh`; assert exit 0 and that `gh --version` then works.
- Run it a second time; assert it is a no-op and still exits 0.
- Simulate the failure path (make the install unavailable); assert exit 0 and one legible message.
- `bash plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh`.
- `node scripts/test-workflow-scripts.mjs` — the hermetic suite must stay green and must not
  acquire a network or `gh` dependency.

**Gate** — what must pass before approval:

- The hook still has no `set -e` and no step that can block session start.
- No new `outputs/` footprint; rebuild only if a built skill changed.

## Considerations

- **Installing the binary may not be the whole fix.** `GH_TOKEN`/`GITHUB_TOKEN` are present in
  this container, so an installed `gh` should authenticate — but that was inferred from the
  environment, not exercised. Whoever drives this should confirm `gh auth status` before
  declaring the cloud PR path restored; if it does not authenticate, the ticket has surfaced a
  second, separate problem rather than failed.
- **Cost on every cold start.** The guard makes the steady state a single `command -v`, but the
  first start in a fresh container pays a package install. If that proves too slow, the
  alternative is baking `gh` into the image — which is what the two earlier concerns asked for
  and what this repository cannot do alone.
- **A non-root or offline container** cannot install anything; the step must degrade there
  rather than accumulate errors at startup.
- **Adjacent work.** `20260805194030-repair-a-superseded-plugin-binding-not-just-report-it.md`
  edits the same hook. Neither blocks the other, but driving them close together avoids two
  conflicting rewrites of the same file.
