---
created_at: 2026-08-04T17:36:26+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on: 20260804173625-enforce-the-mission-ticket-floor-at-every-creation-seam.md
mission: make-a-mission-impossible-to-create-without-its-ticket-set
merge_policy: review
---

# Resolve the two sub-floor missions on record, and make every document describing mission creation state the floor

## Overview

Enforcement stops new violations; it does nothing about the two already on record. And a rule that holds in code but not in `CLAUDE.md` is one an agent reading the docs will keep breaking — the documentation is where the next session learns what a mission is.

Both halves are the same job: make the repository's state and its description agree with the rule.

## The two instances

**`make-the-branch-story-measurably-shorter` — active, 0 tickets, live on `main`.** Created 2026-08-04 by `close.sh --successor-title` when its predecessor was carried. It has a filled `## Experience` and two acceptance items, and it is genuinely wanted work — the predecessor's structural changes landed and stories still got 29% longer, so the cause is unfound. What it lacks is a ticket set.

The fix is a **replan** (`/mission "<instruction>"`), which is the sanctioned route by which a thin mission gets fleshed out, and which emits its ticket set and stamps the acceptance links. Not a deletion: the direction is right and the measurement behind it is recorded.

Note it must reach two tickets or be dissolved. If the work turns out to be one ticket — "measure which sections carry the added lines, then fix them" as a single unit — then the honest outcome is a plain ticket plus a feedback record, and the mission is closed `abandoned` with that noted. Deciding that is part of this ticket, not a foregone conclusion.

**`drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` — archived, 1 ticket.** Already closed and in `missions/archive/`. History is never rewritten, so nothing moves. What is worth doing is one line in the feedback record or the mission docs noting it as the pre-rule instance, so a future reader auditing the tree against the floor does not read it as a live violation.

## The documents

Each states what a mission is, and each is currently silent on the floor:

- `CLAUDE.md` — the `/mission` command row and the "Sources" paragraph in Architecture Policy, which describes a mission as "an optional, epic-equivalent grouping" without a lower bound
- `plugins/workaholic/skills/mission/SKILL.md` — the Creation Interrogation (the decision ticket writes the boundary here; this ticket makes sure the *description* of a mission elsewhere in the file agrees)
- `plugins/workaholic/skills/propose/SKILL.md` — the proposal bar
- `.workaholic/README.md` — the artifact-kind descriptions, which is exactly where the feedback/ticket/mission partition should be visible
- `plugins/workaholic/rules/workaholic.md` — the layout table's mission row

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — outdated documentation is a defect; a rule described in one file and contradicted in four is worse than an undocumented rule
- `workaholic:design` / `policies/history-structures.md` — the archived one-ticket mission is history and stays; annotating is the correct treatment, rewriting is not

## Key Files

- `.workaholic/missions/active/make-the-branch-story-measurably-shorter/mission.md` — the live instance
- `.workaholic/missions/archive/drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main/mission.md` — the archived instance, read-only
- `CLAUDE.md`, `.workaholic/README.md`, `plugins/workaholic/rules/workaholic.md`
- `plugins/workaholic/skills/mission/SKILL.md`, `plugins/workaholic/skills/propose/SKILL.md`
- `plugins/workaholic/skills/mission/scripts/unlinked-acceptance.sh` — the model for a repo-wide audit script, if one is wanted

## Related History

The predecessor mission `make-the-branch-story-concise-by-default` was closed `carried` on 2026-08-04 after its third acceptance criterion was measured as failing: stories averaged 127 lines before its structural changes and 164 after, a 29% increase across eight and ten stories respectively. That measurement is the successor's whole justification and must survive into whatever tickets the replan emits.

`CLAUDE.md` has a standing rule that documentation updates ride in the same change as the behavior they describe. This ticket exists because the behavior change spans two prior tickets, and its documentation surface is wider than either.

## Implementation Steps

1. Replan `make-the-branch-story-measurably-shorter` into a real ticket set — starting from the measurement above, with the first ticket establishing *which sections* carry the growth before anything is changed.
2. If it does not reach two tickets, close it `abandoned`, write the direction into the feedback stream, and emit the single ticket standalone. Record which path was taken and why.
3. Annotate the archived one-ticket mission as the pre-rule instance, in the feedback record rather than in the archived file.
4. Update all five documents so each describes a mission with its floor, and so `.workaholic/README.md` makes the feedback/ticket/mission partition explicit.
5. Consider a repo-wide audit script in the shape of `unlinked-acceptance.sh` (pure read, reports sub-floor active missions). Optional — decide from whether the enforcement makes recurrence possible at all.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No active mission is below the floor.
- The archived one-ticket mission is annotated as pre-rule, and its file is unmodified.
- All five documents state the floor, and none still describes a mission without a lower bound.
- The 29% measurement survives into whatever replaces the successor mission.

