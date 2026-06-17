---
created_at: 2026-06-17T21:32:42+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Config]
effort:
commit_hash:
category:
depends_on:
---

# Night `/drive` runs the whole queue — no per-ticket checkbox

## Overview

Change `/drive` night mode so it **no longer presents a per-ticket
checkbox/multiSelect dialog** asking the developer to tick exactly which tickets
the overnight run may implement. When a user says "night /drive", the
expectation is an unattended run over their queue — not a selection chore.

New behavior:

- **Default: run the whole prioritized batch autonomously.** Night drive takes
  the prioritizer's full ordered list (the current user's `todo/<user>/` queue,
  dependency/severity ordered) and runs it end-to-end with no upfront
  selection dialog. Invoking `/drive night` over the queue **is** the
  authorization for that batch.
- **One question only on mixed topics.** If — and only if — the queued tickets
  span **clearly distinct topic groups**, the command asks **one**
  `AskUserQuestion`: while working on Group A, should Group B (and any further
  groups) be included too? This is a single group-level decision, never a
  per-ticket checklist.
- If all queued tickets form one cohesive topic, no question is asked at all —
  the batch just runs.

This amends the design shipped by the archived night-drive ticket, whose §1
made the per-ticket `multiSelect` "the only interaction" and treated that
selection as the batch approval. That justification is consciously revised
here: the approval is re-anchored on the explicit `/drive night` invocation
(plus the optional group-inclusion answer), and the per-ticket approval gate
stays **skipped** (never auto-answered), so the leaf "NEVER use AskUserQuestion"
boundary remains intact.

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` - PRIMARY. **Night Mode** section (lines 161-182): rewrite §1 "Upfront authorization" (line 165, the `multiSelect`-every-ticket dialog) into "run the whole prioritized batch; ask one group-inclusion question only on distinct topic groups". §4 "Bounded run" (line 175) "upfront-selected batch" → "the whole prioritized queue at session start". Fix every reference to the per-ticket selection being the approval: §2/§5 (lines 167, 182 Critical-Rule exception), Step 2.2 note (line 97 "user pre-authorized the selected batch upfront"), Phase 3 note (line 130 "upfront-authorized batch"). Add topic-group detection to the Navigator (Determine Priority Order, lines 258-267) and a `groups` field to the Prioritizer Output JSON (lines 310-323).
- `plugins/workaholic/commands/drive.md` - SECONDARY. The "Night mode" notice paragraph (line 18) currently says "ask upfront (one `multiSelect`) which tickets to target". Reword to: run the whole prioritized batch autonomously; ask one group-inclusion question only when tickets span distinct topic groups. (Claude-only file, not built into `outputs/`.)
- `scripts/build-plugins/build.mjs` - `drive` is in `DEFAULT_TARGETS` (line 45), so the SKILL.md edit requires a full `node scripts/build-plugins/build.mjs` to refresh the generated copy. `PUBLIC_SUBSTITUTIONS` rewrites `AskUserQuestion`/`multiSelect` wording for the public copy, so phrasing flows through.
- `outputs/workflows/skills/drive/SKILL.md` - GENERATED (committed, do NOT hand-edit). Must be regenerated in lockstep or the Outputs Freshness CI fails.

## Related History

The per-ticket checkbox this ticket removes was introduced very recently as the explicit authorization mechanism for unattended runs; this is a deliberate revision of that interaction model, not a duplicate.

Past tickets that touched similar areas:

- [20260617010324-add-night-drive-mode.md](.workaholic/tickets/archive/work-20260617-000311/20260617010324-add-night-drive-mode.md) - Introduced night mode and the upfront `multiSelect` "select which tickets" dialog as the relocated approval. This ticket supersedes that §1 design while preserving every other Critical Rule (gate-skip, safe-failure, no destructive git, whole-night report).
- [20260131125946-intelligent-drive-prioritization.md](.workaholic/tickets/archive/feat-20260131-125844/20260131125946-intelligent-drive-prioritization.md) - The prioritizer/navigator (type/layer/depends_on → topo-sort + context grouping). Topic-group detection extends its existing metadata/layer grouping; implement it there, not as a parallel system.
- [20260205210724-remove-needs-revision-option-enforce-ticket-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260205210724-remove-needs-revision-option-enforce-ticket-update.md) - Precedent for simplifying the `/drive` interaction surface by pruning a dialog option while preserving the underlying capability.
- [20260613090209-per-user-todo-subdirectories.md](.workaholic/tickets/archive/work-20260528-122941/20260613090209-per-user-todo-subdirectories.md) - The queue night drive runs is scoped to `todo/<user>/`; topic-group detection operates over that scoped set.

## Implementation Steps

1. **Rewrite Night Mode §1 (`SKILL.md`)** — replace the per-ticket `multiSelect` "upfront authorization" with:
   - Default: the night batch IS the prioritizer's full ordered list for the current user's queue; no selection dialog.
   - Re-anchor the approval narrative: the explicit `/drive night` invocation authorizes the autonomous run over the queue; the per-ticket gate stays skipped (not auto-answered).
2. **Add topic-group detection to the Navigator** (Determine Priority Order). Define "clearly distinct topic groups" from signals the prioritizer already reads — primarily disjoint `depends_on` dependency-graph components, reinforced by `layer` and key-file overlap. Cohesive/related tickets collapse into one group; only genuinely unrelated clusters count as separate groups. Document the heuristic so it is reproducible and conservative (prefer one group when in doubt — fewer questions).
3. **Extend the Prioritizer Output JSON** with a `groups` field, e.g. `"groups": [{"label": "...", "tickets": [...]}]` (one entry when cohesive). The leaf prioritizer only **computes** groups; it issues no `AskUserQuestion`.
4. **Add the conditional group question at the command/main-agent level.** If `groups` has one entry → run the whole batch, no question. If `groups` has ≥2 → issue exactly ONE `AskUserQuestion` (selectable options, not free text): proceed with Group A only, or include Group B / all groups. The selected groups (in dependency/priority order) become the night batch. This decision lives in the command per One-Level Fan-Out, since subagents cannot ask.
5. **Sweep consistency edits** across `SKILL.md`: §4 "Bounded run" wording, the Step 2.2 / Phase 3 / Critical-Rule-exception references to "upfront-selected batch", so nothing still implies a per-ticket selection.
6. **Update `commands/drive.md`** night-mode notice paragraph to match the new default + conditional group question; keep it thin.
7. **Regenerate `outputs/`** via `node scripts/build-plugins/build.mjs`; confirm `metadata.internal: true` is retained on the drive skill.
8. **Verify**: `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`.

## Considerations

- **design:Modeless Design** — a forced per-ticket checkbox is a "mode" the user is trapped in before autonomous work can begin; removing it is exactly the policy's "modeless by default, modal only when necessary". The single group-inclusion question is the legitimate residual modal (a genuine decision with a real trade-off); record that trade-off in the PR/branch story per the policy's "record the trade-off when introducing a mode" practice (`plugins/workaholic/skills/design/policies/modeless-design.md`).
- **Authorization integrity** — removing the per-ticket selection must not weaken the "explicit approval" guarantee. Be explicit in the SKILL.md that `/drive night` itself is the batch authorization and the per-ticket gate is *skipped, not invoked*; the leaf Workflow "NEVER use AskUserQuestion" boundary stays intact (`plugins/workaholic/skills/drive/SKILL.md` lines 167, 182).
- **One-Level Fan-Out** — group **detection** may run in the prioritizer subagent (returned as JSON), but the conditional group **question** must be issued by the command/main agent; leaf subagents never call `AskUserQuestion` (`CLAUDE.md` One-Level Fan-Out).
- **Conservative grouping** — over-eager group splitting would reintroduce prompting the user explicitly does not want. The heuristic must bias toward a single cohesive group; only clearly unrelated clusters trigger the one question (`plugins/workaholic/skills/drive/SKILL.md` Navigator §2).
- **Unattended safety unchanged** — all other night-mode Critical Rules remain: skip-and-record on failure, never auto-icebox/auto-abandon, no destructive git, `git stash` isolation of failed partial work, and the whole-night stdout report (`plugins/workaholic/skills/drive/SKILL.md` lines 169-181).
- **outputs/ lockstep** — `drive` is a `DEFAULT_TARGET`; forgetting to regenerate and commit `outputs/` after the SKILL.md change fails the Outputs Freshness CI (`.github/workflows/outputs-freshness.yml`, `scripts/build-plugins/build.mjs`).
