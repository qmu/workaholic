---
created_at: 2026-07-31T22:06:39+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
---

# `gh` is absent in the cloud runner, so the sanctioned PR and ship seams exit 127 there

## Overview

The hourly unattended `/drive` routine runs in a Claude-Code-on-the-web container, and **`gh` is not installed there**. Every seam that shells out to it fails:

```
$ bash plugins/workaholic/skills/report/scripts/create-or-update.sh work-20260731-185904 "…"
plugins/workaholic/skills/report/scripts/create-or-update.sh: line 46: gh: command not found
```

Observed on 2026-07-31 while resuming `batch-20260731185901`. The unit's work was complete and pushed, but step 5 of the Unified Run — the step that publishes the story as a PR — could not run, and the run had to reach GitHub through the MCP server by hand. **A seam that only works on a developer's laptop is not a seam the unattended loop can depend on**, and this is the loop's own critical path: `/drive` step 5 (report), step 6 (`auto` → ship), `/ticket` and `/mission`'s publish-tree PR, and `/propose`'s whole reason to exist.

This is not the `no_token` case. The Slack notifier is *designed* to no-op without a token and says so in its JSON; these scripts have no such contract — they die mid-script with a shell error, after the branch is already pushed, which is the worst place to fail.

## The failure is uneven, which is the real defect

Three of the callers already guard and degrade; three do not, and the split looks accidental rather than decided:

| Script | Guards `command -v gh`? | What happens today in the cloud |
| ------ | ----------------------- | ------------------------------- |
| `branching/scripts/publish-tree-pr.sh` | yes (line 119) | reports a reason, publication survives |
| `mission/scripts/list-related-prs.sh` | yes (line 27) | degrades to no PRs |
| `request/scripts/resolve-target.sh` | yes (line 51) | visibility reports `unknown` |
| `report/scripts/create-or-update.sh` | **no** (lines 42/46/53) | exit 127 **after** the push; no PR, no report item |
| `ship/scripts/pre-check.sh` | **no** (line 15) | `pr_info` silently empty — a *worse* mode than failing |
| `ship/scripts/merge-pr.sh` | **no** (line 33) | exit 127 mid-ship |

`pre-check.sh` is the one to look at hardest: `gh pr list … || echo ""` swallows the 127, so an absent `gh` is indistinguishable from "this branch has no PR". A ship flow that reads that as "nothing to merge" has been misled by its own tooling.

## Policies

- `workaholic:operation` / `policies/deployment-pipeline.md` — the PR and merge seams *are* the delivery path; a dependency that is present on one host and absent on another makes the path non-reproducible
- `workaholic:implementation` / `policies/observability.md` — an exit 127 swallowed by `|| echo ""` is the masked failure this policy forbids: the run continues confidently on a wrong answer
- `workaholic:implementation` / `policies/error-handling.md` — a missing external CLI is a foreseeable environment condition, not an exceptional one; it deserves a named contract, not a shell error

## Key Files

- `plugins/workaholic/skills/report/scripts/create-or-update.sh` — the seam that actually broke; `/drive` step 5 calls it every run
- `plugins/workaholic/skills/ship/scripts/pre-check.sh` — swallows the 127 into an empty result, the dangerous variant
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` — dies mid-ship
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the model to copy: it already guards and reports a reason
- `docs/drive-loop-runbook.md` — the diagnosis table needs the row, since this is what a cloud tick actually hits
- `scripts/test-workflow-scripts.mjs` — the tests stub `gh`; they need a case with `gh` genuinely absent from `PATH`

## Related History

The Slack notifier settled the shape of this problem once already: `{"notified": false, "reason": "no_token"}` and the run continues, with the caller reporting it. `claim.sh`'s announce step reports `announced`/`announce_reason` for the same reason. The PR seams predate that convention and never adopted it.

## Implementation Steps

1. **Decide the contract first, and write it down.** Two candidates, and they are not equivalent:
   - **(a) Report and degrade**, like the notifier: emit `{"pr": null, "reason": "gh_unavailable"}` and let `/drive` record a `pr_error` — which the Unified Run §5 already defines as "its own report item, affecting nothing else".
   - **(b) Fall back to the GitHub API** over `curl` with a token from the environment.

   Recommend **(a)** for this ticket, on the evidence: the run that hit this had a working alternative path (the MCP server) that a *script* cannot reach, and inventing a second HTTP client inside the plugin adds an auth surface for a case the caller can already handle. Record (b) as the rejected alternative with its reason, so the next session does not re-propose it blind.
2. **Guard every unguarded caller** the way `publish-tree-pr.sh` does — `command -v gh` first, a named reason out, never a bare 127.
3. **Fix `pre-check.sh`'s swallow specifically.** `|| echo ""` must stop conflating "no `gh`" with "no PR". These are different answers and only one of them is safe to proceed on.
4. **Make `/drive` report it.** `pr_error: gh_unavailable` becomes a line in the run report and, when the unit was going to ship, a **demotion to the PR path** — never a silent skip and never a `blocked` unit, because the work itself is fine.
5. **Update `docs/drive-loop-runbook.md`** with the diagnosis row: symptom (`gh: command not found` after the push), cause (cloud container has no `gh`), action.
6. **Consider whether the runner should simply have `gh`.** Record the answer either way — if provisioning it is the real fix, this ticket's guards are still correct as the floor, since a container can always lose it again.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With `gh` absent from `PATH`, `create-or-update.sh`, `pre-check.sh` and `merge-pr.sh` each exit 0 with a named `gh_unavailable` reason in their JSON — none exits 127, and none emits a bare shell error.
- `pre-check.sh` reports `gh_unavailable` distinctly from "this branch has no PR"; the two are never the same output.
- A `/drive` run whose report step hits an absent `gh` still finishes its unit, records `pr_error: gh_unavailable`, and demotes an `auto` unit to the PR path rather than merging or reporting `ok`.
- `docs/drive-loop-runbook.md` carries the diagnosis row.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with new cases that run each of the three scripts under a `PATH` from which `gh` is genuinely removed (not stubbed to fail — removed, which is the observed condition).
- A live `/drive` in this cloud container reaches its terminal token without a `command not found` anywhere in the log.

**Gate** — what must pass before approval:

- The suite is green, and the chosen contract (report-and-degrade vs API fallback) is written down with the rejected alternative and its reason.

## Considerations

- **Do not "fix" this by removing the scripts' `gh` use in favour of the MCP server.** A skill script is a shell script; it cannot call an MCP tool. The division is real — scripts get a degradation contract, and the *agent* reaches GitHub through MCP when a script reports it could not.
- **The tests currently stub `gh`**, so they prove the happy path and would keep passing through this whole defect. The new cases must remove `gh` from `PATH` rather than stub a failure, or they test something other than what happened.
- The three already-guarded scripts prove the convention exists in this repo. The work is to apply it uniformly, not to invent it.
