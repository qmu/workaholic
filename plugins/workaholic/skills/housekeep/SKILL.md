---
name: housekeep
description: Use when a session runs `/housekeep` — the hourly maintenance tick that keeps the space around the loop judgeable. Defines the nine-step run, what each step may write, the tick log it leaves behind, and the rulings the ask's steps are held to.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:notify
  - workaholic:feedback
  - workaholic:create-ticket
metadata:
  internal: true
---

# Housekeep

The loop's **maintenance tick**. `[Specificate]` turns asks into work and `[Implement]` drives it; nothing keeps the space *around* them tidy — stale issues, GitHub↔`.workaholic/` drift, pull requests stuck after a failed auto-merge, documentation that no longer matches the concept. `/housekeep` finds those, files them **through the existing seams**, and says what needs a human (issue #471).

Relocated detail: [the nine-step contract](reference/workflow.md) — each step's inputs, what it may write, its abort reasons, and the ruling it is held to.

## Standing rules

- **Unattended by contract**, exactly as `/implement` and `/propose` are: **no `AskUserQuestion` at any step**. Step 9 asks humans things, and it asks them *in Slack* — a routine-fired session has no question mechanism, so "ask a human" and "prompt the operator" are different acts here.
- **It files, it does not invent a home.** A finding becomes a **feedback record** (`workaholic:feedback`), work becomes a **ticket** or a **mission** through the seams that already publish them, and a question becomes a **Slack post** (`workaholic:notify`). The tick log records that it did; nothing else is ever written into `housekeeping/`.
- **A degraded read is reported and skipped, never half-applied.** An unreachable connector, an unreadable inbox and a 403 are each reported **by name** — never rendered as a step that ran and found nothing. That distinction is the one `list-inbound-issues.sh` already makes, and an hourly routine lives on it: a tick that reports "nothing to do" when it could not look is a tick that lies about its own coverage.
- **GitHub over REST only** — `gather/scripts/gh-rest.sh`. Never `gh issue …`, `gh pr …` or `gh repo …`: they are GraphQL-backed and a Claude Code Web session may 403 mid-run (`rules/shell.md`).
- **It never merges, never pushes into somebody else's branch, and never edits a live strategy.** The claim protocol owns `work-*` branches and the strategy layer has exactly two writers; this tick reports what it finds in both and lets their owners act.

## The run

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/housekeep/scripts/run.sh
```

One invocation is one **tick**. It mints the tick id (`tick-id.sh`, UTC — every later write in the same tick is passed that id), runs the nine steps **in order**, writes **one log line per step** into `.workaholic/housekeeping/<UTC-day>.md`, and returns the report as JSON. The step list lives in `run.sh`, not in this prose: every step is invoked and every step contributes a line, so a step that is missing, crashes, or prints nothing is reported `degraded` with its reason instead of vanishing from the report.

`--deadline-seconds <n>` bounds a tick. Steps not reached are logged `skipped` with reason `budget`, **by name** — a step that ran out of clock and a step that found nothing must never read the same.

Then, for every step that returned entries in `needs_agent`, act on them through the seam that step's section names and record what you actually did:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/housekeep/scripts/log-append.sh \
  --tick <tick> --step <step>-filed --status filed --summary "<what was filed, with its id>"
```

`<step>-filed` is a **second, distinct fact** from the probe's own line — what the tick found versus what it filed — and the log is idempotent per `(tick, step)`, so the two never overwrite each other. Both survive a re-entered tick.

