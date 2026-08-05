---
created_at: 2026-08-04T16:09:21+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-194806
---

# The smoke suite is red under a git insteadOf rewrite, so the cloud runner cannot trust its own gate

## Overview

Three cases in `scripts/test-workflow-scripts.mjs` assert that a `https://github.com/…` remote
round-trips unchanged through git. It does not in any environment that configures a URL rewrite:

```
url.http://local_proxy@127.0.0.1:41729/git/.insteadof = https://github.com/
```

`git remote add origin https://github.com/qmu/workaholic` followed by `git remote get-url origin`
returns the **rewritten** form, so the assertions compare a github.com URL against a proxy URL and
fail. The other 2157 cases pass — they are hermetic in the sense that matters, and these three are
not.

**This is the environment the hourly unattended `/drive` routine runs in.** Claude Code on the web
routes git through an agent proxy and installs exactly that rewrite globally.

## Measured, on the 2026-08-04T15:57Z hourly tick

`node scripts/test-workflow-scripts.mjs`, on a clean checkout of `main` at `f423eee`, with no local
modifications:

```
2157 passed, 3 failed
```

```
FAIL  no argument means this checkout
      expected {"repo":"https://github.com/qmu/workaholic","source":"current_checkout"},
      got      {"repo":"http://local_proxy@127.0.0.1:41729/git/qmu/workaholic","source":"current_checkout"}

FAIL  a bare name resolves inside this checkout's organisation
      expected {"repo":"https://github.com/qmu/qfs","source":"same_org_as_checkout"},
      got      {"repo":"http://local_proxy@127.0.0.1:41729/git/qmu/qfs","source":"same_org_as_checkout"}

FAIL  and is reported as the clone URL
      body still names this repository as 'acme-org/source-repo' at line 7:Clone
      git@github.com:acme-org/source-repo.git first. — mask it and re-confirm
```

The same commit's `Validate Plugins` run on GitHub Actions is **green** (run 709, 92s), as are runs
703-708 before it. A GitHub runner has no rewrite, so CI cannot see this.

## Why it matters more than three red tests

`CLAUDE.md`'s **## Local Verification** section names `node scripts/test-workflow-scripts.mjs` as a
command to run before pushing, and a ticket's `## Quality Gate` routinely cites it as the
verification method. `/drive`'s failure contract is unambiguous about what happens next: a ticket
whose checks go red is **`failed`** — partial work stashed, ticket left in `todo`, reason recorded.

So in this container every such ticket fails on evidence it did not produce, is left queued, and is
picked up and failed again on the next tick. The suite is the runner's only local gate, and it
reports red for a reason no diff can fix. That is the masked-failure shape inverted: not a wrong
answer trusted, but a correct change refused.

**The third failure is a different defect wearing the same cause.** It is not an assertion about a
URL string — `submit-request.sh` refused the body under the *wrong rule*, reporting the bare
`owner/name` match where the clone-URL rule should have fired. Both refuse, so the safety property
holds, but the message a developer is handed names the wrong thing to mask. Worth confirming the
rewrite is the whole of it rather than assuming so from the shared root cause.

## The question underneath, which is a decision and not a cleanup

`request/scripts/resolve-target.sh` answers *"which repository is this?"*, and under the rewrite it
answers `http://local_proxy@127.0.0.1:41729/git/qmu/qfs`. That is not a repository anyone can be
sent to, and `/request`'s whole point is that a human confirms a **destination** verbatim. Hardening
only the tests would leave the script returning a proxy-local URL as a cross-repo destination, with
the tests newly asserting that this is fine.

So the two candidate fixes answer different questions and the ticket should not prejudge them:

- **Harden the tests** — compare against whatever the same git returns, or normalize known rewrites
  before asserting. Cheapest, and correct if the script's output is deemed fine.
- **Normalize in the script** — resolve the *canonical* remote (undo `insteadOf`, or read the raw
  configured value) so the destination a developer confirms is the one a colleague could clone.

## Policies

- workaholic:implementation / observability — a gate that reports red for a reason unrelated to the
  change is a signal that trains its reader to ignore it, which is worse than having no gate.
- workaholic:implementation / coding-standards — the fix belongs in the test harness and/or the
  bundled script, never as a caller-side workaround or an environment variable a runner must set.
- workaholic:design / dependency-choice — the rewrite is imposed by the execution environment, not
  chosen by this project; the repair must not require the environment to change.
- workaholic:operation — the affected consumer is the unattended hourly runner, so the wrong signal
  reaches ticket outcomes rather than stopping at a developer's terminal.

## Implementation Steps

1. Reproduce deliberately: set
   `git config --global url."http://127.0.0.1:1/git/".insteadOf https://github.com/` and run the
   suite. All three cases must fail; that is the regression test's fixture.
2. Decide the `resolve-target.sh` question above and record the ruling in the ticket's Final Report
   — it is a design call, not an implementation detail, and the next reader needs to know which was
   chosen and why.