**Verification method** — the commands/tests/probes that prove them:

- A count of tickets per active mission shows every one at two or more (the same count the enforcement uses).
- `git diff` shows no change under `.workaholic/missions/archive/`.
- `node scripts/build-plugins/build.mjs` with `outputs/` committed, and `bash plugins/workaholic/hooks/layout-doctor.sh .` reporting `conforming: true`.

**Gate** — what must pass before approval:

- The active tree is clean against the floor, the docs agree, and `outputs/` is fresh.

## Considerations

- **The successor may honestly be one ticket.** Do not pad it to two to satisfy the rule — that inverts the rule into a reason to invent work. Dissolving it into a ticket plus a feedback record is a correct outcome and is what the partition is for.
- **Do not edit the archived mission.** Annotate elsewhere.
- This ticket depends on enforcement landing first only so that the cleanup is not immediately re-dirtied by a seam that still mints violations.

## Final Report

**The live instance resolved itself before this ticket reached it, which changed what the ticket had to do.** `make-the-branch-story-measurably-shorter` was replanned in the ordinary way earlier the same day and now carries two tickets (`20260804201653-measure-which-story-sections-carry-the-growth.md`, `20260804201653-fix-the-measured-cause-and-verify-a-shorter-story.md`), so it meets the floor and the dissolve-into-a-ticket-plus-feedback path was never needed. The ticket asked for that decision to be made rather than assumed, so it was **re-measured rather than taken on trust**: `check-floor.sh` over every active mission returns `ok` at 4, 4, 2 and 4 tickets. The 29% measurement (127 lines across eight stories before, 164 across ten after) survives in the mission, in both replan tickets, and in the new feedback record.

**The archived instance is annotated, not touched.** `drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main` stays exactly as it is (`git diff .workaholic/missions/archive/` is empty). The annotation lives in the new feedback record `20260804203613-both-sub-floor-missions-are-resolved-one-replanned-one-pre-rule-history.md` and in `mission/SKILL.md`, both saying the same thing an auditor needs: the floor is a rule about **creation**, so only `missions/active/` is auditable against it. A *new* record was written rather than an edit to the rule's own feedback record, because feedback is immutable — resolution is a new record, never an edit.

**All five documents now state the floor**, each at the level it describes a mission: `CLAUDE.md` (the `/mission` row and the Sources paragraph, which now frames the floor and the size ceiling as the two ends of one shape), `mission/SKILL.md` (description, opening definition, the vocabulary partition, the granularity table row), `propose/SKILL.md` (already stated; now pointed at `check-floor.sh`), `.workaholic/README.md` (a new *Which kind of artifact* table making the feedback / ticket / mission partition explicit, plus the missions entry), and `rules/workaholic.md` (the layout table's mission row and a floor paragraph beside the placement rules).

**No audit script was written, and that is a decision.** `check-floor.sh <slug>` over `missions/active/*` is the whole audit; a second script whose entire content is that loop adds a maintenance surface and no information. Recorded in the feedback record so the "optional" step is not left looking unconsidered.

**Two adjacent doc defects were repaired in the paragraphs being edited**, because leaving them would have meant shipping a document that states the floor correctly and the lifecycle wrongly: `.workaholic/README.md`'s missions entry still described `status: draft`/`approved`, `/mission approve`, and publishing straight to `main` (all retired by K1/K2/J4), and `rules/workaholic.md` still listed "approval" as a mission write.

### Discovered Insights

- **Insight**: The `mission/SKILL.md` size ratchet has one line of headroom left.
  **Context**: `test-workflow-scripts.mjs` asserts the file stays under 420 lines; it sat at 419 before this change, so adding the floor sentences broke it. The fix here was to fold a new bullet into an existing one rather than raise the number — but the next legitimate addition hits the same wall, and bumping the constant is exactly what the ratchet exists to prevent. The real answer when that happens is to relocate a section into `reference/`, which is the pattern the file already uses.
- **Insight**: A cleanup ticket written against a snapshot of the world can be stale by the time it is driven, and the honest response is to re-measure, not to re-do.
  **Context**: This ticket named "the two sub-floor missions" as a fact. One had already been fixed. Re-running the count first turned a possible double-fix (replanning an already-replanned mission) into a one-line finding.