**Then persist again — this is the last thing a tick does** (2026-08-18, PR #489):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/housekeep/scripts/persist-log.sh --tick <tick>
```

`run.sh` ran the persist as its closing act *before* you filed anything, because you act on `needs_agent` only after it returns — so without this second call every `<step>-filed` line dies with the container, and the dedups those lines exist to feed read an empty memory forever. It is idempotent: a tick that filed nothing gets `already_current` and writes no commit. Report its outcome in the session; it is deliberately not logged (recording it would need a third persist, and so on). If it comes back `degraded`, say so **by name** in the report — the lines are still in the checkout, and the next tick in the same container carries them up.

Finally report, in the session, one line per step: `<n> <step> <status> — <summary>`, then the counts. The report is the deliverable even when every step was a no-op.

## The tick log

`.workaholic/housekeeping/<YYYY-MM-DD>.md`, one `## <tick-id>` section per tick, one line per step. It is an **operational log, not an OKF knowledge artifact** — no `type:`, no `index.md`, the bundle root links the directory bare — and it is **append-only, never pruned by a machine**. Writer: `log-append.sh` (idempotent per `(tick, step)`). Reader: `log-read.sh`, which is how a step answers *"did an earlier tick already file this?"* instead of re-filing the same finding every hour:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/housekeep/scripts/log-read.sh --step issue-triage --contains "#471"
```

Full rationale for both decisions (why it is not knowledge, why nothing prunes it): `plugins/workaholic/rules/workaholic.md`.

**The log is committed by the tick itself, as its closing act** — `run.sh` runs `persist-log.sh` after the ninth step, and that is the only thing in this skill that writes to the base. A routine-fired tick runs in a fresh container cloned from the base, so a log left in the checkout would take every dedup's memory with it *and* leave an hourly unattended process with no audit trail; a hand-run never sees the failure, because its checkout survives. The seam is the **publish tree, directly** (`branching/scripts/open-publish-tree.sh` → `publish-tree-commit.sh` → `close-publish-tree.sh`): the caller's checkout is left byte-identical, no `work-*` branch is created, and no `publish-main` ref reaches origin, so the claim protocol never sees it. This is **not** the unattended-`main`-writer class `workaholic:ship` §7 refused — the append is not self-referential, it touches no branch a claim owns, and it merges nothing — and the reasoning is spelled out in `persist-log.sh`'s header alongside the rejected alternative (a pull request per tick: twenty-four a day asking a human to approve a line about what a machine already did). Concurrent ticks **union by `(tick, step)`** against a freshly fetched base rather than replaying a patch, so two containers on the same day both land — whole sections the base lacks, and, within a section it already carries, the individual entries it lacks. That line-wise half is what lets the agent's second persist above carry a `<step>-filed` line into a section that has already landed; a `(tick, step)` the base already has is never rewritten, so nothing a colleague's container recorded can be clobbered. A persist that did not reach the base is reported `degraded` **by name** and the log stays in the checkout for the next tick to carry up. The *last* persist's own line is written to the checkout and not to the base — the outcome is only known after the push, and the base already answers the question it would ask: the tick's section is there iff its persist succeeded.

## What the ask asked for, and what this is held to

The ask (issue #471) named nine steps and, at five points, met a decision the loop had already made. None of them is resolved by this skill quietly:

- **Step 8 inverts the propose bar.** `workaholic:propose` states that missions, the queue and commits are *constraints, never triggers* — feedback is the only input that can originate a proposal, and the retired `[Propose Batch]` design was exactly a sweep of the repository's own state for something to propose. Proposing *from a strategy* is a reversal, not an addition, and it is ruled on in its own ticket.
- **`🟡 Proposing` collides with two standing shapes** — 🟡 is the handoff finish line, and the start post was retired on 2026-08-11 by the developer's order. Reintroducing a start post and reusing 🟡 are two separate rulings.
- **Step 4 races the claim protocol.** Pushing into an open pull request's branch was measured and refused for the deployment-plan refresh (`workaholic:ship` §7): the branch belongs to whoever holds its claim. This tick reports conflict state; it does not rebase somebody else's unit.
- **Step 9 needs a surface and a clock.** No `AskUserQuestion` exists here, so asking means posting; "late-night" needs a timezone (the workspace's is Asia/Tokyo) and a boundary.
- **`scope: developer` multiplies steps 5, 6 and 7.** Those three read the *repository*, not the developer, so N copies would triage the same issues and post the same reminders every hour — the exact failure the `repository` scope was introduced for (2026-08-14, issue #451). The ask names `/setup-dev-routines`, so the split is a ruling, made in the routine-template ticket.

One measured fact about the premise: the repository holds **zero** strategies today (`strategy/scripts/list.sh` → `{"count": 0}`), so every step scoped "per strategy" reports `skipped` with that reason until the operator authors one. That is the honest outcome, not a defect.
