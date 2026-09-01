---
created_at: 2026-09-01T08:26:35+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: settle-a-mergeability-reading-before-it-becomes-a-question
merge_policy:
verification_handoff: 
---

# State that GitHub applies no merge driver

## Overview

`merge=union` on the generated OKF indexes landed 2026-08-31 to stop concurrent unit
branches colliding on a file nobody authored, and the record written with it — the
`.gitattributes` header, the `index_merge_union` repair in the web bootstrap, and the
branch story — reads as if the occasion were removed. It is not, on the surface that
matters: **GitHub applies no `.gitattributes` merge strategy when it computes a pull
request's `mergeable` or when the merge button runs**, so those pull requests still show
`CONFLICTING` and cannot be merged from the web. The operator measured it, and this
repository measured it independently the same day (ticket `20260901041500`, same git and
the same two commits: from the checkout `merge-tree` exits 0, from a clone with no
`.gitattributes` it exits 1 and the API answers `mergeable_state: "dirty"`).

`CLAUDE.md` carries the correction and `claim-mergeability.sh` now predicts the remote's
answer. The **shipped** artifacts a consuming repository reads still do not, which is how a
recorded outcome stays true only off GitHub.

## Policies

- `workaholic:development` / `policies/change-history.md` — a record that overstates an outcome is a defect
- `workaholic:operation` / `policies/external-dependency.md` — state where a third party's behaviour differs from local git
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.gitattributes` — its header states the union repair and its cost; it never says the
  remote applies none of it.
- `plugins/workaholic/skills/workaholify/scripts/apply-bootstrap.sh` — writes that same
  header text into every consuming repository's `.gitattributes`; the primary carrier.
- `plugins/workaholic/skills/workaholify/scripts/check-bootstrap.sh` — the
  `index_merge_union` problem text a reader sees first.
- `plugins/workaholic/skills/workaholify/SKILL.md` — the bootstrap's own record.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — already carries the
  measurement; the source the corrected wording cites rather than restates.

## Implementation Steps

1. **Reproduce first**, so the correction rests on this session's own reading and not on a
   quoted one: pick an open pull request whose only conflict is a generated index, run
   `git merge-tree --write-tree <base> <branch>` from the checkout (attributes in reach) and
   again from an empty directory with `GIT_DIR` set (attributes out of reach), and read the
   API's `mergeable` / `mergeable_state` for the same pull request. Record all three.
2. **Localize** every place the union repair's outcome is written: `.gitattributes`'s
   header, the text `apply-bootstrap.sh` appends, `check-bootstrap.sh`'s problem string,
   and `workaholify/SKILL.md`. List them before editing any.
3. Add one clause to each, in that surface's own voice: the driver resolves the conflict
   for every **local** merge and for none of the remote's, so a branch still has to be
   caught up and pushed before GitHub will merge it. Keep it to a clause — the full
   measurement lives in `claim-mergeability.sh` and `CLAUDE.md`, and a third copy is how
   three copies drift.
4. Do **not** remove the union attribute. It is not the defect: the writer
   (`catchup-main.sh`) still resolves such a path with no judgement, which is why
   `mechanical` is the honest class and why the existing catch-up settles these branches.
5. Update `CLAUDE.md`'s `/workaholify` §1 clause only if the reproduction contradicts it;
   it already carries the correction, and the docs rule requires the same-commit update of
   whatever this change makes stale.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `.gitattributes`, `apply-bootstrap.sh`'s appended text, `check-bootstrap.sh` and
  `workaholify/SKILL.md` each state that GitHub applies no `.gitattributes` merge driver
  when it computes `mergeable`.
- The union attribute and every existing line of those files are otherwise unchanged;
  `apply-bootstrap.sh` still rewrites no existing line and stays idempotent.
- No new measurement is restated beyond the one clause; the full record stays in one place.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the bootstrap rows, unchanged behaviour)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- Run `apply-bootstrap.sh` twice in a throwaway clone: the second run appends nothing.

**Gate** — what must pass before approval:

- All three commands above pass and `outputs/` is regenerated in the same commit.

## Considerations

- The ask says "correct the record that says the union attribute solved this". The branch
  story that recorded it is history and is **not** rewritten — a story is an append-only
  record of what a branch did, and the repair is the forward-facing artifacts a consuming
  repository actually reads.
- `apply-bootstrap.sh` is the surface with the widest reach: a consuming repository's
  `.gitattributes` is written from it, so a clause added only to this repository's own file
  reaches nobody.
