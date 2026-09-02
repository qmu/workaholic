---
created_at: 2026-09-02T04:26:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Let the tick resolve a content conflict, not defer it

## Overview

PROPOSED. The tick's current line — "we do not rebase here; generated-index conflicts are
catch-up's to resolve and content conflicts belong to the claim holder" — is the operator's
central correction: completely wrong. The tick must bring every conflicted pull request into
a mergeable state itself, rebasing or merging as appropriate.

Today `content` is a terminal refusal everywhere it appears: `catch-up-claim.sh` refuses
`content_conflict`, `settle-stranded-publication.sh` refuses `not_mechanical:<class>`, and
`/moderate`'s `catchup-blocked` and `stranded-publications` steps turn that refusal into a
question addressed to a claim holder. This ticket gives the tick a resolution act for the
class it currently declines.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — what an unattended act may do, and what it must prove first

## Key Files

- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — the one merge engine; the
  resolution composes it and never becomes a second one.
- `plugins/workaholic/skills/ship/scripts/lib/conflict-class.sh` — the one classification
  rule; `content` keeps its meaning, what changes is what the caller does with it.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` — refuses `content_conflict`
  today; the act is added beside that refusal.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — the same
  refusal on the publication side.
- `plugins/workaholic/skills/drive/reference/claims.md` — where an act's licence, its
  idempotence and its refusal vocabulary are contracted.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the bounds prose this widens.

## Implementation Steps

1. Reproduce a `content` conflict offline in a throwaway repository — two branches editing
   the same lines of one file — and confirm today's refusal, so the change is measured
   against a real case rather than a described one.
2. Decide and state the resolution strategy per class, in `claims.md`, before writing it:
   which side wins for a generated file, what a regenerable file does, and what happens to a
   genuinely divergent hand-written hunk. The operator's instruction is that the tick
   decides; that decision must be written down where a reader can argue with it.
3. Implement the act by composing `catchup-main.sh` — never a second merge engine — and
   regenerate with the repository's own tooling afterwards, exactly as the mechanical path
   already does.
4. Run the repository's fast checks before pushing, and refuse `validation_failed:<check>`
   rather than pushing a resolution that does not build. This is the one bound that is not
   negotiable: resolving must not mean shipping something broken.
5. Keep every act property `claims.md` already requires: re-derive the class at the moment
   of the act, be idempotent, be reversible, and refuse every bound by its own word with
   nothing pushed.
6. Widen the bounds prose in `workaholic:moderate` and `CLAUDE.md` in the same change — the
   tick used to say it never pushes into a branch the claim protocol owns, and that sentence
   is now false. Say what it may do and what it still may not.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `content`-classed pull request the tick can settle is brought to mergeable by the tick.
- The resolution strategy is written down per class before it is applied.
- A resolution that fails the repository's fast checks is refused, with nothing pushed.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- The offline reproduction from step 1, re-run: refusal before, resolution after.

**Gate** — what must pass before approval:

- The act is idempotent: running it twice leaves the branch byte-identical after the first.
- A refusal path leaves no worktree and no pushed ref behind.

## Considerations

- This widens what an unattended tick may write, and the widening is the operator's
  instruction rather than the loop's own reading. Bound it in the code and say so in the
  prose: fast checks before every push, one merge engine, refusals by name.
- A resolution that silently discards a person's hunk is the failure mode to design
  against. Where a hunk cannot be resolved without losing behaviour, the honest act is to
  refuse by name — and that residue is what the mission's third acceptance item is about.
