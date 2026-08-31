---
created_at: 2026-08-31T20:29:34+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-the-base-s-colour-past-a-bookkeeping-tip
merge_policy:
verification_handoff: 
---

# Say how far back the base's colour was read

## Overview

PROPOSED. Once the walk continues past a bookkeeping tip, the answer is about an **ancestor**
rather than the tip, and a reader who is not told that will read it as the tip's. "A green
base at `<sha>`, n commits behind the tip" is a different and more useful sentence than
"green" — and than the silence it replaces. This ticket carries the distance out of the walk
and into both surfaces that read it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/attribute-base-red.sh` — where the field is emitted
  beside `tip`, `last_green`, `walked` and `bound`.
- `plugins/workaholic/skills/moderate/scripts/step-base-health.sh` — the `summary` (log-facing)
  and `event` (post-facing) it composes, and the question it asks.
- `plugins/workaholic/skills/drive/SKILL.md` and `CLAUDE.md` — *The run report*'s base-health
  clause, updated in the same commit.

## Implementation Steps

1. Emit the reading's own coordinates from the walk: which commit the colour was read at, and
   how many commits behind the tip it is. One field per fact, null when the colour was read at
   the tip itself, so the pre-existing shape is unchanged for a repository whose tip carries
   checks.
2. Render it in `step-base-health.sh`'s `summary`, in the words the reader already uses.
   **The summary must carry no timestamp and no age** — that would mark the step changed every
   tick by construction, which is exactly what the tick-post diff normalises against.
3. Render it in the `event` only when there is a repository event to report. A green base read
   two commits back is not an event; it is the healthy steady state, and a line addressed to
   nobody is what two retired status roots were retired for.
4. Carry it into `/implement`'s run report, where the base's own health is already stated at
   the top: `green`, `red` or `unanswerable`, now with where the colour was read. A degraded
   read is still reported as degraded and **never as green**.
5. Update `CLAUDE.md` and `workaholic:drive` in the same commit. Outdated documentation is a
   defect here, not a follow-up.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A colour read at an ancestor names that ancestor and its distance on every surface that
  reports it.
- A colour read at the tip renders exactly as it does today.
- No step summary carries a timestamp or an age.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` over a seeded reading, asserting the
  rendered summary and event for the tip case and the ancestor case.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The step's `event` is absent for a healthy base whatever the distance.
- Nothing acts on the reading; it stays reported and asked about.

## Considerations

- There is a real question about how far back is too far: a green ancestor fifteen commits
  behind is a weaker statement than one directly behind. State the distance rather than
  thresholding it — a threshold nobody chose is how a reading becomes a verdict — and let the
  operator judge.
- Whether the existing `base-red:<commit>` question should mention the distance is a judgement
  this ticket makes explicitly. The question's contract is to lead with what happened in plain
  words and put the identifier after it; a distance belongs on the heading if anywhere.

## Final Report

Development completed as planned.

`attribute-base-red.sh` now carries two fields beside `tip`, `last_green`, `walked` and
`bound`: `read_at` — the newest commit the reader answered `green` or `red` for, which is the
one whose reading produced the emitted colour — and `read_at_distance`, its offset behind the
tip. A skipped commit never sets them, because nothing was read there. **Both are `null` when
the colour was read at the tip**, so a repository whose tip carries checks sees the values it
always saw; measured against the real `origin/main`, the output is the pre-existing line with
`"read_at": null, "read_at_distance": null` added and nothing else moved.

`step-base-health.sh` renders the fact **twice, for the two audiences it already writes for**,
and neither rendering is derived from the other's string. The log-facing `summary` names the
ancestor and the distance (`; read at <sha>, 2 commits behind the tip`) — the sha is normalised
out of the root's hour-to-hour diff anyway, and a commit count is not an age, so the
no-timestamp rule is untouched. The post-facing `event` states **the distance alone**: a root
line is addressed to nobody, and *how far back* is news while *which commit* is a task. A green
base still supplies **no event at all** whatever the distance — a green base read two commits
back is the healthy steady state, not a repository event.

The Considerations asked for two judgements and both were made rather than deferred. **The
distance is stated, never thresholded**: a green ancestor fifteen commits back is a weaker
statement than one directly behind, and the operator judges — a threshold nobody chose is how a
reading becomes a verdict. And the `base-red:<commit>` question **does** carry it, on the
**heading**: `read_at` / `read_at_distance` ride the `needs_agent` row and the `compose`
instruction says explicitly that they belong beside the identifier and never in the body, which
leads with what happened. No key, cap, addressee or gate moved.

Documentation updated in the same commit: `workaholic:drive` §1 and §7, `CLAUDE.md`'s *The run
report*, `moderate/reference/workflow.md`'s `base-health` spec, and `rules/interaction.md`,
whose "never translate a machine word" example was `base_unreadable:tip_no_checks` — a state
the previous ticket made unreachable, so it now names one that still occurs.

### Discovered Insights

- **Insight**: The step already had two output slots with different audiences (`summary` for
  the tick log and the change diff, `event` for the Slack root), and a new fact does not
  automatically belong in both in the same words.
  **Context**: The rule the repository states for the root — an event names no identifier,
  because *how many* is news and *which* is a task — decides the split by itself once the two
  slots are read as two audiences rather than as one string reused.

- **Insight**: `read_at` cannot be derived from `last_green` or from `attributed.commit`, even
  though it coincides with one of them in most cases.
  **Context**: `last_green` is null on a red answer and `attributed.commit` is the *oldest* red
  rather than the newest; the coordinate the reader needs is "where did the colour I am being
  told come from", which is a third thing. Deriving it in the consumer would have been a second
  derivation of the walk's own state — the constraint this pair of scripts is built around.
