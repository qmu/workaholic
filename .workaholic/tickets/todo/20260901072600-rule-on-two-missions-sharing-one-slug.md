---
created_at: 2026-09-01T07:26:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: 20260826071745-say-when-the-loop-has-run-out-of-direction.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
claim: work-20260901-074324
---

# Rule on two missions sharing one slug

## Overview

`main` carries **two** tracked `mission.md` files whose `slug:` is
`say-when-the-loop-has-run-out-of-direction` — one under `missions/active/`
(`created_at: 2026-08-26T07:19:28`, `feedback: [20260826071745-…]`) and one under
`missions/archive/` (`created_at: 2026-08-26T08:19:15`, `status: achieved`,
`actual_hours: 1.1`, `feedback: [20260826081729-…]`). Different asks, different records,
one slug.

**How it happened, measured from git on 2026-09-01** — and this is the finding, because it
is not the seam the first reading of this ticket assumed:

| When | What |
| ---- | ---- |
| 2026-08-26 07:19:28 | Record A created in a publish tree. The base carried no such mission, so `create.sh` correctly saw no collision. |
| 2026-08-26 08:19:15 | Record B created in a **different** publish tree. Record A was still unmerged, so the base still carried no such mission and `create.sh` again correctly saw no collision. |
| 2026-08-26 08:25:18 | Record B merged (`35147ec2`). |
| 2026-09-01 06:22:15 | Record A merged (`01ed9ae9`, PR #625) — **six days stranded** — landing a second record beside the first. |

Git raised no conflict at that merge because record B had by then been archived, so the two
records occupy **different paths** (`active/` vs `archive/`) and nothing collided.

**Two premises this ticket originally carried are false, and are corrected here rather than
implemented against.** `mission/scripts/create.sh` **already** refuses a slug that exists in
either area (`{"created": false, "reason": "exists"}`, line 75; its header states "either
area (active/ or archive/)"). And `mission/scripts/close.sh` **already** handles an occupied
destination deliberately — lines 287-291 report `reason: archive_slug_conflict` and keep the
mission where it is rather than nesting directories, with a comment naming it "a conflicted
state a human must resolve". Neither is the defect.

The real seam is that **`create.sh`'s check reads the tree it is writing into**, which is
correct when the publish tree is built and arbitrarily stale by the time that tree merges.
A publication stranded for six days carries a six-day-old collision check.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a reading that could not be made is named

## Key Files

- `.workaholic/missions/active/say-when-the-loop-has-run-out-of-direction/mission.md` —
  record A; driven and closed `achieved` on 2026-09-01, still in `active/` because the
  destination is occupied.
- `.workaholic/missions/archive/say-when-the-loop-has-run-out-of-direction/mission.md` —
  record B, occupying the destination.
- `plugins/workaholic/skills/mission/scripts/create.sh` — the collision check (line 75); it
  reads the local tree, which is the whole of the seam.
- `plugins/workaholic/skills/mission/scripts/close.sh` — lines 287-291, the existing
  `archive_slug_conflict` answer. **Working as designed; do not "fix" it.**
- `plugins/workaholic/skills/specificate/scripts/lib/unmerged-branches.sh` — the walk
  `/specificate` already uses to see unmerged branches; the candidate reuse.
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — `mission_resolve`, the
  slug-keyed resolver every reader composes; it searches `active/` then `archive/` and
  returns the first hit.

## Implementation Steps

1. Re-read the Overview's table against git before changing anything — the diagnosis is the
   deliverable here, and a repair aimed at `create.sh`'s area coverage or at `close.sh`
   would be aimed at a seam that is already closed.
2. Decide where a stale collision check should be caught. The two candidates, both real:
   extend `create.sh`'s check to consult unmerged branches through the existing
   `unmerged-branches.sh` walk (catches it at build time, and would have caught this case at
   08:19), or catch it at merge time, where no writer currently looks.
3. Weigh the cost of the first honestly: that walk **over-reads on every ambiguity** by
   design, which is right for a dedup and wrong for a gate — an over-read there becomes a
   refusal to create a legitimate mission. If it is adopted, the ambiguous case must not
   refuse; report it and proceed.
4. Note why `/specificate`'s existing ask-dedup did not prevent this: it keys on feedback
   refs, and these two proposals carried **different** refs (`20260826071745-…` and
   `20260826081729-…`) for one topic. A slug check is not reachable from a ref check.
5. Give `mission_resolve` an answer for two matches. Reporting the ambiguity by name is the
   shape this repository uses everywhere else (`ambiguous_claim`); returning the first area
   searched is what it does today, which makes every downstream reading area-order
   dependent. Changing its return shape touches every caller — scope it deliberately.
6. The disposition of the two existing records is a **ruling, not a step** — see Open
   Decisions. Do not delete, merge, rename or re-slug either record without it.

## Open Decisions

- **Which of the two records is authoritative, and what becomes of the other?**

  **Sources consulted.** `CLAUDE.md`'s *Mission lifecycle* paragraph in full: `status:
  active | achieved | abandoned | carried`, `close.sh` the only writer of an end state,
  `archive.sh` closing only "the one outcome that is arithmetic" and **never** `abandoned`
  or `carried`, "which assert intent". It says nothing about two records sharing a slug.
  `skills/mission/SKILL.md` was read for a uniqueness rule and states none — the slug is
  treated throughout as though unique without anything establishing it. `create.sh` and
  `close.sh` were both read in full, and both already do what this ticket first assumed
  they did not, which is recorded in the Overview. Both mission records were read: they
  cite different feedback refs, so neither is a copy of the other. The git history of both
  paths was walked to build the Overview's table.

  **The fork.** Either record B (archived, `achieved`, `actual_hours: 1.1`) stays
  authoritative and record A is re-slugged to a distinct name before being archived under
  it — preserving both histories, at the cost of a migration for every `mission:` relation
  naming the old slug — or the two are recognised as one line of work and consolidated into
  a single record, losing one record's changelog, acceptance and hours.

  Nothing in the repository settles which. Both records were authored by `a@qmu.jp`; the
  question is whether they were meant to be one mission, and that is the operator's ruling.
  It is available to be made rather than unanswerable.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The stale-check seam identified in step 2 is closed at one named place, and a slug already
  taken on an **unmerged branch** cannot be minted a second time without that being reported
- No new refusal path can block mission creation on an ambiguous or degraded read — such a
  read is reported and creation proceeds
- `close.sh`'s `archive_slug_conflict` answer is **unchanged**
- `create.sh`'s existing both-areas check is **unchanged**
- The disposition of the two existing records follows the Open Decision's ruling; neither is
  deleted, merged or re-slugged before it

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a case seeding a slug present only on an
  unmerged branch, asserting the chosen behaviour, and a case asserting a degraded walk does
  not refuse creation
- A case asserting `close.sh` still answers `archive_slug_conflict` with the mission left in
  place, and one asserting `create.sh` still refuses a slug present in either local area
- `git ls-tree -r --name-only origin/main -- .workaholic/missions/` piped through a
  duplicate check on the slug
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The suite passes; the duplicate check is clean; the Open Decision carries a recorded ruling
