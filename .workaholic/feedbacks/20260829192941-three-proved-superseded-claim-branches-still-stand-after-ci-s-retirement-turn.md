---
type: Feedback
title: Three proved-superseded claim branches still stand after CI's retirement turn
kind: instruction
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-29T19:29:41+00:00
author: a@qmu.jp
supersedes: 
---

# Three proved-superseded claim branches still stand after CI's retirement turn

The `/moderate` tick `20260829-185229`, step `retire-claims`, found **7 claimed units, 4 proved `superseded`, 0 retired, 4 refused** — three of them refused on **Act 2, the branch delete**, with the pull request already `already_closed` and the worktree `absent`.

Source: https://github.com/qmu/workaholic/issues/730

## What the finding asks for

Localize why `claim-retirement.yml`'s recorded turn names no candidate while `list-retirable-claims.sh` names three, and **make the difference readable rather than inferred**:

1. Read the workflow's own recorded turn for these units — the candidate reading it stored (`ok`, `reason`, `count`) and each act's own `state`/`reason` — instead of concluding anything from the turn's existence.
2. If the turn never ran on the tip carrying the `rate_limit` probe, say so by name; if it ran and its candidate reading was degraded, name that reason; if it ran and each act was refused, carry the act's own refusal word.
3. Whatever the cause, the outcome must be legible to `/moderate` without a person opening a workflow log — the `retire-blocked:<unit>` question already exists and its key already carries the refusal word.

Nothing may widen the proof gate, add a verdict word, or delete a branch on anything but `superseded` re-derived at the moment of the act.

## The units

| Unit | Branch | Acts |
| ---- | ------ | ---- |
| `batch-20260819063000` | `work-20260819-063001` | `branch_delete_failed` — pull request `already_closed`, branch `failed`, worktree `absent` |
| `make-a-rename-a-registry-entry-not-a-sweep` | `work-20260821-035855` | same three words |
| `make-the-draft-release-note-an-agent-s-release-plan` | `work-20260818-205051` | same three words |

The fourth refusal, `make-workaholify-converge-the-account-s-routines`, is `not_superseded:awaiting_verification` and is **not** part of this finding.

## What this run measured, 2026-08-29 19:2x UTC

The disagreement is at the **candidate reader**, not at the act, and neither side reports a degradation:

- **In the container**, `list-retirable-claims.sh` answers `{"ok": true, "fetched": true, "shallow": false}` and names exactly the three units above, each `state: present`.
- **In CI**, the same script's recorded reading on the current tip is `claim-retirement candidates ok=true reason= count=0` — read back from the `retire` job's own `::notice::` annotation on check run `99149022509`, at head `7cdc58f1`. Every `Claim Retirement` run of the day (`33266999718`, `33267896256`, `33269586701`, `33269876806`, `33270881299`) completed `success`.

So CI is **not** failing, **not** degraded, and **not** refused at the act: its candidate reader finds nothing to do. `ok: true` with `count: 0` is byte-identical to a healthy, empty turn.

## The mechanism this run localized

`drive/scripts/lib/claims.sh` derives the resumability verdict with **identity first**, by its own comment: *"Identity first: a foreign claim is untouchable at any age, so its liveness never even needs measuring."* An empty `_cs_me` answers `identity_unresolved` and an unmatched author answers `foreign_identity` — both **before** `claims_superseded` is ever consulted.

`_cs_me` is `git config user.email`. In this container it is `a@qmu.jp`; in a GitHub Actions runner `actions/checkout@v4` configures no `user.email` at all. Every claim would then read `identity_unresolved`, `superseded` would never be reached, and the candidate set would be empty with `ok: true` — exactly the recorded reading.

This is **not** the failure `gh-rest.sh available` answered. That repair (PR #728, `GET /user` → `GET /rate_limit`, merged 18:18 UTC) is on the base and correct; the finding that *"under an Actions-style credential the two executors' candidate readers agree"* varied the **credential** and never varied the **git identity**, which is the term that decides here.

## What is still open

Which repair is right is a design judgment with a real safety dimension, and this record does not settle it. `superseded` is a proof about the **tree**, while the identity gate exists to protect a **takeover** — a colleague's claim is untouchable at any age. Configuring an identity in the workflow, reordering the precedence, and resolving identity per claim inside the bounded act all have different blast radii, and the one thing none of them may do is let CI delete a branch behind somebody else's live claim.
