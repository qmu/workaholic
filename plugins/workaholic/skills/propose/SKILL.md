---
name: propose
description: Use when a session runs `/propose` or the `[Propose]` routine's clock fires — read the running identity's own active strategies, judge the one evolutionary move that would bring the nearest one closer to its aim, and open that judgment as a GitHub issue the next `/specificate` tick will ingest. Defines the eligibility gates, the three moves, the refusal of housekeeping, and the scripts.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:strategy
metadata:
  internal: true
---

# Propose

The third turning routine. `[Specificate]` (`:15`) turns an ask into a record and the work it
warrants; `[Implement]` (`:30`) drives that work to a pull request; **`[Propose]` (`:40`)
supplies the ask** — so the loop turns without a person having to write the next ticket, and
what a person supplies instead is the **direction**.

It reads the running identity's own `status: active` strategies, judges the single
**evolutionary move** that would bring the nearest one closer to its aim before its date, and
opens that judgment as a **GitHub issue assigned to that identity** — the one surface
`/specificate`'s unattended entrance actually reads.

**It is a pure reader of this repository.** No file, no commit, no branch, no pull request, no
merge, no deployment, and no `AskUserQuestion` at any step. Its only write is the issue, and
that write lands on GitHub, not in the tree — the same contract `/standup` and
`/prepare-release` hold, and the reason it adds no unattended-`main`-writer class.

**It is not the `/propose` this repository retired.** That name belonged to what is now
`/specificate` (renamed 2026-08-19), and `[Propose]` belonged to what is now `[Moderate]`.
Both were vacated in the same change and neither is claimed by any live template
(`reference/loop.md`, *Taking the name back*).

## The one thing it is for: an evolutionary move, never housekeeping

Every proposal declares exactly one **move** against the strategy's Aim, and a run that cannot
name which one it is emits nothing:

| Move | What it does to the aim |
| ---- | ----------------------- |
| **`depth`** | Go further into what the aim already covers than the landed work has gone. |
| **`breadth`** | Go into a part of the aim nothing has touched yet. |
| **`contraction`** | Remove or unify something the landed work made inconsistent with the aim. |

**Housekeeping is refused by name.** "Tidy this up", "the docs drifted", "add a test",
"rename for consistency" are `/moderate`'s job. What they have in common is that they are
chosen against **nothing** — nobody would argue for the mess — which is why the body floor
requires a `## What this is chosen against` section: a proposal that cannot name the fork it
did not take is either uncontroversial or unformed, and both are the safe small change the ask
refuses. **The proposal commits**: it states the change in the imperative, and it carries no
"consider whether", no "we might", no menu of options.

## The bar this drops, and the brake that replaces it

This is the **first** unattended routine here to drop the standing conservative bar
(`workaholic:specificate`, *The judgment bar*: when unsure, record only, and say what made you
unsure). It drops it on purpose — a routine that proposed only what it was sure of would
propose housekeeping. What replaces the bar is not a softer judgment but a set of
**mechanical, derived gates** the running session cannot decide differently
(`survey-strategies.sh`; each refusal is reported by name):

`not_active` · `not_mine` · `past_target_date` · `no_feedback_refs` · `work_waiting` ·
`open_proposal` · `over_cap` · `attribution_unreadable`

Three of them carry the design:

- **`work_waiting` + `open_proposal` are one gate in two halves, and they hand off with no
  window** — from the issue opening until its `/specificate` pull request merges the issue is
  open; from that merge onward the tickets it produced are queued. So **one proposal per
  strategy is in flight at a time**, enforced continuously with no cursor and no stored state.
  A per-day bound was considered and refused: the ask is for three routines turning an
  **hourly** loop, and a daily cap on the only routine that originates work would cap the loop
  itself at one turn a day.
- **`over_cap`** — one proposal per tick across *all* strategies (`WORKAHOLIC_PROPOSE_MAX`,
  default 1), taking the eligible strategy with the nearest `target_date`. A developer
  carrying eight directions must not wake to eight issues at `:40`. A capped strategy is
  reported, so suppression is a delay and never a loss.
- **`no_feedback_refs` is the answer to the lossy reader.** `attributed-work.sh` walks
  `strategy.feedback[] ∩ artifact.feedback[]` plus one hop through a mission and admits it
  cannot see everything. A strategy citing **no** record can never have anything attributed
  back to it, so the judgment would be made on a blind read and every proposal would land
  invisible. Such a strategy is refused with the repair named. **`no_citing_artifacts` is not
  a refusal** — that is a strategy nothing has answered *yet*, which is exactly when a
  proposal is most wanted. One means "no work yet"; the other means "no way to see work".

**A gate that cannot be read is not a gate**: if the open-proposal list cannot be fetched, the
whole tick refuses (`inbox_unreadable`) rather than proposing blind.

## How the loop closes — and it closes with no new field

`open-proposal.sh` writes the issue's first three lines itself, and the third is the
load-bearing one:

```
kind: instruction / source: development / subject: observer_ai:[Propose] routine
strategy: <slug> / move: <depth|breadth|contraction>
feedback: <ref>, <ref>
```

Line 3 names the **strategy's own** `feedback:` refs, and `/specificate` carries them onto the
mission or ticket it emits, beside the record that run writes
(`workaholic:specificate`, *Carry the ask's own feedback refs forward*). Without it the emitted
work would cite only the new record, the intersection would be empty, and the loop would turn
leaving no trace on the direction that asked for it. It uses the existing **many-valued**
`feedback:` relation exactly as designed and **adds no field to any artifact**, which is what
keeps the retired `strategy:` mission relation and its ownership hop retired.

All three lines are **visible text, never an HTML comment**: a hidden marker would be a fact
the loop depends on that no human reading the issue can see.

## Scripts

```bash
# Which strategies may be proposed against this tick, and why each other one may not.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-strategies.sh \
  [--open-proposals <file>] [window] [.workaholic-root]

# The open proposals already in flight, per strategy — the remote half of the brake.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-open-proposals.sh

# The ONE writer, and its only write is a GitHub issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/open-proposal.sh \
  --strategy <slug> --move depth|breadth|contraction --title "<title>" <body-file>
```

The run itself is five steps: [reference/loop.md](reference/loop.md) carries them, together
with the clock placement, the name reclamation, and the alternatives that were refused.

## It posts nothing to Slack

The issue is assigned to exactly one person, who is the running identity, and GitHub already
delivers it to them. A Slack copy would be the same noise twice — the argument that gives
the retired `[Workaholic]` no connector — and a status line addressed to nobody is the noise that retired
`🔧 Needs a decision` and `📦 Release Preparation`. The routine's result reaches its one reader
as a **Claude notification** (`notifications: push`) — since `[Workaholic]` retired on 2026-08-22 (issue #557), the only template that declares the field.
