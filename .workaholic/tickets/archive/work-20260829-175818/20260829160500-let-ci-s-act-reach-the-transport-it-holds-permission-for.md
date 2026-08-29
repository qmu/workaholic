---
created_at: 2026-08-29T16:05:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
feedback: 20260829151654-read-back-whether-the-loop-s-own-act-took-effect.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
merge_policy:
verification_handoff: 
---

# Let CI's act reach the transport it holds permission for

## Overview

MINTED MID-RUN by the mission `read-back-whether-the-loop-s-own-act-took-effect`, while driving
its first ticket. It is **outside that ticket's scope** — that one reproduces and localizes, and
this mission's remaining tickets make the act's outcome *readable* — so it is recorded here
rather than fixed opportunistically.

**The measurement.** `gather/scripts/gh-rest.sh available` decides whether REST is usable by
running `gh api user --jq .login`. `GET /user` is **not accessible to a GitHub App installation
token**, which is what `GITHUB_TOKEN` is inside a workflow. So in
`.github/workflows/claim-retirement.yml`, `delete-retired-claim-branch.sh` reaches:

```sh
if [ ! -f "$GH_REST" ] || ! sh "$GH_REST" available 2>/dev/null | grep -q '"ok": true'; then
    refuse gh_unavailable
fi
```

and refuses **before the proof gate, before every bound, and before the delete** — even though
the job holds `contents: write` and the `DELETE /repos/{o}/{r}/git/refs/heads/<branch>` it was
about to make is exactly what that permission covers. Reproduced locally on 2026-08-29 by
stubbing `gh api user` to answer `403 Resource not accessible by integration`:

| Reading | Container credential | Actions-style credential |
| ------- | -------------------- | ------------------------ |
| `list-retirable-claims.sh` | 3 candidates | 3 candidates |
| `delete-retired-claim-branch.sh` | reaches the transport | `gh_unavailable` |

Consistent with the world: three proved-`superseded` branches have stood on origin since
2026-08-18/19/21, the workflow has run on every merge since it shipped on 2026-08-28, and it has
deleted **nothing, ever**.

**This is the act, not the reading.** The mission it is minted under makes the refusal legible —
after it, `/moderate` will correctly tell the claim holder *CI refused `gh_unavailable`*. This
ticket is what makes the refusal stop happening.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a capability probe must test the capability
- `workaholic:operation` / `policies/delivery.md` — CI is the executor where the write is permitted
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — `available`, the probe; its `login`
  field is what makes `gh api user` look load-bearing
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act refused by it
- `.github/workflows/claim-retirement.yml` — the executor holding `contents: write`
- `.github/workflows/release-note-draft.yml` — the precedent: another CI writer through the
  same seam, whose behaviour under the same token must not move
- `scripts/e2e/loop-drill.sh` — `verify-ci-retirement` and `verify-act-effect`

## Implementation Steps

1. **Establish what `available` is actually asked for**, by reading every caller. Some want *can
   I identify the running person* (`login`) and some want *is REST reachable at all*. Only the
   second is what the CI-side act needs, and conflating them is what makes an installation token
   look like no transport at all.
2. **Choose a probe that tests the capability rather than a proxy for it**, and record the choice
   with its alternatives. A repository-scoped read the token demonstrably holds is the obvious
   candidate; naming the endpoint here would pre-judge step 1, so it is deliberately left to the
   measurement.
3. **Keep `login` available to the callers that need it**, and let a probe that cannot resolve one
   still answer `ok: true` where the caller never asked for an identity. A caller that does need
   an identity must keep getting a named absence, never a guess — `identity.sh`'s discipline.
4. **Change no refusal word.** `gh_unavailable` keeps its meaning; what changes is when it is
   true. Every other caller of `available` must be byte-identical in behaviour under a
   *developer* credential, which is the condition the whole existing suite runs under.
5. **Extend `verify-ci-retirement`** with a row that runs the CI-side act under an
   Actions-style credential — `gh api user` refused, repository reads answered — and asserts the
   delete is **taken**, not refused `gh_unavailable`. This is the row that would have caught it.
6. Confirm the three standing branches are actually deleted by the next real turn, and say so.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `delete-retired-claim-branch.sh` reaches its proof gate and its bounds under an Actions-style
  credential, and deletes a branch it proves retirable.
- Every other caller of `gh-rest.sh available` behaves identically under a developer credential.
- A caller that needs a `login` still gets a named absence rather than a guess when none resolves.
- No refusal word is added, removed or redefined.

