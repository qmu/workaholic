---
created_at: 2026-08-29T06:20:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
---

# State the catch-up and its refusals

## Overview

PROPOSED. `drive/reference/claims.md` and `CLAUDE.md`, in the same change: the reading, the
writer, its bounds, and an **explicit reversal** of *resolving a conflict on a claimed branch
is still nobody's job here* — narrowed to the mechanical case on this identity's own claim,
with the contested case named as staying a person's.

The sentence being narrowed is load-bearing and appears in more than one place, so the change
must find every copy rather than the first one. `step-merge-conflicts.sh`'s own header carries
the fullest statement of the reasoning, and that reasoning is **answered rather than dropped**:
a third party rebasing races the holder's pushes, and this act is neither a third party nor a
rebase.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol's home; the reading's
  classification and the writer's bounds.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — its header states the
  standing rule; the narrowing must be recorded there too.
- `CLAUDE.md` — the claim-protocol section and the `/implement` contract row.
- `plugins/workaholic/skills/drive/SKILL.md` — the routing table's `content` conflict row.

## Implementation Steps

1. Find every copy of the standing rule before editing any of them.
2. State in `claims.md`: the four-valued reading and its classification as judgements, the
   writer's six refusals, the order of its acts, and what it never does (no rebase, no amend,
   no force-push, no scan-held pull request, no colleague's claim).
3. Record the narrowing where the standing rule lives, answering its reasoning by name rather
   than deleting it.
4. Update `CLAUDE.md` in the same commit — this repository treats outdated documentation as a
   defect, and `doc-drift.sh` is a backstop rather than the check.
5. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) if any workflow skill or its
   script closure moved.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The narrowing is stated in every place the standing rule appears.
- The standing rule's reasoning is answered by name, not dropped.
- `CLAUDE.md` is updated in the same change.
- `outputs/` is regenerated and CI's freshness check is clean.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- No documentation drift, and the generated bundle diff is empty after a rebuild.

## Considerations

Writing the reversal in one place and leaving another copy standing is the failure mode here;
the rule is quoted in prose rather than derived from a constant, so only a search finds them all.
