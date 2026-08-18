---
created_at: 2026-08-17T11:45:36+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Diagnose the release note automation drift

## Overview

The mission's first unit, and it writes no feature code. Issue #472 is a **failure report**
— "the trial implementation deviated substantially from the intended design, showing up as
fragmented notifications into each Slack channel" — so the work starts by reproducing and
localizing that, not by building the design the reporter proposed. The reporter's design is
this mission's other six tickets; whether each is the right repair is what this ticket
establishes.

There is a strong prior on where the divergence lies, and it is a decision rather than a
defect: `workaholic:ship` §7, *Why this is a reader*, records that the identical ask ("run
`/ship` once per hour to update the release notes", ticket
`20260814064854-add-the-hourly-release-note-repo-routine`) was resolved on 2026-08-14 by
refusing all three unit-less writer designs and shipping a reader. That must be confirmed
against the live behaviour before it is treated as the cause.

## Policies

- `workaholic:operation` / `policies/observability.md` — a report of wrong behaviour is measured before it is repaired
- `workaholic:development` / `policies/change-history.md` — the divergence between intent and implementation is in the history; read it
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` §7 — the *Release status* section and the
  three-row refusal table. The primary suspect and the primary constraint.
- `plugins/workaholic/skills/ship/scripts/report-deploy-status.sh`,
  `read-deploy-state.sh`, `draft-deploy-plan.sh` — what the tick actually reads and writes.
- `plugins/workaholic/skills/workaholify/routines/release-status.md` — the live routine
  template: `scope: repository`, `45 * * * *`, `allowed_tools` with no `Write`/`Edit`.
- `plugins/workaholic/skills/notify/SKILL.md`, *The repository tick's status line* — the
  `📦 Release status` shape and its two gates. The candidate referent of "fragmented
  notifications".
- `plugins/workaholic/skills/workaholify/SKILL.md` §5 — still names the repository-scoped
  routine `[Release Notes]`, a surviving trace of the original intent.
- `.workaholic/deployments/` (one record: `marketplace.md`), `.workaholic/release-notes/`,
  and the absent `.workaholic/releases/`.

## Implementation Steps

1. **Reproduce.** Run `/release-status` and `sh scripts/e2e/loop-drill.sh verify-status` and
   capture exactly what the tick reads, writes and posts today. Record the actual output,
   not a description of it.
2. **Localize the "fragmented notifications".** Establish precisely which posts the reporter
   means: the per-repository `📦 Release status` root, some other post, or the pattern of
   one line per channel across several repositories. The repair for each is different, and
   the report does not say which. Read the recent `dev-*` channel posts through exact-string
   search under the notify skill's two-query bound.
3. **Trace the intent.** Read ticket `20260814064854-add-the-hourly-release-note-repo-routine`,
   its Open Decision, and §7's resolution; state in the Final Report which of the three
   refusals still binds under the reporter's *daily, per-target, GitHub-Releases-first*
   design and which the design dissolves.
4. **Measure the self-reference.** For each declared target, determine whether a note
   committed to `main` increments its own `unreleased_count` — it does for any target
   declaring no `paths:`, which is what `marketplace.md` does. Quantify it rather than
   assert it; this is the one refusal the reporter's design does not obviously answer.
5. Write the localization into the mission's Final Report and, where it changes a later
   ticket's plan, say which ticket and how.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The current behaviour is captured verbatim, not paraphrased.
- "Fragmented notifications" resolves to a specific, named set of posts.
- Each of §7's three refusals is marked still-binding or dissolved, with the reason.
- The self-reference measurement exists as a number per target.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-status`
- `bash plugins/workaholic/skills/ship/scripts/report-deploy-status.sh`
- `bash plugins/workaholic/skills/ship/scripts/read-deploy-state.sh`

**Gate** — what must pass before approval:

- The Final Report names the localization and its consequence for tickets 2–7.

## Considerations

- The reporter's proposed design is a **hypothesis about the repair**, not the diagnosis.
  It is well-specified and probably largely right; recording it as a hypothesis is what
  keeps this ticket from being the design ticket in disguise.
- This repository is a poor sample: one deployment target, no server runtime, and
  "production" is `origin/main` plus a GitHub Release. A consuming repository with several
  real targets is where the design's value shows and where its edge cases live.

## Final Report

Development completed as planned. This unit wrote no feature code; its deliverable is the
localization below, which the remaining six tickets are driven against.

### 1. Current behaviour, captured verbatim

`bash plugins/workaholic/skills/ship/scripts/report-deploy-status.sh` on `origin/main`
at `34f37e14`:

```json
{"ok": true, "base": "main", "base_rev": "origin/main", "base_sha": "34f37e14", "count": 1,
 "digest": "fdc103b38c664b002a6d6bf85dbe3c136a356336", "actionable": true,
 "targets": [{"slug": "marketplace", "title": "Workaholic marketplace plugin",
 "environment": "production", "deploy_model": "deploy-on-merge",
 "deploy_model_reason": "body_declaration", "confirmation_method": "other",
 "has_confirmation": true, "unreleased_count": 68,
 "since": "05c30b54e21d82a507fd30573f5ab26db15b4895", "since_reason": "latest_tag:v1.0.178",
 "attribution": "whole_range", "latest_note": ".workaholic/release-notes/work-20260807-004323.md",
 "note_match": "recency", "needs": ["release"]}]}
```

`sh scripts/e2e/loop-drill.sh verify-status`:

```json
{"ok": true, "stage": "status", "issue": 0, "verdict": "pass",
 "load_bearing": {"passed": 3, "failed": 0}, "advisory": 0, "rows": []}
```