**Verification method** — the commands/tests/probes that prove them:

- A drill row under a stubbed Actions-style credential: the act takes the delete.
- `node scripts/test-workflow-scripts.mjs` passes.
- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` and `verify-act-effect` pass.

**Gate** — what must pass before approval:

- `sh scripts/e2e/loop-drill.sh verify-all` passes.
- The three branches standing on origin since 2026-08-18/19/21 are gone after the next turn, or
  the reason they are not is named.

## Considerations

- **The tempting narrow fix is to special-case CI** (skip the probe when `GITHUB_ACTIONS` is
  set). It is refused: it makes the probe lie about a condition rather than measure it, and the
  next executor with a non-user token reproduces the defect exactly.
- `release-note-draft.yml` runs through the same seam under the same token. Whatever step 2
  chooses must be checked against it, since it is the one CI writer that currently works.
- This ticket does not touch the effect reading its mission ships. After both, a turn that is
  refused says so **and** stops being refused — and the reading remains correct if it ever is.

## Final Report

Development completed as planned.

**Step 1 settled the design.** Every caller of `available` was read: **seven** call sites, and
**all seven test `"ok": true` and nothing else** — not one reads the `login` field. The four
scripts that genuinely need an identity (`open-proposal.sh`, `list-open-proposals.sh`,
`list-inbound-issues.sh`, the web bootstrap) call `gh api user` **themselves** and answer
`identity_unresolved` in their own vocabulary. So `available` is asked exactly one question —
*does REST answer here* — and was measuring identity as a proxy for it.

**The probe is `GET /rate_limit`**, chosen against two alternatives and recorded so it is not
re-opened:

| Candidate | Verdict |
| --------- | ------- |
| `GET /rate_limit` | answers for **every** token type, installation tokens included; needs no repository context; consumes no quota |
| `GET /repos/{slug}` | proves repository read too, but needs a slug — and `available` is called **before** `slug` by several callers, so it would answer `false` in any checkout with no resolvable remote |
| `GET /user` | what was there: measures identity and calls it reachability |

`login` is kept as an always-empty field so the output shape does not move, documented as
vestigial. **No refusal word moved**: `gh_unavailable` and `rest_unreachable` mean what they
meant; what changed is when `rest_unreachable` is true.

**Measured before and after**, by stubbing `gh api user` to answer
`403 Resource not accessible by integration`:

| | before | after |
| --- | ------ | ----- |
| `gh-rest.sh available` | `rest_unreachable` | `ok: true` |
| `delete-retired-claim-branch.sh` | `gh_unavailable` (before its proof gate) | reaches its transport |

In this container the act then answers `branch_delete_failed` — the known session-type refusal
that moved Act 2 to CI in the first place — which is the correct outcome here and the proof that
the probe is no longer what stops it. `release-note-draft.yml`, the CI writer that already works,
calls `available` nowhere and is unaffected.

**`verify-ci-retirement` gains `ci_retirement_actions_credential`** — a seventh fixture claim
deleted under a credential that cannot call `GET /user`, asserting `deleted` rather than
`gh_unavailable`. That is the row that would have caught this.

**The Gate's last item is honestly open.** The three branches standing since 2026-08-18/19/21 are
deleted by CI's next turn, which fires on the push that merges this unit — after this run ends.
It is not left unverifiable: the same mission made that turn record what it attempted, so the
next `/moderate` tick reads `taken` or `refused:<word>` per unit rather than inferring anything.

### Discovered Insights

- **Insight**: a capability probe that authenticates *a person* silently excludes every non-user
  token, and the failure surfaces as the guarded operation's refusal rather than as the probe's.
  **Context**: this cost the loop every CI branch delete since `claim-retirement.yml` shipped, and
  nothing pointed at `gh-rest.sh` — the act reported `gh_unavailable` about itself.
- **Insight**: `GET /rate_limit` is the cheapest universal reachability probe — no repo context,
  no quota, and reachable by user tokens, installation tokens and fine-grained tokens alike.
  **Context**: worth reusing for any later "is this transport usable" question.
- **Insight**: the drill's own `gh` stub never matched `api user` (its pattern was `user*` against
  an `ARGS` of `api user --jq .login`), so the probe change passed the fixture unnoticed.
  **Context**: the new row had to teach the stub the two endpoints apart before it could assert
  anything — a stub that falls through to a generic success cannot drill a credential.
