---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Make a failing probe's own output the handoff reason

## Overview

«Where a probe genuinely fails, the failure output is the declaration.» A `302` and its
redirect target say more than any sentence, and unlike a sentence they go stale visibly. This
ticket puts the probe's own output into the `## Handoff` section and into the `🟡 Handoff` post.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/reference/routing.md` — the `handoff` route and its non-droppable `## Handoff` section
- `plugins/workaholic/skills/drive/scripts/declared-handoff-detail.sh` — the detail `/moderate` renders
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the `handoff-unit` question
- `plugins/workaholic/skills/notify/reference/notifications.md` — the `🟡 Handoff` shape
- `plugins/workaholic/commands/implement.md` — the ceiling carrying that shape byte-identically

## Implementation Steps

1. On a `blocked` probe, compose `## Handoff` as: the declared reason verbatim (unchanged — it
   is what a person reads), then the probe command, its exit status and its captured output,
   under a heading that says this was measured at claim time and when.
2. On `unmeasured`, say exactly that: the declaration carries no probe, so nothing re-checked it,
   and name the repair (add a `verification_probe:`). Never render it as though a probe had run.
3. On `unprobeable`, keep today's wording — the derived `.claude/` case has no probe by
   construction and inventing one would be a false measurement.
4. Carry the same three cases through `declared-handoff-detail.sh` so `/moderate`'s
   `handoff-unit` question names what was measured rather than only what was declared.
5. The `🟡 Handoff` post's shape does not gain a field: the output belongs in the pull request,
   which the post already links. Keep the shapes byte-identical between
   `notify/reference/notifications.md` and the command ceilings, as the suite pins.
6. Truncate the captured output to the bound the runner already states, and say in the section
   when it was truncated — a silently cut probe output is a false record.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `blocked` unit's `## Handoff` carries the probe command, its exit status and its output beside the declared reason.
- An `unmeasured` unit's section says no probe re-checked the declaration and names the repair.
- The `🟡 Handoff` post shape is unchanged and stays byte-identical across the catalog and the ceilings.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the existing byte-identity rows, plus rows over the three section forms.
- A rendered pull-request body for each case, recorded in the branch story.

**Gate** — what must pass before approval:

- `## Handoff` stays non-droppable and the declared reason is still quoted verbatim.

## Considerations

- Probe output can carry a secret if a probe is written carelessly. The release-safety scan runs
  over the branch diff and would catch a literal, but a body composed at route time is not a
  branch diff — so the field's definition must say a probe prints a status, never a credential,
  and this section is where that cost is recorded.

## Final Report

**Outcome**: implemented.

A `blocking` probe carries its **captured output and exit status** into the `## Handoff` section and
the `🟡 Handoff` post, in place of a sentence. The runner captures stdout and stderr together —
a failing probe usually says why on stderr, and the caller wants the sentence it printed wherever it
printed it — and the route table in `workaholic:drive` §6 states that the output *is* the reason.

**Why this is better than prose, in the ticket's own terms**: a `302` and its redirect target say
more than any sentence, and unlike a sentence they **go stale visibly** — the next claim re-runs the
probe and the output changes when the world does.

**Bounded, because a pull-request body is not a log**: the output is truncated at
`WORKAHOLIC_PROBE_OUTPUT_MAX` (2000 bytes) with `truncated: true` saying so, so a probe that printed
a megabyte cannot become the `## Handoff` section.

**Verified**: `node scripts/test-workflow-scripts.mjs` asserts a non-zero probe's own text reaches
the `output` field and that a large one is truncated and says so.