`read-deploy-state.sh` returns the same target with the full authored `procedure` and
`confirmation` bodies inlined and a 46-entry `commits` list. The tick reads three scripts,
**writes nothing**, and emits one candidate post.

### 2. "Fragmented notifications" — what it resolves to, and what could not be measured

Localization from the wire was **not available from this session**, and that is itself a
finding rather than a gap to paper over:

- `slack_search_public_and_private` for the exact string `📦 Release status`, bots included,
  across public + private + DM: **no results, ever**.
- `slack_search_channels` for `dev-`: **no channel matches**, so no `dev-<repo_name>`
  channel is visible to this session's connector at all.
- The machine fallback is tokenless here — `notify-slack.sh` returns
  `{"notified": false, "reason": "no_token"}`, and this run's own `claim.sh` reported
  `announced: false, announce_reason: "no_token"`.

So **no `📦 Release status` line has ever been posted on any surface this session can
observe**, and the shape named in the routine template is not the thing the reporter saw
here. Two consequences follow, and ticket 7 is to be driven against them:

1. The plural in "fragmented notifications into **each** Slack channel" is load-bearing.
   `[Release Status]` is `scope: repository` and posts into that repository's own
   `dev-<repo_name>` channel. N repositories configured through `/setup-repo-routines`
   produce N hourly lines in N channels with no consolidated view — that is a **scope and
   configuration** property, not a defect in the post's shape. Ticket 7's own
   Considerations anticipate exactly this case and say the repair is then "a scope and
   configuration matter, not a notify-shape change".
2. The single surviving shape is already correctly gated (`actionable`, and the
   `deploy:<digest>` dedup) and already carries no mention token. There is no *unowned,
   ungated* post to remove: the audit of `notify/reference/notifications.md` against the
   routine prompts finds one shape for this event and one only.

**Consequence for ticket 7**: it must not reshape a post that was never wrong. Its work is
(a) point the surviving line at the per-target note so a reader has somewhere to go, and
(b) record the multi-repository fragmentation as what it is — a property of running one
repository-scoped routine in N repositories — rather than deleting or re-shaping the line.

### 3. §7's three refusals, marked

| §7 refusal | Under the reporter's *daily, per-target, GitHub-Releases-first* design |
| ---------- | --------------------------------------------------------------------- |
| Refresh a merged note on `main` is self-referential | **Dissolved — but only by the source-of-truth ruling, not by "daily".** Daily is a 24× reduction in write pressure, not a change in kind; the refresh still counts itself. What dissolves it is holding the draft in a **GitHub draft release**, outside git, so the daily tick makes no commit at all. |
| Pushing the refresh into each open PR's branch races the claim protocol | **Still binding, and untouched.** The design never writes a `work-*` branch; nothing here proposes to. |
| Running `/ship` hourly merges pull requests nobody expected | **Still binding, and honoured.** The cadence runs a generator, never `/ship`; `/ship` keeps its one behaviour. |

### 4. The self-reference, as a number per target

- Targets declared: **1** (`marketplace`). Targets declaring `paths:`: **0 of 1**, so
  `attribution: whole_range` for every target in this repository.
- `unreleased_count` at `34f37e14`: **68** commits since `v1.0.178`.
- Commits since that tag touching only `.workaholic/release-notes/`: **0** — so there is no
  measured treadmill in the history, and the mechanism is confirmed rather than observed.
- Under `whole_range`, a note commit is counted by the very target it describes: **+1 per
  note commit, 100 % self-counted, 1 of 1 targets affected**. A daily committing writer is
  **+365 commits/year** to `main` whose only content is a regenerated document, each of
  which increments the number the next day's regeneration reports.

That number is what rules ticket 3's and ticket 5's Open Decisions: any design that commits
the draft to `main` is refused on this measurement, and the only candidate that survives it
is the GitHub-draft-release home.

### 5. Consequences for tickets 2–7

- **Ticket 2 (mapping)** — unchanged, and its "make the absence of `paths:` loudly visible"
  instruction is upgraded from a nicety to the mission's central datum: 0 of 1 targets
  declare it.
- **Ticket 3 (draft generation)** — its Open Decision is answered by (c), the
  GitHub-Releases-only draft, on the §4 measurement. Its stated conflict with "always
  identical" is answered in ticket 5, not dismissed.
- **Ticket 4 (note as release record)** — unchanged.
- **Ticket 5 (sync)** — Open Decision answered by (b), GitHub draft authoritative while
  drafting; identity guaranteed **by derivation** (one renderer, one input) rather than by
  copying, with divergence reported per target and section.
- **Ticket 6 (cadence)** — Open Decision (a): extend the existing repository-scoped routine
  rather than add a fourth. Because the draft lives outside git, the routine still needs no
  `Write`/`Edit` — it never writes the repository — so the property its template defends
  survives the change intact.
- **Ticket 7 (notification)** — driven against §2 above: the line is kept and pointed at the
  note; the fragmentation is recorded as a multi-repository scope property.

### Discovered Insights

- **Insight**: The `📦 Release status` line has never been observable from a routine
  container in this repository — the fallback has no token and the connector sees no
  `dev-*` channel — so every claim about "what the tick posts here" has been reasoning from
  the template, not from the wire.
  **Context**: A notification surface that is never load-bearing is also never verified.
  Any future report about post behaviour in this repository should state which surface it
  measured, because the default answer is "none".

- **Insight**: `attribution: whole_range` is not a rare edge case but this repository's
  only state — `paths:` is declared by 0 of 1 targets, and the field is optional with no
  reader that complains about its absence.
  **Context**: Every design in this area that reasons about "what is unreleased for a
  target" inherits the whole-repository answer by default. The optionality of `paths:` is
  what turned a plausible writer design into a self-invalidating one.