3. Apply the fix at whichever layer step 2 selected.
4. Confirm the third case independently: assert `submit-request.sh` reports the **clone-URL** rule
   for a clone-URL body under the rewrite, not the `owner/name` rule.
5. Add a suite case that pins the behaviour under a rewrite, so this cannot regress silently on a
   runner CI never resembles.

## Quality Gate

**Acceptance Criteria**

1. `node scripts/test-workflow-scripts.mjs` reports `0 failed` in an environment carrying an
   `insteadOf` rewrite for `https://github.com/`.
2. It still reports `0 failed` with no rewrite configured — the repair is not a rewrite-only branch.
3. A clone-URL body submitted through `submit-request.sh` under the rewrite is refused by the
   clone-URL rule, and the refusal names the clone URL.
4. A new suite case fails if the rewrite handling is reverted.

**Verification Method**

- Run the suite twice in one session: once with the rewrite set globally, once with it unset
  (`git config --global --unset url."…".insteadOf`), asserting `0 failed` both times.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` if any bundled
  script under `skills/request/scripts/` changes — it is in the `outputs/workflows` closure.

**Gate**

All four criteria hold, and the suite is green both with and without the rewrite.

## Considerations

- Do **not** fix this by unsetting the rewrite in the runner, in CI, or in a setup script. The
  rewrite is how the environment reaches the network at all; removing it breaks fetching, and a gate
  that only passes once its environment is altered has not been fixed.
- Do **not** skip the three cases under a detected rewrite. A skipped test in the one environment
  that runs unattended is the coverage gap this ticket is about, relocated.
- CI cannot catch this class at all — a GitHub runner has no rewrite. Whatever is added should be
  driven by a *configured* fixture rather than by the ambient environment, so it runs everywhere.
- Found by the hourly unattended `/drive` runner while checking whether a CI failure was its own.
  CI was green; the local suite was not, and the difference is the finding.

## Final Report

Fixed at the **script** layer, not the test layer, and the ruling the ticket asked for
(*Implementation Steps* 2) is recorded here: `resolve-target.sh` was returning a
locally-rewritten URL as the destination a human confirms in `/request`, which no colleague
can clone and which also silently degraded `visibility` to `unknown` (its sed strips only
the `github.com` forms, so the slug stayed a full URL and the `gh api` call failed). That is
a real defect independent of any test, so hardening the assertions alone was rejected — it
would have pinned the wrong behaviour as correct.

New `skills/request/scripts/lib/remote-url.sh` is the single answer to "what URL does this
repository's origin have", exposing both forms because the right one depends on the
question: `remote_url_configured` (what the repo records — what a colleague clones) for
`resolve-target.sh`, and `remote_url_forms` (every form) for `submit-request.sh`, whose
backstop must match whichever form a developer pasted.

**The premise in the Overview above was measured wrong, and the correction matters.** The
ticket recorded 3 failures from one cause. At drive time the baseline was **2176 passed, 1
failed**: the container's git config had changed mid-session and the proxy rule
(`url.http://local_proxy@…/git/.insteadOf https://github.com/`) was gone, so the two
`resolve-target` failures no longer reproduced. The surviving failure came from a *different*
rule — `url.https://github.com/.insteadOf git@github.com:`, injected through the
`GIT_CONFIG_COUNT`/`KEY`/`VALUE` environment triple, which is why `git config --global --list`
showed nothing while `--get-regexp` did. Two rewrite rules, two provisionings, one class.
The fix covers the class rather than either instance, which is why it still holds now that
only one of them is present.

The surviving failure was **not** an assertion quibble: `submit-request.sh` compared the body
against only the rewritten URL, so a body containing this repository's literal clone URL fell
through the clone-URL rule entirely and was refused by the unrelated `owner/name` rule —
naming the wrong thing to mask, past a human gate that had already confirmed the body
verbatim. The two rules are now applied in two passes, **all clone-URL forms before any
slug**, because every clone URL contains its own slug and a single interleaved pass
reintroduces exactly that mis-attribution.

Verification: suite **2187 passed / 0 failed** (baseline 2176/1 — ten new cases plus the one
fixed). The new `testRequestUnderUrlRewrite` configures the rewrite in the fixture rather
than sensing the ambient environment, so it runs identically on a CI runner that has no
rewrite — the coverage gap that let this survive. Its bite was checked by reverting
`remote_url_forms` to the effective-URL-only behaviour: the clone-URL body went straight back
to reporting the `owner/name` rule, and restoring the fix returned the correct rule. Also
clean: `build.mjs` (no `outputs/` diff — `request` is not in the bundle closure),
`verify.mjs`, `validate-metadata.mjs`, `layout-doctor` `conforming: true`.

Docs updated in the same commit: `CLAUDE.md`'s *Repository confinement* section and
`skills/request/SKILL.md` §6 both said the backstop knows "its clone URL", singular; both now
state that a repository's origin URL is not one string and why the rule order is load-bearing.
